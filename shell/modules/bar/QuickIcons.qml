import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

// Toggle rapidi della vecchia barra: caffeine, impegni, widget sul desktop, trasparenza, cast/monitor.
RowLayout {
    id: root

    property string screenName

    spacing: 0

    IconButton {
        size: Theme.barHeight - 12
        icon: Settings.caffeine ? Icons.coffee : Icons.coffeeOutline
        iconColor: Settings.caffeine ? Theme.primary : Theme.textDim
        onClicked: Settings.caffeine = !Settings.caffeine
    }

    // Impegni: numero da fare in alto a destra, rosso se qualcuno è scaduto
    IconButton {
        size: Theme.barHeight - 12
        icon: Icons.formatListChecks
        toggled: Ui.popout === "tasks" && Ui.popoutScreen === root.screenName
        iconColor: Tasks.overdue ? Theme.error : toggled || Tasks.pending ? Theme.primary : Theme.textDim
        onClicked: Ui.togglePopout("tasks", root.screenName, mapToItem(null, width / 2, 0).x)

        StyledText {
            visible: Tasks.pending > 0
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 1
            text: Tasks.pending
            font.pixelSize: Theme.font.tiny
            font.weight: Font.Bold
            color: Tasks.overdue ? Theme.error : Theme.primary
        }
    }

    // Widget di sistema sul desktop (accende/spegne, come in Impostazioni → Aspetto)
    IconButton {
        size: Theme.barHeight - 12
        icon: Icons.gauge
        iconColor: Settings.desktopWidget ? Theme.primary : Theme.textDim
        onClicked: Settings.desktopWidget = !Settings.desktopWidget
    }

    IconButton {
        size: Theme.barHeight - 12
        icon: Settings.windowTransparency ? Icons.opacity : Icons.eye
        iconColor: Settings.windowTransparency ? Theme.textDim : Theme.primary
        onClicked: Settings.windowTransparency = !Settings.windowTransparency
    }

    // Sinistro: gnome-network-displays · Destro: monique
    IconButton {
        size: Theme.barHeight - 12
        icon: Icons.cast
        iconColor: Theme.textDim
        onClicked: mouse => mouse.button === Qt.RightButton ? Session.monitors() : Session.castScreen()
    }
}
