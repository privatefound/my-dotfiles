pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import qs.config

// Helper per Hyprland (config Lua: i dispatch sono espressioni hl.dsp.*)
Singleton {
    id: root

    readonly property var activeToplevel: Hyprland.activeToplevel
    readonly property string activeTitle: activeToplevel?.title ?? ""
    readonly property string activeClass: activeToplevel?.lastIpcObject?.class ?? ""

    // Modalità di Hyprland attiva ("" = normale, es. "resize" con SUPER+R): mostrata nella barra,
    // perché dentro una modalità le altre scorciatoie (SUPER+1…9 ecc.) non funzionano
    property string submap: ""
    // monitor aggiunti/tolti o configurazione ricaricata (dock collegata/scollegata, Monique…)
    signal monitorsChanged

    // Quando cambiano i monitor (dock scollegata, risoluzione o scala cambiate) awww non sempre
    // ridisegna lo sfondo per la nuova disposizione: lo si riapplica, senza transizione, appena la
    // disposizione si è assestata (gli eventi arrivano a raffica). Qui e non in Wallpaper perché
    // Wallpaper viene creato solo all'apertura del selettore sfondi, Hypr invece è sempre attivo.
    onMonitorsChanged: wallpaperReapply.restart()
    Timer {
        id: wallpaperReapply
        interval: 1500
        onTriggered: Wallpaper.apply("none")
    }
    // Quickshell non inoltra gli eventi "submap" in Hyprland.rawEvent: si leggono dal socket
    // degli eventi di Hyprland (lo stesso di `socat … .socket2.sock`)
    Socket {
        id: eventSocket
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/hypr/" + Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") + "/.socket2.sock"
        connected: true
        parser: SplitParser {
            onRead: line => {
                if (line.startsWith("submap>>"))
                    root.submap = line.slice(8);
                else if (line.startsWith("monitoradded") || line.startsWith("monitorremoved") || line.startsWith("configreloaded"))
                    root.monitorsChanged();
            }
        }
        // se il socket si chiude (Hyprland ricaricato) si riconnette
        onConnectedChanged: if (!connected) reconnect.start()
        property Timer reconnect: Timer {
            interval: 2000
            onTriggered: eventSocket.connected = true
        }
    }
    function resetSubmap() {
        dispatch('hl.dsp.submap("reset")');
    }

    function dispatch(lua) {
        Hyprland.dispatch(lua);
    }

    function focusWorkspace(id) {
        dispatch(`hl.dsp.focus({ workspace = "${id}" })`);
    }

    function exec(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    // Workspace di un monitor, ordinati per id (esclusi gli speciali)
    function workspacesFor(monitorName) {
        return Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor?.name === monitorName).sort((a, b) => a.id - b.id);
    }

    function monitorFor(screen) {
        return Hyprland.monitorFor(screen);
    }

    // Icona di un'app a partire dalla classe della finestra
    function iconForClass(cls) {
        if (!cls)
            return "";
        const entry = DesktopEntries.heuristicLookup(cls);
        return Quickshell.iconPath(entry?.icon ?? cls.toLowerCase(), "application-x-executable");
    }

    // Tieni aggiornate le finestre (servono per le icone nei workspace)
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const n = event.name;
            if (n === "openwindow" || n === "closewindow" || n === "movewindow" || n === "movewindowv2")
                Hyprland.refreshToplevels();
            if (n === "createworkspace" || n === "destroyworkspace" || n === "moveworkspace" || n === "renameworkspace")
                Hyprland.refreshWorkspaces();
        }
    }

    // ── Bordi delle finestre: seguono il colore d'accento ──
    // Sfumatura come quella originale (accento, 80% e 40% di luminosità) e bordo inattivo scuro.
    // L'accento scelto viene anche salvato in settings.json (accentHex) per hyprland.lua all'avvio.
    function _rgba(c, k, a) {
        const h = v => Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16).padStart(2, "0");
        return "rgba(" + h(c.r * k) + h(c.g * k) + h(c.b * k) + a + ")";
    }
    function applyBorders() {
        const c = Theme.primary;
        const active = [_rgba(c, 1, "ee"), _rgba(c, 0.8, "cc"), _rgba(c, 0.4, "cc")].map(x => `"${x}"`).join(", ");
        const argb = (k, a) => "0x" + a + _rgba(c, k, "").slice(5, 11);   // 0xAARRGGBB per l'ombra
        const lua = `hl.config({ general = { col = { active_border = { colors = { ${active} }, angle = 45 }, inactive_border = "${_rgba(c, 0.24, "aa")}" } }, decoration = { shadow = { color = ${argb(1, "55")}, color_inactive = ${argb(0.2, "22")} } } })`;
        Quickshell.execDetached(["hyprctl", "eval", lua]);
        const base = Theme.accentBase;
        const hex = "#" + [base.r, base.g, base.b].map(v => Math.round(v * 255).toString(16).padStart(2, "0")).join("");
        if (Settings.accentHex !== hex)
            Settings.accentHex = hex;
    }
    Connections {
        target: Theme
        function onPrimaryChanged() {
            bordersTimer.restart();
        }
    }
    Timer {
        id: bordersTimer
        interval: 120
        onTriggered: root.applyBorders()
    }
    Component.onCompleted: bordersTimer.restart()

    // ── Trasparenza finestre (toggle della vecchia barra) ──
    function applyTransparency() {
        const on = Settings.windowTransparency;
        const clamp = v => Math.max(0.3, Math.min(1, Number(v) || 1)).toFixed(2);
        const a = on ? clamp(Settings.windowOpacityActive) : "1.0";
        const i = on ? clamp(Settings.windowOpacityInactive) : "1.0";
        const lua = `hl.config({ decoration = { active_opacity = ${a}, inactive_opacity = ${i} } })`;
        Quickshell.execDetached(["hyprctl", "eval", lua]);
    }

    // ── Animazioni di finestre e workspace (preset in ~/.config/hypr/animations) ──
    readonly property var animationPresets: [
        { id: "matrix", name: "Matrix", desc: "Molle reattive, chiusura rapida" },
        { id: "slide", name: "Slide", desc: "Le finestre scivolano dal basso" },
        { id: "gnome", name: "GNOME", desc: "Si espandono e si ritraggono dal basso" },
        { id: "elastic", name: "Elastico", desc: "Rimbalzo evidente, giocoso" },
        { id: "glitch", name: "Glitch", desc: "Lo stile della vecchia config" },
        { id: "minimal", name: "Minimal", desc: "Solo dissolvenze rapide" },
        { id: "off", name: "Spente", desc: "Nessuna animazione, massime prestazioni" }
    ]

    function applyAnimations() {
        const name = animationPresets.some(p => p.id === Settings.windowAnimations) ? Settings.windowAnimations : "matrix";
        const speed = Math.max(0.25, Math.min(3, Settings.animationSpeed || 1));
        Quickshell.execDetached(["hyprctl", "eval", `dofile("${Settings.rootDir}/animations/init.lua").apply("${name}", ${speed})`]);
    }

    Connections {
        target: Settings
        function onWindowTransparencyChanged() {
            root.applyTransparency();
        }
        function onWindowOpacityActiveChanged() {
            opacityDebounce.restart();
        }
        function onWindowOpacityInactiveChanged() {
            opacityDebounce.restart();
        }
        function onWindowAnimationsChanged() {
            animDebounce.restart();
        }
        function onAnimationSpeedChanged() {
            animDebounce.restart();
        }
    }

    Timer {
        id: opacityDebounce
        interval: 60
        onTriggered: root.applyTransparency()
    }

    // accorpa più modifiche ravvicinate in un'unica applicazione (evita comandi in gara)
    Timer {
        id: animDebounce
        interval: 150
        onTriggered: root.applyAnimations()
    }

    Timer {
        running: true
        interval: 1000
        onTriggered: root.applyTransparency()
    }
}
