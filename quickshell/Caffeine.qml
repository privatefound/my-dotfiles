import Quickshell
import Quickshell.Wayland
import QtQuick

Text {
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 13
    property color activeColor: "#00ff41"
    property color dimColor: "#008f11"
    property bool awake: false
    property var window: null

    id: caffeineText
    color: awake ? activeColor : dimColor
    font { family: fontFamily; pixelSize: fontSize }
    text: ""

    IdleInhibitor {
        window: caffeineText.window
        enabled: caffeineText.awake
    }

    function toggle() {
        awake = !awake
    }
}
