import Quickshell
import Quickshell.Io
import QtQuick

Text {
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 13
    property color activeColor: "#00ff41"
    property color dimColor: "#008f11"
    property bool opaque: false

    id: opacityText
    color: opaque ? activeColor : dimColor
    font { family: fontFamily; pixelSize: fontSize }
    text: opaque ? "󰈈" : "󰈉"

    Process {
        id: setOpaqueProc
        command: ["sh", "-c", "hyprctl keyword decoration:active_opacity 1.0 && hyprctl keyword decoration:inactive_opacity 1.0"]
    }

    Process {
        id: setTransparentProc
        command: ["sh", "-c", "hyprctl keyword decoration:active_opacity 0.95 && hyprctl keyword decoration:inactive_opacity 0.80"]
    }

    function toggle() {
        if (opaque) {
            setTransparentProc.running = true
            opaque = false
        } else {
            setOpaqueProc.running = true
            opaque = true
        }
    }
}
