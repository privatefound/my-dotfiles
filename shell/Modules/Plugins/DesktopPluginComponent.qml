import QtQuick

// I widget da desktop dei plugin DMS non sono ancora supportati dalla shell.
Item {
    property string pluginId: ""
    property var pluginService: null
    property var pluginData: ({})
    property real minWidth: 0
    property real minHeight: 0
}
