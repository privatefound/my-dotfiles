import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

BarButton {
    id: root

    required property string screenName

    active: Ui.popout === "calendar" && Ui.popoutScreen === screenName
    padding: 14
    spacing: 10
    onClicked: Ui.togglePopout("calendar", screenName, centerX())

    StyledText {
        visible: Settings.showDate
        text: Time.dateShort
        color: Theme.textDim
        font.pixelSize: Theme.font.small
        font.capitalization: Font.Capitalize
    }

    StyledText {
        text: Time.time
        color: Theme.primary
        font.family: Theme.font.mono
        font.pixelSize: Theme.font.body + 1
        font.weight: Font.Bold
    }
}
