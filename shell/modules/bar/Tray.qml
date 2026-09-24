import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.config
import qs.components
import qs.services

// Tray a scomparsa (come prima). I menu sono disegnati in QML col tema, non più QMenu.
StyledRect {
    id: root

    required property string screenName
    readonly property var items: SystemTray.items.values
    readonly property bool expanded: Settings.trayExpanded

    visible: items.length > 0
    implicitHeight: Theme.barHeight - 10
    implicitWidth: row.implicitWidth + 8
    radius: Theme.radius.full
    color: expanded ? Theme.surfaceContainer : "transparent"
    clip: true

    Behavior on implicitWidth {
        Anim {}
    }

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 4
        spacing: 2
        layoutDirection: Qt.RightToLeft

        IconButton {
            size: Theme.barHeight - 14
            icon: Icons.chevronLeft
            iconColor: root.expanded ? Theme.primary : Theme.textDim
            rotation: root.expanded ? 180 : 0
            onClicked: Settings.trayExpanded = !Settings.trayExpanded

            Behavior on rotation {
                Anim {}
            }
        }

        Repeater {
            model: root.expanded ? root.items : []

            delegate: StyledRect {
                id: trayItem

                required property var modelData

                implicitWidth: Theme.barHeight - 14
                implicitHeight: Theme.barHeight - 14
                radius: width / 2

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 17
                    source: {
                        const ic = trayItem.modelData.icon;
                        // Alcune app passano "nome?path=..." : risolviamo il percorso
                        if (ic.includes("?path=")) {
                            const [name, path] = ic.split("?path=");
                            return "file://" + path + "/" + name.slice(name.lastIndexOf("/") + 1);
                        }
                        return ic;
                    }
                }

                StateLayer {
                    tint: Theme.primary
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: mouse => {
                        const it = trayItem.modelData;
                        const x = trayItem.mapToItem(null, trayItem.width / 2, 0).x;
                        if (mouse.button === Qt.MiddleButton)
                            it.secondaryActivate();
                        else if (mouse.button === Qt.RightButton || it.onlyMenu) {
                            if (it.hasMenu)
                                Ui.togglePopout("tray", root.screenName, x, it);
                        } else
                            it.activate();
                    }
                    onWheel: wheel => trayItem.modelData.scroll(wheel.angleDelta.y / 120, false)
                }
            }
        }
    }
}
