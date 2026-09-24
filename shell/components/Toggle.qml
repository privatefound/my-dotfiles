import QtQuick
import qs.config

// Interruttore stile Material 3.
Item {
    id: root

    property bool checked: false
    property bool disabled: false

    signal toggled(bool value)

    implicitWidth: 46
    implicitHeight: 26

    StyledRect {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.primaryFillStrong : Theme.surfaceContainerHighest
        border.width: root.checked ? 1 : 2
        border.color: root.checked ? Theme.primary : Theme.alpha(Theme.textDim, 0.5)
        opacity: root.disabled ? 0.4 : 1

        StyledRect {
            id: knob

            readonly property int s: root.checked || mouse.pressed ? 18 : 12

            width: s
            height: s
            radius: s / 2
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 4 : (parent.height - s) / 2 + (mouse.pressed ? 0 : 1)
            color: root.checked ? Theme.primary : Theme.textDim

            Behavior on x {
                Anim {
                    easing.bezierCurve: Theme.anim.expressive
                }
            }
            Behavior on width {
                Anim {
                    duration: Theme.anim.fast
                }
            }
            Behavior on height {
                Anim {
                    duration: Theme.anim.fast
                }
            }

            Icon {
                anchors.centerIn: parent
                visible: root.checked
                text: Icons.check
                size: 12
                color: Theme.primaryFillStrong
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: !root.disabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
