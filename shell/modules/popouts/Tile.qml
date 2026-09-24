import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components

// Riquadro rapido del Control Center (stile Material 3 / DMS).
// Click sul riquadro = azione principale; se `hasPage`, la freccia apre la sotto-pagina.
StyledRect {
    id: root

    property string icon
    property string title
    property string subtitle
    property bool toggled: false
    property bool hasPage: false

    signal clicked(var mouse)
    signal pageRequested

    Layout.fillWidth: true
    implicitHeight: 64
    implicitWidth: 180
    radius: toggled ? Theme.radius.large : Theme.radius.normal
    color: toggled ? Theme.primaryContainer : Theme.surfaceContainerHigh

    Behavior on radius {
        Anim {}
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: root.hasPage ? 4 : 12
        spacing: 10

        StyledRect {
            implicitWidth: 40
            implicitHeight: 40
            radius: root.toggled ? 14 : 20
            color: root.toggled ? Theme.primaryFillStrong : Theme.surfaceContainerHighest
            border.width: root.toggled ? 1 : 0
            border.color: Theme.alpha(Theme.primary, 0.6)

            Behavior on radius {
                Anim {}
            }

            Icon {
                anchors.centerIn: parent
                text: root.icon
                size: 19
                color: root.toggled ? Theme.primary : Theme.text
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            StyledText {
                Layout.fillWidth: true
                text: root.title
                font.weight: Font.DemiBold
                color: root.toggled ? Theme.fgPrimaryContainer : Theme.text
            }
            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.subtitle
                font.pixelSize: Theme.font.small
                color: root.toggled ? Theme.alpha(Theme.fgPrimaryContainer, 0.75) : Theme.textDim
            }
        }

        Item {
            visible: root.hasPage
            implicitWidth: 30
            Layout.fillHeight: true
        }
    }

    StateLayer {
        tint: root.toggled ? Theme.fgPrimaryContainer : Theme.text
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => root.clicked(mouse)
    }

    // Freccia verso la sotto-pagina (sopra lo state layer)
    IconButton {
        visible: root.hasPage
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        size: 32
        icon: Icons.chevronRight
        iconColor: root.toggled ? Theme.fgPrimaryContainer : Theme.textDim
        onClicked: root.pageRequested()
    }
}
