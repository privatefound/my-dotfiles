import Quickshell
import Quickshell.Io
import QtQuick

Text {
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 13
    property color activeColor: "#00ff41"
    property color dimColor: "#008f11"

    id: networkDisplayText
    color: dimColor
    font { family: fontFamily; pixelSize: fontSize }
    text: "󰹑"
}
