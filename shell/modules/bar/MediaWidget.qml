import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

// Mini player: click = popout media, click destro = play/pausa, rotella = brano succ./prec.
BarButton {
    id: root

    required property string screenName

    visible: Settings.showMedia && Media.hasPlayer && Media.active?.trackTitle
    active: Ui.popout === "calendar" && Ui.popoutScreen === screenName
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton)
            Media.toggle();
        else
            Ui.togglePopout("calendar", screenName, centerX());
    }
    onWheel: wheel => wheel.angleDelta.y > 0 ? Media.previous() : Media.next()

    // Equalizzatore animato
    Row {
        spacing: 2
        Layout.alignment: Qt.AlignVCenter
        Repeater {
            model: 3
            Rectangle {
                required property int index
                width: 3
                radius: 1.5
                anchors.bottom: parent.bottom
                color: Theme.primary
                height: Media.playing ? 5 : 4
                SequentialAnimation on height {
                    running: Media.playing && Settings.animations
                    loops: Animation.Infinite
                    NumberAnimation { to: 12; duration: 280 + index * 90; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 4; duration: 320 + index * 70; easing.type: Easing.InOutSine }
                }
            }
        }
        height: 12
    }

    StyledText {
        Layout.maximumWidth: 220
        text: Media.title + (Media.artist ? "  ·  " + Media.artist : "")
        color: Media.playing ? Theme.text : Theme.textDim
        font.pixelSize: Theme.font.small
    }
}
