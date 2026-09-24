import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

// Pagina Bluetooth: accensione, ricerca, associazione, connessione, batteria dispositivi.
ColumnLayout {
    id: root

    spacing: 10

    Component.onDestruction: Bt.setDiscovering(false)

    PageHeader {
        title: "Bluetooth"
        icon: Icons.bluetooth

        IconButton {
            icon: Icons.radar
            toggled: Bt.discovering
            disabled: !Bt.enabled
            onClicked: Bt.setDiscovering(!Bt.discovering)
        }
        Toggle {
            checked: Bt.enabled
            onToggled: v => Bt.setEnabled(v)
        }
    }

    ScrollColumn {
        maxHeight: 460
        spacing: 4

        SectionHeader {
            visible: Bt.enabled && Bt.pairedDevices.length > 0
            text: I18n.tr("Dispositivi associati")
            icon: Icons.bluetoothConnect
        }

        Repeater {
            model: Bt.enabled ? Bt.pairedDevices : []

            delegate: ListRow {
                required property var modelData
                icon: Bt.deviceIcon(modelData)
                title: Bt.deviceName(modelData)
                subtitle: Bt.stateLabel(modelData)
                highlighted: modelData.connected
                busy: modelData.state === 2 || modelData.state === 3 || modelData.pairing
                onClicked: Bt.toggleConnection(modelData)

                IconButton {
                    size: 30
                    icon: Icons.trash
                    iconColor: Theme.textDim
                    onClicked: modelData.forget()
                }
            }
        }

        SectionHeader {
            Layout.topMargin: 8
            visible: Bt.enabled
            text: Bt.discovering ? I18n.tr("Dispositivi disponibili") : I18n.tr("Premi il radar per cercare")
            icon: Icons.radar
        }

        Repeater {
            model: Bt.enabled ? Bt.otherDevices : []

            delegate: ListRow {
                required property var modelData
                icon: Bt.deviceIcon(modelData)
                title: Bt.deviceName(modelData)
                subtitle: Bt.stateLabel(modelData)
                busy: modelData.pairing
                onClicked: Bt.toggleConnection(modelData)
            }
        }

        StyledText {
            visible: !Bt.enabled
            Layout.fillWidth: true
            Layout.margins: 20
            text: Bt.blocked ? I18n.tr("Bluetooth bloccato (rfkill): accendilo con l'interruttore") : I18n.tr("Bluetooth spento")
            color: Theme.textFaint
            horizontalAlignment: Text.AlignHCenter
        }
    }

    StyledButton {
        Layout.alignment: Qt.AlignRight
        variant: "text"
        icon: Icons.bluetoothSettings
        text: "Blueman"
        onClicked: {
            Ui.closePopout();
            Session.bluetoothManager();
        }
    }
}
