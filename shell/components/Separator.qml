import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    property bool vertical: false

    Layout.fillWidth: !vertical
    Layout.fillHeight: vertical
    implicitWidth: vertical ? 1 : 10
    implicitHeight: vertical ? 10 : 1
    color: Theme.outlineVariant
}
