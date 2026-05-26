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
    implicitHeight: 140
    color: "transparent"

    property int currentVolume: 50
    property bool isMuted: false

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
        }
    }

    function updateVolume() {
        getVolProc.running = true
    }

    Component.onCompleted: updateVolume()
}
