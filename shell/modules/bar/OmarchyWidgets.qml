import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.Services as P
import qs.Ui as OUi

// Widget dei plugin Omarchy attivi, nella barra.
// Ogni widget riceve il suo oggetto `bar` (PluginBarApi) con colori e callback della shell.
RowLayout {
    id: root

    required property var screen

    // popup Omarchy aperto su questa barra (ne resta aperto uno alla volta)
    property var activePopout: null
    property var clickTargets: []

    spacing: 2
    visible: P.OmarchyPluginService.barWidgets.length > 0

    // se si apre un pannello della shell, chiude quello del plugin
    Connections {
        target: Ui
        function onPopoutChanged() {
            if (Ui.popout !== "" && root.activePopout && typeof root.activePopout.close === "function")
                root.activePopout.close();
        }
    }

    Repeater {
        model: P.OmarchyPluginService.barWidgets

        delegate: Item {
            id: slot
            required property var modelData
            readonly property string pluginId: modelData.id

            Layout.alignment: Qt.AlignVCenter
            implicitWidth: loader.item ? Math.max(loader.item.implicitWidth, 1) : 0
            implicitHeight: Theme.barHeight - 8

            OUi.PluginBarApi {
                id: api
                pluginId: slot.pluginId
                moduleName: slot.pluginId
                foreground: Theme.text
                barForeground: Theme.text
                background: Theme.surface
                urgent: Theme.error
                fontFamily: Theme.font.mono
                position: "top"
                vertical: false
                barSize: Theme.barHeight
                transparent: false
                activePopout: root.activePopout
                clickTargets: root.clickTargets

                _requestPopout: owner => {
                    const prev = root.activePopout;
                    if (prev && prev !== owner && typeof prev.close === "function")
                        prev.close();
                    Ui.closePopout();
                    root.activePopout = owner;
                }
                _releasePopout: owner => {
                    if (root.activePopout === owner)
                        root.activePopout = null;
                }
                _registerClickTarget: t => {
                    if (!root.clickTargets.includes(t))
                        root.clickTargets = root.clickTargets.concat([t]);
                }
                _unregisterClickTarget: t => root.clickTargets = root.clickTargets.filter(x => x !== t)
                _targetBelongsToWindow: (t, w) => !!t && t.QsWindow?.window === w
                _moduleWidgets: id => P.OmarchyPluginService.widgetsOf(id || slot.pluginId)
                _switchPanelFrom: (owner, direction) => false
                _run: cmd => Quickshell.execDetached(["sh", "-c", cmd])
                _showTooltip: (target, text) => {}
                _hideTooltip: target => {}

                // assegnato una volta sola: shellFor() crea l'oggetto e dentro un binding farebbe un loop
                Component.onCompleted: shell = P.OmarchyPluginService.shellFor(slot.pluginId)
            }

            Loader {
                id: loader
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                width: item ? item.implicitWidth : 0
                asynchronous: true

                Component.onCompleted: setSource(P.OmarchyPluginService.entryUrl(slot.modelData, "barWidget"), {
                    bar: api,
                    moduleName: slot.pluginId,
                    settings: P.OmarchyPluginService.settingsFor(slot.pluginId)
                })
                onLoaded: P.OmarchyPluginService.registerWidget(slot.pluginId, root.screen?.name ?? "", item)
                onStatusChanged: if (status === Loader.Error) console.warn("Plugin Omarchy", slot.pluginId, "non caricato")
                Component.onDestruction: if (item) P.OmarchyPluginService.unregisterWidget(slot.pluginId, root.screen?.name ?? "", item)
            }
        }
    }
}
