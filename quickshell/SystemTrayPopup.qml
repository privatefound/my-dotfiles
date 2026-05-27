import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: popup
    visible: false

    anchors { top: true; right: true }
    margins { top: 38; right: 12 }

    implicitWidth: 220
    implicitHeight: contentCol.implicitHeight + 28
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
        id: contentCol
        anchors.fill: parent
        anchors.margins: 14
        spacing: 4

        RowLayout {
            spacing: 8
            Text {
                text: "󱊔"
                color: "#00ff41"
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 16 }
            }
            Text {
                text: "System Tray"
                color: "#00ff41"
                font { family: "JetBrainsMono Nerd Font"; pixelSize: 13; bold: true }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#00ff41"; opacity: 0.1 }

        Item { height: 2 }

        Text {
            visible: SystemTray.items.values.length === 0
            text: "No tray items"
            color: "#008f11"
            font { family: "JetBrainsMono Nerd Font"; pixelSize: 12 }
            opacity: 0.6
        }

        Repeater {
            model: SystemTray.items

            delegate: Rectangle {
                id: trayDelegate
                Layout.fillWidth: true
                height: 36
                radius: 8
                color: trayMA.containsMouse ? "#0a2a0a" : "transparent"

                required property var modelData

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 12

                    IconImage {
                        source: modelData.icon
                        implicitSize: 18
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                    }

                    Text {
                        text: modelData.title || modelData.id || "Unknown"
                        color: trayMA.containsMouse ? "#00ff41" : "#aaaaaa"
                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 12 }
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: trayMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            if (modelData.hasMenu)
                                modelData.display(popup, mouse.x, mouse.y)
                            else
                                modelData.activate()
                        } else {
                            modelData.secondaryActivate()
                        }
                    }
                }
            }
        }
    }
}
