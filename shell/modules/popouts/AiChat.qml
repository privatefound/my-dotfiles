import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.config
import qs.components
import qs.services

// Chat con Morpheus (Ollama / llama.cpp). Click destro sull'icona nella barra = pulisci chat.
Item {
    id: root

    property bool modelMenu: false

    implicitWidth: 600
    implicitHeight: 560

    Component.onCompleted: {
        Ai.refreshModels();
        input.focusInput();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // ── Intestazione ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Image {
                source: Quickshell.shellPath("assets/icons/morpheus.svg")
                sourceSize: Qt.size(34, 34)
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
            }
            ColumnLayout {
                spacing: 0
                StyledText {
                    text: "Morpheus"
                    font.pixelSize: Theme.font.title
                    font.weight: Font.Bold
                    color: Theme.primary
                }
                StyledText {
                    text: Ai.busy ? "sta scrivendo…" : "IA locale"
                    font.pixelSize: Theme.font.tiny
                    color: Theme.textDim
                }
            }
            Item {
                Layout.fillWidth: true
            }

            // Selettore modello
            StyledButton {
                implicitHeight: 32
                padding: 12
                variant: "outline"
                icon: Icons.robot
                text: Ai.modelLabel
                onClicked: root.modelMenu = !root.modelMenu
            }
            IconButton {
                icon: Icons.trash
                iconColor: Theme.textDim
                onClicked: Ai.clear()
            }
        }

        // ── Messaggi ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: list
                anchors.fill: parent
                clip: true
                spacing: 12
                model: Ai.messages
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: StyledScrollBar {}
                onCountChanged: Qt.callLater(() => list.positionViewAtEnd())

                delegate: Item {
                    id: msg
                    required property string role
                    required property string content
                    required property int index
                    readonly property bool mine: role === "user"

                    width: list.width - 10
                    implicitHeight: bubble.implicitHeight

                    onContentChanged: if (index === list.count - 1) Qt.callLater(() => list.positionViewAtEnd())

                    StyledRect {
                        id: bubble
                        anchors.right: msg.mine ? parent.right : undefined
                        anchors.left: msg.mine ? undefined : parent.left
                        width: Math.min(parent.width * (msg.mine ? 0.8 : 0.95), textItem.implicitWidth + 28)
                        implicitHeight: textItem.implicitHeight + 22
                        radius: Theme.radius.large
                        color: msg.mine ? Theme.primaryContainer : Theme.surfaceContainer

                        TextEdit {
                            id: textItem
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 11
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            readOnly: true
                            selectByMouse: true
                            wrapMode: TextEdit.Wrap
                            textFormat: msg.mine ? TextEdit.PlainText : TextEdit.RichText
                            text: msg.mine ? msg.content : (msg.content === "" ? "▍" : Ai.markdown(msg.content))
                            color: msg.mine ? Theme.fgPrimaryContainer : Theme.text
                            selectionColor: Theme.alpha(Theme.primary, 0.35)
                            font.family: Theme.font.sans
                            font.pixelSize: Theme.font.body
                            onLinkActivated: link => Qt.openUrlExternally(link)
                        }

                        IconButton {
                            visible: !msg.mine && msg.content !== ""
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 4
                            size: 26
                            icon: Icons.copy
                            iconColor: Theme.textFaint
                            opacity: hov.hovered ? 1 : 0
                            onClicked: Quickshell.clipboardText = msg.content
                        }
                        HoverHandler {
                            id: hov
                        }
                    }
                }
            }

            // Stato vuoto
            ColumnLayout {
                anchors.centerIn: parent
                visible: Ai.messages.count === 0
                spacing: 8
                Image {
                    Layout.alignment: Qt.AlignHCenter
                    source: Quickshell.shellPath("assets/icons/morpheus.svg")
                    sourceSize: Qt.size(84, 84)
                    opacity: 0.8
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Benvenuto nel deserto del reale, Operatore."
                    color: Theme.textDim
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Fai una domanda. Enter per inviare."
                    font.pixelSize: Theme.font.small
                    color: Theme.textFaint
                }
            }

            // Menu modelli
            StyledRect {
                visible: root.modelMenu
                anchors.right: parent.right
                anchors.top: parent.top
                width: 300
                implicitHeight: Math.min(modelCol.implicitHeight + 12, 300)
                radius: Theme.radius.normal
                color: Theme.surfaceContainerHigh
                border.width: 1
                border.color: Theme.outline
                z: 10

                ScrollColumn {
                    anchors.fill: parent
                    anchors.margins: 6
                    maxHeight: 288
                    ColumnLayout {
                        id: modelCol
                        Layout.fillWidth: true
                        spacing: 2
                        Repeater {
                            model: Ai.models
                            delegate: ListRow {
                                required property var modelData
                                icon: Icons.robot
                                title: modelData.label
                                highlighted: modelData.id === Settings.aiModel && modelData.backend === Settings.aiBackend
                                onClicked: {
                                    Ai.selectModel(modelData);
                                    root.modelMenu = false;
                                }
                            }
                        }
                        StyledText {
                            visible: Ai.models.length === 0
                            Layout.margins: 10
                            text: "Nessun modello trovato (Ollama / llama.cpp spenti?)"
                            color: Theme.textFaint
                            font.pixelSize: Theme.font.small
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }

        StyledText {
            visible: Ai.error !== ""
            Layout.fillWidth: true
            text: Ai.error
            color: Theme.error
            font.pixelSize: Theme.font.small
        }

        // ── Input ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            TextField {
                id: input
                Layout.fillWidth: true
                icon: Icons.sparkle
                placeholder: "Scrivi a Morpheus…"
                onAccepted: {
                    Ai.send(text);
                    text = "";
                }
            }
            IconButton {
                size: 44
                icon: Ai.busy ? Icons.stop : Icons.send
                toggled: true
                background: Ai.busy ? Theme.errorContainer : Theme.primaryFill
                iconColor: Ai.busy ? Theme.error : Theme.primary
                onClicked: {
                    if (Ai.busy)
                        Ai.stop();
                    else {
                        Ai.send(input.text);
                        input.text = "";
                    }
                }
            }
        }
    }
}
