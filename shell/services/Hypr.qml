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
        const lua = on ? "hl.config({ decoration = { active_opacity = 0.98, inactive_opacity = 0.90 } })" : "hl.config({ decoration = { active_opacity = 1.0, inactive_opacity = 1.0 } })";
        Quickshell.execDetached(["hyprctl", "eval", lua]);
    }

    Connections {
        target: Settings
        function onWindowTransparencyChanged() {
            root.applyTransparency();
        }
    }

    Timer {
        running: true
        interval: 1000
        onTriggered: root.applyTransparency()
    }
}
