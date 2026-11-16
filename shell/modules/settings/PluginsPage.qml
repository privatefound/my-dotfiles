import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.services
import qs.Services as P
import qs.Widgets as DW

// Impostazioni → Plugin: plugin DankMaterialShell e Omarchy già installati (attiva, configura, rimuovi).
ColumnLayout {
    id: root

    // DMS e Omarchy in un'unica lista; `__om` dice a quale servizio appartiene la voce
    readonly property var installedList: P.PluginService.availablePluginsList.map(m => Object.assign({}, m, { __om: false })).concat(P.OmarchyPluginService.installedList.map(m => Object.assign({}, m, { __om: true }))).sort((a, b) => (a.name || a.id).localeCompare(b.name || b.id))
    property string expanded: ""            // plugin con le impostazioni aperte

    Layout.fillWidth: true
    spacing: 10

    SectionHeader {
        text: I18n.tr("Plugin")
        icon: Icons.apps
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        StyledText {
            Layout.fillWidth: true
            text: I18n.tr("Plugin installati in ~/.config/hypr/plugins (esclusi da git).")
            wrapMode: Text.Wrap
            color: Theme.textDim
            font.pixelSize: Theme.font.small
        }
        IconButton {
            icon: Icons.folder
            iconColor: Theme.textDim
            onClicked: Quickshell.execDetached(["sh", "-c", "mkdir -p \"$1\" && xdg-open \"$1\"", "_", P.PluginService.pluginDirectory])
        }
        IconButton {
            icon: Icons.refresh
            iconColor: Theme.textDim
            onClicked: {
                P.PluginService.rescan();
                P.OmarchyPluginService.rescan();
            }
        }
    }

    // ═══════════════ Installati ═══════════════
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        ColumnLayout {
            visible: root.installedList.length === 0
            Layout.fillWidth: true
            Layout.topMargin: 20
            spacing: 10
            Icon {
                Layout.alignment: Qt.AlignHCenter
                text: Icons.apps
                size: 40
                color: Theme.primaryDim
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: I18n.tr("Nessun plugin installato")
                color: Theme.textDim
            }
        }

        Repeater {
            model: root.installedList

            delegate: StyledRect {
                id: card
                required property var modelData
                readonly property bool om: modelData.__om
                readonly property var svc: om ? P.OmarchyPluginService : P.PluginService
                readonly property bool on: card.svc.enabledIds.includes(modelData.id)
                readonly property string busy: card.svc.busy[modelData.id] ?? ""
                readonly property bool supported: card.om ? P.OmarchyPluginService.isSupported(modelData) : modelData.supported
                readonly property string kindLabel: card.om ? (modelData.kinds || []).join(", ") : modelData.surface
                // DMS: file di impostazioni del plugin · Omarchy: campi descritti nello schema del manifest
                readonly property bool hasSettings: card.om ? (modelData.barWidget?.schema?.length ?? 0) > 0 : modelData.settingsPath !== ""
                readonly property bool open: root.expanded === modelData.id

                Layout.fillWidth: true
                implicitHeight: cardCol.implicitHeight + 24
                radius: Theme.radius.large
                color: on ? Theme.primaryContainer : Theme.surfaceContainerHigh
                border.width: on ? 1 : 0
                border.color: Theme.alpha(Theme.primary, 0.5)

                ColumnLayout {
                    id: cardCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        StyledRect {
                            implicitWidth: 40
                            implicitHeight: 40
                            radius: 12
                            color: Theme.surfaceContainerHighest
                            DW.DankIcon {
                                anchors.centerIn: parent
                                name: card.modelData.icon || "extension"
                                size: 22
                                color: Theme.primary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            RowLayout {
                                spacing: 6
                                StyledText {
                                    text: card.modelData.name || card.modelData.id
                                    font.weight: Font.DemiBold
                                    color: card.on ? Theme.fgPrimaryContainer : Theme.text
                                }
                                StyledText {
                                    visible: !!card.modelData.version
                                    text: "v" + card.modelData.version
                                    font.family: Theme.font.mono
                                    font.pixelSize: Theme.font.tiny
                                    color: Theme.textFaint
                                }
                                StyledRect {
                                    visible: !card.supported
                                    implicitHeight: 18
                                    implicitWidth: unsup.implicitWidth + 12
                                    radius: 9
                                    color: Theme.errorContainer
                                    StyledText {
                                        id: unsup
                                        anchors.centerIn: parent
                                        text: I18n.tr("non supportato") + " (" + card.kindLabel + ")"
                                        font.pixelSize: Theme.font.tiny
                                        color: Theme.error
                                    }
                                }
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: (card.modelData.author ? card.modelData.author + "  ·  " : "") + (card.om ? card.kindLabel + "  ·  " : "") + (card.modelData.description || "")
                                font.pixelSize: Theme.font.small
                                color: Theme.textDim
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                            }
                        }

                        IconButton {
                            visible: card.hasSettings
                            icon: Icons.cog
                            toggled: card.open
                            onClicked: root.expanded = card.open ? "" : card.modelData.id
                        }
                        IconButton {
                            icon: Icons.trash
                            iconColor: Theme.error
                            disabled: card.busy !== ""
                            onClicked: card.svc.uninstall(card.modelData.id)
                        }
                        Toggle {
                            checked: card.on
                            disabled: !card.supported
                            onToggled: v => card.svc.setEnabled(card.modelData.id, v)
                        }
                    }

                    StyledText {
                        visible: card.busy !== ""
                        text: I18n.tr("Rimozione…")
                        color: Theme.primary
                        font.pixelSize: Theme.font.small
                    }

                    // Impostazioni del plugin (PluginSettings per DMS, modulo generato per Omarchy)
                    StyledRect {
                        visible: card.open
                        Layout.fillWidth: true
                        implicitHeight: settingsLoader.item ? settingsLoader.item.implicitHeight + 24 : 60
                        radius: Theme.radius.normal
                        color: Theme.surfaceContainer

                        Loader {
                            id: settingsLoader
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            active: card.open
                            onActiveChanged: {
                                if (!active)
                                    return;
                                if (card.om)
                                    setSource("OmarchyPluginSettings.qml", { manifest: card.modelData });
                                else
                                    setSource(P.PluginService.componentUrl(card.modelData.settingsPath), { pluginId: card.modelData.id, pluginService: P.PluginService });
                            }
                        }
                        StyledText {
                            anchors.centerIn: parent
                            visible: settingsLoader.status === Loader.Error
                            text: I18n.tr("Impostazioni non compatibili con questa shell")
                            color: Theme.error
                            font.pixelSize: Theme.font.small
                        }
                    }
                }
            }
        }
    }
}
