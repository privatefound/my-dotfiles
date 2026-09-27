import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.services
import qs.Services as P
import qs.Widgets as DW

// Impostazioni → Plugin: plugin DankMaterialShell e Omarchy, installati e cataloghi ufficiali.
ColumnLayout {
    id: root

    property string tab: "installed"      // "installed" | "browse"
    property string source: "dms"          // "dms" | "omarchy"
    readonly property bool om: source === "omarchy"
    readonly property var svc: om ? P.OmarchyPluginService : P.PluginService
    readonly property var installedList: om ? P.OmarchyPluginService.installedList : P.PluginService.availablePluginsList
    property string query: ""
    property string category: ""
    property bool onlyCompatible: true
    property int shown: 40
    property string expanded: ""            // plugin con le impostazioni aperte

    readonly property var categories: {
        const set = {};
        for (const e of root.svc.catalog)
            if (e.category)
                set[e.category.toLowerCase()] = true;
        return Object.keys(set).sort();
    }

    readonly property var results: {
        const q = query.trim().toLowerCase();
        return root.svc.catalog.filter(e => {
            if (onlyCompatible && !root.svc.catalogSupported(e))
                return false;
            if (category && (e.category || "").toLowerCase() !== category)
                return false;
            if (!q)
                return true;
            return ((e.name || "") + " " + (e.description || "") + " " + (e.author || "") + " " + (e.id || "") + " " + (e.tags || []).join(" ")).toLowerCase().includes(q);
        });
    }

    Layout.fillWidth: true
    spacing: 10

    function _maybeFetch() {
        if (tab === "browse" && svc.catalog.length === 0 && !svc.catalogLoading)
            svc.fetchCatalog(false);
    }
    onTabChanged: _maybeFetch()
    onSourceChanged: {
        category = "";
        shown = 40;
        expanded = "";
        _maybeFetch();
    }
    onQueryChanged: shown = 40
    onCategoryChanged: shown = 40

    SectionHeader {
        text: I18n.tr("Plugin")
        icon: Icons.apps
    }

    StyledText {
        Layout.fillWidth: true
        text: root.om ? I18n.tr("Plugin della community di Omarchy (plugins.omarchy.org). Si installano in ~/.config/hypr/plugins/omarchy (esclusi da git). Sono supportati widget per la barra, servizi, pannelli e overlay; quelli che usano comandi specifici di Omarchy potrebbero non funzionare del tutto.") : I18n.tr("Plugin della community di DankMaterialShell. Si installano in ~/.config/hypr/plugins (esclusi da git). Sono supportati i widget per la barra e i plugin di sottofondo; alcuni potrebbero non funzionare del tutto.")
        wrapMode: Text.Wrap
        color: Theme.textDim
        font.pixelSize: Theme.font.small
    }

    // ── Sorgente ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        StyledText {
            text: I18n.tr("Sorgente")
            font.pixelSize: Theme.font.small
            color: Theme.textDim
        }
        Repeater {
            model: [
                { id: "dms", label: "DankMaterialShell", n: P.PluginService.availablePluginsList.length },
                { id: "omarchy", label: "Omarchy", n: P.OmarchyPluginService.installedList.length }
            ]
            delegate: StyledButton {
                required property var modelData
                implicitHeight: 30
                padding: 12
                variant: root.source === modelData.id ? "filled" : "outline"
                text: modelData.label + (modelData.n ? "  ·  " + modelData.n : "")
                onClicked: root.source = modelData.id
            }
        }
        Item {
            Layout.fillWidth: true
        }
    }

    // ── Schede ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: [
                { id: "installed", label: I18n.tr("Installati") + " (" + root.installedList.length + ")", icon: Icons.checkCircle },
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
            onClicked: Quickshell.execDetached(["sh", "-c", "mkdir -p \"$1\" && xdg-open \"$1\"", "_", root.svc.pluginDirectory])
        }
        IconButton {
            icon: Icons.refresh
            iconColor: Theme.textDim
            onClicked: root.tab === "browse" ? root.svc.fetchCatalog(true) : root.svc.rescan()
        }
    }

    // ═══════════════ Installati ═══════════════
    ColumnLayout {
        visible: root.tab === "installed"
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
            StyledButton {
                Layout.alignment: Qt.AlignHCenter
                variant: "filled"
                icon: Icons.magnify
                text: I18n.tr("Sfoglia il catalogo")
                onClicked: root.tab = "browse"
            }
        }

        Repeater {
            model: root.installedList

            delegate: StyledRect {
                id: card
                required property var modelData
                readonly property bool on: root.svc.enabledIds.includes(modelData.id)
                readonly property string busy: root.svc.busy[modelData.id] ?? ""
                readonly property bool supported: root.om ? P.OmarchyPluginService.isSupported(modelData) : modelData.supported
                readonly property string kindLabel: root.om ? (modelData.kinds || []).join(", ") : modelData.surface
                // DMS: file di impostazioni del plugin · Omarchy: campi descritti nello schema del manifest
                readonly property bool hasSettings: root.om ? (modelData.barWidget?.schema?.length ?? 0) > 0 : modelData.settingsPath !== ""
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
                                text: (card.modelData.author ? card.modelData.author + "  ·  " : "") + (root.om ? card.kindLabel + "  ·  " : "") + (card.modelData.description || "")
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
                            icon: Icons.update
                            iconColor: Theme.textDim
                            disabled: card.busy !== ""
                            onClicked: root.svc.update(card.modelData.id)
                        }
                        IconButton {
                            icon: Icons.trash
                            iconColor: Theme.error
                            disabled: card.busy !== ""
                            onClicked: root.svc.uninstall(card.modelData.id)
                        }
                        Toggle {
                            checked: card.on
                            disabled: !card.supported
                            onToggled: v => root.svc.setEnabled(card.modelData.id, v)
                        }
                    }

                    StyledText {
                        visible: card.busy !== ""
                        text: card.busy === "remove" ? I18n.tr("Rimozione…") : I18n.tr("Aggiornamento…")
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
                                if (root.om)
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
            text: root.svc.catalogLoading ? I18n.tr("Scarico il catalogo…") : root.svc.catalogError !== "" ? I18n.tr(root.svc.catalogError) : root.results.length + " " + I18n.tr("plugin")
            color: root.svc.catalogError !== "" ? Theme.error : Theme.textDim
            font.pixelSize: Theme.font.small
        }

        Repeater {
            model: root.results.slice(0, root.shown)

            delegate: StyledRect {
                id: entry
                required property var modelData
                readonly property bool installed: root.om ? P.OmarchyPluginService.installed[modelData.id] !== undefined : P.PluginService.availablePlugins[modelData.id] !== undefined
                readonly property string busy: root.svc.busy[modelData.id] ?? ""
                readonly property bool supported: root.svc.catalogSupported(modelData)

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
                            source: root.om ? (entry.modelData.thumb ? P.OmarchyPluginService.siteUrl + entry.modelData.thumb : "") : (entry.modelData.screenshot || "")
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
                            text: root.om ? [entry.modelData.kind, "★ " + (entry.modelData.stars || 0), entry.modelData.verified ? I18n.tr("verificato") : "", "v" + (entry.modelData.version || "?")].filter(x => x).join(" · ") : (entry.modelData.capabilities || []).join(" · ") + ((entry.modelData.dependencies || []).length ? "   ·   " + I18n.tr("richiede") + ": " + entry.modelData.dependencies.join(", ") : "")
                            font.family: Theme.font.mono
                            font.pixelSize: Theme.font.tiny
                            color: entry.supported ? Theme.primaryDim : Theme.warning
                        }
                    }

                    IconButton {
                        visible: root.om
                        icon: Icons.web
                        iconColor: Theme.textDim
                        onClicked: Qt.openUrlExternally(P.OmarchyPluginService.siteUrl + "plugin.html?id=" + encodeURIComponent(entry.modelData.id))
                    }
                    StyledButton {
                        implicitHeight: 34
                        variant: entry.installed ? "outline" : "filled"
                        disabled: entry.busy !== "" || entry.installed
                        icon: entry.installed ? Icons.check : Icons.download
                        text: entry.busy === "install" ? I18n.tr("Installo…") : entry.installed ? I18n.tr("Installato") : I18n.tr("Installa")
                        onClicked: root.svc.install(entry.modelData)
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
