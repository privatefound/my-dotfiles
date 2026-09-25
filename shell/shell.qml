//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark
//@ pragma Env QS_NO_RELOAD_POPUP=1

import Quickshell
import QtQuick
import qs.modules
import qs.modules.bar
import qs.modules.popouts
import qs.modules.modals
import qs.modules.notifications
import qs.modules.osd
import qs.modules.polkit

ShellRoot {
    // Barra su ogni monitor
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    // Popout agganciati alla barra
    Variants {
        model: Quickshell.screens
        Popouts {}
    }

    // Popup notifiche
    Variants {
        model: Quickshell.screens
        NotificationPopups {}
    }

    // OSD volume / luminosità
    Variants {
        model: Quickshell.screens
        Osd {}
    }

    // Launcher, sessione, sfondi, impostazioni
    Variants {
        model: Quickshell.screens
        Modals {}
    }

    PolkitDialog {}

    Shortcuts {}

    // Plugin DankMaterialShell (Impostazioni → Plugin)
    PluginHost {}
}
