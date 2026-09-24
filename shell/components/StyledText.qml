import QtQuick
import qs.config

Text {
    color: Theme.text
    font.family: Theme.font.sans
    font.pixelSize: Theme.font.body
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
    textFormat: Text.PlainText

    Behavior on color {
        CAnim {}
    }
}
