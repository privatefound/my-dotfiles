import QtQuick
import qs.config

// Pulsante rotondo con icona. `toggled` lo colora con l'accento.
StyledRect {
    id: root

    property string icon
    property int size: 36
    property int iconSize: Math.round(size * 0.52)
    property bool toggled: false
    property bool disabled: false
    property color iconColor: toggled ? Theme.primary : disabled ? Theme.textFaint : Theme.text
    property color background: toggled ? Theme.primaryFill : "transparent"
    property alias hovered: layer.containsMouse
    property alias pressed: layer.pressed

    signal clicked(var mouse)

    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    color: background
    border.width: toggled ? 1 : 0
    border.color: Theme.alpha(Theme.primary, 0.55)
    scale: layer.pressed ? 0.92 : 1

    Behavior on scale {
        Anim {
            duration: Theme.anim.fast
        }
    }

    Icon {
        anchors.centerIn: parent
        text: root.icon
        size: root.iconSize
        color: root.iconColor
    }

    StateLayer {
        id: layer
        tint: root.iconColor
        disabled: root.disabled
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => root.clicked(mouse)
    }
}
