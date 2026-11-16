pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.config as G

// Plugin Omarchy (https://plugins.omarchy.org) nella shell WhiteRabbitShell.
//  - plugin in ~/.config/hypr/plugins/omarchy/<id>  (esclusa da git); niente più catalogo/installazione
//  - stato: state/omarchy-plugins.json (attivi + impostazioni dei widget)
// Tipi supportati: bar-widget, service, panel, overlay, menu (la barra completa "bar" no).
Singleton {
    id: root

    readonly property string pluginDirectory: G.Settings.rootDir + "/plugins/omarchy"
    // Qt ≥ 6.12: `Color` globale nasconde quello del tema Omarchy; lo script qualifica i riferimenti
    readonly property string colorFix: G.Settings.rootDir + "/scripts/omarchy-compat/fix-qt-color"
    readonly property var supportedKinds: ["bar-widget", "service", "panel", "overlay", "menu"]

    property var installed: ({})             // id → manifest (+ __sourceDir)
    readonly property var installedList: Object.keys(installed).map(k => installed[k]).sort((a, b) => (a.name || a.id).localeCompare(b.name || b.id))
    readonly property var enabledIds: ostate.enabled
    readonly property var barWidgets: installedList.filter(m => isEnabled(m.id) && hasKind(m, "bar-widget") && m.entryPoints?.barWidget)

    property var busy: ({})

    // istanze vive
    property var services: ({})              // id → oggetto servizio
    property var panels: ({})                // id → oggetto panel/overlay/menu
    property var widgetInstances: ({})       // "id@schermo" → widget in barra
    property var _shellApis: ({})

    signal pluginListUpdated

    // `kinds` letto da una property var torna come sequenza Qt, non come Array JS:
    // Array.isArray() darebbe false, quindi lo si converte sempre
    function kindsOf(m) {
        return m && m.kinds ? Array.from(m.kinds) : [];
    }
    function hasKind(m, kind) {
        return kindsOf(m).includes(kind);
    }
    function isSupported(m) {
        return kindsOf(m).some(k => supportedKinds.includes(k));
    }
    function isInstalled(id) {
        return installed[id] !== undefined;
    }
    function isEnabled(id) {
        return ostate.enabled.includes(id);
    }
    function setEnabled(id, on) {
        const list = ostate.enabled.filter(x => x !== id);
        if (on)
            list.push(id);
        ostate.enabled = list;
        _sync();
    }

    function entryUrl(m, kind) {
        const ep = m?.entryPoints?.[kind];
        const dir = m?.__sourceDir || "";
        if (!ep || !dir)
            return "";
        const resolved = dir + "/" + String(ep).replace(/^\.\//, "");
        if (resolved.includes("/../"))
            return "";
        return "file://" + resolved;
    }

    // manifest senza campi interni tranne __sourceDir (come Omarchy)
    function publicManifest(m) {
        return JSON.parse(JSON.stringify(m));
    }

    // ════════════════ Impostazioni widget ════════════════

    function settingsFor(id) {
        const m = installed[id];
        const defaults = m?.barWidget?.defaults || {};
        return Object.assign({}, defaults, ostate.settings[id] || {});
    }
    function updateSettings(id, settings) {
        const s = Object.assign({}, ostate.settings);
        s[id] = Object.assign({}, s[id] || {}, settings || {});
        ostate.settings = s;
        _pushSettings(id);
        return true;
    }
    function resetSettings(id) {
        const s = Object.assign({}, ostate.settings);
        delete s[id];
        ostate.settings = s;
        _pushSettings(id);
    }
    // le istanze vive (widget su ogni barra, servizio, pannello) ricevono subito i nuovi valori
    function _pushSettings(id) {
        const v = settingsFor(id);
        for (const obj of widgetsOf(id).concat([services[id], panels[id]]))
            if (obj && "settings" in obj)
                obj.settings = Object.assign({}, v);
    }

    // ════════════════ API "shell" passata ai plugin ════════════════

    function shellFor(id) {
        if (!_shellApis[id]) {
            const a = Object.assign({}, _shellApis);
            a[id] = shellApiComp.createObject(root, { pluginId: id });
            _shellApis = a;
        }
        return _shellApis[id];
    }

    Component {
        id: shellApiComp
        QtObject {
            required property string pluginId
            readonly property var barConfig: ({ position: "top" })
            readonly property var idleConfig: ({})
            property var appLibrary: null
            function serviceFor(id) {
                return root.services[String(id || "")] || null;
            }
            function firstPartyServiceFor(id) {
                return null;
            }
            function pluginShellForBarEntry(ownerId, moduleName) {
                return root.shellFor(String(ownerId || ""));
            }
            function summon(id, payloadJson) {
                return root.summon(String(id || ""), String(payloadJson || ""));
            }
            function hide(id) {
                return root.hide(String(id || ""));
            }
            function toggle(id, payloadJson) {
                return root.toggle(String(id || ""), String(payloadJson || ""));
            }
            function isPluginOpen(id) {
                return root.isOpen(String(id || ""));
            }
            function updateEntryInline(id, settings) {
                return root.updateSettings(String(id || pluginId), settings);
            }
            function mutateShellConfig(mutator) {
                return false;
            }
        }
    }

    // ════════════════ summon / hide / toggle ════════════════

    function registerWidget(id, screenName, item) {
        const w = Object.assign({}, widgetInstances);
        w[id + "@" + screenName] = item;
        widgetInstances = w;
    }
    function unregisterWidget(id, screenName, item) {
        if (widgetInstances[id + "@" + screenName] !== item)
            return;
        const w = Object.assign({}, widgetInstances);
        delete w[id + "@" + screenName];
        widgetInstances = w;
    }
    function widgetsOf(id) {
        return Object.keys(widgetInstances).filter(k => k.startsWith(id + "@")).map(k => widgetInstances[k]);
    }
    // widget sul monitor col focus, altrimenti il primo disponibile
    function _widget(id) {
        const mon = Hyprland.focusedMonitor?.name ?? "";
        return widgetInstances[id + "@" + mon] ?? widgetsOf(id)[0] ?? null;
    }

    function summon(id, payload) {
        const m = installed[id];
        if (!m || !isEnabled(id))
            return false;
        if (hasKind(m, "bar-widget")) {
            const w = _widget(id);
            if (w && typeof w.open === "function") {
                w.open();
                return true;
            }
        }
        const p = _ensurePanel(id);
        if (!p)
            return false;
        if (typeof p.open === "function") {
            try {
                p.open(payload || "");
            } catch (e) {
                console.warn("Omarchy", id, "open()", e);
            }
        }
        return true;
    }
    function hide(id) {
        const w = _widget(id);
        if (w && typeof w.close === "function")
            w.close();
        const p = panels[id];
        if (p && typeof p.close === "function")
            p.close();
        return true;
    }
    function isOpen(id) {
        const w = _widget(id);
        if (w && w.opened === true)
            return true;
        const p = panels[id];
        return !!p && (p.opened === true || p.visible === true);
    }
    function toggle(id, payload) {
        return isOpen(id) ? hide(id) : summon(id, payload);
    }

    // ════════════════ Servizi e pannelli ════════════════

    function _create(url, id, cb) {
        const comp = Qt.createComponent(url);
        const make = () => {
            if (comp.status === Component.Ready) {
                const m = installed[id];
                const obj = comp.createObject(root, {});
                if (!obj) {
                    console.warn("Omarchy", id, "creazione fallita");
                    return;
                }
                if ("shell" in obj)
                    obj.shell = shellFor(id);
                if ("manifest" in obj)
                    obj.manifest = publicManifest(m);
                if ("service" in obj)
                    obj.service = services[id] || null;
                if ("settings" in obj)
                    obj.settings = settingsFor(id);
                cb(obj);
            } else if (comp.status === Component.Error) {
                console.warn("Omarchy", id, comp.errorString());
            }
        };
        if (comp.status === Component.Loading)
            comp.statusChanged.connect(make);
        else
            make();
    }

    function _panelKind(m) {
        return ["panel", "overlay", "menu"].find(k => hasKind(m, k) && m.entryPoints?.[k]) ?? "";
    }

    function _ensurePanel(id) {
        if (panels[id])
            return panels[id];
        const m = installed[id];
        const kind = _panelKind(m);
        if (!kind)
            return null;
        let created = null;
        _create(entryUrl(m, kind), id, obj => {
            created = obj;
            const p = Object.assign({}, panels);
            p[id] = obj;
            panels = p;
        });
        return created;
    }

    function _sync() {
        // servizi
        const s = Object.assign({}, services);
        let changed = false;
        for (const id of Object.keys(s)) {
            if (!isInstalled(id) || !isEnabled(id)) {
                s[id].destroy();
                delete s[id];
                changed = true;
            }
        }
        if (changed)
            services = s;
        for (const m of installedList) {
            if (!isEnabled(m.id) || !hasKind(m, "service") || !m.entryPoints?.service || services[m.id])
                continue;
            const id = m.id;
            _create(entryUrl(m, "service"), id, obj => {
                const n = Object.assign({}, services);
                n[id] = obj;
                services = n;
            });
        }
        // pannelli: via quelli disattivati, carica subito i keepLoaded
        const p = Object.assign({}, panels);
        changed = false;
        for (const id of Object.keys(p)) {
            if (!isInstalled(id) || !isEnabled(id)) {
                p[id].destroy();
                delete p[id];
                changed = true;
            }
        }
        if (changed)
            panels = p;
        for (const m of installedList)
            if (isEnabled(m.id) && m.keepLoaded === true && _panelKind(m))
                _ensurePanel(m.id);
    }

    // ════════════════ Plugin installati ════════════════

    function rescan() {
        scanProc.running = true;
    }

    Process {
        id: scanProc
        command: ["sh", "-c", "mkdir -p \"$1\"; \"$2\" \"$1\" 2>/dev/null; for d in \"$1\"/*/; do [ -f \"$d/manifest.json\" ] || continue; printf '%s\\t' \"${d%/}\"; tr -d '\\n\\r' < \"$d/manifest.json\"; echo; done", "_", root.pluginDirectory, root.colorFix]
        stdout: StdioCollector {
            onStreamFinished: {
                const map = {};
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 0)
                        continue;
                    const dir = line.slice(0, tab);
                    try {
                        const m = JSON.parse(line.slice(tab + 1));
                        if (!m.id || !Array.isArray(m.kinds))
                            continue;
                        m.__sourceDir = dir;
                        map[m.id] = m;
                    } catch (e) {
                        console.warn("Omarchy: manifest.json non valido in", dir, e);
                    }
                }
                root.installed = map;
                root._sync();
                root.pluginListUpdated();
            }
        }
    }

    // ════════════════ Rimozione ════════════════

    function _setBusy(id, what) {
        const b = Object.assign({}, busy);
        if (what)
            b[id] = what;
        else
            delete b[id];
        busy = b;
    }

    function uninstall(id) {
        _setBusy(id, "remove");
        setEnabled(id, false);
        const s = Object.assign({}, ostate.settings);
        delete s[id];
        ostate.settings = s;
        const dir = installed[id]?.__sourceDir || (pluginDirectory + "/" + id);
        const proc = installComp.createObject(root, {
            pluginId: id,
            command: ["sh", "-c", "case \"$1\" in \"$2\"/*) rm -rf -- \"$1\";; esac", "_", dir, root.pluginDirectory]
        });
        proc.running = true;
    }

    Component {
        id: installComp
        Process {
            id: p
            property string pluginId
            property string err: ""
            stderr: StdioCollector {
                onStreamFinished: p.err = text.trim()
            }
            onExited: code => {
                root._setBusy(pluginId, "");
                if (code === 0)
                    Quickshell.execDetached(["notify-send", "-a", "Plugin", "Plugin rimosso", pluginId]);
                else
                    Quickshell.execDetached(["notify-send", "-a", "Plugin", "-u", "critical", "Rimozione non riuscita: " + pluginId, p.err]);
                root.rescan();
                p.destroy();
            }
        }
    }

    // ════════════════ Persistenza ════════════════

    FileView {
        path: G.Settings.rootDir + "/state/omarchy-plugins.json"
        onAdapterUpdated: writeAdapter()
        onLoaded: root.rescan()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
            root.rescan();
        }
        JsonAdapter {
            id: ostate
            property var enabled: []
            property var sources: ({})
            property var settings: ({})
        }
    }
}
