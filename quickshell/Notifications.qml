import Quickshell
import Quickshell.Io
import QtQuick

Text {
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 13
    property color activeColor: "#00ff41"
    property color dimColor: "#008f11"
    property int unreadCount: 0

    id: notifText
    color: unreadCount > 0 ? activeColor : dimColor
    font { family: fontFamily; pixelSize: fontSize }
    text: unreadCount > 0 ? "󰂚 " + unreadCount : "󰂜"

    Process {
        id: countProc
        command: ["swaync-client", "-c"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var n = parseInt(data.trim())
                if (!isNaN(n)) notifText.unreadCount = n
            }
        }
        Component.onCompleted: running = true
    }

    function refresh() {
        countProc.running = true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: countProc.running = true
    }

    Component.onCompleted: refresh()
}
