pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import qs.config

// Suoni di sistema minimali (assets/sounds/system, Impostazioni → Notifiche → Suoni di sistema):
// notifiche, tasti volume, dispositivo USB inserito o tolto (anche con notifica), alimentatore collegato o staccato.
// Spenti, resta solo il suono classico delle notifiche.
Singleton {
    id: root

    function play(name) {
        if (!Settings.systemSounds && name !== "notify")
            return;
        const file = Settings.systemSounds ? "assets/sounds/system/" + name + ".ogg" : "assets/notification.ogg";
        Quickshell.execDetached(["pw-play", "--volume", name === "tick" ? "0.5" : "0.6", Quickshell.shellPath(file)]);
    }

    // tasti volume: un "tick" al nuovo volume (dopo che wpctl l'ha applicato), non più di uno ogni 70 ms
    property double _lastTick: 0
    function tick() {
        const now = Date.now();
        if (now - _lastTick < 70)
            return;
        _lastTick = now;
        tickDelay.restart();
    }
    Timer {
        id: tickDelay
        interval: 60
        onTriggered: root.play("tick")
    }

    // alimentatore
    Connections {
        target: UPower
        function onOnBatteryChanged() {
            root.play(UPower.onBattery ? "power-off" : "power-on");
        }
    }

    // dispositivi USB (script usb-events: un evento per dispositivo, con il nome): suono + notifica
    Process {
        running: true
        command: [Settings.rootDir + "/scripts/usb-events"]
        stdout: SplitParser {
            onRead: line => {
                const i = line.indexOf("|");
                if (i < 0)
                    return;
                const added = line.slice(0, i) === "add";
                root.play(added ? "plug" : "unplug");
                if (Settings.usbNotifications)
                    // urgenza bassa: niente secondo suono (c'è già quello sopra)
                    Quickshell.execDetached(["notify-send", "--app-name", "USB", "--urgency", "low", "--icon", added ? "drive-removable-media" : "media-eject", "--expire-time", "3000", added ? I18n.tr("Dispositivo USB collegato") : I18n.tr("Dispositivo USB scollegato"), line.slice(i + 1)]);
            }
        }
    }
}
