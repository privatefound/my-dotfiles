import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.config
import qs.components
import qs.services

// Pannello musica: vinile (copertina come etichetta) con spettro "liquido" che segue i bassi, sfondo sfocato,
// avanzamento, controlli, lettore / uscita audio / volume.
Item {
    id: root

    readonly property var player: Media.active
    readonly property real artSize: 210
    property string menu: ""           // "players" | "outputs" | "volume"

    implicitWidth: 560
    implicitHeight: 640

    component SideButton: StyledRect {
        id: sb
        property string icon
        property bool active: false
        signal clicked
        implicitWidth: 42
        implicitHeight: 42
        radius: 21
        color: active ? Theme.primaryFillStrong : Theme.alpha(Theme.surface, 0.55)
        border.width: 1
        border.color: Theme.alpha(Theme.primary, active ? 0.8 : 0.3)
        Icon {
            anchors.centerIn: parent
            text: sb.icon
            size: 18
            color: sb.active ? Theme.primary : Theme.text
        }
        StateLayer {
            tint: Theme.primary
            onClicked: sb.clicked()
        }
    }

    Component.onCompleted: Spectrum.acquire()
    Component.onDestruction: Spectrum.release()

    // posizione più fluida mentre il pannello è aperto
    Timer {
        interval: 250
        repeat: true
        running: Media.playing
        onTriggered: root.player?.positionChanged()
    }

    // ── Sfondo: copertina sfocata e scurita ──
    ClippingRectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Theme.radius.large - 1
        color: "transparent"

        Image {
            id: bgArt
            anchors.fill: parent
            source: Media.art
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize: Qt.size(200, 200)
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: bgArt
            visible: bgArt.status === Image.Ready
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            brightness: -0.45
            saturation: 0.1
            opacity: 0.9
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.alpha(Theme.surface, 0.15) }
                GradientStop { position: 1.0; color: Theme.alpha(Theme.surface, 0.85) }
            }
        }
    }

    // ── Spettro circolare (centrato sulla copertina) ──
    Canvas {
        id: spectrum
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative
        property real bass: 0
        property real phase: 0

        Connections {
            target: Spectrum
            function onValuesChanged() {
                spectrum.requestPaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const vals = Spectrum.values;
            const n = vals.length;
            if (n === 0)
                return;
            // forma "liquida": segue i bassi (primo 10% delle bande) e ondeggia da sola mentre suona
            const nb = Math.max(1, Math.round(n * 0.1));
            let sum = 0;
            for (let i = 0; i < nb; i++)
                sum += Math.max(0, Math.min(1, vals[i]));
            spectrum.bass += (Math.sqrt(sum / nb) - spectrum.bass) * 0.35;
            if (Media.playing)
                spectrum.phase += 0.02;
            const c = artHolder.mapToItem(spectrum, artHolder.width / 2, artHolder.height / 2);
            const inner = root.artSize / 2;
            const bass = spectrum.bass, phase = spectrum.phase;
            const r = Theme.primary.r, g = Theme.primary.g, b = Theme.primary.b;
            const N = 96, pts = [];
            for (let i = 0; i < N; i++) {
                const a = -Math.PI / 2 + i / N * Math.PI * 2;
                const w = Math.sin(a * 3 + phase * 1.3) * 0.5 + Math.sin(a * 5 - phase * 0.9) * 0.3 + Math.sin(a * 2 + phase * 0.5) * 0.4;
                const d = inner + 16 + bass * 34 + w * (6 + bass * 24);
                pts.push([c.x + Math.cos(a) * d, c.y + Math.sin(a) * d]);
            }
            // curva chiusa morbida: quadratiche tra i punti medi
            ctx.beginPath();
            for (let i = 0; i <= N; i++) {
                const p0 = pts[i % N], p1 = pts[(i + 1) % N];
                const mx = (p0[0] + p1[0]) / 2, my = (p0[1] + p1[1]) / 2;
                if (i === 0)
                    ctx.moveTo(mx, my);
                else
                    ctx.quadraticCurveTo(p0[0], p0[1], mx, my);
            }
            ctx.closePath();
            const grad = ctx.createRadialGradient(c.x, c.y, inner, c.x, c.y, inner + 90);
            grad.addColorStop(0, Qt.rgba(r, g, b, 0.55));
            grad.addColorStop(1, Qt.rgba(r, g, b, 0.04));
            ctx.fillStyle = grad;
            ctx.fill();
            ctx.lineWidth = 2.5;
            ctx.strokeStyle = Qt.rgba(r, g, b, 0.9);
            ctx.stroke();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        anchors.topMargin: 84
        spacing: 6

        // ── Vinile: solchi neri, copertina come etichetta centrale, braccio del giradischi ──
        Item {
            id: artHolder
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: root.artSize
            implicitHeight: root.artSize

            readonly property real labelSize: root.artSize * 0.44
            // avanzamento del brano (0..1): il braccio scorre dal bordo verso l'etichetta
            readonly property real trackFrac: (root.player?.lengthSupported ?? false) && (root.player?.length ?? 0) > 0 ? Math.max(0, Math.min(1, root.player.position / root.player.length)) : 0

            // disco che gira (33⅓ giri) solo mentre suona
            Item {
                id: disc
                anchors.fill: parent

                RotationAnimation on rotation {
                    running: Settings.animations
                    paused: !Media.playing
                    from: 0
                    to: 360
                    duration: 1800
                    loops: Animation.Infinite
                }

                // solchi (cerchi concentrici: disegnati una volta sola)
                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const c = width / 2, R = width / 2;
                        const base = ctx.createRadialGradient(c, c, 0, c, c, R);
                        base.addColorStop(0, "#1c1c1e");
                        base.addColorStop(1, "#0a0a0b");
                        ctx.fillStyle = base;
                        ctx.beginPath();
                        ctx.arc(c, c, R, 0, Math.PI * 2);
                        ctx.fill();
                        ctx.lineWidth = 0.8;
                        for (let r = artHolder.labelSize / 2 + 5; r < R - 3; r += 1.6) {
                            // intensità "casuale" ma fissa, per l'effetto solco
                            const n = Math.abs(Math.sin(r * 12.9898) * 43758.5453) % 1;
                            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.025 + n * 0.05);
                            ctx.beginPath();
                            ctx.arc(c, c, r, 0, Math.PI * 2);
                            ctx.stroke();
                        }
                        // pause tra un brano e l'altro
                        ctx.lineWidth = 2;
                        ctx.strokeStyle = "rgba(0,0,0,0.85)";
                        for (const f of [0.62, 0.74, 0.86]) {
                            ctx.beginPath();
                            ctx.arc(c, c, R * f, 0, Math.PI * 2);
                            ctx.stroke();
                        }
                        // bordo esterno liscio
                        ctx.lineWidth = 3;
                        ctx.strokeStyle = "#202022";
                        ctx.beginPath();
                        ctx.arc(c, c, R - 1.5, 0, Math.PI * 2);
                        ctx.stroke();
                    }
                }

                // etichetta: la copertina
                ClippingRectangle {
                    anchors.centerIn: parent
                    width: artHolder.labelSize
                    height: width
                    radius: width / 2
                    color: Theme.primaryContainer

                    Image {
                        anchors.fill: parent
                        source: Media.art
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize: Qt.size(240, 240)
                    }
                    Icon {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -parent.height * 0.22
                        visible: Media.art === ""
                        text: Icons.musicNote
                        size: 22
                        color: Theme.primary
                    }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: artHolder.labelSize + 2
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.alpha(Theme.primary, 0.7)
                }
                // foro centrale
                Rectangle {
                    anchors.centerIn: parent
                    width: 10
                    height: 10
                    radius: 5
                    color: "#0a0a0b"
                    border.width: 2
                    border.color: Theme.alpha("#ffffff", 0.35)
                }
            }

            // riflesso della luce: fermo mentre il disco gira, come su un giradischi vero
            Canvas {
                anchors.fill: parent
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const c = width / 2, R = width / 2 - 2;
                    const g = ctx.createConicalGradient(c, c, -Math.PI / 4);
                    g.addColorStop(0.00, "rgba(255,255,255,0)");
                    g.addColorStop(0.10, "rgba(255,255,255,0.13)");
                    g.addColorStop(0.20, "rgba(255,255,255,0)");
                    g.addColorStop(0.50, "rgba(255,255,255,0)");
                    g.addColorStop(0.60, "rgba(255,255,255,0.10)");
                    g.addColorStop(0.70, "rgba(255,255,255,0)");
                    g.addColorStop(1.00, "rgba(255,255,255,0)");
                    ctx.fillStyle = g;
                    ctx.beginPath();
                    ctx.arc(c, c, R, 0, Math.PI * 2, false);
                    ctx.arc(c, c, artHolder.labelSize / 2 + 2, 0, Math.PI * 2, true);
                    ctx.fill();
                }
            }

            // bordo colorato
            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: Theme.alpha(Theme.primary, 0.75)
            }

            // braccio: a riposo fuori dal disco, in pausa/stop si solleva e torna indietro
            Item {
                id: tonearm
                readonly property real armLength: root.artSize * 0.62
                x: root.artSize + 18 - width / 2
                y: 2
                width: 16
                height: armLength + 14
                transformOrigin: Item.Top
                rotation: Media.playing ? 18 + 10 * artHolder.trackFrac : 0
                Behavior on rotation {
                    Anim {
                        duration: 700
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 4
                    width: 4
                    height: tonearm.armLength
                    radius: 2
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#9a9aa0" }
                        GradientStop { position: 0.5; color: "#e6e6ea" }
                        GradientStop { position: 1.0; color: "#7a7a80" }
                    }
                }
                // testina
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: 11
                    height: 20
                    radius: 3
                    color: Theme.primary
                    border.width: 1
                    border.color: Theme.alpha("#000000", 0.4)
                }
            }
            // perno del braccio
            Rectangle {
                x: root.artSize + 18 - width / 2
                y: 2 - height / 2 + 4
                width: 24
                height: 24
                radius: 12
                color: Theme.surfaceContainerHighest
                border.width: 2
                border.color: Theme.alpha(Theme.primary, 0.6)
                Rectangle {
                    anchors.centerIn: parent
                    width: 8
                    height: 8
                    radius: 4
                    color: "#d0d0d4"
                }
            }
        }

        Item {
            implicitHeight: 34
        }

        // ── Titoli ──
        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Media.title
            font.pixelSize: Theme.font.large
            font.weight: Font.DemiBold
        }
        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Media.artist
            color: Theme.textDim
        }
        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            visible: text !== ""
            text: root.player?.trackAlbum ?? ""
            font.pixelSize: Theme.font.small
            color: Theme.textFaint
        }

        Item {
            Layout.fillHeight: true
        }

        // ── Avanzamento (trascinabile) ──
        Item {
            id: progress
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            implicitHeight: 20

            readonly property real length: Math.max(1, root.player?.length ?? 1)
            property real dragFrac: -1
            readonly property real frac: dragFrac >= 0 ? dragFrac : Math.min(1, (root.player?.position ?? 0) / length)

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: Theme.alpha(Theme.text, 0.18)
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * progress.frac
                height: 4
                radius: 2
                color: Theme.primary
            }
            Rectangle {
                x: parent.width * progress.frac - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: 5
                height: 18
                radius: 2.5
                color: Theme.primary
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                enabled: root.player?.canSeek ?? false
                cursorShape: Qt.PointingHandCursor
                onPressed: m => progress.dragFrac = Math.max(0, Math.min(1, (m.x - 6) / progress.width))
                onPositionChanged: m => {
                    if (pressed)
                        progress.dragFrac = Math.max(0, Math.min(1, (m.x - 6) / progress.width));
                }
                onReleased: {
                    root.player.position = progress.dragFrac * progress.length;
                    progress.dragFrac = -1;
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            StyledText {
                text: Media.formatTime(progress.dragFrac >= 0 ? progress.dragFrac * progress.length : root.player?.position ?? 0)
                font.family: Theme.font.mono
                font.pixelSize: Theme.font.small
                color: Theme.textDim
            }
            Item {
                Layout.fillWidth: true
            }
            StyledText {
                text: Media.formatTime(root.player?.length ?? 0)
                font.family: Theme.font.mono
                font.pixelSize: Theme.font.small
                color: Theme.textDim
            }
        }

        // ── Controlli ──
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
            spacing: 22

            IconButton {
                size: 40
                icon: Icons.shuffle
                disabled: !(root.player?.shuffleSupported ?? false)
                iconColor: root.player?.shuffle ? Theme.primary : Theme.textDim
                onClicked: root.player.shuffle = !root.player.shuffle
            }
            IconButton {
                size: 44
                icon: Icons.skipPrevious
                onClicked: Media.previous()
            }
            IconButton {
                size: 72
                iconSize: 34
                icon: Media.playing ? Icons.pause : Icons.play
                toggled: true
                onClicked: Media.toggle()
            }
            IconButton {
                size: 44
                icon: Icons.skipNext
                onClicked: Media.next()
            }
            IconButton {
                size: 40
                disabled: !(root.player?.loopSupported ?? false)
                icon: root.player?.loopState === MprisLoopState.Track ? Icons.repeatOnce : Icons.repeat
                iconColor: (root.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None ? Theme.primary : Theme.textDim
                onClicked: {
                    const s = root.player.loopState;
                    root.player.loopState = s === MprisLoopState.None ? MprisLoopState.Playlist : s === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None;
                }
            }
        }
    }

    // ── Colonna laterale: lettore, uscita audio, volume ──
    ColumnLayout {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.top: parent.top
        anchors.topMargin: 84
        spacing: 10

        SideButton {
            icon: Icons.musicNote
            active: root.menu === "players"
            onClicked: root.menu = root.menu === "players" ? "" : "players"
        }
        SideButton {
            icon: Audio.sinkIcon(Audio.sink)
            active: root.menu === "outputs"
            onClicked: root.menu = root.menu === "outputs" ? "" : "outputs"
        }
        SideButton {
            icon: Audio.icon
            active: root.menu === "volume"
            onClicked: root.menu = root.menu === "volume" ? "" : "volume"
        }
    }

    // ── Menu della colonna laterale ──
    StyledRect {
        visible: root.menu !== ""
        anchors.right: parent.right
        anchors.rightMargin: 66
        anchors.top: parent.top
        anchors.topMargin: 56
        width: 280
        implicitHeight: menuCol.implicitHeight + 16
        radius: Theme.radius.normal
        color: Theme.alpha(Theme.surfaceContainerHigh, 0.97)
        border.width: 1
        border.color: Theme.outline
        z: 5

        ColumnLayout {
            id: menuCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 2

            StyledText {
                Layout.margins: 6
                text: root.menu === "players" ? I18n.tr("Lettore") : root.menu === "outputs" ? I18n.tr("Uscita audio") : I18n.tr("Volume")
                font.pixelSize: Theme.font.small
                font.weight: Font.Bold
                color: Theme.primary
            }

            Repeater {
                model: root.menu === "players" ? Media.players : []
                delegate: ListRow {
                    required property var modelData
                    icon: Icons.musicNote
                    title: modelData.identity || modelData.desktopEntry || "Player"
                    subtitle: modelData.trackTitle || ""
                    highlighted: Media.active === modelData
                    onClicked: {
                        Media.selected = modelData;
                        root.menu = "";
                    }
                }
            }

            Repeater {
                model: root.menu === "outputs" ? Audio.sinks : []
                delegate: ListRow {
                    required property var modelData
                    icon: Audio.sinkIcon(modelData)
                    title: Audio.nodeName(modelData)
                    highlighted: Audio.sink === modelData
                    onClicked: {
                        Audio.setDefaultSink(modelData);
                        root.menu = "";
                    }
                }
            }

            StyledSlider {
                visible: root.menu === "volume"
                Layout.fillWidth: true
                Layout.margins: 4
                icon: Audio.icon
                value: Math.min(Audio.volume, 1)
                muted: Audio.muted
                onMoved: v => Audio.setVolume(v)
                onIconClicked: Audio.toggleMute()
            }
            StyledSlider {
                visible: root.menu === "volume" && (root.player?.volumeSupported ?? false)
                Layout.fillWidth: true
                Layout.margins: 4
                icon: Icons.musicNote
                value: root.player?.volume ?? 0
                onMoved: v => root.player.volume = v
            }
        }
    }

    // nessun lettore
    StyledText {
        anchors.centerIn: parent
        visible: !Media.hasPlayer
        text: I18n.tr("Nessun lettore attivo")
        color: Theme.textDim
    }
}
