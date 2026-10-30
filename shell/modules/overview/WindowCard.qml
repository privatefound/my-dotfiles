import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

// Scheda di una finestra nella panoramica: anteprima dal vivo, icona e titolo.
StyledRect {
    id: card

    required property var toplevel
    property bool selected: false
    signal hovered
    signal activated
    signal closeRequested

    readonly property var size: toplevel.lastIpcObject?.size ?? [16, 9]
    readonly property real aspect: size[1] > 0 ? size[0] / size[1] : 16 / 9
    // anteprima dentro un riquadro 300×190, proporzioni della finestra
    readonly property real thumbW: Math.min(300, 190 * aspect)
    readonly property real thumbH: thumbW / aspect

    implicitWidth: 312
    implicitHeight: 190 + 46
    radius: Theme.radius.large
    color: selected ? Theme.primaryContainer : mouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
    border.width: selected ? 2 : 1
    border.color: selected ? Theme.primary : Theme.outlineVariant

    Item {
        id: thumbBox
        x: 6
        y: 6
        width: 300
        height: 190

        ClippingRectangle {
            anchors.centerIn: parent
            width: card.thumbW
            height: card.thumbH
            radius: Theme.radius.normal
            color: Theme.surfaceContainerHighest

            ScreencopyView {
                id: shot
                anchors.fill: parent
                captureSource: card.toplevel.wayland
                live: true
            }
            // finestra minimizzata o anteprima non disponibile
            IconImage {
                anchors.centerIn: parent
                visible: !shot.hasContent
                implicitSize: 56
                source: Hypr.iconForClass(card.toplevel.lastIpcObject?.class ?? "")
            }
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10
        anchors.bottomMargin: 12
        spacing: 8
        IconImage {
            implicitSize: 18
            source: Hypr.iconForClass(card.toplevel.lastIpcObject?.class ?? "")
        }
        StyledText {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: card.toplevel.title || (card.toplevel.lastIpcObject?.class ?? "")
            font.pixelSize: Theme.font.small
            font.weight: card.selected ? Font.DemiBold : Font.Normal
            color: card.selected ? Theme.fgPrimaryContainer : Theme.text
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onEntered: card.hovered()
        onClicked: mouse => mouse.button === Qt.MiddleButton ? card.closeRequested() : card.activated()
    }

    // pulsante chiudi al passaggio del mouse
    IconButton {
        visible: mouse.containsMouse || hovered
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        size: 28
        icon: Icons.close
        iconColor: Theme.error
        onClicked: card.closeRequested()
    }
}
