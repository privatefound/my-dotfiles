import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.config
import qs.components
import qs.services

// Pannello musica: copertina rotonda con spettro circolare, sfondo sfocato,
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
            const c = artHolder.mapToItem(spectrum, artHolder.width / 2, artHolder.height / 2);
            const inner = root.artSize / 2 + 9;
            const total = n * 2;
            const r = Theme.primary.r, g = Theme.primary.g, b = Theme.primary.b;
            ctx.lineCap = "round";
            for (let i = 0; i < total; i++) {
                // specchiato: bassi in alto, acuti in basso, simmetrico
                const raw = vals[i < n ? i : total - 1 - i];
                const v = Math.sqrt(Math.max(0, Math.min(1, raw)));
                const a = -Math.PI / 2 + ((i + 0.5) / total) * Math.PI * 2;
                const len = 3 + v * 40;
                const cos = Math.cos(a), sin = Math.sin(a);
                const x1 = c.x + cos * inner, y1 = c.y + sin * inner;
                const x2 = c.x + cos * (inner + len), y2 = c.y + sin * (inner + len);
                // alone
                ctx.lineWidth = 7;
                ctx.strokeStyle = Qt.rgba(r, g, b, 0.08 + v * 0.18);
                ctx.beginPath();
                ctx.moveTo(x1, y1);
                ctx.lineTo(x2, y2);
                ctx.stroke();
                // barra
                ctx.lineWidth = 3;
                ctx.strokeStyle = Qt.rgba(r, g, b, 0.45 + v * 0.55);
                ctx.beginPath();
                ctx.moveTo(x1, y1);
                ctx.lineTo(x2, y2);
                ctx.stroke();
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        anchors.topMargin: 84
        spacing: 6

        // ── Copertina ──
        Item {
            id: artHolder
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: root.artSize
            implicitHeight: root.artSize

            ClippingRectangle {
                id: artClip
                anchors.fill: parent
                radius: width / 2
                color: Theme.surfaceContainerHighest

                Image {
                    anchors.fill: parent
                    source: Media.art
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(420, 420)
                }
                Icon {
                    anchors.centerIn: parent
                    visible: Media.art === ""
                    text: Icons.musicNote
                    size: 64
                    color: Theme.primary
                }

                // effetto vinile: rotazione lenta mentre suona
                RotationAnimation on rotation {
                    running: Settings.animations
                    paused: !Media.playing
                    from: 0
                    to: 360
                    duration: 30000
                    loops: Animation.Infinite
                }
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: width / 2
                color: "transparent"
                border.width: 3
                border.color: Theme.primary
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
