import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.components
import qs.services

// Barra di un monitor.
PanelWindow {
    id: bar

    required property var modelData
    readonly property string screenName: modelData.name
    readonly property var monitor: Hyprland.monitorFor(modelData)

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barTotal
    exclusiveZone: Theme.barTotal
    color: "transparent"

    WlrLayershell.namespace: "greenshell-bar"
    WlrLayershell.layer: WlrLayer.Top

    // Caffeine: blocca lo spegnimento/blocco schermo (idle-inhibit nativo)
    IdleInhibitor {
        window: bar
        enabled: Settings.caffeine
    }

    StyledRect {
        id: bg

        anchors.fill: parent
        anchors.topMargin: Theme.barMargin
        anchors.leftMargin: Theme.barMargin + (Settings.barFloating ? 2 : 0)
        anchors.rightMargin: Theme.barMargin + (Settings.barFloating ? 2 : 0)
        radius: Settings.barFloating ? Theme.radius.large : 0
        color: Theme.alpha(Theme.surface, Settings.barOpacity)
        border.width: Settings.barFloating ? 1 : 0
        border.color: Theme.outline
        clip: true

        Scanlines {
            anchors.fill: parent
            strength: 0.025
        }

        // Linea "scan" verde sul bordo inferiore (omaggio alla vecchia barra)
        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            visible: Settings.scanlineEffect && Settings.animations

            Rectangle {
                id: beam
                width: 160
                height: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: Theme.primary }
                    GradientStop { position: 1.0; color: "transparent" }
                }
                SequentialAnimation on x {
                    running: beam.parent.visible
                    loops: Animation.Infinite
                    NumberAnimation { from: -160; to: bg.width; duration: 3800; easing.type: Easing.InOutQuad }
                    PauseAnimation { duration: 2500 }
                }
            }
        }

        // ── Sinistra ──
        RowLayout {
            id: left
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // Logo: click = launcher, click destro = menu sessione
            BarButton {
                padding: 9
                active: Ui.modal === "launcher"
                onClicked: mouse => mouse.button === Qt.RightButton ? Ui.toggleModal("session") : Ui.toggleModal("launcher", "apps")

                // Logo Arch Linux
                Icon {
                    text: Icons.arch
                    size: 19
                    color: Theme.primary
                }
            }

            // AI (click = chat, click destro = pulisci chat)
            IconButton {
                size: Theme.barHeight - 12
                icon: Icons.sparkle
                toggled: Ui.popout === "ai" && Ui.popoutScreen === bar.screenName
                iconColor: toggled ? Theme.primary : Theme.primaryDim
                onClicked: mouse => mouse.button === Qt.RightButton ? Ai.clear() : Ui.togglePopout("ai", bar.screenName, mapToItem(null, width / 2, 0).x)
            }

            // Calcolatore subnet
            IconButton {
                size: Theme.barHeight - 12
                icon: Icons.ipNetwork
                toggled: Ui.popout === "subnet" && Ui.popoutScreen === bar.screenName
                iconColor: toggled ? Theme.primary : Theme.primaryDim
                onClicked: Ui.togglePopout("subnet", bar.screenName, mapToItem(null, width / 2, 0).x)
            }

            Workspaces {
                monitor: bar.monitor
            }

            ActiveWindow {
                visible: Settings.showWindowTitle && title !== ""
                monitor: bar.monitor
                Layout.leftMargin: 6
                Layout.maximumWidth: Math.max(0, center.x - left.x - x - 40)
            }
        }

        // ── Centro ──
        RowLayout {
            id: center
            anchors.centerIn: parent
            spacing: 4

            ClockWidget {
                screenName: bar.screenName
            }
            MediaWidget {
                screenName: bar.screenName
            }
        }

        // ── Destra ──
        RowLayout {
            id: right
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            SysStatsWidget {
                screenName: bar.screenName
            }

            Tray {
                screenName: bar.screenName
            }

            QuickIcons {}

            StatusCluster {
                screenName: bar.screenName
            }

            NotifButton {
                screenName: bar.screenName
            }

            IconButton {
                size: Theme.barHeight - 12
                icon: Icons.power
                iconColor: Theme.error
                onClicked: Ui.toggleModal("session")
            }
        }
    }
}
