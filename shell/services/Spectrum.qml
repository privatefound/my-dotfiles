pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Spettro audio per il pannello musica.
// Con `cava` installato: spettro vero (48 bande). Senza: livelli simulati dal picco Pipewire.
// Gira solo mentre qualcuno lo usa (users > 0), per non consumare batteria.
Singleton {
    id: root

    property int users: 0
    readonly property bool active: users > 0
    readonly property int bands: 48
    property var values: []           // 0..1 per banda
    property bool cavaAvailable: false

    function acquire() {
        if (!cavaAvailable)
            cavaCheck.running = true;
        users++;
    }
    function release() {
        users = Math.max(0, users - 1);
    }

    Process {
        id: cavaCheck
        running: true
        command: ["sh", "-c", "command -v cava"]
        onExited: code => root.cavaAvailable = code === 0
    }

    // ── cava ──
    readonly property string configPath: Quickshell.cachePath("cava.conf")

    FileView {
        id: cavaConf
        path: root.configPath
        Component.onCompleted: setText(`[general]
bars = ${root.bands}
framerate = 50
autosens = 1
[input]
method = pipewire
source = auto
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 1000
bar_delimiter = 59
frame_delimiter = 10
[smoothing]
noise_reduction = 60
`)
    }

    Process {
        id: cava
        running: root.active && root.cavaAvailable
        command: ["cava", "-p", root.configPath]
        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(";");
                const out = [];
                for (let i = 0; i < root.bands && i < parts.length; i++)
                    out.push((parseInt(parts[i]) || 0) / 1000);
                if (out.length === root.bands)
                    root.values = out;
            }
        }
        onRunningChanged: if (!running) root.values = []
    }

    // ── ripiego senza cava: picco Pipewire + forma a campana animata ──
    PwNodePeakMonitor {
        id: peak
        node: Pipewire.defaultAudioSink
        enabled: root.active && !root.cavaAvailable
    }

    property real _phase: 0
    Timer {
        interval: 33
        repeat: true
        running: root.active && !root.cavaAvailable
        onTriggered: {
            root._phase += 0.35;
            const p = Math.min(1, peak.peak * 1.4);
            const out = [];
            for (let i = 0; i < root.bands; i++) {
                const x = i / root.bands;
                const shape = 0.35 + 0.65 * Math.exp(-Math.pow((x - 0.25) * 3, 2));
                const wobble = 0.55 + 0.45 * Math.sin(root._phase + i * 0.9) * Math.cos(root._phase * 0.6 + i * 0.37);
                out.push(Math.max(0, p * shape * wobble));
            }
            root.values = out;
        }
    }
}
