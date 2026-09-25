pragma Singleton

import QtQuick
import Quickshell

// Visualizzatore audio non disponibile nella shell.
Singleton {
    readonly property bool cavaAvailable: false
    property var values: []
}
