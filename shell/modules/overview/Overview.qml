import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.config
import qs.components
import qs.services

// Panoramica delle finestre: anteprime dal vivo di tutte le finestre, divise per workspace.
// Scrivi per filtrare (titolo o app) · frecce/Tab per muoversi · Invio o click per andarci ·
// click centrale o Canc per chiuderla · Esc per uscire.
StyledRect {
    id: root

    readonly property var screenObj: Quickshell.screens.find(s => s.name === Ui.modalScreen) ?? Quickshell.screens[0]
    readonly property string query: search.text.trim().toLowerCase()

    // finestre visibili (filtrate), ordinate per workspace; gli speciali (id < 0) in fondo
    readonly property var windows: {
        const q = query;
        return Hyprland.toplevels.values.filter(t => {
            const ws = t.workspace;
            if (!ws || !t.wayland)
                return false;
            if (!q)
                return true;
            return (t.title ?? "").toLowerCase().includes(q) || (t.lastIpcObject?.class ?? "").toLowerCase().includes(q);
        }).sort((a, b) => {
            const wa = a.workspace.id < 0 ? 10000 - a.workspace.id : a.workspace.id;
            const wb = b.workspace.id < 0 ? 10000 - b.workspace.id : b.workspace.id;
            return wa - wb;
        });
    }
    // sezioni: [{ ws, name, items: [{ top, index }] }]
    readonly property var sections: {
        const out = [];
        windows.forEach((t, i) => {
            let s = out[out.length - 1];
            if (!s || s.ws !== t.workspace.id) {
                s = { ws: t.workspace.id, name: t.workspace.name, monitor: t.workspace.monitor?.name ?? "", items: [] };
                out.push(s);
            }
            s.items.push({ top: t, index: i });
        });
        return out;
    }
    property int current: 0
    onWindowsChanged: current = Math.max(0, Math.min(current, windows.length - 1))

    implicitWidth: Math.round((screenObj?.width ?? 1920) * 0.86)
    implicitHeight: Math.round((screenObj?.height ?? 1080) * 0.82)
    radius: Theme.radius.xl
    color: Theme.alpha(Theme.surface, Theme.panelOpacity)
    border.width: 1
    border.color: Theme.outline
    clip: true

    Component.onCompleted: {
        Hyprland.refreshToplevels();
        // si parte dalla finestra attiva
        const i = windows.indexOf(Hyprland.activeToplevel);
        current = i >= 0 ? i : 0;
        search.focusInput();
    }

    function activate(i) {
        const t = windows[i];
        if (!t)
            return;
        Ui.closeModal();
        Hypr.dispatch(`hl.dsp.focus({ window = "address:0x${String(t.address).replace(/^0x/, "")}" })`);
    }
    function closeWindow(i) {
        const t = windows[i];
        if (t)
            Hyprland.dispatch(`hl.dsp.window.close({ window = "address:0x${String(t.address).replace(/^0x/, "")}" })`);
        refreshTimer.restart();
    }
    Timer {
        id: refreshTimer
        interval: 300
        onTriggered: Hyprland.refreshToplevels()
    }
    // su/giù: stessa posizione nella sezione precedente/successiva
    function moveSection(dir) {
        const si = sections.findIndex(s => s.items.some(it => it.index === current));
        const ns = sections[si + dir];
        if (!ns)
            return;
        const pos = sections[si].items.findIndex(it => it.index === current);
        current = ns.items[Math.min(pos, ns.items.length - 1)].index;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Icon {
                text: Icons.apps
                size: 22
                color: Theme.primary
            }
            StyledText {
                text: I18n.tr("Finestre")
                font.pixelSize: Theme.font.title
                font.weight: Font.DemiBold
            }
            StyledText {
                text: root.windows.length + " · " + I18n.tr("Invio per andarci · Canc per chiudere")
                font.pixelSize: Theme.font.small
                color: Theme.textDim
            }
            Item {
                Layout.fillWidth: true
            }
            TextField {
                id: search
                implicitWidth: 340
                icon: Icons.magnify
                placeholder: I18n.tr("Filtra per titolo o app…")
                onTextChanged: root.current = 0
                onAccepted: root.activate(root.current)
                onEscapePressed: Ui.closeModal()
                Keys.forwardTo: [keyHandler]
            }
        }

        Item {
            id: keyHandler
            Keys.onPressed: event => {
                const n = root.windows.length;
                if (n === 0)
                    return;
                if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                    root.current = (root.current + 1) % n;
                } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
                    root.current = (root.current - 1 + n) % n;
                } else if (event.key === Qt.Key_Down) {
                    root.moveSection(1);
                } else if (event.key === Qt.Key_Up) {
                    root.moveSection(-1);
                } else if (event.key === Qt.Key_Delete) {
                    root.closeWindow(root.current);
                } else
                    return;
                event.accepted = true;
            }
        }

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: col.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: col
                width: flick.width
                spacing: 18

                Repeater {
                    model: root.sections
                    delegate: ColumnLayout {
                        id: sec
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 8

                        RowLayout {
                            spacing: 8
                            StyledRect {
                                implicitHeight: 24
                                implicitWidth: wsLabel.implicitWidth + 18
                                radius: 12
                                color: sec.modelData.ws === Hyprland.focusedWorkspace?.id ? Theme.primaryFillStrong : Theme.surfaceContainerHigh
                                StyledText {
                                    id: wsLabel
                                    anchors.centerIn: parent
                                    text: sec.modelData.ws < 0 ? sec.modelData.name.replace(/^special:/, "★ ") : I18n.tr("Workspace") + " " + sec.modelData.name
                                    font.pixelSize: Theme.font.small
                                    font.weight: Font.DemiBold
                                    color: sec.modelData.ws === Hyprland.focusedWorkspace?.id ? Theme.primary : Theme.text
                                }
                            }
                            StyledText {
                                text: sec.modelData.monitor
                                font.family: Theme.font.mono
                                font.pixelSize: Theme.font.tiny
                                color: Theme.textFaint
                            }
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 14

                            Repeater {
                                model: sec.modelData.items
                                delegate: WindowCard {
                                    required property var modelData
                                    toplevel: modelData.top
                                    selected: modelData.index === root.current
                                    onHovered: root.current = modelData.index
                                    onActivated: root.activate(modelData.index)
                                    onCloseRequested: root.closeWindow(modelData.index)
                                    onSelectedChanged: if (selected) {
                                        // tiene la scheda selezionata visibile durante la navigazione da tastiera
                                        const p = mapToItem(col, 0, 0);
                                        if (p.y < flick.contentY)
                                            flick.contentY = p.y;
                                        else if (p.y + height > flick.contentY + flick.height)
                                            flick.contentY = p.y + height - flick.height;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        StyledText {
            visible: root.windows.length === 0
            Layout.alignment: Qt.AlignHCenter
            text: root.query ? I18n.tr("Nessuna finestra corrisponde") : I18n.tr("Nessuna finestra aperta")
            color: Theme.textFaint
        }
    }
}
