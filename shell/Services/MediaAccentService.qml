pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services as S

// Colore d'accento estratto dalla copertina del brano in riproduzione (come in DMS).
Singleton {
    id: root

    readonly property bool hasAccent: accent.a > 0
    property color accent: "transparent"

    // le copertine remote (es. Spotify) vanno scaricate: ColorQuantizer legge solo file locali
    readonly property string artUrl: S.Media.art
    property string localArt: ""
    readonly property string cacheDir: Quickshell.cachePath("art")

    onArtUrlChanged: {
        if (!artUrl) {
            localArt = "";
        } else if (artUrl.startsWith("http")) {
            const name = Qt.md5(artUrl);
            fetch.target = cacheDir + "/" + name;
            fetch.command = ["sh", "-c", "mkdir -p \"$1\"; [ -s \"$2\" ] || curl -fsSL --max-time 10 -o \"$2\" \"$3\"", "_", cacheDir, fetch.target, artUrl];
            fetch.running = true;
        } else {
            localArt = artUrl;
        }
    }
    Component.onCompleted: artUrlChanged()

    Process {
        id: fetch
        property string target
        onExited: code => {
            if (code === 0)
                root.localArt = "file://" + target;
        }
    }

    ColorQuantizer {
        id: quantizer
        source: root.localArt
        depth: 3
        rescaleSize: 64
        onColorsChanged: root.pick()
    }

    // sceglie il colore più saturo e luminoso, poi lo schiarisce abbastanza per un tema scuro
    function pick() {
        const cols = quantizer.colors || [];
        let best = null, score = -1;
        for (const c of cols) {
            const sc = c.hsvSaturation * 0.7 + c.hsvValue * 0.3;
            if (c.hsvValue > 0.15 && sc > score) {
                score = sc;
                best = c;
            }
        }
        if (!best) {
            accent = "transparent";
            return;
        }
        accent = Qt.hsva(best.hsvHue < 0 ? 0 : best.hsvHue, Math.max(0.45, best.hsvSaturation), Math.max(0.8, best.hsvValue), 1);
    }

    Connections {
        target: S.Media
        function onArtChanged() {
            if (!S.Media.art)
                root.accent = "transparent";
        }
    }
}
