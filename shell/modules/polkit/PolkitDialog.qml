import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import qs.config
import qs.components
import qs.services

// Agente polkit integrato: finestra per l'autenticazione da amministratore.
Scope {
    id: root

    PolkitAgent {
        id: agent
    }

    readonly property var flow: agent.flow

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            readonly property bool active: agent.isActive && root.flow !== null && modelData.name === Ui.focusedScreen

            screen: modelData
            visible: active
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            WlrLayershell.namespace: "greenshell-polkit"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            onActiveChanged: if (active) pw.focusInput()

            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: 0.55
            }

            StyledRect {
                anchors.centerIn: parent
                implicitWidth: 460
                implicitHeight: col.implicitHeight + 48
                radius: Theme.radius.xl
                color: Theme.alpha(Theme.surface, 0.97)
                border.width: 1
                border.color: Theme.outline

                ColumnLayout {
                    id: col
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 14

                    StyledRect {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 64
                        implicitHeight: 64
                        radius: 20
                        color: Theme.primaryContainer
                        Icon {
                            anchors.centerIn: parent
                            text: Icons.shieldKey
                            size: 34
                            color: Theme.primary
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: I18n.tr("Autenticazione richiesta")
                        font.pixelSize: Theme.font.large
                        font.weight: Font.Bold
                    }

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: root.flow?.message ?? ""
                        wrapMode: Text.Wrap
                        color: Theme.textDim
                    }

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        visible: (root.flow?.selectedIdentity?.displayName ?? "") !== ""
                        text: I18n.tr("come ") + (root.flow?.selectedIdentity?.displayName ?? "")
                        font.family: Theme.font.mono
                        font.pixelSize: Theme.font.small
                        color: Theme.primary
                    }

                    TextField {
                        id: pw
                        Layout.fillWidth: true
                        icon: Icons.key
                        password: !(root.flow?.responseVisible ?? false)
                        placeholder: (root.flow?.inputPrompt || I18n.tr("Password")).replace(/:\s*$/, "")
                        error: root.flow?.failed ?? false
                        onAccepted: {
                            root.flow.submit(text);
                            text = "";
                        }
                        onEscapePressed: root.flow.cancelAuthenticationRequest()
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: text !== ""
                        horizontalAlignment: Text.AlignHCenter
                        text: root.flow?.failed ? I18n.tr("Password errata, riprova") : (root.flow?.supplementaryMessage ?? "")
                        color: root.flow?.failed || root.flow?.supplementaryIsError ? Theme.error : Theme.textDim
                        font.pixelSize: Theme.font.small
                        wrapMode: Text.Wrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        StyledButton {
                            Layout.fillWidth: true
                            variant: "outline"
                            text: I18n.tr("Annulla")
                            onClicked: root.flow.cancelAuthenticationRequest()
                        }
                        StyledButton {
                            Layout.fillWidth: true
                            variant: "filled"
                            icon: Icons.lockOpen
                            text: I18n.tr("Autentica")
                            onClicked: {
                                root.flow.submit(pw.text);
                                pw.text = "";
                            }
                        }
                    }
                }
            }
        }
    }
}
