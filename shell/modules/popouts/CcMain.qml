import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.services

// Pagina principale del Control Center.
ColumnLayout {
    id: root

    spacing: 12

    // ── Slider ──
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            StyledSlider {
                Layout.fillWidth: true
                icon: Audio.icon
                value: Math.min(Audio.volume, 1)
                muted: Audio.muted
                onMoved: v => Audio.setVolume(v)
                onIconClicked: Audio.toggleMute()
            }
            IconButton {
                icon: Icons.chevronRight
                iconColor: Theme.textDim
                onClicked: Ui.controlPage = "audio"
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            StyledSlider {
                Layout.fillWidth: true
                icon: Audio.micIcon
                value: Math.min(Audio.micVolume, 1)
                muted: Audio.micMuted
                onMoved: v => Audio.setMicVolume(v)
                onIconClicked: Audio.toggleMicMute()
            }
            Item {
                implicitWidth: 36
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: Brightness.available
            spacing: 6
            StyledSlider {
                Layout.fillWidth: true
                icon: Brightness.value > 0.66 ? Icons.brightnessHigh : Brightness.value > 0.33 ? Icons.brightnessMid : Icons.brightnessLow
                value: Brightness.value
                onMoved: v => Brightness.set(v)
            }
            Item {
                implicitWidth: 36
            }
        }
    }

    // ── Riquadri rapidi ──
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 8
        rowSpacing: 8

        Tile {
            icon: Network.icon
            title: Network.wiredConnected ? "Rete" : "Wi‑Fi"
            subtitle: Network.label + (Network.vpnActive ? " · VPN" : "")
            toggled: Network.connected || Network.wifiEnabled
            hasPage: true
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    Ui.networkTab = "wifi";
                    Ui.controlPage = "network";
                }
                else
                    Network.setWifiEnabled(!Network.wifiEnabled);
            }
            onPageRequested: {
                Ui.networkTab = "wifi";
                Ui.controlPage = "network";
            }
        }

        Tile {
            icon: Bt.icon
            title: "Bluetooth"
            subtitle: Bt.label
            toggled: Bt.enabled
            hasPage: true
            onClicked: mouse => mouse.button === Qt.RightButton ? Ui.controlPage = "bluetooth" : Bt.setEnabled(!Bt.enabled)
            onPageRequested: Ui.controlPage = "bluetooth"
        }

        Tile {
            icon: Network.vpnActive ? Icons.vpn : Icons.lan
            title: "Schede & VPN"
            subtitle: Network.defaultIface ? "via " + Network.defaultIface : "Nessuna route"
            toggled: Network.vpnActive
            hasPage: true
            onClicked: {
                Ui.networkTab = Network.vpns.length > 0 ? "vpn" : "ethernet";
                Ui.controlPage = "network";
            }
            onPageRequested: {
                Ui.networkTab = "ethernet";
                Ui.controlPage = "network";
            }
        }

        Tile {
            icon: Audio.sinkIcon(Audio.sink)
            title: "Audio"
            subtitle: Audio.nodeName(Audio.sink)
            hasPage: true
            onClicked: Ui.controlPage = "audio"
            onPageRequested: Ui.controlPage = "audio"
        }

        Tile {
            icon: Settings.dnd ? Icons.bellOff : Icons.bell
            title: "Non disturbare"
            subtitle: Settings.dnd ? "Attivo" : "Spento"
            toggled: Settings.dnd
            onClicked: Notifs.toggleDnd()
        }

        Tile {
            icon: Settings.caffeine ? Icons.coffee : Icons.coffeeOutline
            title: "Caffeine"
            subtitle: Settings.caffeine ? "Schermo sempre acceso" : "Spento"
            toggled: Settings.caffeine
            onClicked: Settings.caffeine = !Settings.caffeine
        }

        Tile {
            icon: Icons.opacity
            title: "Trasparenza"
            subtitle: Settings.windowTransparency ? "Finestre trasparenti" : "Finestre opache"
            toggled: Settings.windowTransparency
            onClicked: Settings.windowTransparency = !Settings.windowTransparency
        }

        Tile {
            icon: Audio.micIcon
            title: "Microfono"
            subtitle: Audio.micMuted ? "Muto" : "Attivo"
            toggled: !Audio.micMuted
            onClicked: Audio.toggleMicMute()
        }

        Tile {
            icon: Icons.cast
            title: "Trasmetti"
            subtitle: "Click destro: monitor"
            onClicked: mouse => {
                Ui.closePopout();
                mouse.button === Qt.RightButton ? Session.monitors() : Session.castScreen();
            }
        }

        Tile {
            icon: Icons.screenshot
            title: "Screenshot"
            subtitle: "Area · click destro: schermo"
            onClicked: mouse => {
                Ui.closePopout();
                const cmd = mouse.button === Qt.RightButton ? "sleep 0.4; grim - | swappy -f -" : "sleep 0.4; g=$(slurp) && sleep 0.05 && grim -g \"$g\" - | swappy -f -";
                Quickshell.execDetached(["sh", "-c", cmd]);
            }
        }
    }

    // ── Media ──
    MediaCard {
        Layout.fillWidth: true
        visible: Media.hasPlayer
    }

    // ── Batteria ──
    StyledRect {
        Layout.fillWidth: true
        visible: Power.hasBattery
        implicitHeight: 44
        radius: Theme.radius.normal
        color: Theme.surfaceContainer

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10

            Icon {
                text: Power.icon
                size: 20
                color: Power.low ? Theme.error : Theme.primary
            }
            StyledText {
                text: Power.percent + "%"
                font.family: Theme.font.mono
                font.weight: Font.Bold
            }
            StyledText {
                Layout.fillWidth: true
                text: Power.timeLabel
                color: Theme.textDim
                font.pixelSize: Theme.font.small
            }
            StyledText {
                text: Power.acPlugged ? "Alimentatore" : "Batteria"
                color: Theme.textDim
                font.pixelSize: Theme.font.small
            }
        }
    }
}
