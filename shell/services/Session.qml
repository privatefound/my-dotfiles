pragma Singleton

import Quickshell
import QtQuick
import qs.config

Singleton {
    id: root

    function lock() {
        Quickshell.execDetached(["sh", "-c", "pidof hyprlock || hyprlock -c " + Settings.rootDir + "/hyprlock.conf"]);
    }
    function suspend() {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }
    function hibernate() {
        Quickshell.execDetached(["systemctl", "hibernate"]);
    }
    function reboot() {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }
    function poweroff() {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }
    function logout() {
        Quickshell.execDetached(["sh", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"]);
    }
    function sysMonitor() {
        Quickshell.execDetached(["sh", "-c", Settings.sysMonitor]);
    }

    // Cast schermo / gestione monitor (come nella vecchia barra)
    function castScreen() {
        Quickshell.execDetached(["gnome-network-displays"]);
    }
    function monitors() {
        Quickshell.execDetached(["monique"]);
    }
    function audioMixer() {
        Quickshell.execDetached(["pavucontrol"]);
    }
    function bluetoothManager() {
        Quickshell.execDetached(["blueman-manager"]);
    }
}
