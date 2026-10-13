import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

// Pagina Rete con tre schede come il vecchio popup: Wi‑Fi · Ethernet · VPN.
ColumnLayout {
    id: root

    spacing: 10

    Component.onCompleted: {
        Network.setScanning(Ui.networkTab === "wifi");
        Network.refreshNm();
    }
    Component.onDestruction: Network.setScanning(false)

    Connections {
        target: Ui
        function onNetworkTabChanged() {
            Network.setScanning(Ui.networkTab === "wifi");
            Network.refreshNm();
        }
    }

    // Aggiorna schede/profili mentre la pagina è aperta
    Timer {
        interval: 4000
        running: true
        repeat: true
        onTriggered: Network.refreshNm()
    }

    PageHeader {
        title: I18n.tr("Rete")
        icon: Icons.lan

        IconButton {
            icon: Icons.refresh
            iconColor: Theme.textDim
            onClicked: {
                if (Ui.networkTab === "wifi") {
                    Network.setScanning(false);
                    Network.setScanning(true);
                }
                Network.refreshNm();
            }
        }
        IconButton {
            icon: Icons.cog
            iconColor: Theme.textDim
            onClicked: {
                Ui.closePopout();
                Network.openEditor();
            }
        }
    }

    // ── Schede ──
    StyledRect {
        Layout.fillWidth: true
        implicitHeight: 44
        radius: 22
        color: Theme.surfaceContainerHigh

        RowLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 4

            Repeater {
                model: [
                    { id: "wifi", label: "Wi‑Fi", icon: Icons.wifi4, on: Network.wifiConnected },
                    { id: "ethernet", label: "Ethernet", icon: Icons.ethernet, on: Network.wiredConnected },
                    { id: "vpn", label: "VPN", icon: Icons.vpn, on: Network.vpnActive }
                ]
                delegate: StyledRect {
                    required property var modelData
                    readonly property bool sel: Ui.networkTab === modelData.id
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 18
                    color: sel ? Theme.primaryFillStrong : "transparent"

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Icon {
                            text: modelData.icon
                            size: 16
                            color: sel ? Theme.primary : Theme.textDim
                        }
                        StyledText {
                            text: modelData.label
                            font.weight: Font.DemiBold
                            color: sel ? Theme.primary : Theme.text
                        }
                        Rectangle {
                            visible: modelData.on
                            implicitWidth: 7
                            implicitHeight: 7
                            radius: 4
                            color: Theme.primary
                        }
                    }
                    StateLayer {
                        tint: sel ? Theme.primary : Theme.text
                        onClicked: Ui.networkTab = modelData.id
                    }
                }
            }
        }
    }

    // ═══════════════ Wi‑Fi ═══════════════
    ColumnLayout {
        visible: Ui.networkTab === "wifi"
        Layout.fillWidth: true
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            StyledText {
                Layout.fillWidth: true
                text: Network.wifiEnabled ? (Network.wifiConnected ? I18n.tr("Connesso a ") + Network.activeNetwork.name : I18n.tr("Non connesso")) : I18n.tr("Wi‑Fi spento")
                color: Theme.textDim
            }
            Toggle {
                checked: Network.wifiEnabled
                onToggled: v => Network.setWifiEnabled(v)
            }
        }

        StyledText {
            visible: Network.lastError !== ""
            Layout.fillWidth: true
            text: Network.lastError
            color: Theme.error
            font.pixelSize: Theme.font.small
        }

        ScrollColumn {
            maxHeight: 420
            spacing: 4

            Repeater {
                model: Network.wifiEnabled ? Network.networks : []

                delegate: ColumnLayout {
                    id: netItem
                    required property var modelData
                    readonly property bool asking: Network.pendingNetwork === modelData
                    Layout.fillWidth: true
                    spacing: 4

                    ListRow {
                        icon: Network.strengthIcon(netItem.modelData.signalStrength)
                        title: netItem.modelData.name
                        subtitle: (netItem.modelData.connected ? I18n.tr("Connesso") : netItem.modelData.stateChanging ? I18n.tr("Connessione…") : netItem.modelData.known ? I18n.tr("Salvata") : Network.isSecure(netItem.modelData) ? I18n.tr("Protetta") : I18n.tr("Aperta")) + "  ·  " + Math.round(Network.strength(netItem.modelData.signalStrength) * 100) + "%"
                        highlighted: netItem.modelData.connected
                        busy: netItem.modelData.stateChanging
                        onClicked: Network.connectTo(netItem.modelData)

                        Icon {
                            visible: Network.isSecure(netItem.modelData)
                            text: Icons.lockOutline
                            size: 14
                            color: Theme.textFaint
                        }
                        IconButton {
                            visible: netItem.modelData.known
                            size: 30
                            icon: Icons.trash
                            iconColor: Theme.textDim
                            onClicked: Network.forget(netItem.modelData)
                        }
                    }

                    // Password inline
                    RowLayout {
                        visible: netItem.asking
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        Layout.rightMargin: 4
                        spacing: 6

                        TextField {
                            id: pw
                            Layout.fillWidth: true
                            icon: Icons.key
                            placeholder: I18n.tr("Password di ") + netItem.modelData.name
                            password: true
                            onAccepted: Network.connectWithPassword(netItem.modelData, text)
                            onEscapePressed: Network.pendingNetwork = null
                            onVisibleChanged: if (visible) focusInput()
                        }
                        IconButton {
                            icon: Icons.check
                            toggled: true
                            onClicked: Network.connectWithPassword(netItem.modelData, pw.text)
                        }
                        IconButton {
                            icon: Icons.close
                            onClicked: Network.pendingNetwork = null
                        }
                    }
                }
            }

            StyledText {
                visible: Network.wifiEnabled && Network.networks.length === 0
                Layout.fillWidth: true
                Layout.margins: 16
                text: I18n.tr("Ricerca reti in corso…")
                color: Theme.textFaint
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // ═══════════════ Ethernet: expansion card 1/2, docking station, ognuna con i suoi profili ═══════════════
    ScrollColumn {
        visible: Ui.networkTab === "ethernet"
        maxHeight: 470
        spacing: 8

        Repeater {
            model: Network.ethSlots
            delegate: EthSlot {
                required property var modelData
                label: modelData.label
                icon: modelData.icon
                iface: modelData.iface
            }
        }

        // altre schede ethernet senza posto fisso (es. una terza scheda)
        Repeater {
            model: Network.otherEthernet
            delegate: EthSlot {
                required property var modelData
                label: "Ethernet " + modelData.device
                iface: modelData
            }
        }

        StyledText {
            visible: Network.ethProfiles.length === 0
            Layout.fillWidth: true
            Layout.margins: 8
            wrapMode: Text.Wrap
            text: I18n.tr("Nessun profilo ethernet libero: crea un profilo in NetworkManager senza scheda associata e apparirà su tutte le schede.")
            color: Theme.textFaint
            font.pixelSize: Theme.font.small
        }

        StyledButton {
            Layout.alignment: Qt.AlignRight
            variant: "text"
            icon: Icons.cog
            text: I18n.tr("Modifica profili")
            onClicked: Network.openEditor()
        }
    }

    // ═══════════════ VPN ═══════════════
    ScrollColumn {
        visible: Ui.networkTab === "vpn"
        maxHeight: 470
        spacing: 4

        Repeater {
            model: Network.vpns

            delegate: ListRow {
                required property var modelData
                icon: modelData.active ? Icons.shieldLock : Icons.vpn
                title: modelData.name
                subtitle: (modelData.type === "wireguard" ? "WireGuard" : "VPN") + (modelData.active ? I18n.tr("  ·  connessa") + (modelData.device && modelData.device !== "--" ? " (" + modelData.device + ")" : "") : I18n.tr("  ·  disconnessa"))
                highlighted: modelData.active
                onClicked: Network.toggleVpn(modelData)

                Toggle {
                    checked: modelData.active
                    onToggled: Network.toggleVpn(modelData)
                }
            }
        }

        ColumnLayout {
            visible: Network.vpns.length === 0
            Layout.fillWidth: true
            Layout.margins: 20
            spacing: 10
            Icon {
                Layout.alignment: Qt.AlignHCenter
                text: Icons.vpn
                size: 36
                color: Theme.primaryDim
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: I18n.tr("Nessuna VPN configurata")
                color: Theme.textFaint
            }
            StyledButton {
                Layout.alignment: Qt.AlignHCenter
                variant: "tonal"
                icon: Icons.plus
                text: I18n.tr("Aggiungi VPN")
                onClicked: {
                    Ui.closePopout();
                    Network.openEditor();
                }
            }
        }
    }

    // Stato operazioni nmcli
    StyledText {
        visible: Network.nmBusy
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: I18n.tr("Applico…")
        color: Theme.primary
        font.pixelSize: Theme.font.small
    }
}
