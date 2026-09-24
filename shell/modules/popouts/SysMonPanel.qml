import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

// Monitor di sistema: grafici CPU/RAM/GPU, temperature, rete, dischi, processi.
Item {
    id: root

    implicitWidth: 460
    implicitHeight: col.implicitHeight + 32

    Component.onCompleted: SysStats.detailed = true
    Component.onDestruction: SysStats.detailed = false

    component GraphCard: StyledRect {
        id: graphCard
        property string title
        property string icon
        property string value
        property string detail
        property var values: []
        property color tint: Theme.primary
        Layout.fillWidth: true
        implicitHeight: 110
        radius: Theme.radius.large
        color: Theme.surfaceContainer
        clip: true

        Graph {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * 0.62
            values: graphCard.values
            color: graphCard.tint
        }

        ColumnLayout {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 0
            RowLayout {
                spacing: 6
                Icon {
                    text: graphCard.icon
                    size: 15
                    color: graphCard.tint
                }
                StyledText {
                    text: graphCard.title
                    font.pixelSize: Theme.font.small
                    color: Theme.textDim
                }
            }
            StyledText {
                text: graphCard.value
                font.family: Theme.font.mono
                font.pixelSize: Theme.font.large
                font.weight: Font.Bold
            }
            StyledText {
                visible: graphCard.detail !== ""
                text: graphCard.detail
                font.pixelSize: Theme.font.tiny
                color: Theme.textFaint
            }
        }
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Icon {
                text: Icons.speedometer
                size: 20
                color: Theme.primary
            }
            StyledText {
                Layout.fillWidth: true
                text: "Sistema"
                font.pixelSize: Theme.font.title
                font.weight: Font.DemiBold
            }
            StyledText {
                text: "load " + SysStats.load
                font.family: Theme.font.mono
                font.pixelSize: Theme.font.tiny
                color: Theme.textFaint
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 8
            rowSpacing: 8

            GraphCard {
                title: "CPU"
                icon: Icons.chip
                value: Math.round(SysStats.cpu * 100) + "%"
                detail: SysStats.cpuTemp > 0 ? Math.round(SysStats.cpuTemp) + " °C" + (SysStats.fanRpm > 0 ? "  ·  ventola " + SysStats.fanRpm + " rpm" : "") : ""
                values: SysStats.cpuHistory
                tint: SysStats.cpu > 0.85 ? Theme.error : Theme.primary
            }
            GraphCard {
                title: "Memoria"
                icon: Icons.memory
                value: Math.round(SysStats.mem * 100) + "%"
                detail: SysStats.memUsedGb.toFixed(1) + " / " + SysStats.memTotalGb.toFixed(1) + " GB" + (SysStats.swap > 0.01 ? "  ·  swap " + Math.round(SysStats.swap * 100) + "%" : "")
                values: SysStats.memHistory
                tint: Theme.mix(Theme.primary, Theme.text, 0.35)
            }
            GraphCard {
                visible: SysStats.gpuTemp > 0 || SysStats.gpuBusy > 0
                title: "GPU"
                icon: Icons.gpu
                value: Math.round(SysStats.gpuBusy * 100) + "%"
                detail: SysStats.gpuTemp > 0 ? Math.round(SysStats.gpuTemp) + " °C" : ""
                values: SysStats.gpuHistory
                tint: Theme.mix(Theme.primary, Theme.warning, 0.5)
            }
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 110
                radius: Theme.radius.large
                color: Theme.surfaceContainer

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 4
                    RowLayout {
                        spacing: 6
                        Icon {
                            text: Icons.web
                            size: 15
                            color: Theme.primary
                        }
                        StyledText {
                            text: "Rete · " + (Network.defaultIface || "—")
                            font.pixelSize: Theme.font.small
                            color: Theme.textDim
                        }
                    }
                    RowLayout {
                        Icon {
                            text: Icons.download
                            size: 16
                            color: Theme.primary
                        }
                        StyledText {
                            text: SysStats.formatBytes(SysStats.netRx) + "/s"
                            font.family: Theme.font.mono
                            font.weight: Font.Bold
                        }
                    }
                    RowLayout {
                        Icon {
                            text: Icons.upload
                            size: 16
                            color: Theme.primaryDim
                        }
                        StyledText {
                            text: SysStats.formatBytes(SysStats.netTx) + "/s"
                            font.family: Theme.font.mono
                            font.weight: Font.Bold
                        }
                    }
                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }

        // Dischi
        Repeater {
            model: SysStats.disks
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 10
                Icon {
                    text: Icons.harddisk
                    size: 16
                    color: Theme.textDim
                }
                StyledText {
                    Layout.preferredWidth: 90
                    text: modelData.mount
                    font.family: Theme.font.mono
                    font.pixelSize: Theme.font.small
                }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 8
                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: Theme.surfaceContainerHighest
                    }
                    Rectangle {
                        width: parent.width * modelData.pct
                        height: parent.height
                        radius: 4
                        color: modelData.pct > 0.9 ? Theme.error : Theme.primary
                    }
                }
                StyledText {
                    text: SysStats.formatBytes(modelData.used) + " / " + SysStats.formatBytes(modelData.size)
                    font.family: Theme.font.mono
                    font.pixelSize: Theme.font.tiny
                    color: Theme.textDim
                }
            }
        }

        // Processi
        SectionHeader {
            Layout.topMargin: 4
            text: "Processi più attivi"
            icon: Icons.cli
        }

        Repeater {
            model: SysStats.processes
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 10
                StyledText {
                    Layout.preferredWidth: 56
                    text: modelData.pid
                    font.family: Theme.font.mono
                    font.pixelSize: Theme.font.tiny
                    color: Theme.textFaint
                }
                StyledText {
                    Layout.fillWidth: true
                    text: modelData.name
                    font.family: Theme.font.mono
                    font.pixelSize: Theme.font.small
                }
                StyledText {
                    text: modelData.cpu.toFixed(1) + "%"
                    font.family: Theme.font.mono
                    font.pixelSize: Theme.font.small
                    color: modelData.cpu > 50 ? Theme.warning : Theme.primary
                }
                StyledText {
                    Layout.preferredWidth: 70
                    horizontalAlignment: Text.AlignRight
                    text: modelData.memMb.toFixed(0) + " MB"
                    font.family: Theme.font.mono
                    font.pixelSize: Theme.font.small
                    color: Theme.textDim
                }
            }
        }

        StyledButton {
            Layout.alignment: Qt.AlignRight
            variant: "tonal"
            icon: Icons.speedometer
            text: "Mission Center"
            onClicked: {
                Ui.closePopout();
                Session.sysMonitor();
            }
        }
    }
}
