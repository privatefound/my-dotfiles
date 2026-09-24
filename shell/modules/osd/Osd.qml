import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services

// OSD volume / luminosità (in basso al centro sul monitor attivo, non intercetta i click).
PanelWindow {
    id: win

    required property var modelData
    property string kind: "volume"
    property bool shown: false

    screen: modelData
    visible: modelData.name === Ui.focusedScreen && (shown || card.opacity > 0)
    anchors.bottom: true
    margins.bottom: 60
    implicitWidth: 340
    implicitHeight: 64
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}

    WlrLayershell.namespace: "greenshell-osd"
    WlrLayershell.layer: WlrLayer.Overlay

    function show(k) {
        kind = k;
        shown = true;
        hideTimer.restart();
    }

    Connections {
        target: Audio
        function onVolumeTouched() {
            win.show("volume");
        }
    }
    Connections {
        target: Brightness
        function onBrightnessTouched() {
            win.show("brightness");
        }
    }

    Timer {
        id: hideTimer
        interval: 1600
        onTriggered: win.shown = false
    }

    StyledRect {
        id: card
        anchors.fill: parent
        radius: height / 2
        color: Theme.alpha(Theme.surface, Theme.panelOpacity)
        border.width: 1
        border.color: Theme.outline
        opacity: win.shown ? 1 : 0
        scale: win.shown ? 1 : 0.9

        Behavior on opacity {
            Anim {}
        }
        Behavior on scale {
            Anim {}
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 20
            spacing: 14

            Icon {
                text: win.kind === "volume" ? Audio.icon : Icons.brightnessHigh
                size: 24
                color: win.kind === "volume" && Audio.muted ? Theme.error : Theme.primary
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: 8

                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: Theme.surfaceContainerHighest
                }
                Rectangle {
                    readonly property real v: win.kind === "volume" ? Math.min(1, Audio.volume) : Brightness.value
                    width: parent.width * v
                    height: parent.height
                    radius: 4
                    color: win.kind === "volume" && Audio.muted ? Theme.textFaint : Theme.primary
                    Behavior on width {
                        Anim {
                            duration: Theme.anim.fast
                        }
                    }
                }
            }

            StyledText {
                Layout.preferredWidth: 44
                horizontalAlignment: Text.AlignRight
                text: win.kind === "volume" ? (Audio.muted ? I18n.tr("muto") : Math.round(Audio.volume * 100) + "%") : Math.round(Brightness.value * 100) + "%"
                font.family: Theme.font.mono
                font.weight: Font.Bold
            }
        }
    }
}
