import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services
import qs.modules.launcher
import qs.modules.session
import qs.modules.wallpaper
import qs.modules.settings

// Livello dei modali a schermo intero (sfondo scurito + contenuto centrato animato).
PanelWindow {
    id: win

    required property var modelData
    readonly property bool active: Ui.modal !== "" && Ui.modalScreen === modelData.name
    property string shown: ""

    screen: modelData
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: shown !== ""

    WlrLayershell.namespace: "greenshell-modal"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onActiveChanged: {
        if (active) {
            hideTimer.stop();
            shown = Ui.modal;
        } else
            hideTimer.restart();
    }
    Connections {
        target: Ui
        function onModalChanged() {
            if (win.active)
                win.shown = Ui.modal;
        }
    }
    Timer {
        id: hideTimer
        interval: Theme.anim.normal + 40
        onTriggered: win.shown = ""
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: win.active ? (win.shown === "session" ? 0.7 : 0.45) : 0
        Behavior on opacity {
            Anim {}
        }
        MouseArea {
            anchors.fill: parent
            enabled: win.active
            onClicked: Ui.closeModal()
        }
    }

    Loader {
        id: loader
        anchors.centerIn: parent
        anchors.verticalCenterOffset: win.shown === "launcher" ? -parent.height * 0.12 : 0
        focus: true
        opacity: win.active ? 1 : 0
        scale: win.active ? 1 : 0.92

        Behavior on opacity {
            Anim {}
        }
        Behavior on scale {
            Anim {
                easing.bezierCurve: win.active ? Theme.anim.expressive : Theme.anim.emphasizedAccel
            }
        }

        sourceComponent: {
            switch (win.shown) {
            case "launcher": return launcherComp;
            case "session": return sessionComp;
            case "wallpaper": return wallpaperComp;
            case "settings": return settingsComp;
            }
            return null;
        }
        Keys.onEscapePressed: Ui.closeModal()
    }

    Component { id: launcherComp; Launcher {} }
    Component { id: sessionComp; SessionMenu {} }
    Component { id: wallpaperComp; WallpaperPicker {} }
    Component { id: settingsComp; SettingsPanel {} }
}
