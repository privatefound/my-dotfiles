import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.config
import qs.components
import qs.services

// Workspace del monitor, con icone delle app e pillola attiva che si allarga.
StyledRect {
    id: root

    required property var monitor
    // "fixed": sempre 1..N (come la vecchia barra), "monitor": solo i workspace di questo monitor
    readonly property var existing: Hyprland.workspaces.values.filter(w => w.id > 0)
    readonly property var workspaces: {
        if (Settings.workspaceMode === "monitor")
            return Hypr.workspacesFor(monitor?.name ?? "").map(w => ({ id: w.id, name: w.name, ws: w }));
        const out = [];
        for (let i = 1; i <= Settings.workspaceCount; i++)
            out.push({ id: i, name: String(i), ws: existing.find(w => w.id === i) ?? null });
        for (const w of existing)
            if (w.id > Settings.workspaceCount)
                out.push({ id: w.id, name: w.name, ws: w });
        return out;
    }
    readonly property int activeId: monitor?.activeWorkspace?.id ?? -1

    implicitHeight: Theme.barHeight - 10
    implicitWidth: row.implicitWidth + 8
    radius: Theme.radius.full
    color: Theme.surfaceContainer

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => Hypr.dispatch(`hl.dsp.focus({ workspace = "${wheel.angleDelta.y > 0 ? "m-1" : "m+1"}" })`)
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 3

        Repeater {
            model: root.workspaces

            delegate: StyledRect {
                id: ws

                required property var modelData
                readonly property bool isActive: modelData.id === root.activeId
                readonly property var hws: modelData.ws
                readonly property bool elsewhere: hws !== null && hws.monitor?.name !== root.monitor?.name && (hws.monitor?.activeWorkspace?.id === modelData.id)
                readonly property var windows: hws?.toplevels?.values ?? []
                readonly property var icons: {
                    const seen = [];
                    for (const w of windows) {
                        const cls = w.lastIpcObject?.class ?? "";
                        if (cls && !seen.includes(cls))
                            seen.push(cls);
                    }
                    return seen.slice(0, 3);
                }
                readonly property bool showIcons: Settings.workspaceIcons && icons.length > 0

                implicitHeight: Theme.barHeight - 18
                implicitWidth: Math.max(isActive ? 40 : 24, content.implicitWidth + (isActive ? 20 : 12))
                radius: height / 2
                color: hws?.urgent ? Theme.error : isActive ? Theme.primaryFillStrong : wsMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent"
                border.width: elsewhere || isActive ? 1 : 0
                border.color: Theme.alpha(Theme.primary, isActive ? 0.8 : 0.45)

                Behavior on implicitWidth {
                    Anim {
                        easing.bezierCurve: Theme.anim.expressive
                    }
                }

                RowLayout {
                    id: content
                    anchors.centerIn: parent
                    spacing: 4

                    StyledText {
                        text: ws.modelData.name
                        font.family: Theme.font.mono
                        font.pixelSize: Theme.font.small
                        font.weight: ws.isActive ? Font.Bold : Font.Medium
                        color: ws.isActive ? Theme.primary : ws.windows.length > 0 ? Theme.text : Theme.textFaint
                        visible: !ws.showIcons || ws.isActive
                    }

                    Repeater {
                        model: ws.showIcons ? ws.icons : []
                        delegate: IconImage {
                            required property string modelData
                            implicitSize: 14
                            source: Hypr.iconForClass(modelData)
                            opacity: ws.isActive ? 1 : 0.75
                        }
                    }
                }

                MouseArea {
                    id: wsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hypr.focusWorkspace(ws.modelData.id)
                }
            }
        }
    }
}
