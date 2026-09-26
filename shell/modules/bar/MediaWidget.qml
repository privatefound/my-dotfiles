import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

// Mini player: click = pannello musica, click destro = play/pausa, rotella = brano succ./prec.
BarButton {
    id: root

    required property string screenName

    visible: Settings.showMedia && Media.hasPlayer && Media.active?.trackTitle
    active: Ui.popout === "media" && Ui.popoutScreen === screenName
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton)
            Media.toggle();
        else
            Ui.togglePopout("media", screenName, centerX());
    }
    onWheel: wheel => wheel.angleDelta.y > 0 ? Media.previous() : Media.next()

    // Equalizzatore: barre aggiornate 6 volte al secondo (non a ogni fotogramma),
    // ferme quando il lettore non è visibile o in pausa: consumo trascurabile.
    Row {
        id: eq
        property var levels: [5, 9, 6]
        spacing: 2
        height: 12
        Layout.alignment: Qt.AlignVCenter
        Repeater {
            model: 3
            Rectangle {
                required property int index
                width: 3
                radius: 1.5
                anchors.bottom: parent.bottom
                color: Theme.primary
                height: Media.playing ? eq.levels[index] : 4
            }
        }
        Timer {
            interval: 160
            repeat: true
            running: Media.playing && Settings.animations && root.visible
            onTriggered: eq.levels = [4 + Math.random() * 8, 4 + Math.random() * 8, 4 + Math.random() * 8]
        }
    }

    StyledText {
        Layout.maximumWidth: 220
        text: Media.title + (Media.artist ? "  ·  " + Media.artist : "")
        color: Media.playing ? Theme.text : Theme.textDim
        font.pixelSize: Theme.font.small
    }
}
