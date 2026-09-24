import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.config
import qs.components
import qs.services

// Popup delle notifiche (in alto a destra sul monitor attivo).
PanelWindow {
    id: win

    required property var modelData
    readonly property bool isTarget: modelData.name === Ui.focusedScreen

    screen: modelData
    visible: isTarget && (Notifs.popups.length > 0 || column.implicitHeight > 1)
    anchors {
        top: true
        right: true
    }
    margins {
        top: 8
        right: 10
    }
    implicitWidth: 400
    implicitHeight: Math.max(1, column.implicitHeight + 10)
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    color: "transparent"

    WlrLayershell.namespace: "greenshell-notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    ColumnLayout {
        id: column
        width: 390
        anchors.right: parent.right
        spacing: 8

        Repeater {
            model: Notifs.popups

            delegate: Item {
                id: wrap

                required property var modelData
                required property int index
                readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
                readonly property int timeout: modelData.expireTimeout > 0 ? modelData.expireTimeout : Settings.notifTimeout
                property real elapsed: 0
                property bool leaving: false

                Layout.fillWidth: true
                implicitHeight: leaving ? 0 : card.implicitHeight
                clip: true

                Behavior on implicitHeight {
                    Anim {}
                }

                NotificationCard {
                    id: card
                    width: parent.width
                    notification: wrap.modelData
                    popup: true
                    progress: 1 - wrap.elapsed / wrap.timeout
                    x: wrap.leaving ? width + 20 : 0
                    opacity: wrap.leaving ? 0 : 1
                    onDismissed: wrap.close(true)

                    Behavior on x {
                        Anim {}
                    }
                    Behavior on opacity {
                        Anim {}
                    }

                    // entrata da destra
                    Component.onCompleted: enter.start()
                    NumberAnimation {
                        id: enter
                        target: card
                        property: "x"
                        from: 420
                        to: 0
                        duration: Theme.anim.slow
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.anim.emphasized
                    }
                }

                function close(dismiss) {
                    if (leaving)
                        return;
                    leaving = true;
                    removeTimer.dismiss = dismiss;
                    removeTimer.start();
                }

                Timer {
                    id: removeTimer
                    property bool dismiss: false
                    interval: Theme.anim.normal + 20
                    onTriggered: dismiss ? Notifs.dismiss(wrap.modelData) : Notifs.hidePopup(wrap.modelData)
                }

                // Timeout (in pausa col mouse sopra)
                Timer {
                    running: !wrap.critical && !card.hovered && !wrap.leaving
                    interval: 50
                    repeat: true
                    onTriggered: {
                        wrap.elapsed += 50;
                        if (wrap.elapsed >= wrap.timeout)
                            wrap.close(false);
                    }
                }

                Connections {
                    target: wrap.modelData
                    function onClosed() {
                        wrap.close(false);
                    }
                }
            }
        }
    }
}
