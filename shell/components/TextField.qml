import QtQuick
import QtQuick.Layouts
import qs.config

// Campo di testo con icona, placeholder, pulsante per mostrare la password.
StyledRect {
    id: root

    property alias text: input.text
    property alias input: input
    property string placeholder
    property string icon
    property bool password: false
    property bool revealed: false
    property bool error: false

    signal accepted
    signal escapePressed

    implicitHeight: 44
    implicitWidth: 260
    radius: Theme.radius.full
    color: Theme.surfaceContainerHighest
    border.width: input.activeFocus ? 2 : 1
    border.color: error ? Theme.error : input.activeFocus ? Theme.primary : Theme.outlineVariant

    function focusInput() {
        input.forceActiveFocus();
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 8
        spacing: 10

        Icon {
            visible: root.icon !== ""
            text: root.icon
            size: 18
            color: input.activeFocus ? Theme.primary : Theme.textDim
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            TextInput {
                id: input
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.text
                selectionColor: Theme.alpha(Theme.primary, 0.35)
                selectedTextColor: Theme.text
                font.family: Theme.font.sans
                font.pixelSize: Theme.font.body
                clip: true
                echoMode: root.password && !root.revealed ? TextInput.Password : TextInput.Normal
                passwordCharacter: "•"
                onAccepted: root.accepted()
                Keys.onEscapePressed: root.escapePressed()
            }

            StyledText {
                anchors.fill: parent
                visible: input.text.length === 0
                text: root.placeholder
                color: Theme.textFaint
            }
        }

        IconButton {
            visible: root.password
            size: 30
            icon: root.revealed ? Icons.eyeOff : Icons.eye
            iconColor: Theme.textDim
            onClicked: root.revealed = !root.revealed
        }

        IconButton {
            visible: !root.password && input.text.length > 0
            size: 30
            icon: Icons.close
            iconColor: Theme.textDim
            onClicked: input.text = ""
        }
    }
}
