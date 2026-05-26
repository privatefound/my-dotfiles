import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: popup
    visible: false

    signal actionTriggered(string action)

    anchors { top: true; left: true }
    margins { top: 38; left: 12 }

    implicitWidth: 200
    implicitHeight: 260
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: "#0a0a0a"
        radius: 12
        border.color: Qt.rgba(0, 1, 0.255, 0.2)
        border.width: 1

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 11
            color: "transparent"
            border.color: Qt.rgba(0, 1, 0.255, 0.05)
            border.width: 1
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 4

        RowLayout {
            spacing: 8
            Text {
                text: "󰣇"
                color: "#00ff41"
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 18 }
            }
            Text {
                text: "Arch Linux"
                color: "#00ff41"
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 13; bold: true }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#00ff41"; opacity: 0.1 }

        Item { height: 2 }

        Repeater {
            model: [
                { icon: "󰍛", label: "System Monitor", action: "sysmon", danger: false },
                { icon: "󰌾", label: "Lock Screen", action: "lock", danger: false },
                { icon: "󰍃", label: "Log Out", action: "logout", danger: false },
                { icon: "󰜉", label: "Reboot", action: "reboot", danger: false },
                { icon: "󰐥", label: "Shut Down", action: "shutdown", danger: true }
            ]

            delegate: Rectangle {
                Layout.fillWidth: true
                height: 34
                radius: 8
                color: itemMA.containsMouse ? (modelData.danger ? "#2a0a0a" : "#0a2a0a") : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 12

                    Text {
                        text: modelData.icon
                        color: modelData.danger ? (itemMA.containsMouse ? "#ff4444" : "#993333") : (itemMA.containsMouse ? "#00ff41" : "#008f11")
                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 15 }
                    }

                    Text {
                        text: modelData.label
                        color: modelData.danger ? (itemMA.containsMouse ? "#ff4444" : "#993333") : (itemMA.containsMouse ? "#00ff41" : "#aaaaaa")
                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 12 }
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: itemMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        popup.actionTriggered(modelData.action)
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
