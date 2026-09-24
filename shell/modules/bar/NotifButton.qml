import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

// Campanella: click = centro notifiche, click destro = Non disturbare.
BarButton {
    id: root

    required property string screenName

    active: Ui.popout === "notifications" && Ui.popoutScreen === screenName
    padding: 8
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            Notifs.toggleDnd();
        else
            Ui.togglePopout("notifications", screenName, centerX());
    }

    Icon {
        text: Settings.dnd ? Icons.bellOff : Notifs.count > 0 ? Icons.bellBadge : Icons.bellOutline
        size: 17
        color: Settings.dnd ? Theme.textFaint : Notifs.count > 0 ? Theme.primary : Theme.textDim
    }

    StyledText {
        visible: Notifs.count > 0 && !Settings.dnd
        text: Notifs.count
        font.family: Theme.font.mono
        font.pixelSize: Theme.font.small
        font.weight: Font.Bold
        color: Theme.primary
    }
}
