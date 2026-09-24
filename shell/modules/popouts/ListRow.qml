import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.components

// Riga di lista generica: icona (glifo o immagine) · titolo/sottotitolo · azioni a destra.
StyledRect {
    id: root

    property string icon
    property string image
    property string title
    property string subtitle
    property bool highlighted: false
    property bool busy: false
    property string badge
    default property alias trailing: trailingRow.data

    signal clicked(var mouse)

    Layout.fillWidth: true
    implicitHeight: subtitle !== "" ? 54 : 44
    radius: Theme.radius.normal
    color: highlighted ? Theme.primaryContainer : "transparent"

    StateLayer {
        tint: Theme.text
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => root.clicked(mouse)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 6
        spacing: 12

        Item {
            implicitWidth: 24
            implicitHeight: 24

            Icon {
                anchors.centerIn: parent
                visible: root.image === ""
                text: root.icon
                size: 19
                color: root.highlighted ? Theme.primary : Theme.textDim
            }
            IconImage {
                anchors.fill: parent
                visible: root.image !== ""
                source: root.image
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                spacing: 6
                StyledText {
                    Layout.fillWidth: badgeItem.visible ? false : true
                    Layout.maximumWidth: 230
                    text: root.title
                    color: root.highlighted ? Theme.fgPrimaryContainer : Theme.text
                    font.weight: root.highlighted ? Font.DemiBold : Font.Normal
                }
                StyledRect {
                    id: badgeItem
                    visible: root.badge !== ""
                    implicitHeight: 18
                    implicitWidth: badgeText.implicitWidth + 12
                    radius: 9
                    color: Theme.primaryFillStrong
                    border.width: 1
                    border.color: Theme.primary
                    StyledText {
                        id: badgeText
                        anchors.centerIn: parent
                        text: root.badge
                        font.pixelSize: Theme.font.tiny
                        font.weight: Font.Bold
                        color: Theme.primary
                    }
                }
                Item {
                    Layout.fillWidth: true
                    visible: badgeItem.visible
                }
            }
            StyledText {
                Layout.fillWidth: true
                visible: root.subtitle !== ""
                text: root.subtitle
                font.pixelSize: Theme.font.small
                color: Theme.textDim
            }
        }

        // indicatore "in corso"
        Icon {
            visible: root.busy
            text: Icons.refresh
            size: 16
            color: Theme.primary
            RotationAnimation on rotation {
                running: root.busy
                from: 0
                to: 360
                duration: 900
                loops: Animation.Infinite
            }
        }

        RowLayout {
            id: trailingRow
            spacing: 2
        }
    }
}
