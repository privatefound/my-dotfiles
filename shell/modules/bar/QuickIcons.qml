import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

// Toggle rapidi della vecchia barra: caffeine, widget sul desktop, trasparenza, cast/monitor.
RowLayout {
    id: root

    spacing: 0

    IconButton {
        size: Theme.barHeight - 12
        icon: Settings.caffeine ? Icons.coffee : Icons.coffeeOutline
        iconColor: Settings.caffeine ? Theme.primary : Theme.textDim
        onClicked: Settings.caffeine = !Settings.caffeine
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
