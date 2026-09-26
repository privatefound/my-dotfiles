pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Ponte D-Bus compatibile con il servizio "dms" di DankMaterialShell, usato dai plugin
// (es. KDE Connect). Implementato con `busctl --json` (systemd), senza il backend dms.
//
// Formati delle risposte (come in DMS):
//   dbusCall            → { result: { values: [ret0, ret1, …] } }
//   dbusListNames       → { result: { names: [...] } }
//   dbusGetAllProperties→ { result: { prop: value, … } }
//   dbusGetProperty     → { result: { value: v } }
//   errori              → { error: "messaggio" }
// Segnali: dbusSignalReceived(subId, { sender, path, interface, member, body: [...] })
Singleton {
    id: root

    readonly property bool isConnected: true
    signal connectionStateChanged
    signal dbusSignalReceived(string subId, var data)

    property var _subs: []              // { id, bus, service, path, iface, member }
    property var _monitors: ({})        // "bus|service" → Process
    property var _introspection: ({})   // "bus|service|path" → { iface: { method: [sig per overload] , props: { name: sig } } }
    property int _nextId: 1

    // ── utilità ──

    function _busFlag(bus) {
        return bus === "system" ? "--system" : "--user";
    }

    // {type, data} di busctl → valori JS semplici
    function unwrap(v) {
        if (Array.isArray(v))
            return v.map(x => unwrap(x));
        if (v && typeof v === "object") {
            const keys = Object.keys(v);
            if (keys.length === 2 && "type" in v && "data" in v && typeof v.type === "string")
                return unwrap(v.data);
            const o = {};
            for (const k of keys)
                o[k] = unwrap(v[k]);
            return o;
        }
        return v;
    }

    function _guessSig(v) {
        if (typeof v === "boolean")
            return "b";
        if (typeof v === "number")
            return Number.isInteger(v) ? "i" : "d";
        if (Array.isArray(v))
            return "a" + (v.length ? _guessSig(v[0]) : "s");
        return "s";
    }

    // divide una firma D-Bus nei tipi completi di primo livello
    function _splitSig(sig) {
        const out = [];
        let i = 0;
        const one = () => {
            const start = i;
            const c = sig[i++];
            if (c === "a") {
                one();
            } else if (c === "(" || c === "{") {
                const close = c === "(" ? ")" : "}";
                while (sig[i] !== close)
                    one();
                i++;
            }
            return sig.slice(start, i);
        };
        while (i < sig.length)
            out.push(one());
        return out;
    }

    // argomenti per `busctl call` a partire da firma + valori
    function _encode(sig, v) {
        if (sig === "b")
            return [v ? "true" : "false"];
        if (sig === "v") {
            const t = _guessSig(v);
            return [t].concat(_encode(t, v));
        }
        if (sig.startsWith("a{")) {
            const inner = _splitSig(sig.slice(2, -1));
            const entries = Object.entries(v || {});
            let out = [String(entries.length)];
            for (const [k, val] of entries)
                out = out.concat(_encode(inner[0], k), _encode(inner[1], val));
            return out;
        }
        if (sig.startsWith("a")) {
            const inner = sig.slice(1);
            const arr = Array.isArray(v) ? v : [];
            let out = [String(arr.length)];
            for (const x of arr)
                out = out.concat(_encode(inner, x));
            return out;
        }
        return [String(v)];
    }

    // esegue un comando e passa (codice, stdout, stderr) alla callback
    function _run(cmd, cb) {
        const p = runner.createObject(root, { command: cmd, callback: cb });
        p.running = true;
    }

    Component {
        id: runner
        Process {
            id: proc
            property var callback: null
            stdout: StdioCollector {
                id: so
            }
            stderr: StdioCollector {
                id: se
            }
            onExited: code => {
                try {
                    if (proc.callback)
                        proc.callback(code, so.text, se.text);
                } catch (e) {
                    console.warn("[DMSService]", e);
                }
                proc.destroy();
            }
        }
    }

    function _parse(text) {
        try {
            return JSON.parse(text);
        } catch (e) {
            return null;
        }
    }

    // ── introspezione (firme dei metodi e dei tipi delle proprietà) ──

    function _introspect(bus, service, path, cb) {
        const key = bus + "|" + service + "|" + path;
        if (_introspection[key]) {
            cb(_introspection[key]);
            return;
        }
        _run(["busctl", _busFlag(bus), "--json=short", "call", service, path || "/", "org.freedesktop.DBus.Introspectable", "Introspect"], (code, out) => {
            const map = {};
            const j = _parse(out);
            const xml = j ? String(unwrap(j.data)[0] || "") : "";
            const ifaceRe = /<interface name="([^"]+)">([\s\S]*?)<\/interface>/g;
            let m;
            while ((m = ifaceRe.exec(xml)) !== null) {
                const entry = { methods: {}, props: {} };
                const methRe = /<method name="([^"]+)"\s*(\/>|>([\s\S]*?)<\/method>)/g;
                let mm;
                while ((mm = methRe.exec(m[2])) !== null) {
                    const body = mm[3] || "";
                    const argRe = /<arg\b[^>]*>/g;
                    let sig = "", a;
                    while ((a = argRe.exec(body)) !== null) {
                        const tag = a[0];
                        if (/direction="out"/.test(tag))
                            continue;
                        const t = tag.match(/type="([^"]+)"/);
                        if (t)
                            sig += t[1];
                    }
                    (entry.methods[mm[1]] = entry.methods[mm[1]] || []).push(sig);
                }
                const propRe = /<property name="([^"]+)" type="([^"]+)"/g;
                let pp;
                while ((pp = propRe.exec(m[2])) !== null)
                    entry.props[pp[1]] = pp[2];
                map[m[1]] = entry;
            }
            const c = Object.assign({}, _introspection);
            c[key] = map;
            _introspection = c;
            cb(map);
        });
    }

    // ── API usata dai plugin ──

    function dbusListNames(bus, cb) {
        _run(["busctl", _busFlag(bus), "--json=short", "call", "org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus", "ListNames"], (code, out, err) => {
            const j = _parse(out);
            if (code !== 0 || !j)
                cb?.({ error: err.trim() || "ListNames fallita" });
            else
                cb?.({ result: { names: unwrap(j.data)[0] || [] } });
        });
    }

    function dbusCall(bus, service, path, iface, method, args, cb) {
        args = args || [];
        _introspect(bus, service, path, map => {
            const overloads = map[iface]?.methods?.[method] || [];
            let sig = overloads.find(s => _splitSig(s).length === args.length);
            if (sig === undefined)
                sig = args.map(a => _guessSig(a)).join("");
            const types = _splitSig(sig);
            let encoded = [];
            for (let i = 0; i < types.length; i++)
                encoded = encoded.concat(_encode(types[i], args[i]));
            const cmd = ["busctl", _busFlag(bus), "--json=short", "call", service, path, iface, method];
            if (sig)
                cmd.push(sig);
            _run(cmd.concat(encoded), (code, out, err) => {
                const j = _parse(out);
                if (code !== 0)
                    cb?.({ error: err.trim() || ("chiamata " + method + " fallita") });
                else
                    cb?.({ result: { values: j ? unwrap(j.data) : [] } });
            });
        });
    }

    function dbusGetAllProperties(bus, service, path, iface, cb) {
        _run(["busctl", _busFlag(bus), "--json=short", "call", service, path, "org.freedesktop.DBus.Properties", "GetAll", "s", iface], (code, out, err) => {
            const j = _parse(out);
            if (code !== 0 || !j)
                cb?.({ error: err.trim() || "GetAll fallita" });
            else
                cb?.({ result: unwrap(j.data)[0] || {} });
        });
    }

    function dbusGetProperty(bus, service, path, iface, prop, cb) {
        _run(["busctl", _busFlag(bus), "--json=short", "get-property", service, path, iface, prop], (code, out, err) => {
            const j = _parse(out);
            if (code !== 0 || !j)
                cb?.({ error: err.trim() || "get-property fallita" });
            else
                cb?.({ result: { value: unwrap(j) } });
        });
    }

    function dbusSetProperty(bus, service, path, iface, prop, value, cb) {
        _introspect(bus, service, path, map => {
            const sig = map[iface]?.props?.[prop] || _guessSig(value);
            _run(["busctl", _busFlag(bus), "set-property", service, path, iface, prop, sig].concat(_encode(sig, value)), (code, out, err) => {
                if (code !== 0)
                    cb?.({ error: err.trim() || "set-property fallita" });
                else
                    cb?.({ result: {} });
            });
        });
    }

    // Iscrizione ai segnali: un monitor `busctl` per servizio, filtri applicati qui
    function dbusSubscribe(bus, service, path, iface, member, cb) {
        const id = "sub" + (_nextId++);
        _subs = _subs.concat([{ id, bus, service, path, iface, member }]);
        const key = bus + "|" + service;
        if (!_monitors[key]) {
            const mon = monitorComp.createObject(root, {
                command: ["busctl", _busFlag(bus), "--json=short", "monitor", service],
                monKey: key
            });
            const m = Object.assign({}, _monitors);
            m[key] = mon;
            _monitors = m;
            mon.running = true;
        }
        cb?.({ result: { subscriptionId: id } });
        return id;
    }

    function dbusUnsubscribe(subId, cb) {
        _subs = _subs.filter(s => s.id !== subId);
        cb?.({ result: {} });
    }

    function _dispatch(key, msg) {
        if (msg.type !== "signal" || msg.sender === "org.freedesktop.DBus")
            return;
        const data = {
            sender: msg.sender,
            path: msg.path,
            interface: msg.interface,
            member: msg.member,
            body: unwrap(msg.payload?.data ?? [])
        };
        for (const s of _subs) {
            if (s.bus + "|" + s.service !== key)
                continue;
            if (s.path && s.path !== data.path)
                continue;
            if (s.iface && s.iface !== data.interface)
                continue;
            if (s.member && s.member !== data.member)
                continue;
            dbusSignalReceived(s.id, data);
        }
    }

    Component {
        id: monitorComp
        Process {
            id: mon
            property string monKey
            stdout: SplitParser {
                onRead: line => {
                    const j = root._parse(line);
                    if (j)
                        root._dispatch(mon.monKey, j);
                }
            }
            // se il monitor si chiude (es. servizio riavviato) riparte dopo poco
            onExited: restart.start()
            property Timer restart: Timer {
                interval: 3000
                onTriggered: mon.running = true
            }
        }
    }

    // stub rimasti per compatibilità
    function sendRequest(method, params, cb) {
        cb?.({ error: "backend dms non disponibile" });
    }
}
