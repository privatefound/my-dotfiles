import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.config
import qs.components
import qs.services

// Selettore sfondi a griglia (frecce + Invio, o click).
StyledRect {
    id: root

    readonly property var transitions: ["grow", "wipe", "outer", "wave", "fade", "any"]

    implicitWidth: 980
    implicitHeight: 640
    radius: Theme.radius.xl
    color: Theme.alpha(Theme.surface, Settings.panelOpacity)
    border.width: 1
    border.color: Theme.outline
    clip: true

    focus: true
    Component.onCompleted: {
        Wallpaper.refresh();
        grid.forceActiveFocus();
    }

    MouseArea {
        anchors.fill: parent
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Icon {
                text: Icons.wallpaper
                size: 22
                color: Theme.primary
            }
            ColumnLayout {
                spacing: 0
                StyledText {
                    text: I18n.tr("Sfondi")
                    font.pixelSize: Theme.font.title
                    font.weight: Font.DemiBold
                }
                StyledText {
                    text: Settings.wallpaperDir
                    font.family: Theme.font.mono
                    font.pixelSize: Theme.font.tiny
                    color: Theme.textFaint
                }
            }
            Item {
                Layout.fillWidth: true
            }
            StyledText {
                text: I18n.tr("Transizione")
                font.pixelSize: Theme.font.small
                color: Theme.textDim
            }
            Repeater {
                model: root.transitions
                delegate: StyledButton {
                    required property string modelData
                    implicitHeight: 30
                    padding: 10
                    variant: Settings.wallpaperTransition === modelData ? "filled" : "tonal"
                    text: modelData
                    onClicked: Settings.wallpaperTransition = modelData
                }
            }
            IconButton {
                icon: Icons.shuffle
                onClicked: Wallpaper.random()
            }
            IconButton {
                icon: Icons.folder
                onClicked: Quickshell.execDetached(["xdg-open", Settings.wallpaperDir])
            }
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: Wallpaper.files
            cellWidth: Math.floor(width / 4)
            cellHeight: Math.floor(cellWidth * 0.62)
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationEnabled: true
            currentIndex: Math.max(0, Wallpaper.files.indexOf(Settings.wallpaper))
            ScrollBar.vertical: StyledScrollBar {}

            Keys.onReturnPressed: Wallpaper.set(Wallpaper.files[currentIndex])
            Keys.onEnterPressed: Wallpaper.set(Wallpaper.files[currentIndex])
            Keys.onEscapePressed: Ui.closeModal()

            delegate: Item {
                id: cell
                required property string modelData
                required property int index
                readonly property bool isCurrent: Settings.wallpaper === modelData
                readonly property bool sel: GridView.isCurrentItem

                width: grid.cellWidth
                height: grid.cellHeight

                StyledRect {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: Theme.radius.large
                    color: Theme.surfaceContainer
                    border.width: cell.isCurrent || cell.sel ? 3 : 0
                    border.color: cell.isCurrent ? Theme.primary : Theme.alpha(Theme.primary, 0.5)
                    scale: mouse.containsMouse || cell.sel ? 1.03 : 1
                    clip: true

                    Behavior on scale {
                        Anim {}
                    }

                    Image {
                        anchors.fill: parent
                        anchors.margins: parent.border.width
                        source: "file://" + cell.modelData
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize: Qt.size(480, 300)
                        cache: true
                    }

                    StyledRect {
                        visible: cell.isCurrent
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 10
                        implicitWidth: 28
                        implicitHeight: 28
                        radius: 14
                        color: Theme.primaryFillStrong
                        border.width: 1
                        border.color: Theme.primary
                        Icon {
                            anchors.centerIn: parent
                            text: Icons.check
                            size: 16
                            color: Theme.primary
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 30
                        color: Theme.alpha(Theme.surface, 0.75)
                        visible: mouse.containsMouse || cell.sel
                        StyledText {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            text: cell.modelData.split("/").pop()
                            font.family: Theme.font.mono
                            font.pixelSize: Theme.font.tiny
                        }
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        grid.currentIndex = cell.index;
                        Wallpaper.set(cell.modelData);
                    }
                }
            }
        }
    }
}
