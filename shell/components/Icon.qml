import QtQuick
import qs.config

// Glifo Nerd Font. Uso: Icon { text: Icons.wifi4; size: 18 }
Text {
    property int size: 18

    color: Theme.text
    font.family: Theme.font.icon
    font.pixelSize: size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    textFormat: Text.PlainText

    Behavior on color {
        CAnim {}
    }
}
