import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.config
import qs.components
import qs.services

// Impegni: lista a sinistra, dettaglio del selezionato a destra.
Item {
    id: root

    property string sel: (Tasks.sorted.find(t => !t.done) ?? Tasks.sorted[0])?.id ?? ""
    readonly property var task: Tasks.get(sel)

    implicitWidth: 500
    implicitHeight: 340

    // i campi non sono legati al modello (ogni salvataggio sposterebbe il cursore): si caricano al cambio di selezione
    // (legge Tasks.get(sel): in onSelChanged `task` può essere ancora quello vecchio)
    property bool loading: false
    function load() {
        const t = Tasks.get(sel);
        loading = true;
        titleIn.text = t?.title ?? "";
        descIn.text = t?.desc ?? "";
        dateIn.text = "";
        loading = false;
    }
    onSelChanged: load()
    Component.onCompleted: load()

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // ── Lista ──
        ColumnLayout {
            Layout.preferredWidth: 200
            Layout.maximumWidth: 200
            Layout.fillWidth: false
            Layout.fillHeight: true
            spacing: 6

            RowLayout {
                spacing: 6
                Icon {
                    text: Icons.formatListChecks
                    size: 16
                    color: Theme.primary
                }
                StyledText {
                    Layout.fillWidth: true
                    text: I18n.tr("Impegni") + (Tasks.pending ? "  ·  " + Tasks.pending : "")
                    font.weight: Font.DemiBold
                }
            }

            TextField {
                id: newIn
                Layout.fillWidth: true
                implicitHeight: 32
                placeholder: I18n.tr("Nuovo impegno…")
                onAccepted: {
                    const id = Tasks.add(text);
                    if (id) {
                        text = "";
                        root.sel = id;
                    }
                }
            }

            ScrollColumn {
                Layout.fillHeight: true
                maxHeight: 400
                spacing: 3

                Repeater {
                    model: Tasks.sorted

                    delegate: StyledRect {
                        id: row
                        required property var modelData
                        readonly property bool selected: modelData.id === root.sel
                        readonly property color prioColor: Tasks.priorities[modelData.prio].color

                        Layout.fillWidth: true
                        implicitHeight: 30
                        radius: Theme.radius.small
                        color: selected ? Theme.primaryContainer : Theme.surfaceContainerHigh
                        opacity: modelData.done ? 0.5 : 1

                        Rectangle {
                            width: 3
                            height: parent.height - 10
                            anchors.left: parent.left
                            anchors.leftMargin: 3
                            anchors.verticalCenter: parent.verticalCenter
                            radius: 2
                            color: row.prioColor
                        }

                        StateLayer {
                            onClicked: root.sel = row.modelData.id
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 6

                            IconButton {
                                size: 22
                                icon: row.modelData.done ? Icons.checkboxMarked : Icons.checkboxBlank
                                iconColor: row.modelData.done ? Theme.primary : Theme.textDim
                                onClicked: Tasks.toggle(row.modelData.id)
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: row.modelData.title
                                elide: Text.ElideRight
                                font.pixelSize: Theme.font.small
                                font.strikeout: row.modelData.done
                            }
                            StyledText {
                                visible: !!row.modelData.due && !row.modelData.done
                                text: Tasks.dueLabel(row.modelData.due)
                                font.pixelSize: Theme.font.tiny
                                color: Tasks.isOverdue(row.modelData) || row.modelData.due === Tasks.today() ? Theme.error : Theme.textDim
                            }
                        }
                    }
                }
            }

            StyledText {
                visible: Tasks.sorted.length === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: I18n.tr("Nessun impegno")
                color: Theme.textFaint
                font.pixelSize: Theme.font.small
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // ── Dettaglio ──
        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.radius.normal
            color: Theme.surfaceContainer

            StyledText {
                anchors.centerIn: parent
                visible: !root.task
                text: I18n.tr("Seleziona un impegno")
                color: Theme.textFaint
                font.pixelSize: Theme.font.small
            }

            ColumnLayout {
                visible: !!root.task
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                RowLayout {
                    spacing: 4
                    TextInput {
                        id: titleIn
                        Layout.fillWidth: true
                        color: Theme.text
                        font.family: Theme.font.sans
                        font.pixelSize: Theme.font.body
                        font.weight: Font.DemiBold
                        selectionColor: Theme.alpha(Theme.primary, 0.35)
                        clip: true
                        onTextEdited: if (text.trim()) Tasks.update(root.sel, { title: text })
                    }
                    IconButton {
                        size: 24
                        icon: Icons.trash
                        iconColor: Theme.error
                        onClicked: {
                            Tasks.remove(root.sel);
                            root.sel = (Tasks.sorted.find(t => !t.done) ?? Tasks.sorted[0])?.id ?? "";
                        }
                    }
                }

                // priorità
                RowLayout {
                    spacing: 4
                    Repeater {
                        model: Tasks.priorities
                        delegate: StyledRect {
                            id: chip
                            required property var modelData
                            required property int index
                            readonly property bool on: root.task?.prio === index
                            implicitHeight: 20
                            implicitWidth: chipText.implicitWidth + 14
                            radius: 10
                            color: on ? Theme.alpha(modelData.color, 0.2) : "transparent"
                            border.width: 1
                            border.color: on ? modelData.color : Theme.outlineVariant
                            StyledText {
                                id: chipText
                                anchors.centerIn: parent
                                text: I18n.tr(chip.modelData.label)
                                font.pixelSize: Theme.font.tiny
                                color: chip.on ? chip.modelData.color : Theme.textDim
                            }
                            StateLayer {
                                tint: chip.modelData.color
                                onClicked: Tasks.update(root.sel, { prio: chip.index })
                            }
                        }
                    }
                }

                // scadenza
                RowLayout {
                    spacing: 4
                    Icon {
                        text: Icons.calendar
                        size: 13
                        color: root.task && Tasks.isOverdue(root.task) ? Theme.error : Theme.textDim
                    }
                    Repeater {
                        model: [{ l: "Oggi", d: 0 }, { l: "Domani", d: 1 }, { l: "+7", d: 7 }]
                        delegate: StyledRect {
                            id: dchip
                            required property var modelData
                            readonly property bool on: root.task?.due === Tasks.dueIn(modelData.d)
                            implicitHeight: 20
                            implicitWidth: dText.implicitWidth + 12
                            radius: 10
                            color: on ? Theme.primaryFill : "transparent"
                            border.width: 1
                            border.color: on ? Theme.primary : Theme.outlineVariant
                            StyledText {
                                id: dText
                                anchors.centerIn: parent
                                text: I18n.tr(dchip.modelData.l)
                                font.pixelSize: Theme.font.tiny
                                color: dchip.on ? Theme.primary : Theme.textDim
                            }
                            StateLayer {
                                onClicked: Tasks.update(root.sel, { due: dchip.on ? "" : Tasks.dueIn(dchip.modelData.d) })
                            }
                        }
                    }
                    // data libera: gg/mm[/aaaa] + Invio
                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: 20
                        radius: 10
                        color: "transparent"
                        border.width: 1
                        border.color: dateIn.activeFocus ? Theme.primary : Theme.outlineVariant
                        TextInput {
                            id: dateIn
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.text
                            font.pixelSize: Theme.font.tiny
                            clip: true
                            onAccepted: {
                                const d = Tasks.parseDate(text);
                                if (d || !text.trim()) {
                                    Tasks.update(root.sel, { due: d });
                                    text = "";
                                    focus = false;
                                }
                            }
                        }
                        StyledText {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            visible: !dateIn.text && !dateIn.activeFocus
                            text: root.task?.due ? Tasks.dueLabel(root.task.due) : "gg/mm"
                            font.pixelSize: Theme.font.tiny
                            color: root.task && Tasks.isOverdue(root.task) ? Theme.error : root.task?.due ? Theme.text : Theme.textFaint
                        }
                    }
                }

                // descrizione (Ctrl+V incolla anche uno screenshot)
                StyledRect {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radius.small
                    color: Theme.surfaceContainerHigh
                    border.width: 1
                    border.color: descIn.activeFocus ? Theme.alpha(Theme.primary, 0.6) : "transparent"

                    Flickable {
                        id: descFlick
                        anchors.fill: parent
                        anchors.margins: 8
                        contentHeight: descIn.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: StyledScrollBar {}

                        TextEdit {
                            id: descIn
                            width: descFlick.width
                            height: Math.max(implicitHeight, descFlick.height)   // click ovunque nel riquadro
                            wrapMode: TextEdit.Wrap
                            color: Theme.text
                            font.family: Theme.font.sans
                            font.pixelSize: Theme.font.small
                            selectionColor: Theme.alpha(Theme.primary, 0.35)
                            onTextChanged: if (activeFocus && !root.loading) Tasks.update(root.sel, { desc: text })
                            onCursorRectangleChanged: {
                                if (cursorRectangle.y + cursorRectangle.height > descFlick.contentY + descFlick.height)
                                    descFlick.contentY = cursorRectangle.y + cursorRectangle.height - descFlick.height;
                                else if (cursorRectangle.y < descFlick.contentY)
                                    descFlick.contentY = cursorRectangle.y;
                            }
                            Keys.onPressed: event => {
                                if (event.matches(StandardKey.Paste))
                                    Tasks.pasteImage(root.sel);   // il testo viene incollato comunque
                            }
                        }
                    }
                    StyledText {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: 8
                        visible: !descIn.text && !descIn.activeFocus
                        text: I18n.tr("Descrizione · Ctrl+V incolla uno screenshot")
                        font.pixelSize: Theme.font.small
                        color: Theme.textFaint
                    }
                }

                // screenshot: click apre, click destro rimuove
                Flow {
                    visible: (root.task?.images.length ?? 0) > 0
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: root.task?.images ?? []
                        delegate: StyledRect {
                            id: thumb
                            required property string modelData
                            readonly property string path: Tasks.imageDir + "/" + modelData
                            implicitWidth: 64
                            implicitHeight: 40
                            radius: Theme.radius.xs
                            color: Theme.surfaceContainerHighest
                            clip: true
                            Image {
                                anchors.fill: parent
                                source: "file://" + thumb.path
                                fillMode: Image.PreserveAspectCrop
                                sourceSize: Qt.size(128, 80)
                                asynchronous: true
                            }
                            StateLayer {
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => mouse.button === Qt.RightButton ? Tasks.removeImage(root.sel, thumb.modelData) : Quickshell.execDetached(["xdg-open", thumb.path])
                            }
                        }
                    }
                }
            }
        }
    }
}
