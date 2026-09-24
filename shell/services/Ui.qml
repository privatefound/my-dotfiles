pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

// Stato globale dell'interfaccia: quale popout / modale è aperto e su quale schermo.
Singleton {
    id: root

    // Popout ancorati alla barra
    // "control" | "notifications" | "calendar" | "sysmon" | "tray" | "ai" | "subnet" | "media"
    property string popout: ""
    property string popoutScreen: ""
    property real popoutX: -1          // centro orizzontale (coord. schermo), -1 = allinea a destra
    property var popoutData: null
    property string controlPage: ""    // sotto-pagina del control center ("network", "bluetooth", "audio")
    property string networkTab: "wifi" // scheda della pagina rete ("wifi", "ethernet", "vpn")

    // Modali a schermo intero
    // "launcher" | "session" | "wallpaper" | "settings"
    property string modal: ""
    property string modalScreen: ""
    property string launcherMode: "apps"   // "apps" | "clipboard" | "calc" | "commands"

    readonly property string focusedScreen: Hyprland.focusedMonitor?.name ?? (Quickshell.screens[0]?.name ?? "")

    function openPopout(name, screenName, x, data) {
        modal = "";
        if (name !== "control")
            controlPage = "";
        popoutData = data ?? null;
        popoutX = x ?? -1;
        popoutScreen = screenName || focusedScreen;
        popout = name;
    }

    function togglePopout(name, screenName, x, data) {
        const scr = screenName || focusedScreen;
        if (popout === name && popoutScreen === scr && (data === undefined || data === popoutData))
            closePopout();
        else
            openPopout(name, scr, x, data);
    }

    function closePopout() {
        popout = "";
        popoutData = null;
    }

    function openModal(name, mode) {
        closePopout();
        if (mode)
            launcherMode = mode;
        modalScreen = focusedScreen;
        modal = name;
    }

    function toggleModal(name, mode) {
        if (modal === name && (!mode || launcherMode === mode))
            closeModal();
        else
            openModal(name, mode);
    }

    function closeModal() {
        modal = "";
    }

    function closeAll() {
        closePopout();
        closeModal();
    }

    // Chiudi tutto quando si cambia workspace (come facevi nella vecchia barra)
    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            if (root.popout !== "" && root.popout !== "ai")
                root.closePopout();
        }
    }
}
