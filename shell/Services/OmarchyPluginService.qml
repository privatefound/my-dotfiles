pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.config as G

// Plugin Omarchy (https://plugins.omarchy.org) nella shell WhiteRabbitShell.
//  - catalogo: catalog.json del marketplace, ridotto con jq e messo in cache
//  - installazione: git clone in ~/.config/hypr/plugins/omarchy/<id>  (esclusa da git)
//  - stato: state/omarchy-plugins.json (attivi + impostazioni dei widget)
// Tipi supportati: bar-widget, service, panel, overlay, menu (la barra completa "bar" no).
Singleton {
    id: root

    readonly property string pluginDirectory: G.Settings.rootDir + "/plugins/omarchy"
    readonly property string catalogUrl: "https://plugins.omarchy.org/catalog.json"
    readonly property string siteUrl: "https://plugins.omarchy.org/"
    readonly property string catalogCache: Quickshell.cachePath("omarchy-catalog.json")
    readonly property var supportedKinds: ["bar-widget", "service", "panel", "overlay", "menu"]

    property var installed: ({})             // id → manifest (+ __sourceDir)
    readonly property var installedList: Object.keys(installed).map(k => installed[k]).sort((a, b) => (a.name || a.id).localeCompare(b.name || b.id))
    readonly property var enabledIds: ostate.enabled
    readonly property var barWidgets: installedList.filter(m => isEnabled(m.id) && hasKind(m, "bar-widget") && m.entryPoints?.barWidget)

    property var catalog: []
    property bool catalogLoading: false
    property string catalogError: ""
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
        return true;
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
        command: ["sh", "-c", "mkdir -p \"$1\"; for d in \"$1\"/*/; do [ -f \"$d/manifest.json\" ] || continue; printf '%s\\t' \"${d%/}\"; tr -d '\\n\\r' < \"$d/manifest.json\"; echo; done", "_", root.pluginDirectory]
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

    // ════════════════ Catalogo ════════════════

    // campi utili per la ricerca, ordinati per stelle
    readonly property string slimFilter: "[.plugins[] | select(.installAvailable == true and .repositoryLayout == \"root-plugin\") | {id, name, description, author, version, repo, kind, category, stars: (.stars // 0), verified: (.verificationStatus == \"verified\"), tags: (.tags // []), thumb: (.previewThumbnail // \"\")}] | sort_by(-.stars)"

    function fetchCatalog(force) {
        if (catalogLoading)
            return;
        catalogLoading = true;
        catalogError = "";
        catalogProc.command = ["sh", "-c", "c=\"$1\"; if [ \"$3\" = 1 ] || [ ! -s \"$c\" ] || [ -n \"$(find \"$c\" -mmin +360)\" ]; then curl -fsSL --max-time 60 \"$2\" | jq -c \"$4\" > \"$c.tmp\" && mv \"$c.tmp\" \"$c\"; fi; cat \"$c\"", "_", catalogCache, catalogUrl, force ? "1" : "0", slimFilter];
        catalogProc.running = true;
    }

    Process {
        id: catalogProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.catalog = JSON.parse(text);
                } catch (e) {
                    root.catalogError = "Impossibile scaricare il catalogo (connessione?)";
                }
                root.catalogLoading = false;
            }
        }
    }

    function catalogSupported(entry) {
        return entry.kind !== "Bar";
    }

    // ════════════════ Installazione ════════════════

    function _setBusy(id, what) {
        const b = Object.assign({}, busy);
        if (what)
            b[id] = what;
        else
            delete b[id];
        busy = b;
    }

    function install(entry) {
        if (busy[entry.id] || !/^[A-Za-z0-9._-]+$/.test(entry.id))
            return;
        _setBusy(entry.id, "install");
        const sources = Object.assign({}, ostate.sources);
        sources[entry.id] = { repo: entry.repo };
        ostate.sources = sources;
        const proc = installComp.createObject(root, {
            pluginId: entry.id,
            command: ["sh", "-c", root.installScript, "_", entry.repo, root.pluginDirectory, entry.id]
        });
        proc.running = true;
    }

    function update(id) {
        const src = ostate.sources[id];
        if (src)
            install({ id: id, repo: src.repo });
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
            removing: true,
            command: ["sh", "-c", "case \"$1\" in \"$2\"/*) rm -rf -- \"$1\";; esac", "_", dir, root.pluginDirectory]
        });
        proc.running = true;
    }

    // clona, verifica che manifest.json abbia lo stesso id, copia senza .git
    readonly property string installScript: "set -e\n" + "repo=\"$1\"; dir=\"$2\"; id=\"$3\"\n" + "case \"$repo\" in https://*) ;; *) echo 'repository non valido' >&2; exit 2;; esac\n" + "tmp=$(mktemp -d)\n" + "trap 'rm -rf \"$tmp\"' EXIT\n" + "git clone --depth 1 --quiet \"$repo\" \"$tmp/r\"\n" + "[ -f \"$tmp/r/manifest.json\" ] || { echo 'manifest.json non trovato' >&2; exit 2; }\n" + "mid=$(jq -r .id \"$tmp/r/manifest.json\")\n" + "[ \"$mid\" = \"$id\" ] || { echo \"id del manifest diverso: $mid\" >&2; exit 2; }\n" + "rm -rf \"$tmp/r/.git\"\n" + "mkdir -p \"$dir\"\n" + "rm -rf -- \"$dir/$id\"\n" + "mv \"$tmp/r\" \"$dir/$id\"\n"

    Component {
        id: installComp
        Process {
            id: p
            property string pluginId
            property bool removing: false
            property string err: ""
            stderr: StdioCollector {
                onStreamFinished: p.err = text.trim()
            }
            onExited: code => {
                root._setBusy(pluginId, "");
                if (removing) {
                    Quickshell.execDetached(["notify-send", "-a", "Plugin", "Plugin rimosso", pluginId]);
                } else if (code === 0) {
                    const list = ostate.enabled.filter(x => x !== pluginId);
                    list.push(pluginId);
                    ostate.enabled = list;
                    Quickshell.execDetached(["notify-send", "-a", "Plugin", "Plugin Omarchy installato", pluginId]);
                } else {
                    Quickshell.execDetached(["notify-send", "-a", "Plugin", "-u", "critical", "Installazione non riuscita: " + pluginId, p.err]);
                }
                // ricarica: un plugin aggiornato deve ricrearsi da zero
                if (!removing && code === 0) {
                    root._drop(pluginId);
                }
                root.rescan();
                p.destroy();
            }
        }
    }

    function _drop(id) {
        if (services[id]) {
            const s = Object.assign({}, services);
            s[id].destroy();
            delete s[id];
            services = s;
        }
        if (panels[id]) {
            const p = Object.assign({}, panels);
            p[id].destroy();
            delete p[id];
            panels = p;
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
