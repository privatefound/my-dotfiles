import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services

// Livello dei popout di un monitor. Un unico pannello che "si trasforma" fra i
// vari contenuti (dimensioni e posizione animate), agganciato al pulsante della barra.
PanelWindow {
    id: win

    required property var modelData
    readonly property string screenName: modelData.name
    readonly property bool active: Ui.popout !== "" && Ui.popoutScreen === screenName
    property string shown: ""

    screen: modelData
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    color: "transparent"
    visible: shown !== ""

    WlrLayershell.namespace: "greenshell-popout"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Solo l'area cliccabile quando è aperto; quando si chiude i click passano sotto
    mask: Region {
        item: win.active ? catcher : null
    }

    onActiveChanged: {
        if (active) {
            hideTimer.stop();
            shown = Ui.popout;
        } else {
            hideTimer.restart();
        }
    }

    Connections {
        target: Ui
        function onPopoutChanged() {
            if (win.active)
                win.shown = Ui.popout;
        }
    }

    Timer {
        id: hideTimer
        interval: Theme.anim.normal + 40
        onTriggered: win.shown = ""
    }

    MouseArea {
        id: catcher
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: Ui.closePopout()
    }

    StyledRect {
        id: panel

        readonly property Item content: loader.item
        readonly property real targetW: content ? content.implicitWidth : 0
        readonly property real targetH: content ? content.implicitHeight : 0
        readonly property real centerX: Ui.popoutX < 0 ? win.width : Ui.popoutX

        width: targetW
        height: targetH
        x: Math.max(8, Math.min(win.width - width - 8, centerX - width / 2))
        y: 6
        radius: Theme.radius.large
        color: Theme.alpha(Theme.surface, Theme.panelOpacity)
        border.width: 1
        border.color: Theme.outline
        clip: true

        opacity: win.active ? 1 : 0
        scale: win.active ? 1 : 0.94
        transformOrigin: Item.Top
        transform: Translate {
            y: win.active ? 0 : -14
            Behavior on y {
                Anim {}
            }
        }

        Behavior on opacity {
            Anim {
                duration: win.active ? Theme.anim.normal : Theme.anim.fast
            }
        }
        Behavior on scale {
            Anim {}
        }
        Behavior on x {
            enabled: win.active && panel.opacity > 0.9
            Anim {}
        }
        Behavior on width {
            enabled: win.active && panel.opacity > 0.9
            Anim {}
        }
        Behavior on height {
            enabled: win.active && panel.opacity > 0.9
            Anim {}
        }

        // blocca i click al "catcher" dietro
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        Scanlines {
            anchors.fill: parent
            strength: 0.02
        }

        Loader {
            id: loader
            focus: true
            asynchronous: false
            sourceComponent: {
                switch (win.shown) {
                case "control": return controlComp;
                case "notifications": return notifComp;
                case "calendar": return calendarComp;
                case "sysmon": return sysmonComp;
                case "tray": return trayComp;
                case "ai": return aiComp;
                case "subnet": return subnetComp;
                }
                return null;
            }
            Keys.onEscapePressed: Ui.closePopout()

            // dissolvenza del contenuto quando si passa da un popout all'altro
            onLoaded: if (item) fadeIn.restart()
            NumberAnimation {
                id: fadeIn
                target: loader.item
                property: "opacity"
                from: 0
                to: 1
                duration: Theme.anim.normal
            }
        }
    }

    Component { id: controlComp; ControlCenter { screenName: win.screenName } }
    Component { id: notifComp; NotificationCenter {} }
    Component { id: calendarComp; CalendarPanel {} }
    Component { id: sysmonComp; SysMonPanel {} }
    Component { id: trayComp; TrayMenu { item: Ui.popoutData } }
    Component { id: aiComp; AiChat {} }
    Component { id: subnetComp; SubnetCalc {} }
}
