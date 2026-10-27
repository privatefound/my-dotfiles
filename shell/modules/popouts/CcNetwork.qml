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
    Component.onDestruction: {
        Network.setScanning(false);
        Network.clearShare();   // la password condivisa non resta in memoria a pannello chiuso
    }

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
            // connettiti inquadrando con la webcam il QR code condiviso dal telefono
            IconButton {
                size: 32
                icon: Icons.qrcodeScan
                toggled: Network.qrScanning
                iconColor: Network.qrScanning ? Theme.primary : Theme.textDim
                onClicked: {
                    if (Network.qrScanning) {
                        Network.cancelQrScan();
                    } else {
                        Network.scanWifiQr();
                        Ui.closePopout();   // libera lo schermo per l'anteprima della webcam
                    }
                }
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
                    readonly property bool sharing: Network.shareSsid !== "" && Network.shareSsid === modelData.name
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
                        // condividi (QR code + password), come su Android
                        IconButton {
                            visible: netItem.modelData.known
                            size: 30
                            icon: Icons.qrcode
                            toggled: netItem.sharing
                            iconColor: netItem.sharing ? Theme.primary : Theme.textDim
                            onClicked: netItem.sharing ? Network.clearShare() : Network.shareWifi(netItem.modelData)
                        }
                        IconButton {
                            visible: netItem.modelData.known
                            size: 30
                            icon: Icons.trash
                            iconColor: Theme.textDim
                            onClicked: Network.forget(netItem.modelData)
                        }
                    }

                    // Scheda di condivisione: QR da inquadrare con la fotocamera + password
                    StyledRect {
                        id: shareCard
                        property bool reveal: false
                        visible: netItem.sharing
                        onVisibleChanged: if (!visible) reveal = false
                        Layout.fillWidth: true
                        Layout.leftMargin: 4
                        Layout.rightMargin: 4
                        implicitHeight: shareCol.implicitHeight + 24
                        radius: Theme.radius.large
                        color: Theme.surfaceContainerHigh

                        ColumnLayout {
                            id: shareCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            spacing: 8

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: I18n.tr("Inquadra il QR code per connetterti a") + " " + netItem.modelData.name
                                font.pixelSize: Theme.font.small
                                color: Theme.textDim
                            }
                            // QR nero su bianco (il contrasto serve per la lettura)
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: 196
                                implicitHeight: 196
                                radius: Theme.radius.normal
                                color: "white"
                                visible: Network.shareQr !== ""
                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    source: Network.shareQr ? "data:image/svg+xml;utf8," + encodeURIComponent(Network.shareQr) : ""
                                    sourceSize: Qt.size(360, 360)
                                    fillMode: Image.PreserveAspectFit
                                    smooth: false
                                }
                            }
                            StyledText {
                                visible: Network.shareBusy
                                Layout.alignment: Qt.AlignHCenter
                                text: I18n.tr("Preparo il QR code…")
                                color: Theme.textDim
                            }
                            StyledText {
                                visible: Network.shareError !== ""
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.Wrap
                                text: Network.shareError
                                color: Theme.error
                                font.pixelSize: Theme.font.small
                            }
                            // password, nascosta finché non si preme l'occhio
                            RowLayout {
                                visible: Network.sharePassword !== ""
                                Layout.fillWidth: true
                                spacing: 8
                                Icon {
                                    text: Icons.key
                                    size: 16
                                    color: Theme.primary
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: shareCard.reveal ? Network.sharePassword : "•".repeat(Math.min(16, Network.sharePassword.length))
                                    font.family: Theme.font.mono
                                    font.pixelSize: Theme.font.body
                                    elide: Text.ElideRight
                                }
                                IconButton {
                                    size: 30
                                    icon: shareCard.reveal ? Icons.eyeOff : Icons.eye
                                    iconColor: Theme.textDim
                                    onClicked: shareCard.reveal = !shareCard.reveal
                                }
                                IconButton {
                                    size: 30
                                    icon: Icons.close
                                    iconColor: Theme.textDim
                                    onClicked: Network.clearShare()
                                }
                            }
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
