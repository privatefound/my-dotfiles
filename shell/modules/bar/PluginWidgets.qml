import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.Services as P

// Widget dei plugin DMS attivi, nella barra.
RowLayout {
    id: root

    required property var screen

    spacing: 2
    visible: P.PluginService.barPlugins.length > 0

    Repeater {
        model: P.PluginService.barPlugins

        delegate: Loader {
            id: loader
            required property var modelData
            Layout.alignment: Qt.AlignVCenter
            asynchronous: true

            // proprietà passate alla creazione (come fa DMS): pluginId è già valido in Component.onCompleted
            Component.onCompleted: setSource(P.PluginService.componentUrl(modelData.componentPath), {
                pluginId: modelData.id,
                pluginService: P.PluginService,
                parentScreen: root.screen,
                section: "right",
                barThickness: Theme.barHeight,
                widgetThickness: Theme.barHeight - 10
            })
            onLoaded: P.PluginService.registerWidget(modelData.id, root.screen?.name ?? "", item)
            onStatusChanged: if (status === Loader.Error) console.warn("Plugin", modelData.id, "non caricato")
        }
    }
}
