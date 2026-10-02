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
    // conky non risponde al SIGTERM di fine sessione: systemd lo aspetta 90 s prima di
    // ucciderlo, e lo spegnimento resta fermo. Lo si chiude prima (non ha stato da salvare).
    function reboot() {
        Quickshell.execDetached(["sh", "-c", "pkill -KILL -x conky; systemctl reboot"]);
    }
    function poweroff() {
        Quickshell.execDetached(["sh", "-c", "pkill -KILL -x conky; systemctl poweroff"]);
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
