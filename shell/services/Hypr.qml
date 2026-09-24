pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.config

// Helper per Hyprland (config Lua: i dispatch sono espressioni hl.dsp.*)
Singleton {
    id: root

    readonly property var activeToplevel: Hyprland.activeToplevel
    readonly property string activeTitle: activeToplevel?.title ?? ""
    readonly property string activeClass: activeToplevel?.lastIpcObject?.class ?? ""

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
