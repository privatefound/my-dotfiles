import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

// Pagina Audio: volume con boost fino al 150% e preset (come prima), uscite, ingressi, volume per app.
ColumnLayout {
    id: root

    spacing: 10

    PageHeader {
        title: "Audio"
        icon: Icons.volumeHigh

        StyledButton {
            implicitHeight: 32
            padding: 12
            variant: "text"
            icon: Icons.tune
            text: "Mixer"
            onClicked: {
                Ui.closePopout();
                Session.audioMixer();
            }
        }
    }

    ScrollColumn {
        maxHeight: 540
        spacing: 6

        // ── Uscita ──
        SectionHeader {
            text: "Uscita"
            icon: Icons.speaker
        }

        StyledSlider {
            Layout.fillWidth: true
            icon: Audio.icon
            to: 1.5
            step: 0.05 / 1.5
            value: Audio.volume
            muted: Audio.muted
            accent: Audio.muted ? Theme.textFaint : Audio.volume > 1 ? Theme.warning : Theme.primary
            onMoved: v => Audio.setVolume(v)
            onIconClicked: Audio.toggleMute()

            // tacca del 100%
            Rectangle {
                x: parent.width / 1.5
                anchors.verticalCenter: parent.verticalCenter
                width: 2
                height: parent.height * 0.6
                radius: 1
                color: Theme.text
                opacity: 0.35
                z: 3
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            IconButton {
                icon: Audio.muted ? Icons.volumeOff : Icons.volumeHigh
                toggled: Audio.muted
                background: Audio.muted ? Theme.errorContainer : Theme.surfaceContainerHigh
                iconColor: Audio.muted ? Theme.error : Theme.text
                onClicked: Audio.toggleMute()
            }
            Item {
                Layout.fillWidth: true
            }
            Repeater {
                model: [25, 50, 75, 100, 125]
                delegate: StyledButton {
                    required property int modelData
                    implicitHeight: 32
                    padding: 10
                    variant: Math.round(Audio.volume * 100) === modelData ? "filled" : "tonal"
                    text: modelData
                    onClicked: Audio.setVolume(modelData / 100)
                }
            }
        }

        Repeater {
            model: Audio.sinks
            delegate: ListRow {
                required property var modelData
                icon: Audio.sinkIcon(modelData)
                title: Audio.nodeName(modelData)
                highlighted: Audio.sink === modelData
                onClicked: Audio.setDefaultSink(modelData)
            }
        }

        // ── Ingresso ──
        SectionHeader {
            Layout.topMargin: 8
            text: "Ingresso"
            icon: Icons.mic
        }

        StyledSlider {
            Layout.fillWidth: true
            icon: Audio.micIcon
            value: Math.min(Audio.micVolume, 1)
            muted: Audio.micMuted
            onMoved: v => Audio.setMicVolume(v)
            onIconClicked: Audio.toggleMicMute()
        }

        Repeater {
            model: Audio.sources
            delegate: ListRow {
                required property var modelData
                icon: Icons.mic
                title: Audio.nodeName(modelData)
                highlighted: Audio.source === modelData
                onClicked: Audio.setDefaultSource(modelData)
            }
        }

        // ── Applicazioni ──
        SectionHeader {
            Layout.topMargin: 8
            visible: Audio.streams.length > 0
            text: "Applicazioni"
            icon: Icons.apps
        }

        Repeater {
            model: Audio.streams
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 10

                IconImage {
                    implicitSize: 26
                    source: Audio.streamIcon(modelData)
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    StyledText {
                        Layout.fillWidth: true
                        text: Audio.streamName(modelData) + (Audio.streamDetail(modelData) ? "  ·  " + Audio.streamDetail(modelData) : "")
                        font.pixelSize: Theme.font.small
                        color: Theme.textDim
                    }
                    StyledSlider {
                        Layout.fillWidth: true
                        implicitHeight: 30
                        icon: modelData.audio?.muted ? Icons.volumeOff : Icons.volumeHigh
                        value: modelData.audio?.volume ?? 0
                        muted: modelData.audio?.muted ?? false
                        onMoved: v => {
                            if (modelData.audio)
                                modelData.audio.volume = v;
                        }
                        onIconClicked: {
                            if (modelData.audio)
                                modelData.audio.muted = !modelData.audio.muted;
                        }
                    }
                }
            }
        }
    }
}
