import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

// CPU / RAM / temperatura. Click = monitor di sistema, click destro = Mission Center.
BarButton {
    id: root

    required property string screenName

    visible: Settings.showSysStats
    active: Ui.popout === "sysmon" && Ui.popoutScreen === screenName
    spacing: 10
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            Session.sysMonitor();
        else
            Ui.togglePopout("sysmon", screenName, centerX());
    }

    component Stat: RowLayout {
        property string icon
        property string value
        property color tint: Theme.primary
        spacing: 4
        Icon {
            text: parent.icon
            size: 15
            color: parent.tint
        }
        StyledText {
            text: parent.value
            font.family: Theme.font.mono
            font.pixelSize: Theme.font.small
            color: Theme.text
        }
    }

    Stat {
        icon: Icons.chip
        value: Math.round(SysStats.cpu * 100).toString().padStart(2, " ") + "%"
        tint: SysStats.cpu > 0.85 ? Theme.error : Theme.primary
    }
    Stat {
        icon: Icons.memory
        value: Math.round(SysStats.mem * 100) + "%"
        tint: SysStats.mem > 0.9 ? Theme.error : Theme.primaryDim
    }
    Stat {
        visible: SysStats.cpuTemp > 0
        icon: Icons.thermometer
        value: Math.round(SysStats.cpuTemp) + "°"
        tint: SysStats.cpuTemp > 85 ? Theme.error : SysStats.cpuTemp > 70 ? Theme.warning : Theme.textDim
    }
}
