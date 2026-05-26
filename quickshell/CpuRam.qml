import QtQuick
import QtQuick.Layouts

RowLayout {
    property string fontFamily: "monospace"
    property int fontSize: 13
    property color cpuColor: "#00ff41"
    property color ramColor: "#008f11"
    property int cpuValue: 0
    property int ramValue: 0

    spacing: 8

    Text {
        text: "󰍛 " + cpuValue + "%"
        color: cpuColor
        font {
            family: parent.fontFamily
            pixelSize: parent.fontSize
        }
    }

    Text {
        text: "󰘚 " + ramValue + "%"
        color: ramColor
        font {
            family: parent.fontFamily
            pixelSize: parent.fontSize
        }
    }
}