import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: popup
    visible: false

    anchors { top: true; right: true }
    margins { top: 38; right: 180 }

    implicitWidth: 340
    implicitHeight: 460
    color: "transparent"

    property int activeTab: 0  // 0=wifi, 1=ethernet, 2=vpn
    property var wifiList: []
    property var ethList: []
    property var vpnList: []
    property bool scanning: false
    property string connectedSsid: ""

    readonly property string ff: "JetBrainsMono Nerd Font"

    // ── Background ──
    Rectangle {
        anchors.fill: parent
        color: "#0a0a0a"
        radius: 12
        border.color: Qt.rgba(0, 1, 0.255, 0.2)
        border.width: 1
    }

    // ── Processes ──
    Process {
        id: wifiScanProc
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", "yes"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(":")
                if (parts.length < 4) return
                var active = parts[0] === "yes"
                var ssid = parts[1] || ""
                if (!ssid) return
                var signal = parseInt(parts[2]) || 0
                var secure = parts[3] && parts[3] !== "" && parts[3] !== "--"
                if (active) popup.connectedSsid = ssid
                var nets = popup.wifiList.slice()
                if (!nets.some(n => n.ssid === ssid)) {
                    nets.push({ ssid: ssid, signal: signal, secure: secure, active: active })
                    nets.sort((a, b) => a.active !== b.active ? (a.active ? -1 : 1) : b.signal - a.signal)
                    popup.wifiList = nets
                }
            }
        }
        onRunningChanged: {
            if (!running && popup.scanning) popup.scanning = false
        }
    }

    Process {
        id: ethProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE,DEVICE,ACTIVE,IP4.ADDRESS", "connection", "show"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var line = data.trim()
                if (!line) return
                var parts = line.split(":")
                if (parts.length < 4) return
                var ctype = parts[1] || ""
                if (ctype.indexOf("ethernet") === -1 && ctype.indexOf("802-3") === -1) return
                var name = parts[0]
                var device = parts[2] || "--"
                var active = parts[3] === "yes"
                var eths = popup.ethList.slice()
                if (!eths.some(e => e.name === name)) {
                    eths.push({ name: name, device: device, active: active, type: "ethernet" })
                    eths.sort((a, b) => a.active !== b.active ? (a.active ? -1 : 1) : 0)
                    popup.ethList = eths
                }
            }
        }
    }

    Process {
        id: vpnProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE,ACTIVE", "connection", "show"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var line = data.trim()
                if (!line) return
                var parts = line.split(":")
                if (parts.length < 3) return
                var ctype = parts[1] || ""
                if (ctype.indexOf("vpn") === -1 && ctype.indexOf("wireguard") === -1 && ctype.indexOf("tun") === -1) return
                var name = parts[0]
                var active = parts[2] === "yes"
                var vpns = popup.vpnList.slice()
                if (!vpns.some(v => v.name === name)) {
                    vpns.push({ name: name, active: active, type: ctype })
                    popup.vpnList = vpns
                }
            }
        }
    }

    Process {
        id: connUpProc
        command: ["nmcli", "connection", "up", "placeholder"]
    }

    Process {
        id: connDownProc
        command: ["nmcli", "connection", "down", "placeholder"]
    }

    Process {
        id: nmEditorProc
        command: ["nm-connection-editor"]
    }

    // ── Layout ──
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 0

        // Header
        RowLayout {
            spacing: 10
            Text {
                text: "󰛳"
                color: "#00ff41"
                font { family: popup.ff; pixelSize: 18 }
            }
            Text {
                text: "Network"
                color: "#00ff41"
                font { family: popup.ff; pixelSize: 14; bold: true }
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 56
                height: 24
                radius: 6
                color: settMA.containsMouse ? "#0a2a0a" : "#111111"
                border.color: Qt.rgba(0, 1, 0.255, 0.15)
                border.width: 1
                Text {
                    anchors.centerIn: parent; text: "󰒓 Edit"
                    color: "#008f11"; font { family: popup.ff; pixelSize: 9 }
                }
                MouseArea { id: settMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: nmEditorProc.running = true }
            }
        }

        Item { height: 8 }

        // ── Tab bar ──
        RowLayout {
            spacing: 4
            Repeater {
                model: [
                    { label: "󰤨 WiFi", idx: 0 },
                    { label: "󰈀 Ethernet", idx: 1 },
                    { label: "󰦝 VPN", idx: 2 }
                ]
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 28
                    radius: 6
                    color: popup.activeTab === modelData.idx ? Qt.rgba(0, 1, 0.255, 0.1) : (tabMA.containsMouse ? "#111111" : "transparent")
                    border.color: popup.activeTab === modelData.idx ? Qt.rgba(0, 1, 0.255, 0.3) : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: popup.activeTab === modelData.idx ? "#00ff41" : "#555555"
                        font { family: popup.ff; pixelSize: 10; bold: popup.activeTab === modelData.idx }
                    }
                    MouseArea {
                        id: tabMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            popup.activeTab = modelData.idx
                            if (modelData.idx === 0 && popup.wifiList.length === 0) scanNetworks()
                            if (modelData.idx === 1) refreshEthernet()
                            if (modelData.idx === 2) refreshVpn()
                        }
                    }
                }
            }
        }

        Item { height: 8 }
        Rectangle { Layout.fillWidth: true; height: 1; color: "#00ff41"; opacity: 0.08 }
        Item { height: 6 }

        // ── WiFi Tab ──
        Flickable {
            visible: popup.activeTab === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: wifiCol.height
            clip: true

            Column {
                id: wifiCol
                width: parent.width
                spacing: 2

                // Scan button row
                Rectangle {
                    width: parent.width; height: 30; color: "transparent"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 4; anchors.rightMargin: 4
                        Text {
                            text: popup.connectedSsid ? "  " + popup.connectedSsid : "  Not connected"
                            color: popup.connectedSsid ? "#008f11" : "#444444"
                            font { family: popup.ff; pixelSize: 10 }
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 52; height: 22; radius: 5
                            color: wScanMA.containsMouse ? "#0a2a0a" : "#111111"
                            border.color: Qt.rgba(0, 1, 0.255, 0.15); border.width: 1
                            Text { anchors.centerIn: parent; text: popup.scanning ? "···" : "󰑐 Scan"; color: "#00ff41"; font { family: popup.ff; pixelSize: 9 } }
                            MouseArea { id: wScanMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: scanNetworks() }
                        }
                    }
                }

                Repeater {
                    model: popup.wifiList
                    delegate: Rectangle {
                        width: wifiCol.width; height: 40; radius: 6
                        color: wfMA.containsMouse ? "#0a2a0a" : (modelData.active ? Qt.rgba(0, 1, 0.255, 0.04) : "transparent")
                        border.color: modelData.active ? Qt.rgba(0, 1, 0.255, 0.15) : "transparent"; border.width: 1

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8

                            // Signal bars
                            Item {
                                width: 14; height: 14; Layout.alignment: Qt.AlignVCenter
                                Row {
                                    anchors.bottom: parent.bottom; spacing: 1
                                    Repeater {
                                        model: 4
                                        Rectangle {
                                            width: 2.5; height: 3 + (index * 2.5); anchors.bottom: parent.bottom; radius: 1
                                            color: modelData.signal > (index * 25) ? "#00ff41" : "#1a1a1a"
                                            opacity: modelData.signal > (index * 25) ? 0.9 : 0.3
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                spacing: 0; Layout.fillWidth: true
                                Text {
                                    text: modelData.ssid; color: modelData.active ? "#00ff41" : "#bbbbbb"
                                    font { family: popup.ff; pixelSize: 11; bold: modelData.active }
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                }
                                Text {
                                    text: (modelData.secure ? "󰌾 Secured" : "Open") + "  " + modelData.signal + "%"
                                    color: "#444444"; font { family: popup.ff; pixelSize: 8 }
                                }
                            }

                            Rectangle {
                                visible: modelData.active; width: 56; height: 18; radius: 3
                                color: Qt.rgba(0, 1, 0.255, 0.08); border.color: Qt.rgba(0, 1, 0.255, 0.2); border.width: 1
                                Text { anchors.centerIn: parent; text: "󰄬 Active"; color: "#00ff41"; font { family: popup.ff; pixelSize: 8 } }
                            }
                            Text { visible: !modelData.active; text: "›"; color: "#333333"; font { family: popup.ff; pixelSize: 14 } }
                        }
                        MouseArea {
                            id: wfMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { if (!modelData.active) nmEditorProc.running = true }
                        }
                    }
                }

                // Scanning indicator
                Item {
                    visible: popup.scanning && popup.wifiList.length === 0
                    width: wifiCol.width; height: 50
                    Text {
                        anchors.centerIn: parent; text: "Scanning..."; color: "#008f11"
                        font { family: popup.ff; pixelSize: 11 }
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.3; duration: 500 }
                            NumberAnimation { from: 0.3; to: 1.0; duration: 500 }
                        }
                    }
                }
            }
        }

        // ── Ethernet Tab ──
        Flickable {
            visible: popup.activeTab === 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: ethCol.height
            clip: true

            Column {
                id: ethCol
                width: parent.width
                spacing: 2

                Repeater {
                    model: popup.ethList
                    delegate: Rectangle {
                        width: ethCol.width; height: 50; radius: 6
                        color: ethMA.containsMouse ? "#0a2a0a" : (modelData.active ? Qt.rgba(0, 1, 0.255, 0.04) : "transparent")
                        border.color: modelData.active ? Qt.rgba(0, 1, 0.255, 0.15) : "transparent"; border.width: 1

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10

                            Text {
                                text: "󰈀"
                                color: modelData.active ? "#00ff41" : "#555555"
                                font { family: popup.ff; pixelSize: 16 }
                            }

                            ColumnLayout {
                                spacing: 1; Layout.fillWidth: true
                                Text {
                                    text: modelData.name
                                    color: modelData.active ? "#00ff41" : "#bbbbbb"
                                    font { family: popup.ff; pixelSize: 11; bold: modelData.active }
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                }
                                Text {
                                    text: modelData.device !== "--" ? modelData.device : "No device"
                                    color: "#444444"; font { family: popup.ff; pixelSize: 9 }
                                }
                            }

                            // Toggle button
                            Rectangle {
                                width: 56; height: 22; radius: 5
                                color: ethBtnMA.containsMouse ? (modelData.active ? "#2a0a0a" : "#0a2a0a") : "#111111"
                                border.color: modelData.active ? Qt.rgba(1, 0.3, 0.3, 0.2) : Qt.rgba(0, 1, 0.255, 0.2); border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.active ? "󰅖 Down" : "󰄬 Up"
                                    color: modelData.active ? "#ff4444" : "#00ff41"
                                    font { family: popup.ff; pixelSize: 9 }
                                }
                                MouseArea {
                                    id: ethBtnMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.active) {
                                            connDownProc.command = ["nmcli", "connection", "down", modelData.name]
                                            connDownProc.running = true
                                        } else {
                                            connUpProc.command = ["nmcli", "connection", "up", modelData.name]
                                            connUpProc.running = true
                                        }
                                        ethRefreshTimer.running = true
                                    }
                                }
                            }
                        }
                        MouseArea { id: ethMA; anchors.fill: parent; hoverEnabled: true; z: -1 }
                    }
                }

                // Empty state
                Item {
                    visible: popup.ethList.length === 0
                    width: ethCol.width
                    height: 80
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "󰈀"
                            color: "#333333"
                            font { family: popup.ff; pixelSize: 24 }
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: "No ethernet connections"
                            color: "#444444"
                            font { family: popup.ff; pixelSize: 10 }
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }

        // ── VPN Tab ──
        Flickable {
            visible: popup.activeTab === 2
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: vpnCol.height
            clip: true

            Column {
                id: vpnCol
                width: parent.width
                spacing: 2

                Repeater {
                    model: popup.vpnList
                    delegate: Rectangle {
                        width: vpnCol.width; height: 50; radius: 6
                        color: vpnItemMA.containsMouse ? "#0a2a0a" : (modelData.active ? Qt.rgba(0, 1, 0.255, 0.04) : "transparent")
                        border.color: modelData.active ? Qt.rgba(0, 1, 0.255, 0.15) : "transparent"; border.width: 1

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10

                            Text {
                                text: modelData.active ? "󰦝" : "󰦞"
                                color: modelData.active ? "#00ff41" : "#555555"
                                font { family: popup.ff; pixelSize: 16 }
                            }

                            ColumnLayout {
                                spacing: 1; Layout.fillWidth: true
                                Text {
                                    text: modelData.name
                                    color: modelData.active ? "#00ff41" : "#bbbbbb"
                                    font { family: popup.ff; pixelSize: 11; bold: modelData.active }
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                }
                                Text {
                                    text: modelData.type.indexOf("wireguard") !== -1 ? "WireGuard" : "OpenVPN"
                                    color: "#444444"; font { family: popup.ff; pixelSize: 9 }
                                }
                            }

                            // Toggle
                            Rectangle {
                                width: 70; height: 22; radius: 5
                                color: vpnBtnMA.containsMouse ? (modelData.active ? "#2a0a0a" : "#0a2a0a") : "#111111"
                                border.color: modelData.active ? Qt.rgba(1, 0.3, 0.3, 0.2) : Qt.rgba(0, 1, 0.255, 0.2); border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.active ? "󰅖 Disconnect" : "󰄬 Connect"
                                    color: modelData.active ? "#ff4444" : "#00ff41"
                                    font { family: popup.ff; pixelSize: 9 }
                                }
                                MouseArea {
                                    id: vpnBtnMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.active) {
                                            connDownProc.command = ["nmcli", "connection", "down", modelData.name]
                                            connDownProc.running = true
                                        } else {
                                            connUpProc.command = ["nmcli", "connection", "up", modelData.name]
                                            connUpProc.running = true
                                        }
                                        vpnRefreshTimer.running = true
                                    }
                                }
                            }
                        }
                        MouseArea { id: vpnItemMA; anchors.fill: parent; hoverEnabled: true; z: -1 }
                    }
                }

                // Empty state
                Item {
                    visible: popup.vpnList.length === 0
                    width: vpnCol.width
                    height: 80
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "󰦞"
                            color: "#333333"
                            font { family: popup.ff; pixelSize: 24 }
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: "No VPN configured"
                            color: "#444444"
                            font { family: popup.ff; pixelSize: 10 }
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: "Add via nm-connection-editor"
                            color: "#333333"
                            font { family: popup.ff; pixelSize: 9 }
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }

        // Footer
        Item { height: 4 }
        Rectangle { Layout.fillWidth: true; height: 1; color: "#00ff41"; opacity: 0.06 }
        Item { height: 4 }

        RowLayout {
            spacing: 6
            Text {
                property int total: popup.activeTab === 0 ? popup.wifiList.length : (popup.activeTab === 1 ? popup.ethList.length : popup.vpnList.length)
                text: total > 0 ? total + " connections" : ""
                color: "#333333"; font { family: popup.ff; pixelSize: 9 }
            }
            Item { Layout.fillWidth: true }
        }
    }

    Timer {
        id: ethRefreshTimer
        interval: 500
        onTriggered: refreshEthernet()
    }

    Timer {
        id: vpnRefreshTimer
        interval: 500
        onTriggered: refreshVpn()
    }

    function scanNetworks() {
        popup.scanning = true
        popup.wifiList = []
        popup.connectedSsid = ""
        wifiScanProc.running = true
    }

    function refreshEthernet() {
        popup.ethList = []
        ethProc.running = true
    }

    function refreshVpn() {
        popup.vpnList = []
        vpnProc.running = true
    }

    function refreshAll() {
        scanNetworks()
        refreshEthernet()
        refreshVpn()
    }

    Component.onCompleted: {
        refreshEthernet()
        refreshVpn()
    }
}
