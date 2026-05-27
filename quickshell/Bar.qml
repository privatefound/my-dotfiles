import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    property color colBg: "#000000"
    property color colBgAlt: "#0a0a0a"
    property color colFg: "#00ff41"
    property color colFgDim: "#008f11"
    property color colAccent: "#00ff41"
    property color colAlert: "#ff0000"
    property color colMuted: "#1a1a1a"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 13
    property int barHeight: 32

    property int volTick: 0
    property int netTick: 0
    property bool showDismiss: false

    SystemData { id: sysData }

    // ── Power processes at Scope level ──
    Process { id: sysMonProc; command: ["missioncenter"] }
    Process { id: lockProc; command: ["sh", "-c", "hyprlock &"] }
    Process { id: rebootProc; command: ["systemctl", "reboot"] }
    Process { id: shutdownProc; command: ["systemctl", "poweroff"] }
    Process { id: swayncToggle; command: ["swaync-client", "-t"] }

    Process { id: volUpProc; command: ["pamixer", "--allow-boost", "-i", "5"] }
    Process { id: volDownProc; command: ["pamixer", "--allow-boost", "-d", "5"] }

    function executePowerAction(action) {
        switch (action) {
            case "sysmon": sysMonProc.running = true; break
            case "lock": lockProc.running = true; break
            case "reboot": rebootProc.running = true; break
            case "shutdown": shutdownProc.running = true; break
        }
        closeAllPopups()
    }

    function closeAllPopups() {
        volumePopupInstance.visible = false
        networkPopupInstance.visible = false
        powerMenuInstance.visible = false
        subnetCalcInstance.visible = false
        root.showDismiss = false
    }

    function togglePopup(popup, setupFn) {
        var wasVisible = popup.visible
        closeAllPopups()
        if (!wasVisible) {
            root.showDismiss = true
            popup.visible = true
            if (setupFn) setupFn()
        }
    }

    // ── Auto-close on Hyprland focus/workspace change ──
    property string watchedAddr: Hyprland.focusedClient ? Hyprland.focusedClient.address : ""
    onWatchedAddrChanged: if (showDismiss) closeAllPopups()

    property int watchedWsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0
    onWatchedWsIdChanged: if (showDismiss) closeAllPopups()

    // ── Dismiss overlay — maps FIRST so popups render on top ──
    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData
                visible: root.showDismiss
                anchors { top: true; bottom: true; left: true; right: true }
                margins { top: root.barHeight }
                color: Qt.rgba(0, 0, 0, 0.01)

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.closeAllPopups()
                }
            }
        }
    }

    // ── Popups (map AFTER overlay → render on top) ──
    VolumePopup {
        id: volumePopupInstance
        onVolumeChanged: root.volTick++
    }

    NetworkPopup { id: networkPopupInstance }

    PowerMenu {
        id: powerMenuInstance
        onActionTriggered: (action) => root.executePowerAction(action)
    }

    SubnetCalc { id: subnetCalcInstance }

    Timer {
        id: volWheelRefresh
        interval: 100
        onTriggered: {
            root.volTick++
            if (volumePopupInstance.visible) volumePopupInstance.updateVolume()
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.volTick++
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: root.netTick++
    }

    // ── Bar panels ──
    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: barWindow
                required property var modelData
                screen: modelData

                anchors { top: true; left: true; right: true }
                implicitHeight: root.barHeight
                color: root.colBg

                // ── Animated bottom line ──
                Item {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 2

                    // Base glow (dim, pulsing)
                    Rectangle {
                        anchors.fill: parent
                        color: root.colAccent
                        opacity: 0.12

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.18; duration: 2000; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 0.08; duration: 2000; easing.type: Easing.InOutSine }
                        }
                    }

                    // Bright scan beam
                    Rectangle {
                        id: scanBeam
                        y: 0
                        width: 120
                        height: parent.height
                        radius: 1

                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.4; color: Qt.rgba(0, 1, 0.255, 0.7) }
                            GradientStop { position: 0.5; color: root.colAccent }
                            GradientStop { position: 0.6; color: Qt.rgba(0, 1, 0.255, 0.7) }
                            GradientStop { position: 1.0; color: "transparent" }
                        }

                        SequentialAnimation on x {
                            loops: Animation.Infinite
                            NumberAnimation {
                                from: -120
                                to: barWindow.width
                                duration: 3000
                                easing.type: Easing.InOutQuad
                            }
                            PauseAnimation { duration: 800 }
                        }
                    }

                    // Thin bright top edge
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: root.colAccent
                        opacity: 0.25
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 0

                    // === LEFT ===
                    RowLayout {
                        spacing: 12

                        ArchLogo {
                            fontFamily: root.fontFamily
                            fontSize: 18
                            logoColor: root.colAccent
                            glowColor: root.colFgDim
                            onClicked: root.togglePopup(powerMenuInstance)
                        }

                        Text {
                            text: "󰂺"
                            color: root.colFgDim
                            font { family: root.fontFamily; pixelSize: 15 }
                            opacity: subnetMA.containsMouse ? 1.0 : 0.5

                            Behavior on opacity { NumberAnimation { duration: 120 } }

                            MouseArea {
                                id: subnetMA
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.togglePopup(subnetCalcInstance)
                            }
                        }

                        Rectangle {
                            width: 1; height: 14
                            color: root.colFgDim; opacity: 0.15
                        }

                        Workspaces {
                            fontFamily: root.fontFamily
                            fontSize: 11
                            activeColor: root.colAccent
                            inactiveColor: root.colFgDim
                            emptyColor: root.colMuted
                        }

                        Rectangle {
                            width: 1; height: 14
                            color: root.colFgDim; opacity: 0.15
                        }

                        Text {
                            text: Hyprland.focusedClient?.title?.substring(0, 40) || ""
                            color: root.colFg
                            font { family: root.fontFamily; pixelSize: root.fontSize }
                            opacity: 0.6
                            elide: Text.ElideRight
                            Layout.maximumWidth: 300
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Clock {
                        fontFamily: root.fontFamily
                        fontSize: root.fontSize + 1
                        textColor: root.colAccent
                    }

                    Item { Layout.fillWidth: true }

                    // === RIGHT ===
                    RowLayout {
                        spacing: 14

                        CpuRam {
                            fontFamily: root.fontFamily
                            fontSize: root.fontSize
                            cpuColor: root.colFg
                            ramColor: root.colFgDim
                            cpuValue: sysData.cpuUsage
                            ramValue: sysData.memUsage
                        }

                        Rectangle {
                            width: 1; height: 14
                            color: root.colFgDim; opacity: 0.15
                        }

                        Network {
                            id: netWidget
                            fontFamily: root.fontFamily
                            fontSize: root.fontSize
                            activeColor: root.colAccent
                            inactiveColor: root.colFgDim

                            property int _nt: root.netTick
                            on_NtChanged: refresh()

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.togglePopup(networkPopupInstance, function() { networkPopupInstance.refreshAll() })
                            }
                        }

                        Volume {
                            id: volWidget
                            fontFamily: root.fontFamily
                            fontSize: root.fontSize
                            activeColor: root.colAccent
                            mutedColor: root.colAlert

                            property int _vt: root.volTick
                            on_VtChanged: refresh()

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.togglePopup(volumePopupInstance, function() { volumePopupInstance.updateVolume() })
                                onWheel: (wheel) => {
                                    if (wheel.angleDelta.y > 0)
                                        volUpProc.running = true
                                    else
                                        volDownProc.running = true
                                    volWheelRefresh.restart()
                                }
                            }
                        }

                        Notifications {
                            id: notifWidget
                            fontFamily: root.fontFamily
                            fontSize: root.fontSize
                            activeColor: root.colAccent
                            dimColor: root.colFgDim

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.closeAllPopups()
                                    swayncToggle.running = true
                                    notifWidget.refresh()
                                }
                            }
                        }

                        Battery {
                            fontFamily: root.fontFamily
                            fontSize: root.fontSize
                            highColor: root.colAccent
                            midColor: "#ffff00"
                            lowColor: root.colAlert
                        }

                        Rectangle {
                            width: 1; height: 14
                            color: root.colFgDim; opacity: 0.15
                        }

                        Text {
                            text: ""
                            color: root.colFgDim
                            font { family: root.fontFamily; pixelSize: root.fontSize }
                            opacity: 0.6

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.togglePopup(powerMenuInstance)
                            }
                        }
                    }
                }
            }
        }
    }
}
