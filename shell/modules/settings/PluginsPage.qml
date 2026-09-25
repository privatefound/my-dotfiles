import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.services
import qs.Services as P
import qs.Widgets as DW

// Impostazioni → Plugin: plugin DankMaterialShell installati e catalogo ufficiale.
ColumnLayout {
    id: root

    property string tab: "installed"      // "installed" | "browse"
    property string query: ""
    property string category: ""
    property bool onlyCompatible: true
    property int shown: 40
    property string expanded: ""            // plugin con le impostazioni aperte

    readonly property var categories: {
        const set = {};
        for (const e of P.PluginService.catalog)
            if (e.category)
                set[e.category.toLowerCase()] = true;
        return Object.keys(set).sort();
    }

    readonly property var results: {
        const q = query.trim().toLowerCase();
        return P.PluginService.catalog.filter(e => {
            if (onlyCompatible && !P.PluginService.catalogSupported(e))
                return false;
            if (category && (e.category || "").toLowerCase() !== category)
                return false;
            if (!q)
                return true;
            return ((e.name || "") + " " + (e.description || "") + " " + (e.author || "") + " " + (e.id || "")).toLowerCase().includes(q);
        });
    }

    Layout.fillWidth: true
    spacing: 10

    onTabChanged: {
        if (tab === "browse" && P.PluginService.catalog.length === 0)
            P.PluginService.fetchCatalog();
    }
    onQueryChanged: shown = 40
    onCategoryChanged: shown = 40

    SectionHeader {
        text: I18n.tr("Plugin")
        icon: Icons.apps
    }

    StyledText {
        Layout.fillWidth: true
        text: I18n.tr("Plugin della community di DankMaterialShell. Si installano in ~/.config/hypr/plugins (esclusi da git). Sono supportati i widget per la barra e i plugin di sottofondo; alcuni potrebbero non funzionare del tutto.")
        wrapMode: Text.Wrap
        color: Theme.textDim
        font.pixelSize: Theme.font.small
    }

    // ── Schede ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: [
                { id: "installed", label: I18n.tr("Installati") + " (" + P.PluginService.availablePluginsList.length + ")", icon: Icons.checkCircle },
                { id: "browse", label: I18n.tr("Sfoglia"), icon: Icons.magnify }
            ]
            delegate: StyledButton {
                required property var modelData
                implicitHeight: 34
                variant: root.tab === modelData.id ? "filled" : "tonal"
                icon: modelData.icon
                text: modelData.label
                onClicked: root.tab = modelData.id
            }
        }
        Item {
            Layout.fillWidth: true
        }
        IconButton {
            icon: Icons.folder
            iconColor: Theme.textDim
            onClicked: Quickshell.execDetached(["xdg-open", P.PluginService.pluginDirectory])
        }
        IconButton {
            icon: Icons.refresh
            iconColor: Theme.textDim
            onClicked: root.tab === "browse" ? P.PluginService.fetchCatalog() : P.PluginService.rescan()
        }
    }

    // ═══════════════ Installati ═══════════════
    ColumnLayout {
        visible: root.tab === "installed"
        Layout.fillWidth: true
        spacing: 8

        ColumnLayout {
            visible: P.PluginService.availablePluginsList.length === 0
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
            StyledButton {
                Layout.alignment: Qt.AlignHCenter
                variant: "filled"
                icon: Icons.magnify
                text: I18n.tr("Sfoglia il catalogo")
                onClicked: root.tab = "browse"
            }
        }

        Repeater {
            model: P.PluginService.availablePluginsList

            delegate: StyledRect {
                id: card
                required property var modelData
                readonly property bool on: P.PluginService.isEnabled(modelData.id)
                readonly property string busy: P.PluginService.busy[modelData.id] ?? ""
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
                                    visible: !card.modelData.supported
                                    implicitHeight: 18
                                    implicitWidth: unsup.implicitWidth + 12
                                    radius: 9
                                    color: Theme.errorContainer
                                    StyledText {
                                        id: unsup
                                        anchors.centerIn: parent
                                        text: I18n.tr("non supportato") + " (" + card.modelData.surface + ")"
                                        font.pixelSize: Theme.font.tiny
                                        color: Theme.error
                                    }
                                }
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: (card.modelData.author ? card.modelData.author + "  ·  " : "") + (card.modelData.description || "")
                                font.pixelSize: Theme.font.small
                                color: Theme.textDim
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                            }
                        }

                        IconButton {
                            visible: card.modelData.settingsPath !== ""
                            icon: Icons.cog
                            toggled: card.open
                            onClicked: root.expanded = card.open ? "" : card.modelData.id
                        }
                        IconButton {
                            icon: Icons.update
                            iconColor: Theme.textDim
                            disabled: card.busy !== ""
                            onClicked: P.PluginService.update(card.modelData.id)
                        }
                        IconButton {
                            icon: Icons.trash
                            iconColor: Theme.error
                            disabled: card.busy !== ""
                            onClicked: P.PluginService.uninstall(card.modelData.id)
                        }
                        Toggle {
                            checked: card.on
                            disabled: !card.modelData.supported
                            onToggled: v => P.PluginService.setEnabled(card.modelData.id, v)
                        }
                    }

                    StyledText {
                        visible: card.busy !== ""
                        text: card.busy === "remove" ? I18n.tr("Rimozione…") : I18n.tr("Aggiornamento…")
                        color: Theme.primary
                        font.pixelSize: Theme.font.small
                    }

                    // Impostazioni del plugin (il suo PluginSettings)
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
                                if (active)
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

    // ═══════════════ Sfoglia ═══════════════
    ColumnLayout {
        visible: root.tab === "browse"
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            TextField {
                Layout.fillWidth: true
                icon: Icons.magnify
                placeholder: I18n.tr("Cerca plugin…")
                onTextChanged: root.query = text
            }
            StyledText {
                text: I18n.tr("Solo compatibili")
                font.pixelSize: Theme.font.small
                color: Theme.textDim
            }
            Toggle {
                checked: root.onlyCompatible
                onToggled: v => root.onlyCompatible = v
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: [""].concat(root.categories)
                delegate: StyledButton {
                    required property string modelData
                    implicitHeight: 28
                    padding: 10
                    variant: root.category === modelData ? "filled" : "tonal"
                    text: modelData === "" ? I18n.tr("Tutte") : modelData.charAt(0).toUpperCase() + modelData.slice(1)
                    onClicked: root.category = modelData
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: P.PluginService.catalogLoading ? I18n.tr("Scarico il catalogo…") : P.PluginService.catalogError !== "" ? I18n.tr(P.PluginService.catalogError) : root.results.length + " " + I18n.tr("plugin")
            color: P.PluginService.catalogError !== "" ? Theme.error : Theme.textDim
            font.pixelSize: Theme.font.small
        }

        Repeater {
            model: root.results.slice(0, root.shown)

            delegate: StyledRect {
                id: entry
                required property var modelData
                readonly property bool installed: P.PluginService.isInstalled(modelData.id)
                readonly property string busy: P.PluginService.busy[modelData.id] ?? ""
                readonly property bool supported: P.PluginService.catalogSupported(modelData)

                Layout.fillWidth: true
                implicitHeight: Math.max(96, entryRow.implicitHeight + 24)
                radius: Theme.radius.large
                color: Theme.surfaceContainerHigh

                RowLayout {
                    id: entryRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 12
                    spacing: 12

                    // anteprima
                    StyledRect {
                        implicitWidth: 120
                        implicitHeight: 72
                        radius: Theme.radius.normal
                        color: Theme.surfaceContainerHighest
                        clip: true
                        Image {
                            id: shot
                            anchors.fill: parent
                            source: entry.modelData.screenshot || ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize: Qt.size(240, 144)
                        }
                        DW.DankIcon {
                            anchors.centerIn: parent
                            visible: shot.status !== Image.Ready
                            name: entry.modelData.icon || "extension"
                            size: 28
                            color: Theme.primaryDim
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        RowLayout {
                            spacing: 6
                            StyledText {
                                text: entry.modelData.name
                                font.weight: Font.DemiBold
                            }
                            StyledText {
                                text: "· " + (entry.modelData.author || "")
                                font.pixelSize: Theme.font.small
                                color: Theme.textFaint
                            }
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: entry.modelData.description || ""
                            font.pixelSize: Theme.font.small
                            color: Theme.textDim
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: (entry.modelData.capabilities || []).join(" · ") + ((entry.modelData.dependencies || []).length ? "   ·   " + I18n.tr("richiede") + ": " + entry.modelData.dependencies.join(", ") : "")
                            font.family: Theme.font.mono
                            font.pixelSize: Theme.font.tiny
                            color: entry.supported ? Theme.primaryDim : Theme.warning
                        }
                    }

                    StyledButton {
                        implicitHeight: 34
                        variant: entry.installed ? "outline" : "filled"
                        disabled: entry.busy !== "" || entry.installed
                        icon: entry.installed ? Icons.check : Icons.download
                        text: entry.busy === "install" ? I18n.tr("Installo…") : entry.installed ? I18n.tr("Installato") : I18n.tr("Installa")
                        onClicked: P.PluginService.install(entry.modelData)
                    }
                }
            }
        }

        StyledButton {
            Layout.alignment: Qt.AlignHCenter
            visible: root.results.length > root.shown
            variant: "tonal"
            text: I18n.tr("Mostra altri")
            onClicked: root.shown += 40
        }
    }
}
