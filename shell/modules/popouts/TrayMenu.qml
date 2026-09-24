import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

// Menu della tray disegnato in QML (col tema), con navigazione nei sottomenu.
Item {
    id: root

    required property var item
    property var stack: []
    readonly property var currentMenu: stack.length > 0 ? stack[stack.length - 1].handle : item?.menu ?? null

    implicitWidth: 300
    implicitHeight: col.implicitHeight + 16

    QsMenuOpener {
        id: opener
        menu: root.currentMenu
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 8
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 4
            spacing: 8

            IconButton {
                visible: root.stack.length > 0
                size: 28
                icon: Icons.arrowLeft
                onClicked: root.stack = root.stack.slice(0, -1)
            }
            IconImage {
                visible: root.stack.length === 0
                implicitSize: 18
                source: root.item?.icon ?? ""
            }
            StyledText {
                Layout.fillWidth: true
                text: root.stack.length > 0 ? root.stack[root.stack.length - 1].text : (root.item?.tooltipTitle || root.item?.title || root.item?.id || "")
                font.weight: Font.DemiBold
                color: Theme.primary
            }
        }

        Separator {}

        Repeater {
            model: opener.children

            delegate: Loader {
                id: entryLoader
                required property var modelData
                Layout.fillWidth: true
                sourceComponent: modelData.isSeparator ? sepComp : rowComp

                Component {
                    id: sepComp
                    Item {
                        implicitHeight: 9
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - 16
                            height: 1
                            color: Theme.outlineVariant
                        }
                    }
                }

                Component {
                    id: rowComp
                    StyledRect {
                        readonly property var entry: entryLoader.modelData
                        implicitHeight: 36
                        radius: Theme.radius.small
                        opacity: entry.enabled ? 1 : 0.4

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 10

                            // check / radio
                            Item {
                                implicitWidth: 18
                                implicitHeight: 18
                                visible: entry.buttonType !== 0 || entry.icon !== ""
                                Icon {
                                    anchors.centerIn: parent
                                    visible: entry.buttonType !== 0
                                    text: entry.checkState === Qt.Checked ? (entry.buttonType === 2 ? Icons.record : Icons.check) : ""
                                    size: 16
                                    color: Theme.primary
                                }
                                IconImage {
                                    anchors.fill: parent
                                    visible: entry.buttonType === 0 && entry.icon !== ""
                                    source: entry.icon
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: entry.text.replace(/_(?!_)/g, "")
                                color: entry.enabled ? Theme.text : Theme.textFaint
                            }

                            Icon {
                                visible: entry.hasChildren
                                text: Icons.chevronRight
                                size: 16
                                color: Theme.textDim
                            }
                        }

                        StateLayer {
                            disabled: !entry.enabled
                            tint: Theme.primary
                            onClicked: {
                                if (entry.hasChildren) {
                                    root.stack = root.stack.concat([{ handle: entry, text: entry.text.replace(/_(?!_)/g, "") }]);
                                } else {
                                    entry.triggered();
                                    Ui.closePopout();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
