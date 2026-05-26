import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: popup
    visible: false

    anchors { top: true; left: true }
    margins { top: 38; left: 50 }

    implicitWidth: 520
    implicitHeight: 380
    color: "transparent"

    readonly property string ff: "JetBrainsMono Nerd Font"
    property string outputText: ""
    property bool calculating: false

    Process {
        id: ipcalcProc
        command: ["ipcalc", "192.168.1.0/24"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                popup.outputText += data + "\n"
            }
        }
        onRunningChanged: {
            if (!running) popup.calculating = false
        }
    }

    // Background
    Rectangle {
        anchors.fill: parent
        color: "#0a0a0a"
        radius: 12
        border.color: Qt.rgba(0, 1, 0.255, 0.2)
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
            spacing: 10
            Text {
                text: "󰛳"
                color: "#00ff41"
                font { family: popup.ff; pixelSize: 18 }
            }
            Text {
                text: "Subnet Calculator"
                color: "#00ff41"
                font { family: popup.ff; pixelSize: 14; bold: true }
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "ipcalc"
                color: "#333333"
                font { family: popup.ff; pixelSize: 10 }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#00ff41"
            opacity: 0.08
        }

        // Input row
        RowLayout {
            spacing: 8

            Text {
                text: "›"
                color: "#00ff41"
                font { family: popup.ff; pixelSize: 16; bold: true }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 6
                color: "#111111"
                border.color: inputField.activeFocus ? Qt.rgba(0, 1, 0.255, 0.5) : Qt.rgba(0, 1, 0.255, 0.15)
                border.width: 1

                TextInput {
                    id: inputField
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    color: "#00ff41"
                    selectionColor: "#00ff41"
                    selectedTextColor: "#000000"
                    font { family: popup.ff; pixelSize: 12 }
                    text: "192.168.1.0/24"
                    selectByMouse: true
                    onAccepted: calculate()

                    // Placeholder
                    Text {
                        visible: !inputField.text && !inputField.activeFocus
                        text: "e.g. 10.0.0.0/8 or 172.16.0.0 255.255.0.0"
                        color: "#333333"
                        font: inputField.font
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                width: 70
                height: 32
                radius: 6
                color: calcMA.containsMouse ? "#0a2a0a" : "#111111"
                border.color: Qt.rgba(0, 1, 0.255, 0.3)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: popup.calculating ? "···" : "󰃬 Calc"
                    color: "#00ff41"
                    font { family: popup.ff; pixelSize: 11 }
                }

                MouseArea {
                    id: calcMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: calculate()
                }
            }
        }

        // Quick presets
        RowLayout {
            spacing: 4
            Text {
                text: "Quick:"
                color: "#333333"
                font { family: popup.ff; pixelSize: 9 }
            }
            Repeater {
                model: ["/8", "/16", "/24", "/25", "/26", "/27", "/28", "/30", "/32"]
                delegate: Rectangle {
                    width: 32
                    height: 20
                    radius: 4
                    color: presetMA.containsMouse ? "#0a2a0a" : "#0d0d0d"
                    border.color: Qt.rgba(0, 1, 0.255, 0.1)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: "#008f11"
                        font { family: popup.ff; pixelSize: 9 }
                    }

                    MouseArea {
                        id: presetMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var base = inputField.text.split("/")[0].split(" ")[0]
                            if (!base) base = "192.168.1.0"
                            inputField.text = base + modelData
                            calculate()
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#00ff41"
            opacity: 0.06
        }

        // Output
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: outputCol.height
            clip: true

            ColumnLayout {
                id: outputCol
                width: parent.width
                spacing: 0

                // Empty state
                Item {
                    visible: !popup.outputText
                    Layout.fillWidth: true
                    height: 80
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "󰃬"
                            color: "#222222"
                            font { family: popup.ff; pixelSize: 28 }
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: "Enter an IP/CIDR and hit Calc"
                            color: "#333333"
                            font { family: popup.ff; pixelSize: 10 }
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                // Results
                Text {
                    visible: popup.outputText !== ""
                    text: popup.outputText
                    color: "#00ff41"
                    font { family: popup.ff; pixelSize: 10 }
                    textFormat: Text.PlainText
                    wrapMode: Text.NoWrap
                    Layout.fillWidth: true

                    // Color key fields
                    opacity: 0.9
                }
            }
        }
    }

    function calculate() {
        if (!inputField.text.trim()) return
        popup.outputText = ""
        popup.calculating = true
        var parts = inputField.text.trim().split(/\s+/)
        ipcalcProc.command = ["ipcalc"].concat(parts)
        ipcalcProc.running = true
    }

    onVisibleChanged: {
        if (visible) inputField.forceActiveFocus()
    }
}
