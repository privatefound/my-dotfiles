import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: popup
    visible: false

    signal volumeChanged()

    anchors { top: true; right: true }
    margins { top: 38; right: 100 }

    implicitWidth: 300
    property int btMaxDevicesVisible: 3
    property int btDeviceHeight: 30
    property int btDeviceSpacing: 4
    property int btListHeight: popup.btPowered && popup.btDevices.length > 0
        ? Math.min(popup.btDevices.length, btMaxDevicesVisible) * (btDeviceHeight + btDeviceSpacing) - btDeviceSpacing
        : 20
    implicitHeight: 140 + 1 + 20 + 10 + btListHeight + 36 + 14
    color: "transparent"

    property int currentVolume: 50
    property bool isMuted: false

    // ── Bluetooth state ──
    property bool btPowered: false
    property var btDevices: []
    property var btConnected: []

    Process {
        id: getVolProc
        command: ["sh", "-c", "echo $(pamixer --get-volume):$(pamixer --get-mute)"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(":")
                popup.currentVolume = parseInt(parts[0]) || 0
                popup.isMuted = parts[1] === "true"
                popup.volumeChanged()
            }
        }
    }

    Process {
        id: setVolProc
        command: ["pamixer", "--set-volume", "50"]
    }

    Process {
        id: muteProc
        command: ["pamixer", "-t"]
    }

    // ── Bluetooth processes ──
    Process {
        id: btPowerProc
        command: ["bluetoothctl", "show"]
        stdout: SplitParser {
            onRead: data => {
                if (data.indexOf("Powered:") !== -1)
                    popup.btPowered = data.indexOf("yes") !== -1
            }
        }
    }

    Process {
        id: btPairedProc
        property var _buf: []
        command: ["bluetoothctl", "devices", "Paired"]
        stdout: SplitParser {
            onRead: data => {
                var m = data.trim().match(/^Device\s+(\S+)\s+(.+)$/)
                if (m) btPairedProc._buf.push({ mac: m[1], name: m[2] })
            }
        }
        onRunningChanged: {
            if (!running) {
                popup.btDevices = btPairedProc._buf
                btPairedProc._buf = []
                btConnectedProc.running = true
            }
        }
    }

    Process {
        id: btConnectedProc
        property var _buf: []
        command: ["bluetoothctl", "devices", "Connected"]
        stdout: SplitParser {
            onRead: data => {
                var m = data.trim().match(/^Device\s+(\S+)/)
                if (m) btConnectedProc._buf.push(m[1])
            }
        }
        onRunningChanged: {
            if (!running) {
                popup.btConnected = btConnectedProc._buf
                btConnectedProc._buf = []
            }
        }
    }

    Process {
        id: btTogglePowerProc
        command: ["bluetoothctl", "power", "on"]
        onRunningChanged: if (!running) btRefreshTimer.running = true
    }

    Process {
        id: btConnectProc
        command: ["bluetoothctl", "connect", ""]
        onRunningChanged: if (!running) btRefreshTimer.running = true
    }

    Process {
        id: btDisconnectProc
        command: ["bluetoothctl", "disconnect", ""]
        onRunningChanged: if (!running) btRefreshTimer.running = true
    }

    Timer {
        id: btRefreshTimer
        interval: 800
        onTriggered: popup.refreshBluetooth()
    }

    Timer {
        id: refreshTimer
        interval: 300
        onTriggered: getVolProc.running = true
    }

    Rectangle {
        anchors.fill: parent
        color: "#0a0a0a"
        radius: 12
        border.color: Qt.rgba(0, 1, 0.255, 0.2)
        border.width: 1

        // Subtle inner glow
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 11
            color: "transparent"
            border.color: Qt.rgba(0, 1, 0.255, 0.05)
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            // Header
            RowLayout {
                spacing: 10

                Text {
                    text: popup.isMuted ? "󰖁" : (popup.currentVolume > 70 ? "󰕾" : popup.currentVolume > 30 ? "󰖀" : "󰕿")
                    color: popup.isMuted ? "#ff4444" : "#00ff41"
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 18 }
                }

                Text {
                    text: popup.isMuted ? "Muted" : "Volume"
                    color: popup.isMuted ? "#ff4444" : "#00ff41"
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 13; bold: true }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: popup.currentVolume + "%"
                    color: popup.isMuted ? "#ff4444" : "#00ff41"
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 22; bold: true }
                }
            }

            // Slider
            Item {
                Layout.fillWidth: true
                height: 24

                // Track bg
                Rectangle {
                    id: sliderTrack
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    radius: 2
                    color: "#1a1a1a"

                    // Fill
                    Rectangle {
                        width: Math.min(popup.currentVolume / 150, 1.0) * parent.width
                        height: parent.height
                        radius: 2
                        color: popup.isMuted ? "#ff4444" : "#00ff41"
                        opacity: 0.8

                        Behavior on width { NumberAnimation { duration: 50 } }
                    }

                    // 100% marker
                    Rectangle {
                        x: (100 / 150) * parent.width
                        y: -2
                        width: 1
                        height: parent.height + 4
                        color: "#00ff41"
                        opacity: 0.3
                    }
                }

                // Handle
                Rectangle {
                    id: handle
                    x: Math.min(popup.currentVolume / 150, 1.0) * (sliderTrack.width - width)
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14
                    height: 14
                    radius: 7
                    color: popup.isMuted ? "#ff4444" : "#00ff41"

                    Behavior on x { NumberAnimation { duration: 50 } }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 6
                        height: 6
                        radius: 3
                        color: "#000000"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: (mouse) => applyVolume(mouse.x)
                    onPositionChanged: (mouse) => applyVolume(mouse.x)

                    function applyVolume(x) {
                        var newVal = Math.round((x / sliderTrack.width) * 150)
                        newVal = Math.max(0, Math.min(150, newVal))
                        popup.currentVolume = newVal
                        setVolProc.command = ["pamixer", "--allow-boost", "--set-volume", String(newVal)]
                        setVolProc.running = true
                        popup.volumeChanged()
                    }
                }
            }

            // Bottom row
            RowLayout {
                spacing: 8

                // Mute button
                Rectangle {
                    width: 32
                    height: 26
                    radius: 6
                    color: muteMA.containsMouse ? (popup.isMuted ? "#2a0a0a" : "#0a2a0a") : "#111111"
                    border.color: popup.isMuted ? Qt.rgba(1, 0.27, 0.27, 0.3) : Qt.rgba(0, 1, 0.255, 0.2)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: popup.isMuted ? "󰖁" : "󰕾"
                        color: popup.isMuted ? "#ff4444" : "#00ff41"
                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 13 }
                    }

                    MouseArea {
                        id: muteMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            muteProc.running = true
                            refreshTimer.running = true
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Preset buttons
                Repeater {
                    model: [25, 50, 75, 100]
                    delegate: Rectangle {
                        width: 36
                        height: 26
                        radius: 6
                        color: presetMA.containsMouse ? "#0a2a0a" : (popup.currentVolume === modelData ? "#0a2a0a" : "#111111")
                        border.color: popup.currentVolume === modelData ? Qt.rgba(0, 1, 0.255, 0.4) : Qt.rgba(0, 1, 0.255, 0.1)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: popup.currentVolume === modelData ? "#00ff41" : "#008f11"
                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 10 }
                        }

                        MouseArea {
                            id: presetMA
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                popup.currentVolume = modelData
                                setVolProc.command = ["pamixer", "--set-volume", String(modelData)]
                                setVolProc.running = true
                                popup.volumeChanged()
                            }
                        }
                    }
                }
            }

            // ── Bluetooth Section ──
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(0, 1, 0.255, 0.12)
            }

            ColumnLayout {
                id: btSection
                Layout.fillWidth: true
                spacing: 10

                // BT Header
                RowLayout {
                    spacing: 10

                    Text {
                        text: "󰂯"
                        color: popup.btPowered ? "#00ff41" : "#555555"
                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 16 }
                    }

                    Text {
                        text: "Bluetooth"
                        color: popup.btPowered ? "#00ff41" : "#555555"
                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 13; bold: true }
                    }

                    Item { Layout.fillWidth: true }

                    // Power toggle
                    Rectangle {
                        width: 38
                        height: 20
                        radius: 10
                        color: popup.btPowered ? Qt.rgba(0, 1, 0.255, 0.15) : "#1a1a1a"
                        border.color: popup.btPowered ? Qt.rgba(0, 1, 0.255, 0.3) : Qt.rgba(1, 1, 1, 0.1)
                        border.width: 1

                        Rectangle {
                            x: popup.btPowered ? parent.width - width - 3 : 3
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 14
                            radius: 7
                            color: popup.btPowered ? "#00ff41" : "#555555"

                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                btTogglePowerProc.command = ["bluetoothctl", "power", popup.btPowered ? "off" : "on"]
                                btTogglePowerProc.running = true
                            }
                        }
                    }
                }

                // Device list (scrollable)
                Item {
                    Layout.fillWidth: true
                    implicitHeight: popup.btListHeight
                    visible: popup.btPowered && popup.btDevices.length > 0
                    clip: true

                    Flickable {
                        id: btFlick
                        anchors.fill: parent
                        contentHeight: btDeviceCol.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: btDeviceCol
                            width: parent.width
                            spacing: popup.btDeviceSpacing

                            Repeater {
                                model: popup.btDevices.length
                                delegate: Rectangle {
                                    required property int index
                                    property var dev: popup.btDevices[index] || { mac: "", name: "" }
                                    property bool isConn: popup.btConnected.indexOf(dev.mac) !== -1

                                    width: btDeviceCol.width
                                    height: popup.btDeviceHeight
                                    radius: 6
                                    color: devMA.containsMouse ? (isConn ? "#0a2a0a" : "#151515") : "#111111"
                                    border.color: isConn ? Qt.rgba(0, 1, 0.255, 0.3) : Qt.rgba(1, 1, 1, 0.05)
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Text {
                                            text: isConn ? "󰂱" : "󰂳"
                                            color: isConn ? "#00ff41" : "#555555"
                                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 12 }
                                        }

                                        Text {
                                            text: dev.name
                                            color: isConn ? "#00ff41" : "#888888"
                                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 11 }
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: isConn ? "connected" : "paired"
                                            color: isConn ? Qt.rgba(0, 1, 0.255, 0.5) : "#444444"
                                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 9 }
                                        }
                                    }

                                    MouseArea {
                                        id: devMA
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (isConn) {
                                                btDisconnectProc.command = ["bluetoothctl", "disconnect", dev.mac]
                                                btDisconnectProc.running = true
                                            } else {
                                                btConnectProc.command = ["bluetoothctl", "connect", dev.mac]
                                                btConnectProc.running = true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Scroll indicator
                    Rectangle {
                        visible: btFlick.contentHeight > btFlick.height
                        anchors.right: parent.right
                        anchors.rightMargin: 1
                        y: btFlick.height * (btFlick.contentY / btFlick.contentHeight)
                        width: 2
                        height: Math.max(10, btFlick.height * (btFlick.height / btFlick.contentHeight))
                        radius: 1
                        color: "#00ff41"
                        opacity: btFlick.moving ? 0.6 : 0.2

                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                }

                // Empty state
                Text {
                    visible: popup.btPowered && popup.btDevices.length === 0
                    text: "No paired devices"
                    color: "#444444"
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 10 }
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    visible: !popup.btPowered
                    text: "Bluetooth off"
                    color: "#444444"
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 10 }
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    function updateVolume() {
        getVolProc.running = true
    }

    function refreshBluetooth() {
        btPowerProc.running = true
        btPairedProc._buf = []
        btPairedProc.running = true
    }

    Component.onCompleted: {
        updateVolume()
        refreshBluetooth()
    }

    onVisibleChanged: {
        if (visible) refreshBluetooth()
    }
}
