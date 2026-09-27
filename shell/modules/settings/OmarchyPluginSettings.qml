import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.Services as P

// Impostazioni di un plugin Omarchy, generate dallo `schema` del suo manifest
// (barWidget.schema: campi string / enum / boolean / integer / number).
// Ogni modifica è salvata subito e arriva al widget in barra senza riavvii.
ColumnLayout {
    id: root

    required property var manifest
    readonly property string pluginId: manifest.id
    readonly property var schema: manifest.barWidget?.schema ? Array.from(manifest.barWidget.schema) : []
    // si aggiorna da solo quando cambiano le impostazioni salvate
    readonly property var values: P.OmarchyPluginService.settingsFor(pluginId)

    function valueOf(field) {
        const v = values[field.key];
        return v === undefined || v === null ? field.defaultValue : v;
    }
    function set(field, value) {
        const s = {};
        s[field.key] = value;
        P.OmarchyPluginService.updateSettings(pluginId, s);
    }

    spacing: 12

    Repeater {
        model: root.schema

        delegate: ColumnLayout {
            id: row
            required property var modelData
            readonly property var field: modelData
            readonly property string type: field.type || "string"
            readonly property var current: root.valueOf(field)
            // gli enum a volte hanno valori numerici: si confrontano come testo
            readonly property var options: field.options ? Array.from(field.options).map(o => String(o)) : []

            Layout.fillWidth: true
            spacing: 4

            // i campi di testo perdono il binding quando si scrive: li riallinea (es. dopo "Ripristina")
            onCurrentChanged: {
                if (!textField.input.activeFocus)
                    textField.text = String(current ?? "");
                if (!numField.input.activeFocus)
                    numField.text = String(current ?? "");
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                StyledText {
                    Layout.fillWidth: true
                    text: row.field.label || row.field.key
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                // on/off
                Toggle {
                    visible: row.type === "boolean"
                    checked: row.current === true || row.current === "true"
                    onToggled: v => root.set(row.field, v)
                }

                // numeri: − valore +
                RowLayout {
                    visible: row.type === "integer" || row.type === "number"
                    spacing: 2

                    readonly property real step: Number(row.field.step) || 1
                    function clamp(v) {
                        if (row.field.min !== undefined)
                            v = Math.max(Number(row.field.min), v);
                        if (row.field.max !== undefined)
                            v = Math.min(Number(row.field.max), v);
                        return row.type === "integer" ? Math.round(v) : Math.round(v * 1000) / 1000;
                    }

                    IconButton {
                        size: 30
                        icon: Icons.minus
                        onClicked: root.set(row.field, parent.clamp(Number(row.current) - parent.step))
                    }
                    TextField {
                        id: numField
                        implicitWidth: 84
                        text: String(row.current ?? "")
                        input.horizontalAlignment: TextInput.AlignHCenter
                        onAccepted: {
                            const n = Number(text);
                            if (!isNaN(n))
                                root.set(row.field, parent.clamp(n));
                        }
                    }
                    IconButton {
                        size: 30
                        icon: Icons.plus
                        onClicked: root.set(row.field, parent.clamp(Number(row.current) + parent.step))
                    }
                }
            }

            // scelte
            Flow {
                visible: row.type === "enum"
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: row.options
                    delegate: StyledButton {
                        required property string modelData
                        implicitHeight: 28
                        padding: 10
                        variant: String(row.current) === modelData ? "filled" : "tonal"
                        text: modelData
                        // mantiene il tipo originale (numero se lo schema usa numeri)
                        onClicked: root.set(row.field, typeof row.field.defaultValue === "number" ? Number(modelData) : modelData)
                    }
                }
            }

            // testo (salvato con Invio o uscendo dal campo)
            TextField {
                id: textField
                visible: row.type !== "boolean" && row.type !== "enum" && row.type !== "integer" && row.type !== "number"
                Layout.fillWidth: true
                text: String(row.current ?? "")
                placeholder: String(row.field.defaultValue ?? "")
                onAccepted: root.set(row.field, text)
                Connections {
                    target: textField.input
                    function onActiveFocusChanged() {
                        if (!textField.input.activeFocus && textField.visible && textField.text !== String(row.current ?? ""))
                            root.set(row.field, textField.text);
                    }
                }
            }

            StyledText {
                visible: !!row.field.description
                Layout.fillWidth: true
                text: row.field.description || ""
                wrapMode: Text.Wrap
                font.pixelSize: Theme.font.small
                color: Theme.textDim
            }
        }
    }

    StyledButton {
        Layout.alignment: Qt.AlignRight
        variant: "text"
        icon: Icons.refresh
        text: I18n.tr("Ripristina predefiniti")
        onClicked: P.OmarchyPluginService.resetSettings(root.pluginId)
    }
}
