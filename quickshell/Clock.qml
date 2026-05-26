import QtQuick

Text {
    property string fontFamily: "monospace"
    property int fontSize: 14
    property color textColor: "#00ff41"   // <-- RINOMINATA! Non "color"!

    id: clockText
    text: Qt.formatDateTime(new Date(), "ddd dd MMM  HH:mm:ss")
    color: textColor                       // <-- Usa la proprietà custom
    font {
        family: fontFamily
        pixelSize: fontSize
        bold: true
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            clockText.text = Qt.formatDateTime(new Date(), "ddd dd MMM  HH:mm:ss")
        }
    }
}