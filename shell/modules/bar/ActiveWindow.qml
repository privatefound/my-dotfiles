import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.config
import qs.components
import qs.services

// Titolo della finestra attiva del monitor (con icona dell'app).
RowLayout {
    id: root

    required property var monitor
    readonly property var focusedTop: Hyprland.activeToplevel
    readonly property bool isThisMonitor: focusedTop?.monitor?.name === monitor?.name
    readonly property string title: isThisMonitor ? (focusedTop?.title ?? "") : (monitor?.activeWorkspace?.lastIpcObject?.lastwindowtitle ?? "")
    readonly property string cls: isThisMonitor ? (focusedTop?.lastIpcObject?.class ?? "") : ""

    spacing: 8
    visible: title !== ""

    IconImage {
        visible: root.cls !== ""
        implicitSize: 16
        source: Hypr.iconForClass(root.cls)
    }

    StyledText {
        Layout.maximumWidth: 320
        text: root.title
        color: root.isThisMonitor ? Theme.text : Theme.textDim
        font.pixelSize: Theme.font.small
    }
}
