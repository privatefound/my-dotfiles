import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components

// Contenitore cliccabile per i widget della barra (pillola con hover).
StyledRect {
    id: root

    default property alias content: row.data
    property int padding: 10
    property bool active: false
    property alias spacing: row.spacing
    property alias hovered: layer.containsMouse

    signal clicked(var mouse)
    signal wheel(var wheel)

    implicitHeight: Theme.barHeight - 10
    implicitWidth: row.implicitWidth + padding * 2
    radius: Theme.radius.full
    color: active ? Theme.primaryContainer : "transparent"

    function centerX() {
        return mapToItem(null, width / 2, 0).x;
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
    }

    StateLayer {
        id: layer
        tint: Theme.primary
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.wheel(wheel)
    }
}
