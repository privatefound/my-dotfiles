import QtQuick
import qs.config

// Strato hover/pressed stile Material. Va messo dentro un Rectangle:
// eredita il raggio del genitore e ne copre tutta l'area.
MouseArea {
    id: root

    property color tint: Theme.text
    property real radius: parent && parent.radius !== undefined ? parent.radius : 0
    property bool disabled: false

    anchors.fill: parent
    hoverEnabled: true
    enabled: !disabled
    cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.tint
        opacity: root.disabled ? 0 : root.pressed ? Theme.pressOpacity : root.containsMouse ? Theme.hoverOpacity : 0

        Behavior on opacity {
            Anim {
                duration: Theme.anim.fast
            }
        }
    }
}
