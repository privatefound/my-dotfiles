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
        // per ogni monitor sceglie la versione adatta alle sue proporzioni (es. sfondo@3x2.png sul portatile)
        Quickshell.execDetached([Settings.rootDir + "/scripts/set-wallpaper", Settings.wallpaper, transition || "fade"]);
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
            // le versioni per altre proporzioni (nome@3x2.png…) non sono sfondi a sé: si nascondono
            onStreamFinished: root.files = text.split("\n").filter(l => l && !/@\d+x\d+\.[^/.]+$/.test(l)).sort()
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
