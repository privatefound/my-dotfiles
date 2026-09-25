pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    readonly property bool isHyprland: true
    readonly property bool isNiri: false
    readonly property bool isSway: false
    readonly property string compositor: "hyprland"

    function getFocusedScreen() {
        const name = Hyprland.focusedMonitor?.name;
        return Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0];
    }
    function getScreenScale(screen) {
        return Hyprland.monitorFor(screen)?.scale ?? 1;
    }
}
