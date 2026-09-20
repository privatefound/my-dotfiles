import Quickshell
import Quickshell.Wayland
import QtQuick

Text {
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 13
    property color activeColor: "#00ff41"
    property color dimColor: "#008f11"
    property bool awake: false

    id: caffeineText
    color: awake ? activeColor : dimColor
    font { family: fontFamily; pixelSize: fontSize }
    text: ""

    IdleInhibitor {
        window: caffeineText.Window.window
        enabled: caffeineText.awake
    }

    function toggle() {
        awake = !awake
    }
}
