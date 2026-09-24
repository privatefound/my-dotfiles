import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// Colonna scorrevole con altezza massima: cresce col contenuto fino a `maxHeight`.
Flickable {
    id: root

    default property alias content: col.data
    property int maxHeight: 320
    property alias spacing: col.spacing

    Layout.fillWidth: true
    implicitHeight: Math.min(col.implicitHeight, maxHeight)
    contentHeight: col.implicitHeight
    contentWidth: width
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: col.implicitHeight > maxHeight

    ScrollBar.vertical: StyledScrollBar {}

    ColumnLayout {
        id: col
        width: root.width - (root.interactive ? 8 : 0)
        spacing: 2
    }
}
