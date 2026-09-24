import QtQuick
import qs.config

// Slider "spesso" stile Material 3 expressive, con icona dentro la traccia.
// Supporta trascinamento, click e rotella del mouse.
Item {
    id: root

    property real value: 0          // 0..to
    property real to: 1
    property real step: 0.05
    property string icon
    property bool showValue: true
    property bool muted: false
    property color accent: muted ? Theme.textFaint : Theme.primary

    readonly property bool dragging: area.pressed
    property real _dragValue: 0
    readonly property real shown: Math.max(0, Math.min(1, (dragging ? _dragValue : value) / to))

    signal moved(real value)
    signal iconClicked

    implicitHeight: 40
    implicitWidth: 240

    StyledRect {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.surfaceContainerHighest
        clip: true

        StyledRect {
            id: fill
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(parent.height, parent.width * root.shown)
            radius: parent.radius
            color: Theme.mix(Theme.surfaceContainerHighest, root.accent, 0.4)

            Behavior on width {
                enabled: !root.dragging
                Anim {
                    duration: Theme.anim.normal
                }
            }

            // Maniglia verticale in fondo al riempimento
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: parent.height * 0.55
                radius: 2
                color: root.accent
                opacity: 1
            }
        }
    }

    Icon {
        id: iconItem
        anchors.left: parent.left
        anchors.leftMargin: 11
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        size: 18
        color: root.muted ? Theme.textDim : root.accent
        z: 2

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }

    StyledText {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        visible: root.showValue
        text: Math.round(root.shown * root.to * 100) + "%"
        font.family: Theme.font.mono
        font.pixelSize: Theme.font.small
        color: Theme.text
        z: 2
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.leftMargin: 34
        cursorShape: Qt.PointingHandCursor

        function valueAt(x) {
            const full = root.width;
            const px = x + anchors.leftMargin;
            return Math.max(0, Math.min(1, px / full)) * root.to;
        }

        onPressed: mouse => {
            root._dragValue = valueAt(mouse.x);
            root.moved(root._dragValue);
        }
        onPositionChanged: mouse => {
            if (!pressed)
                return;
            root._dragValue = valueAt(mouse.x);
            root.moved(root._dragValue);
        }
        onWheel: wheel => {
            const d = wheel.angleDelta.y > 0 ? root.step : -root.step;
            root.moved(Math.max(0, Math.min(root.to, root.value + d * root.to)));
        }
    }
}
