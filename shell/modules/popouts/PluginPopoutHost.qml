import QtQuick
import qs.config
import qs.components
import qs.services

// Contenuto del popup di un plugin DMS (popoutContent del PluginComponent).
Item {
    id: root

    required property var owner
    readonly property real padding: 16

    implicitWidth: (owner?.popoutWidth || 400) + padding * 2
    implicitHeight: Math.min(760, (owner?.popoutHeight > 0 ? owner.popoutHeight : (loader.item?.implicitHeight ?? 200)) + padding * 2)

    Flickable {
        anchors.fill: parent
        anchors.margins: root.padding
        contentHeight: loader.item?.implicitHeight ?? 0
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Loader {
            id: loader
            width: parent.width
            sourceComponent: root.owner?.popoutContent ?? null
            onLoaded: {
                if ("closePopout" in item)
                    item.closePopout = () => Ui.closePopout();
                if ("parentPopout" in item)
                    item.parentPopout = root;
            }
        }
    }
}
