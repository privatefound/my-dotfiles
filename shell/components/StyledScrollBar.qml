import QtQuick
import QtQuick.Controls
import qs.config

ScrollBar {
    id: root

    policy: ScrollBar.AsNeeded
    padding: 2

    contentItem: Rectangle {
        implicitWidth: 4
        radius: 2
        color: Theme.primary
        opacity: root.pressed ? 0.8 : root.active || root.hovered ? 0.5 : 0

        Behavior on opacity {
            Anim {
                duration: Theme.anim.fast
            }
        }
    }
    background: null
}
