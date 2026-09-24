import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

// Rete · Bluetooth · Volume · Batteria. Ogni segmento apre la sua pagina del Control Center.
StyledRect {
    id: root

    required property string screenName
    readonly property bool ccOpen: Ui.popout === "control" && Ui.popoutScreen === screenName

    implicitHeight: Theme.barHeight - 10
    implicitWidth: row.implicitWidth + 8
    radius: Theme.radius.full
    color: ccOpen ? Theme.primaryContainer : Theme.surfaceContainer

    function open(page, item) {
        const x = root.mapToItem(null, root.width / 2, 0).x;
        if (ccOpen && Ui.controlPage === page)
            Ui.closePopout();
        else {
            Ui.openPopout("control", screenName, x);
            Ui.controlPage = page;
        }
    }

    component Segment: StyledRect {
        id: seg
        default property alias content: segRow.data
        signal clicked(var mouse)
        signal wheel(var wheel)
        implicitHeight: Theme.barHeight - 16
        implicitWidth: segRow.implicitWidth + 16
        radius: height / 2
        RowLayout {
            id: segRow
            anchors.centerIn: parent
            spacing: 5
        }
        StateLayer {
            tint: Theme.primary
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: mouse => seg.clicked(mouse)
            onWheel: wheel => seg.wheel(wheel)
        }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 0

        // ── Rete: ethernet + wifi (quella con la route di default è evidenziata) + VPN ──
        Segment {
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    Network.openEditor();
                else {
                    Ui.networkTab = Network.wiredConnected && !Network.wifiConnected ? "ethernet" : "wifi";
                    root.open("network");
                }
            }

            Icon {
                visible: Network.wiredConnected
                text: Icons.ethernet
                size: 16
                color: Network.defaultKind === "ethernet" || !Network.wifiConnected ? Theme.primary : Theme.textDim
            }
            Icon {
                visible: !Network.wiredConnected || Network.wifiConnected
                text: Network.icon === Icons.ethernet ? Network.strengthIcon(Network.activeNetwork?.signalStrength ?? 0) : Network.icon
                size: 16
                color: !Network.wifiConnected ? Theme.textFaint : Network.defaultKind === "wifi" || !Network.wiredConnected ? Theme.primary : Theme.textDim
            }
            Icon {
                visible: Network.vpnActive
                text: Icons.vpn
                size: 15
                color: Theme.primary
            }
            StyledText {
                visible: Network.wifiConnected && !Network.wiredConnected
                Layout.maximumWidth: 110
                text: Network.activeNetwork?.name ?? ""
                font.pixelSize: Theme.font.small
                color: Theme.textDim
            }
        }

        // ── Bluetooth ──
        Segment {
            onClicked: mouse => mouse.button === Qt.RightButton ? Session.bluetoothManager() : root.open("bluetooth")

            Icon {
                text: Bt.icon
                size: 16
                color: Bt.connectedDevices.length > 0 ? Theme.primary : Bt.enabled ? Theme.text : Theme.textDim
            }
        }

        // ── Volume: rotella regola, click destro = pavucontrol ──
        Segment {
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    Session.audioMixer();
                else if (mouse.button === Qt.MiddleButton)
                    Audio.toggleMute();
                else
                    root.open("audio");
            }
            onWheel: wheel => Audio.changeVolume(wheel.angleDelta.y > 0 ? 0.05 : -0.05)

            Icon {
                text: Audio.icon
                size: 16
                color: Audio.muted ? Theme.error : Theme.primary
            }
            StyledText {
                text: Math.round(Audio.volume * 100) + "%"
                font.family: Theme.font.mono
                font.pixelSize: Theme.font.small
                color: Audio.muted ? Theme.error : Theme.text
            }
            Icon {
                visible: Audio.micMuted
                text: Icons.micOff
                size: 14
                color: Theme.error
            }
        }

        // ── Batteria ──
        Segment {
            visible: Power.hasBattery
            onClicked: root.open("")

            Icon {
                text: Power.icon
                size: 16
                color: Power.low ? Theme.error : Power.charging ? Theme.primary : Power.percent < 30 ? Theme.warning : Theme.text
            }
            StyledText {
                text: Power.percent + "%"
                font.family: Theme.font.mono
                font.pixelSize: Theme.font.small
                color: Power.low ? Theme.error : Theme.text
            }
        }
    }
}
