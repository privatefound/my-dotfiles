import Quickshell
import Quickshell.Io
import QtQuick

Text {
    property string fontFamily: "monospace"
    property int fontSize: 13
    property color activeColor: "#00ff41"
    property color inactiveColor: "#008f11"

    id: netText
    text: "󰤭 Offline"
    color: inactiveColor
    font {
        family: fontFamily
        pixelSize: fontSize
    }

    property var networkLines: []

    Process {
        id: netProc
        command: ["sh", "-c", `
            DEFAULT_IF=$(ip route | grep '^default' | head -n1 | awk '{print $5}')
            WIFI_INFO=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi | grep '^yes' | cut -d: -f2,3)
            ETH_CONN=$(nmcli -t -f NAME,TYPE,DEVICE connection show --active | grep ':802-3-ethernet:' | head -n1)
            
            if [ -z "$WIFI_INFO" ] && [ -z "$ETH_CONN" ]; then
                echo "OFFLINE"
            else
                echo "DEFAULT:$DEFAULT_IF"
                [ -n "$WIFI_INFO" ] && echo "WIFI:$WIFI_INFO"
                [ -n "$ETH_CONN" ] && echo "$ETH_CONN"
            fi
        `]
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line) {
                    networkLines.push(line)
                }
            }
        }
        onRunningChanged: {
            if (!running && networkLines.length > 0) {
                parseNetworkData()
                networkLines = []
            }
        }
        onExited: {
            if (networkLines.length > 0) {
                parseNetworkData()
                networkLines = []
            }
        }
        Component.onCompleted: running = true
    }

    function parseNetworkData() {
        if (networkLines.length === 0 || networkLines[0] === "OFFLINE") {
            netText.text = "󰤭 Offline"
            netText.color = inactiveColor
            return
        }
        
        var defaultIf = ""
        var wifiText = ""
        var wifiDev = ""
        var ethText = ""
        var ethDev = ""
        
        for (var i = 0; i < networkLines.length; i++) {
            var line = networkLines[i]
            if (line.startsWith("DEFAULT:")) {
                defaultIf = line.substring(8)
            } else if (line.startsWith("WIFI:")) {
                var info = line.substring(5)
                var parts = info.split(":")
                var ssid = parts[0] || "Unknown"
                var signal = parts[1] || "0"
                var icon = parseInt(signal) > 70 ? "󰤨" : parseInt(signal) > 40 ? "󰤥" : "󰤟"
                wifiText = icon + " " + ssid
                // Ottieni device WiFi - assume wl* o wlan*
                wifiDev = defaultIf.startsWith("wl") || defaultIf.startsWith("wlan") ? defaultIf : ""
            } else if (line.includes(":802-3-ethernet:")) {
                var ethParts = line.split(":")
                var ethName = ethParts[0] || "Ethernet"
                ethDev = ethParts[2] || ""
                ethText = "󰈀 " + ethName
            }
        }
        
        // Evidenzia quella con route di default
        if (wifiText && wifiDev && wifiDev === defaultIf) {
            wifiText = "[" + wifiText + "]"
        }
        if (ethText && ethDev && ethDev === defaultIf) {
            ethText = "[" + ethText + "]"
        }
        
        var result = []
        if (wifiText) result.push(wifiText)
        if (ethText) result.push(ethText)
        
        if (result.length > 0) {
            netText.text = result.join(" | ")
            netText.color = activeColor
        } else {
            netText.text = "󰤭 Offline"
            netText.color = inactiveColor
        }
    }

    function refresh() {
        netProc.running = true
    }

    Component.onCompleted: refresh()
}