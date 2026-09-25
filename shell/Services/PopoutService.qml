pragma Singleton

import QtQuick
import Quickshell
import qs.services as S

// Aperture di finestre DMS richieste dai plugin, mappate sulla shell.
Singleton {
    property var settingsModal: null
    property var colorPickerModal: null

    function openSettingsWithTab(tab) {
        S.Ui.settingsSection = "plugins";
        S.Ui.openModal("settings");
    }
    function closeControlCenter() {
        S.Ui.closePopout();
    }
}
