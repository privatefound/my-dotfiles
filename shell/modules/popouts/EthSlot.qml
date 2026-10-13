import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

// Una scheda ethernet nel pannello rete (expansion card, docking station…) con i profili
// applicabili proprio a quella scheda.
StyledRect {
    id: slot
    property string label
    property string icon: Icons.ethernet
    property var iface: null                 // null = scheda non collegata
    readonly property bool present: iface !== null
    readonly property bool plugged: present && !iface.state.startsWith("unavailable")
    readonly property bool up: present && iface.state.startsWith("connected")
    readonly property string active: up && iface.connection !== "--" ? iface.connection : ""

    Layout.fillWidth: true
    implicitHeight: slotCol.implicitHeight + 20
    radius: Theme.radius.normal
    color: up ? Theme.primaryContainer : Theme.surfaceContainerHigh
    border.width: up ? 1 : 0
    border.color: Theme.alpha(Theme.primary, 0.45)
    opacity: present ? 1 : 0.55

    ColumnLayout {
        id: slotCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Icon {
                text: slot.up ? Icons.lanConnect : slot.plugged ? slot.icon : Icons.lanDisconnect
                size: 20
                color: slot.up ? Theme.primary : Theme.textDim
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                RowLayout {
                    spacing: 8
                    StyledText {
                        text: slot.label
                        font.weight: Font.DemiBold
                        color: slot.up ? Theme.fgPrimaryContainer : Theme.text
                    }
                    // pallino: verde pieno = scheda inserita nel PC (USB‑C), vuoto = non inserita
                    Rectangle {
                        implicitWidth: 8
                        implicitHeight: 8
                        radius: 4
                        color: slot.present ? Theme.success : "transparent"
                        border.width: slot.present ? 0 : 1
                        border.color: Theme.textFaint
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    font.pixelSize: Theme.font.small
                    font.family: Theme.font.mono
                    color: Theme.textDim
                    text: !slot.present ? I18n.tr("non collegata")
                        : !slot.plugged ? slot.iface.device + "  ·  " + I18n.tr("cavo scollegato")
                        : slot.up ? slot.iface.device + "  ·  " + (slot.iface.ip || I18n.tr("nessun IP")) + (slot.iface.isDefault ? "  ·  " + I18n.tr("predefinita") : "")
                        : slot.iface.device + "  ·  " + I18n.tr("non connessa")
                }
            }
            IconButton {
                visible: slot.up
                size: 30
                icon: Icons.close
                iconColor: Theme.textDim
                onClicked: Network.disconnectInterface(slot.iface)
            }
        }

        // un bottone per profilo: quello attivo su questa scheda è evidenziato
        Flow {
            visible: slot.present
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: Network.ethProfiles
                delegate: StyledButton {
                    required property var modelData
                    readonly property bool on: slot.active === modelData.name
                    implicitHeight: 30
                    padding: 12
                    disabled: !slot.plugged || Network.nmBusy
                    variant: on ? "filled" : "tonal"
                    text: modelData.name.replace(/^Ethernet\s+/i, "")
                    onClicked: on ? Network.disconnectInterface(slot.iface) : Network.applyProfile(slot.iface, modelData)
                }
            }
        }
    }
}
