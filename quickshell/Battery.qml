import Quickshell
import Quickshell.Io
import QtQuick

Text {
    property string fontFamily: "monospace"
    property int fontSize: 13
    property color highColor: "#00ff41"
    property color midColor: "#ffff00"
    property color lowColor: "#ff0000"

    id: batText
    visible: false
    font {
        family: fontFamily
        pixelSize: fontSize
    }

    Process {
        id: batProc
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/capacity /sys/class/power_supply/BAT0/status 2>/dev/null | tr '\\n' ':'"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(":")
                var pct = parseInt(parts[0])
                if (isNaN(pct)) {
                    batText.visible = false
                    return
                }
                batText.visible = true
                var status = (parts[1] || "").trim()
                var charging = status === "Charging"
                var icon
                if (charging) {
                    icon = "󰂄"
                    batText.color = highColor
                } else if (pct > 60) {
                    icon = pct > 80 ? "󰁹" : "󰂀"
                    batText.color = highColor
                } else if (pct > 20) {
                    icon = pct > 40 ? "󰁾" : "󰁻"
                    batText.color = midColor
                } else {
                    icon = "󰁺"
                    batText.color = lowColor
                }
                batText.text = icon + " " + pct + "%"
            }
        }
        Component.onCompleted: running = true
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: batProc.running = true
    }
}
