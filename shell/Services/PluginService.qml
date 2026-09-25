pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.config as G

// Plugin DankMaterialShell nella shell green-hyprtheme.
//  - catalogo: registro ufficiale github.com/AvengeMedia/dms-plugin-registry
//  - installazione: git clone in ~/.config/hypr/plugins/<id>  (cartella esclusa da git)
//  - stato: state/plugins.json (attivi), state/plugin-settings.json, state/plugin-state.json
// Espone anche l'API che i plugin DMS si aspettano (loadPluginData, savePluginData, globalVars…).
Singleton {
    id: root

    readonly property string pluginDirectory: G.Settings.rootDir + "/plugins"
    readonly property string registryUrl: "https://codeload.github.com/AvengeMedia/dms-plugin-registry/tar.gz/refs/heads/master"

    // Superfici supportate dalla shell
    readonly property var supportedSurfaces: ["widget", "daemon"]

    property var availablePlugins: ({})      // id → manifest + { pluginDirectory, components, surface, supported }
    readonly property var availablePluginsList: Object.keys(availablePlugins).map(k => availablePlugins[k]).sort((a, b) => (a.name || a.id).localeCompare(b.name || b.id))
    property var loadedPlugins: ({})
    property var pluginDaemonInstances: ({})
    property var globalVars: ({})
    property var pluginLoadErrors: ({})

    property var catalog: []                 // voci del registro
    property bool catalogLoading: false
    property string catalogError: ""
    property var busy: ({})                  // id → "install" | "remove" | "update"

    readonly property var enabledIds: pstate.enabled
    readonly property var barPlugins: availablePluginsList.filter(p => p.surface === "widget" && p.supported && pstate.enabled.includes(p.id))
    readonly property var daemonPlugins: availablePluginsList.filter(p => p.surface === "daemon" && p.supported && pstate.enabled.includes(p.id))

    signal pluginLoaded(string pluginId)
    signal pluginUnloaded(string pluginId)
    signal pluginDataChanged(string pluginId)
    signal pluginStateChanged(string pluginId)
    signal pluginListUpdated
    signal globalVarChanged(string pluginId, string varName)
    signal registryInstallFinished(string pluginId, bool success)
    signal requestLauncherUpdate(string pluginId)

    // ════════════════ Plugin installati ════════════════

    function rescan() {
        scanProc.running = true;
    }

    function _surfaceOf(m) {
        if (m.components && typeof m.components === "object") {
            for (const s of ["widget", "daemon", "desktop", "launcher", "dash", "dashCard"])
                if (m.components[s])
                    return s;
        }
        const caps = m.capabilities || [];
        if (m.type === "daemon")
            return "daemon";
        if (m.type === "launcher" || caps.includes("launcher"))
            return "launcher";
        if (["desktop", "dash", "dashCard"].includes(m.type))
            return m.type;
        return "widget";
    }

    function _componentPath(m, dir, surface) {
        const strip = p => p.replace(/^\.\//, "");
        if (m.components && m.components[surface])
            return dir + "/" + strip(m.components[surface]);
        return m.component ? dir + "/" + strip(m.component) : "";
    }

    Process {
        id: scanProc
        command: ["sh", "-c", "mkdir -p \"$1\"; for d in \"$1\"/*/; do [ -f \"$d/plugin.json\" ] || continue; printf '%s\\t' \"${d%/}\"; tr -d '\\n\\r' < \"$d/plugin.json\"; echo; done", "_", root.pluginDirectory]
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
                        const id = m.id || dir.split("/").pop();
                        const surface = root._surfaceOf(m);
                        const comp = root._componentPath(m, dir, surface);
                        map[id] = Object.assign({}, m, {
                            id: id,
                            pluginDirectory: dir,
                            surface: surface,
                            componentPath: comp,
                            settingsPath: m.settings ? dir + "/" + m.settings.replace(/^\.\//, "") : "",
                            supported: root.supportedSurfaces.includes(surface) && comp !== ""
                        });
                    } catch (e) {
                        console.warn("Plugin: plugin.json non valido in", dir, e);
                    }
                }
                root.availablePlugins = map;
                root.pluginListUpdated();
            }
        }
    }

    function isInstalled(id) {
        return availablePlugins[id] !== undefined;
    }
    function isEnabled(id) {
        return pstate.enabled.includes(id);
    }
    function setEnabled(id, on) {
        const list = pstate.enabled.filter(x => x !== id);
        if (on)
            list.push(id);
        pstate.enabled = list;
    }
    function togglePlugin(id) {
        setEnabled(id, !isEnabled(id));
    }
    function isPluginLoaded(id) {
        return isEnabled(id) && isInstalled(id);
    }
    function getPluginPath(id) {
        return availablePlugins[id]?.pluginDirectory ?? "";
    }
    function componentUrl(path) {
        return path ? "file://" + path : "";
    }
    function getPluginTrigger(id) {
        return "";
    }

    // Istanze dei widget in barra (per aprirne il popup da scorciatoia/IPC)
    property var widgetInstances: ({})
    function registerWidget(id, screenName, item) {
        const w = Object.assign({}, widgetInstances);
        w[id + "@" + screenName] = item;
        widgetInstances = w;
    }
    function openWidgetPopout(id, screenName) {
        const key = Object.keys(widgetInstances).find(k => k === id + "@" + screenName) ?? Object.keys(widgetInstances).find(k => k.startsWith(id + "@"));
        const it = key ? widgetInstances[key] : null;
        if (it && it.triggerPopout)
            it.triggerPopout();
        return !!it;
    }

    // ════════════════ Catalogo e installazione ════════════════

    function fetchCatalog() {
        if (catalogLoading)
            return;
        catalogLoading = true;
        catalogError = "";
        catalogProc.running = true;
    }

    Process {
        id: catalogProc
        command: ["sh", "-c", "curl -fsSL --max-time 30 \"$1\" | tar -xzO --wildcards '*/plugins/*.json' | jq -cs '.'", "_", root.registryUrl]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const list = JSON.parse(text);
                    root.catalog = list.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
                } catch (e) {
                    root.catalogError = "Impossibile scaricare il catalogo (connessione?)";
                }
                root.catalogLoading = false;
            }
        }
    }

    function catalogSupported(entry) {
        const caps = entry.capabilities || [];
        if (caps.includes("desktop-widget") || caps.includes("launcher") || caps.includes("wallpaper"))
            return caps.includes("dankbar-widget");
        return caps.includes("dankbar-widget") || caps.includes("daemon") || caps.includes("ipc") || caps.includes("control-center");
    }

    function _setBusy(id, what) {
        const b = Object.assign({}, busy);
        if (what)
            b[id] = what;
        else
            delete b[id];
        busy = b;
    }

    function install(entry) {
        if (busy[entry.id])
            return;
        _setBusy(entry.id, "install");
        const sources = Object.assign({}, pstate.sources);
        sources[entry.id] = { repo: entry.repo, path: entry.path || "" };
        pstate.sources = sources;
        const proc = installComp.createObject(root, {
            pluginId: entry.id,
            command: ["sh", "-c", root.installScript, "_", entry.repo, entry.path || "", root.pluginDirectory, entry.id]
        });
        proc.running = true;
    }

    function update(id) {
        const src = pstate.sources[id];
        if (!src)
            return;
        install({ id: id, repo: src.repo, path: src.path });
    }

    function uninstall(id) {
        _setBusy(id, "remove");
        setEnabled(id, false);
        SettingsData.removePluginSettings(id);
        const dir = getPluginPath(id) || (pluginDirectory + "/" + id);
        const proc = installComp.createObject(root, {
            pluginId: id,
            removing: true,
            command: ["sh", "-c", "case \"$1\" in \"$2\"/*) rm -rf -- \"$1\";; esac", "_", dir, root.pluginDirectory]
        });
        proc.running = true;
    }

    // clona in una cartella temporanea, prende la sottocartella indicata (o quella con plugin.json)
    readonly property string installScript: "set -e\n" + "repo=\"$1\"; sub=\"$2\"; dir=\"$3\"; id=\"$4\"\n" + "tmp=$(mktemp -d)\n" + "trap 'rm -rf \"$tmp\"' EXIT\n" + "git clone --depth 1 --quiet \"$repo\" \"$tmp/r\"\n" + "src=\"$tmp/r/$sub\"\n" + "if [ ! -f \"$src/plugin.json\" ]; then\n" + "  f=$(find \"$tmp/r\" -maxdepth 3 -name plugin.json | head -n1)\n" + "  [ -n \"$f\" ] || { echo 'plugin.json non trovato' >&2; exit 2; }\n" + "  src=$(dirname \"$f\")\n" + "fi\n" + "mkdir -p \"$dir\"\n" + "rm -rf -- \"$dir/$id\"\n" + "cp -r \"$src\" \"$dir/$id\"\n" + "rm -rf \"$dir/$id/.git\"\n"

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
                    ToastService.showInfo("Plugin rimosso: " + pluginId);
                } else if (code === 0) {
                    root.setEnabled(pluginId, true);
                    ToastService.showInfo("Plugin installato: " + pluginId);
                    root.registryInstallFinished(pluginId, true);
                } else {
                    ToastService.showError("Installazione non riuscita: " + pluginId, p.err);
                    root.registryInstallFinished(pluginId, false);
                }
                root.rescan();
                p.destroy();
            }
        }
    }

    // ════════════════ Dati, stato, variabili globali (API DMS) ════════════════

    function savePluginData(pluginId, key, value) {
        SettingsData.setPluginSetting(pluginId, key, value);
        pluginDataChanged(pluginId);
        return true;
    }
    function loadPluginData(pluginId, key, defaultValue) {
        return SettingsData.getPluginSetting(pluginId, key, defaultValue);
    }

    function loadPluginState(pluginId, key, defaultValue) {
        const s = pluginState.data[pluginId];
        return s && s[key] !== undefined ? s[key] : defaultValue;
    }
    function savePluginState(pluginId, key, value) {
        const d = JSON.parse(JSON.stringify(pluginState.data));
        if (!d[pluginId])
            d[pluginId] = {};
        d[pluginId][key] = value;
        pluginState.data = d;
        pluginStateChanged(pluginId);
    }
    function clearPluginState(pluginId) {
        const d = JSON.parse(JSON.stringify(pluginState.data));
        delete d[pluginId];
        pluginState.data = d;
        pluginStateChanged(pluginId);
    }
    function removePluginStateKey(pluginId, key) {
        const d = JSON.parse(JSON.stringify(pluginState.data));
        if (d[pluginId])
            delete d[pluginId][key];
        pluginState.data = d;
        pluginStateChanged(pluginId);
    }

    function setGlobalVar(pluginId, varName, value) {
        const g = Object.assign({}, globalVars);
        g[pluginId] = Object.assign({}, g[pluginId] || {});
        g[pluginId][varName] = value;
        globalVars = g;
        globalVarChanged(pluginId, varName);
    }
    function getGlobalVar(pluginId, varName, defaultValue) {
        const g = globalVars[pluginId];
        return g && g[varName] !== undefined ? g[varName] : defaultValue;
    }

    // Varianti (istanze multiple dello stesso widget)
    function getPluginVariants(pluginId) {
        return SettingsData.getPluginSetting(pluginId, "variants", []);
    }
    function createPluginVariant(pluginId, variantName, variantConfig) {
        const v = getPluginVariants(pluginId).slice();
        const id = "variant_" + Date.now();
        v.push(Object.assign({ id: id, name: variantName }, variantConfig || {}));
        savePluginData(pluginId, "variants", v);
        return id;
    }
    function removePluginVariant(pluginId, variantId) {
        savePluginData(pluginId, "variants", getPluginVariants(pluginId).filter(x => x.id !== variantId));
    }
    function updatePluginVariant(pluginId, variantId, variantConfig) {
        savePluginData(pluginId, "variants", getPluginVariants(pluginId).map(x => x.id === variantId ? Object.assign({}, x, variantConfig) : x));
    }
    function getPluginVariantData(pluginId, variantId) {
        return getPluginVariants(pluginId).find(x => x.id === variantId) ?? null;
    }

    // ════════════════ Persistenza ════════════════

    FileView {
        path: G.Settings.rootDir + "/state/plugins.json"
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
        }
        JsonAdapter {
            id: pstate
            property var enabled: []
            property var sources: ({})
        }
    }

    FileView {
        path: G.Settings.rootDir + "/state/plugin-state.json"
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
        }
        JsonAdapter {
            id: pluginState
            property var data: ({})
        }
    }

    Component.onCompleted: rescan()
}
