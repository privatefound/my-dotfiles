import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services

// Widget di sistema sul desktop (sostituisce conky): sistema, disco, processi,
// memoria e reti attive. Sta sul livello "bottom": sopra lo sfondo, sotto le finestre,
// e non intercetta né click né tastiera.
PanelWindow {
    id: win

    required property var modelData
    readonly property string screenName: modelData.name

    // schermo scelto nelle impostazioni, altrimenti quello del portatile, altrimenti il primo
    readonly property string targetScreen: {
        const names = Quickshell.screens.map(s => s.name);
        if (Settings.desktopWidgetScreen && names.includes(Settings.desktopWidgetScreen))
            return Settings.desktopWidgetScreen;
        return names.find(n => /^(eDP|LVDS|DSI)/.test(n)) ?? names[0] ?? "";
    }

    screen: modelData
    visible: Settings.desktopWidget && screenName === targetScreen
    anchors {
        top: true
        right: true
    }
    margins {
        top: Theme.barTotal + 14
        right: 20
    }
    implicitWidth: 372
    implicitHeight: card.implicitHeight
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}

    WlrLayershell.namespace: "whiterabbit-desktop"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    readonly property color accent: Theme.primary
    readonly property string mono: Theme.font.mono
    readonly property int fs: Math.round(11 * Theme.font.scale)

    component Header: RowLayout {
        property string icon
        property string text
        property string trailing: ""
        Layout.fillWidth: true
        Layout.topMargin: 6
        spacing: 8
        Icon {
            text: parent.icon
            size: win.fs + 3
            color: win.accent
        }
        StyledText {
            text: parent.text
            font.family: win.mono
            font.pixelSize: win.fs
            font.weight: Font.DemiBold
            font.letterSpacing: 1
            color: Theme.text
        }
        Item {
            Layout.fillWidth: true
        }
        StyledText {
            visible: parent.trailing !== ""
            text: parent.trailing
            font.family: win.mono
            font.pixelSize: win.fs
            color: Theme.textDim
        }
    }

    component Line: Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 4
        implicitHeight: 1
        color: Theme.alpha(win.accent, 0.18)
    }

    // etichetta + valore (+ barra opzionale)
    component Stat: RowLayout {
        property string icon
        property string label
        property string value
        property real bar: -1          // 0..1, -1 = nessuna barra
        property color valueColor: Theme.textDim
        Layout.fillWidth: true
        spacing: 8
        Icon {
            text: parent.icon
            size: win.fs + 1
            color: win.accent
            Layout.preferredWidth: win.fs + 4
        }
        StyledText {
            text: parent.label
            font.family: win.mono
            font.pixelSize: win.fs
            color: Theme.text
            Layout.preferredWidth: 70
        }
        StyledText {
            text: parent.value
            font.family: win.mono
            font.pixelSize: win.fs
            color: parent.valueColor
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        Rectangle {
            visible: parent.bar >= 0
            Layout.preferredWidth: 96
            implicitHeight: 5
            radius: 3
            color: Theme.alpha(win.accent, 0.14)
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, parent.parent.bar))
                height: parent.height
                radius: 3
                color: win.accent
            }
        }
    }

    // grafico di velocità normalizzato sul suo massimo
    component Speed: Graph {
        property var samples: []
        readonly property real peak: Math.max(1024, ...samples)
        Layout.fillWidth: true
        implicitHeight: 22
        points: DesktopInfo.histPoints
        values: samples.map(v => v / peak)
        color: win.accent
    }

    StyledRect {
        id: card
        width: parent.width
        implicitHeight: col.implicitHeight + 28
        radius: Theme.radius.large
        color: Theme.alpha(Theme.background, 0.78)
        border.width: 1
        border.color: Theme.alpha(win.accent, 0.22)

        ColumnLayout {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 3

            Header {
                icon: Icons.arch
                text: "SYSTEM"
                Layout.topMargin: 0
            }
            Line {}
            Stat {
                icon: Icons.arch
                label: "OS"
                value: DesktopInfo.osName + "  ·  " + DesktopInfo.hostname
            }
            Stat {
                icon: Icons.chip
                label: "Kernel"
                value: DesktopInfo.kernel + " " + DesktopInfo.arch
            }
            Stat {
                icon: Icons.clock
                label: "Uptime"
                value: DesktopInfo.uptime
            }
            Stat {
                visible: DesktopInfo.installed !== ""
                icon: Icons.calendar
                label: "Installed"
                value: DesktopInfo.installed
            }

            Header {
                icon: Icons.harddisk
                text: "FILESYSTEM"
            }
            Line {}
            Stat {
                icon: Icons.harddisk
                label: "root"
                value: DesktopInfo.bytes(DesktopInfo.rootUsed) + " / " + DesktopInfo.bytes(DesktopInfo.rootSize)
                bar: DesktopInfo.rootSize > 0 ? DesktopInfo.rootUsed / DesktopInfo.rootSize : 0
            }

            Header {
                icon: Icons.speedometer
                text: "TOP PROCESSES"
                trailing: "CPU " + Math.round(SysStats.cpu * 100) + "%"
            }
            Line {}
            // memoria a sinistra, CPU a destra (come la vecchia conky)
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 14
                rowSpacing: 2
                Repeater {
                    model: 3
                    delegate: RowLayout {
                        required property int index
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        spacing: 14
                        Repeater {
                            model: [DesktopInfo.topMem[index], DesktopInfo.topCpu[index]]
                            delegate: RowLayout {
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                spacing: 6
                                Icon {
                                    text: index === 0 ? Icons.memory : Icons.chip
                                    size: win.fs
                                    color: Theme.alpha(win.accent, 0.8)
                                }
                                StyledText {
                                    text: modelData?.name ?? "—"
                                    font.family: win.mono
                                    font.pixelSize: win.fs
                                    color: Theme.text
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                StyledText {
                                    text: modelData?.value ?? ""
                                    font.family: win.mono
                                    font.pixelSize: win.fs
                                    color: Theme.textDim
                                }
                            }
                        }
                    }
                }
            }
            Item {
                implicitHeight: 4
            }
            Stat {
                icon: Icons.memory
                label: "RAM"
                value: SysStats.memUsedGb.toFixed(1) + " / " + SysStats.memTotalGb.toFixed(1) + " GiB"
                bar: SysStats.mem
            }
            Stat {
                icon: Icons.swap
                label: "Swap"
                value: DesktopInfo.bytes(DesktopInfo.swapUsed) + " / " + DesktopInfo.bytes(DesktopInfo.swapTotal)
                bar: DesktopInfo.swapTotal > 0 ? DesktopInfo.swapUsed / DesktopInfo.swapTotal : 0
            }
            Stat {
                icon: Icons.chip
                label: "CPU"
                value: DesktopInfo.cpuGhz.toFixed(2) + " GHz" + (SysStats.cpuTemp > 0 ? "  ·  " + Math.round(SysStats.cpuTemp) + "°C" : "")
                bar: SysStats.cpu
            }

            // una sezione per ogni rete collegata (ethernet, wi‑fi, VPN)
            Repeater {
                model: DesktopInfo.nets
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 3
                    Header {
                        icon: modelData.kind === "wifi" ? Icons.wifi4 : modelData.kind === "vpn" ? Icons.vpn : Icons.ethernet
                        // per le schede ethernet il nome del pannello rete (Expansion card 1, Docking station…)
                        readonly property string slot: Network.ethSlots.find(s => s.iface?.device === modelData.dev)?.label ?? ""
                        text: (modelData.kind === "wifi" ? "WIRELESS" : modelData.kind === "vpn" ? "VPN" : "ETHERNET") + " · " + (slot || modelData.dev)
                    }
                    Line {}
                    Stat {
                        icon: Icons.ipNetwork
                        label: "IP"
                        value: modelData.ip + (DesktopInfo.publicIp && modelData.kind !== "vpn" ? "   pub " + DesktopInfo.publicIp : "")
                    }
                    Stat {
                        icon: Icons.upload
                        label: "Up"
                        value: DesktopInfo.speed(modelData.txSpeed) + "   tot " + DesktopInfo.bytes(modelData.txTotal)
                    }
                    Stat {
                        icon: Icons.download
                        label: "Down"
                        value: DesktopInfo.speed(modelData.rxSpeed) + "   tot " + DesktopInfo.bytes(modelData.rxTotal)
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Speed {
                            samples: modelData.txHist
                        }
                        Speed {
                            samples: modelData.rxHist
                        }
                    }
                }
            }

            Header {
                icon: Icons.earth
                text: "NETWORK INFO"
            }
            Line {}
            Stat {
                icon: Icons.web
                label: "DNS"
                value: DesktopInfo.dns || "—"
            }
            Stat {
                icon: Icons.lan
                label: "Gateway"
                value: DesktopInfo.gateway || "—"
            }
        }
    }
}
