pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Sfondi con awww (transizioni animate). Il percorso scelto viene salvato nelle impostazioni.
Singleton {
    id: root

    property var files: []
    readonly property string current: Settings.wallpaper

    function refresh() {
        listProc.running = true;
    }

    function set(path) {
        Settings.wallpaper = path;
        apply(Settings.wallpaperTransition);
    }

    function apply(transition) {
        Quickshell.execDetached(["sh", "-c", "pgrep -x awww-daemon >/dev/null || { awww-daemon >/dev/null 2>&1 & sleep 0.6; }; awww img \"$1\" --transition-type \"$2\" --transition-pos top-right --transition-duration 1.1 --transition-fps 120", "_", Settings.wallpaper, transition || "fade"]);
    }

    function random() {
        const others = files.filter(f => f !== current);
        if (others.length > 0)
            set(others[Math.floor(Math.random() * others.length)]);
    }

    Process {
        id: listProc
        command: ["find", Settings.wallpaperDir, "-maxdepth", "2", "-type", "f", "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", "-o", "-iname", "*.gif", ")"]
        stdout: StdioCollector {
            onStreamFinished: root.files = text.split("\n").filter(l => l).sort()
        }
    }

    // All'avvio riapplica l'ultimo sfondo scelto
    Timer {
        running: true
        interval: 800
        onTriggered: {
            root.apply("fade");
            root.refresh();
        }
    }
}
