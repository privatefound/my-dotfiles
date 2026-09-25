import QtQuick
import Quickshell
import qs.DankCommon.Common as DC
import qs.Common as App
import qs.Services as AppServices
import qs.Widgets as AppWidgets
import qs.Modules.Plugins as AppPlugins

// Collega la libreria dank-qml-common (widget dei plugin DMS) alla shell
// e avvia i plugin "daemon" attivi (senza interfaccia).
Scope {
    id: root

    Component.onCompleted: {
        DC.Style.theme = App.Theme;
        DC.Style.settings = App.SettingsData;
        DC.I18n.backend = App.I18n;
        DC.Paths.backend = App.Paths;
        DC.Log.backend = AppServices.Log;
        DC.Host.session = AppServices.SessionService;
        DC.Host.cache = App.CacheData;
        DC.Host.files = AppServices.FilesBackend;
    }

    Instantiator {
        model: AppServices.PluginService.daemonPlugins

        delegate: QtObject {
            id: daemon
            required property var modelData
            property var instance: null

            Component.onCompleted: {
                const comp = Qt.createComponent(AppServices.PluginService.componentUrl(modelData.componentPath));
                const make = () => {
                    if (comp.status === Component.Ready) {
                        instance = comp.createObject(null, { pluginId: modelData.id, pluginService: AppServices.PluginService });
                        const d = Object.assign({}, AppServices.PluginService.pluginDaemonInstances);
                        d[modelData.id] = instance;
                        AppServices.PluginService.pluginDaemonInstances = d;
                    } else if (comp.status === Component.Error) {
                        console.warn("Plugin", modelData.id, comp.errorString());
                    }
                };
                if (comp.status === Component.Loading)
                    comp.statusChanged.connect(make);
                else
                    make();
            }
            Component.onDestruction: {
                if (instance)
                    instance.destroy();
                const d = Object.assign({}, AppServices.PluginService.pluginDaemonInstances);
                delete d[modelData.id];
                AppServices.PluginService.pluginDaemonInstances = d;
            }
        }
    }
}
