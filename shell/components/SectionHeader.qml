import QtQuick
import QtQuick.Layouts
import qs.config

RowLayout {
    id: root

    property string text
    property string icon

    spacing: 8
    Layout.fillWidth: true

    Icon {
        visible: root.icon !== ""
        text: root.icon
        size: 15
        color: Theme.primary
    }

    StyledText {
        text: root.text.toUpperCase()
        color: Theme.primary
        font.pixelSize: Theme.font.tiny
        font.weight: Font.Bold
        font.letterSpacing: 1.2
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Theme.outline
        opacity: 0.6
    }
}
