import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.config
import qs.services

// Scorciatoie globali (Hyprland: hl.dsp.global("greenshell:<nome>")) e comandi IPC
// (qs -p ~/.config/hypr/shell ipc call <target> <funzione>).
Scope {
    id: root

    component Shortcut: GlobalShortcut {
        appid: "greenshell"
    }

    Shortcut { name: "launcher"; description: I18n.tr("Apri il launcher"); onPressed: Ui.toggleModal("launcher", "apps") }
    Shortcut { name: "clipboard"; description: I18n.tr("Cronologia appunti"); onPressed: Ui.toggleModal("launcher", "clipboard") }
    Shortcut { name: "commands"; description: "Comandi rapidi"; onPressed: Ui.toggleModal("launcher", "commands") }
    Shortcut { name: "session"; description: I18n.tr("Menu sessione"); onPressed: Ui.toggleModal("session") }
    Shortcut { name: "wallpaper"; description: I18n.tr("Selettore sfondi"); onPressed: Ui.toggleModal("wallpaper") }
    Shortcut { name: "settings"; description: I18n.tr("Impostazioni"); onPressed: Ui.toggleModal("settings") }
    Shortcut { name: "control"; description: "Control center"; onPressed: Ui.togglePopout("control", "", -1) }
    Shortcut { name: "notifications"; description: I18n.tr("Centro notifiche"); onPressed: Ui.togglePopout("notifications", "", -1) }
    Shortcut { name: "ai"; description: I18n.tr("Chat Morpheus"); onPressed: Ui.togglePopout("ai", "", 320) }
    Shortcut { name: "subnet"; description: I18n.tr("Calcolatore subnet"); onPressed: Ui.togglePopout("subnet", "", 320) }
    Shortcut { name: "sysmon"; description: I18n.tr("Monitor di sistema"); onPressed: Ui.togglePopout("sysmon", "", -1) }
    Shortcut { name: "calendar"; description: I18n.tr("Calendario"); onPressed: Ui.togglePopout("calendar", "", -1 ) }
    Shortcut { name: "dnd"; description: I18n.tr("Non disturbare"); onPressed: Notifs.toggleDnd() }
    Shortcut { name: "caffeine"; description: "Caffeine"; onPressed: Settings.caffeine = !Settings.caffeine }
    Shortcut { name: "transparency"; description: I18n.tr("Trasparenza finestre"); onPressed: Settings.windowTransparency = !Settings.windowTransparency }
    Shortcut { name: "volumeUp"; description: "Volume +"; onPressed: Audio.changeVolume(0.05) }
    Shortcut { name: "volumeDown"; description: "Volume -"; onPressed: Audio.changeVolume(-0.05) }
    Shortcut { name: "volumeMute"; description: I18n.tr("Muto"); onPressed: Audio.toggleMute() }
    Shortcut { name: "micMute"; description: I18n.tr("Muto microfono"); onPressed: Audio.toggleMicMute() }
    Shortcut { name: "brightnessUp"; description: I18n.tr("Luminosità +"); onPressed: Brightness.change(0.05) }
    Shortcut { name: "brightnessDown"; description: I18n.tr("Luminosità -"); onPressed: Brightness.change(-0.05) }
    Shortcut { name: "closeAll"; description: I18n.tr("Chiudi popup"); onPressed: Ui.closeAll() }

    IpcHandler {
        target: "shell"
        function launcher(): void { Ui.toggleModal("launcher", "apps"); }
        function clipboard(): void { Ui.toggleModal("launcher", "clipboard"); }
        function commands(): void { Ui.toggleModal("launcher", "commands"); }
        function session(): void { Ui.toggleModal("session"); }
        function wallpaper(): void { Ui.toggleModal("wallpaper"); }
        function settings(): void { Ui.toggleModal("settings"); }
        function control(): void { Ui.togglePopout("control", "", -1); }
        function notifications(): void { Ui.togglePopout("notifications", "", -1); }
        function ai(): void { Ui.togglePopout("ai", "", 320); }
        function closeAll(): void { Ui.closeAll(); }
        function openOn(name: string, screen: string): void { Ui.openPopout(name, screen, -1); }
        function network(tab: string): void {
            Ui.openPopout("control", "", -1);
            Ui.networkTab = tab || "wifi";
            Ui.controlPage = "network";
        }
        function state(): string { return JSON.stringify({ popout: Ui.popout, popoutScreen: Ui.popoutScreen, modal: Ui.modal, modalScreen: Ui.modalScreen, focused: Ui.focusedScreen }); }
    }

    IpcHandler {
        target: "audio"
        function up(): void { Audio.changeVolume(0.05); }
        function down(): void { Audio.changeVolume(-0.05); }
        function mute(): void { Audio.toggleMute(); }
        function micMute(): void { Audio.toggleMicMute(); }
    }

    IpcHandler {
        target: "brightness"
        function up(): void { Brightness.change(0.05); }
        function down(): void { Brightness.change(-0.05); }
    }

    IpcHandler {
        target: "toggle"
        function dnd(): void { Notifs.toggleDnd(); }
        function caffeine(): void { Settings.caffeine = !Settings.caffeine; }
        function transparency(): void { Settings.windowTransparency = !Settings.windowTransparency; }
        function wifi(): void { Network.setWifiEnabled(!Network.wifiEnabled); }
        function bluetooth(): void { Bt.setEnabled(!Bt.enabled); }
    }

    IpcHandler {
        target: "wallpaper"
        function set(path: string): void { Wallpaper.set(path); }
        function random(): void { Wallpaper.random(); }
    }
}
