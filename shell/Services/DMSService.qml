pragma Singleton

import QtQuick
import Quickshell

// Il backend "dms" non esiste in questa shell.
Singleton {
    readonly property bool isConnected: false

    function dbusSubscribe() {
    }
    function dbusCall() {
    }
    function dbusGetAllProperties() {
    }
}
