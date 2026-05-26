import QtQuick

Text {
    id: logo
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 16
    property color logoColor: "#00ff41"
    property color glowColor: "#008f11"

    signal clicked()

    text: "󰣇"
    color: logoColor
    font {
        family: fontFamily
        pixelSize: fontSize
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: logo.clicked()
    }
}
