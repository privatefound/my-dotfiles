import Quickshell
import Quickshell.Io
import QtQuick

Text {
    property string fontFamily: "monospace"
    property int fontSize: 13
    property color activeColor: "#00ff41"
    property color mutedColor: "#ff0000"

    id: volText
    color: activeColor
    font {
        family: fontFamily
        pixelSize: fontSize
    }

    Process {
        id: volProc
        command: ["sh", "-c", "echo $(pamixer --get-volume):$(pamixer --get-mute)"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(":")
                var num = parseInt(parts[0]) || 0
                var muted = parts[1] === "true"
                if (muted) {
                    volText.text = "󰖁 MUTED"
                    volText.color = mutedColor
                } else {
                    var icon = num > 70 ? "󰕾" : num > 30 ? "󰖀" : "󰕿"
                    volText.text = icon + " " + num + "%"
                    volText.color = activeColor
                }
            }
        }
        Component.onCompleted: running = true
    }

    function refresh() {
        volProc.running = true
    }

    Component.onCompleted: refresh()
}
