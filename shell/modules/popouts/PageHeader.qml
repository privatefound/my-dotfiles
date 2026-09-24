import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

// Intestazione delle sotto-pagine (freccia indietro + titolo + azioni).
RowLayout {
    id: root

    property string title
    property string icon
    default property alias actions: actionsRow.data

    Layout.fillWidth: true
    spacing: 8

    IconButton {
        icon: Icons.arrowLeft
        size: 34
        onClicked: Ui.controlPage = ""
    }

    Icon {
        text: root.icon
        size: 20
        color: Theme.primary
    }

    StyledText {
        Layout.fillWidth: true
        text: root.title
        font.pixelSize: Theme.font.title
        font.weight: Font.DemiBold
    }

    RowLayout {
        id: actionsRow
        spacing: 2
    }
}
