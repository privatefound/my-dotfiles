import QtQuick
import QtQuick.Layouts
import qs.config

// Pulsante con testo (e icona opzionale).
// variant: "filled" | "tonal" | "outline" | "text" | "danger"
StyledRect {
    id: root

    property string text
    property string icon
    property string variant: "tonal"
    property bool disabled: false
    property int padding: 16

    readonly property color fg: disabled ? Theme.textFaint
        : variant === "filled" ? Theme.primary
        : variant === "danger" ? Theme.error
        : variant === "tonal" ? Theme.fgPrimaryContainer
        : Theme.primary

    signal clicked

    implicitHeight: 38
    implicitWidth: row.implicitWidth + padding * 2
    radius: Theme.radius.full
    color: disabled ? Theme.surfaceContainerHigh
        : variant === "filled" ? Theme.primaryFillStrong
        : variant === "danger" ? Theme.errorContainer
        : variant === "tonal" ? Theme.primaryContainer
        : "transparent"
    border.width: variant === "outline" || variant === "filled" || variant === "danger" ? 1 : 0
    border.color: variant === "filled" ? Theme.alpha(Theme.primary, 0.6) : variant === "danger" ? Theme.alpha(Theme.error, 0.6) : Theme.outline
    scale: layer.pressed ? 0.96 : 1

    Behavior on scale {
        Anim {
            duration: Theme.anim.fast
        }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Icon {
            visible: root.icon !== ""
            text: root.icon
            size: 17
            color: root.fg
        }

        StyledText {
            text: root.text
            color: root.fg
            font.weight: Font.DemiBold
        }
    }

    StateLayer {
        id: layer
        tint: root.fg
        disabled: root.disabled
        onClicked: root.clicked()
    }
}
