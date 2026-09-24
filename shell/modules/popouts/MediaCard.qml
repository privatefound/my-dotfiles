import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

// Scheda del lettore multimediale: copertina, titolo, barra di avanzamento, controlli.
StyledRect {
    id: root

    property bool large: false
    readonly property var player: Media.active

    implicitHeight: large ? 150 : 96
    implicitWidth: 380
    radius: Theme.radius.large
    color: Theme.surfaceContainer
    clip: true

    // Copertina sfocata di sfondo
    Image {
        id: bgArt
        anchors.fill: parent
        source: Media.art
        fillMode: Image.PreserveAspectCrop
        opacity: 0.18
        asynchronous: true
        visible: status === Image.Ready
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.alpha(Theme.surfaceContainer, 0.4) }
            GradientStop { position: 1.0; color: Theme.alpha(Theme.surfaceContainer, 0.95) }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 14

        ClippingRectangle {
            implicitWidth: root.large ? 126 : 72
            implicitHeight: implicitWidth
            radius: Theme.radius.normal
            color: Theme.surfaceContainerHighest

            Image {
                anchors.fill: parent
                source: Media.art
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(256, 256)
            }
            Icon {
                anchors.centerIn: parent
                visible: Media.art === ""
                text: Icons.musicNote
                size: 30
                color: Theme.primary
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: Media.title
                font.weight: Font.DemiBold
                font.pixelSize: root.large ? Theme.font.title : Theme.font.body
            }
            StyledText {
                Layout.fillWidth: true
                text: Media.artist
                color: Theme.textDim
                font.pixelSize: Theme.font.small
            }

            // Avanzamento
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.large && (root.player?.lengthSupported ?? false)
                spacing: 2
                Layout.topMargin: 6

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 6

                    Rectangle {
                        anchors.fill: parent
                        radius: 3
                        color: Theme.surfaceContainerHighest
                    }
                    Rectangle {
                        width: parent.width * Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))
                        height: parent.height
                        radius: 3
                        color: Theme.primary
                        Behavior on width {
                            Anim {
                                duration: 900
                                easing.type: Easing.Linear
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        enabled: root.player?.canSeek ?? false
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => root.player.position = (mouse.x / width) * root.player.length
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: Media.formatTime(root.player?.position ?? 0)
                        font.family: Theme.font.mono
                        font.pixelSize: Theme.font.tiny
                        color: Theme.textDim
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    StyledText {
                        text: Media.formatTime(root.player?.length ?? 0)
                        font.family: Theme.font.mono
                        font.pixelSize: Theme.font.tiny
                        color: Theme.textDim
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                spacing: 4
                IconButton {
                    visible: root.large && (root.player?.shuffleSupported ?? false)
                    size: 32
                    icon: Icons.shuffle
                    iconColor: root.player?.shuffle ? Theme.primary : Theme.textDim
                    onClicked: root.player.shuffle = !root.player.shuffle
                }
                IconButton {
                    size: 34
                    icon: Icons.skipPrevious
                    onClicked: Media.previous()
                }
                IconButton {
                    size: 40
                    icon: Media.playing ? Icons.pause : Icons.play
                    toggled: true
                    onClicked: Media.toggle()
                }
                IconButton {
                    size: 34
                    icon: Icons.skipNext
                    onClicked: Media.next()
                }
                Item {
                    Layout.fillWidth: true
                }
                // Cambia lettore se ce n'è più d'uno
                IconButton {
                    visible: Media.players.length > 1
                    size: 30
                    icon: Icons.swap
                    iconColor: Theme.textDim
                    onClicked: {
                        const i = Media.players.indexOf(Media.active);
                        Media.selected = Media.players[(i + 1) % Media.players.length];
                    }
                }
            }
        }
    }
}
