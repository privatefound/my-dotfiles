import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services
import qs.modules.notifications

// Centro notifiche: raggruppate per app, Non disturbare, cancella tutto.
Item {
    id: root

    implicitWidth: 420
    implicitHeight: col.implicitHeight + 32

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Icon {
                text: Icons.bell
                size: 20
                color: Theme.primary
            }
            StyledText {
                Layout.fillWidth: true
                text: I18n.tr("Notifiche") + (Notifs.count > 0 ? "  ·  " + Notifs.count : "")
                font.pixelSize: Theme.font.title
                font.weight: Font.DemiBold
            }
            StyledText {
                text: I18n.tr("Non disturbare")
                color: Theme.textDim
                font.pixelSize: Theme.font.small
            }
            Toggle {
                checked: Settings.dnd
                onToggled: Notifs.toggleDnd()
            }
        }

        ScrollColumn {
            maxHeight: 560
            spacing: 10

            Repeater {
                model: Notifs.groups

                delegate: ColumnLayout {
                    id: group
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        IconImage {
                            implicitSize: 16
                            source: Notifs.appIconFor(group.modelData.items[0])
                            visible: source != ""
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: group.modelData.app + (group.modelData.items.length > 1 ? "  (" + group.modelData.items.length + ")" : "")
                            font.pixelSize: Theme.font.small
                            font.weight: Font.DemiBold
                            color: Theme.textDim
                        }
                        IconButton {
                            size: 26
                            icon: Icons.clearAll
                            iconColor: Theme.textFaint
                            onClicked: Notifs.dismissGroup(group.modelData)
                        }
                    }

                    Repeater {
                        model: group.modelData.items
                        delegate: NotificationCard {
                            required property var modelData
                            Layout.fillWidth: true
                            notification: modelData
                            onDismissed: Notifs.dismiss(modelData)
                        }
                    }
                }
            }

            // Stato vuoto
            ColumnLayout {
                visible: Notifs.count === 0
                Layout.fillWidth: true
                Layout.topMargin: 24
                Layout.bottomMargin: 24
                spacing: 10

                Icon {
                    Layout.alignment: Qt.AlignHCenter
                    text: Settings.dnd ? Icons.bellOff : Icons.checkCircle
                    size: 44
                    color: Theme.primaryDim
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Settings.dnd ? I18n.tr("Non disturbare attivo") : I18n.tr("Tutto tranquillo, Operatore")
                    color: Theme.textDim
                }
            }
        }

        StyledButton {
            Layout.alignment: Qt.AlignRight
            visible: Notifs.count > 0
            variant: "tonal"
            icon: Icons.clearAll
            text: I18n.tr("Cancella tutto")
            onClicked: Notifs.clearAll()
        }
    }
}
