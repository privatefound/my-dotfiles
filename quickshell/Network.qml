import Quickshell
import Quickshell.Io
import QtQuick

Text {
    property string fontFamily: "monospace"
    property int fontSize: 13
    property color activeColor: "#00ff41"
    property color inactiveColor: "#008f11"

    id: netText
    color: activeColor
    font {
        family: fontFamily
        pixelSize: fontSize
    }

    Process {
        id: netProc
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi | grep '^yes' | cut -d: -f2,3 || echo 'DISCONNECTED'"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var info = data.trim()
                if (info === "DISCONNECTED" || info === "") {
                    netText.text = "󰤭 Offline"
                    netText.color = inactiveColor
                } else {
                    var parts = info.split(":")
                    var ssid = parts[0] || "Unknown"
                    var signal = parts[1] || "0"
                    var icon = parseInt(signal) > 70 ? "󰤨" : parseInt(signal) > 40 ? "󰤥" : "󰤟"
                    netText.text = icon + " " + ssid
                    netText.color = activeColor
                }
            }
        }
        Component.onCompleted: running = true
    }

    function refresh() {
        netProc.running = true
    }

    Component.onCompleted: refresh()
}