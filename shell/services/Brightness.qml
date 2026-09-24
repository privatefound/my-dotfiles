pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Luminosità dello schermo interno (sysfs + brightnessctl).
Singleton {
    id: root

    property string device: ""
    property int max: 1
    property int current: 0
    readonly property bool available: device !== ""
    readonly property real value: max > 0 ? current / max : 0

    signal brightnessTouched

    function set(v) {
        if (!available)
            return;
        const pct = Math.round(Math.max(0.01, Math.min(1, v)) * 100);
        current = Math.round(pct / 100 * max);
        setProc.command = ["brightnessctl", "-d", device, "set", pct + "%"];
        setProc.running = true;
    }
    function change(delta) {
        set(value + delta);
        brightnessTouched();
    }

    Process {
        id: detect
        running: true
        command: ["sh", "-c", "ls /sys/class/backlight 2>/dev/null | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.device = text.trim();
                if (root.device !== "") {
                    maxFile.reload();
                    curFile.reload();
                }
            }
        }
    }

    Process {
        id: setProc
    }

    FileView {
        id: maxFile
        path: root.device ? `/sys/class/backlight/${root.device}/max_brightness` : ""
        onLoaded: root.max = parseInt(text()) || 1
    }

    FileView {
        id: curFile
        path: root.device ? `/sys/class/backlight/${root.device}/brightness` : ""
        onLoaded: root.current = parseInt(text()) || 0
    }

    // sysfs non emette eventi inotify: rileggiamo il file (niente processi)
    Timer {
        interval: 1500
        running: root.available
        repeat: true
        onTriggered: curFile.reload()
    }
}
