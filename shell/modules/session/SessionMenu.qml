import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.services

// Menu sessione: frecce/Tab per muoversi, Invio per confermare, lettere come scorciatoie.
// Spegni / Riavvia / Esci chiedono conferma (secondo Invio o click).
Item {
    id: root

    readonly property var actions: [
        { id: "lock", label: I18n.tr("Blocca"), key: "L", icon: "lock", glyph: Icons.lock, confirm: false, run: () => Session.lock() },
        { id: "suspend", label: I18n.tr("Sospendi"), key: "S", icon: "suspend", glyph: Icons.sleep, confirm: false, run: () => Session.suspend() },
        { id: "hibernate", label: I18n.tr("Iberna"), key: "H", icon: "hibernate", glyph: Icons.snowflake, confirm: false, run: () => Session.hibernate() },
        { id: "logout", label: I18n.tr("Esci"), key: "E", icon: "logout", glyph: Icons.logout, confirm: true, run: () => Session.logout() },
        { id: "reboot", label: I18n.tr("Riavvia"), key: "R", icon: "reboot", glyph: Icons.restart, confirm: true, run: () => Session.reboot() },
        { id: "shutdown", label: I18n.tr("Spegni"), key: "P", icon: "shutdown", glyph: Icons.power, confirm: true, run: () => Session.poweroff() }
    ]
    property int current: 0
    property string pending: ""

    implicitWidth: grid.implicitWidth
    implicitHeight: col.implicitHeight

    focus: true
    Component.onCompleted: forceActiveFocus()

    function trigger(i) {
        const a = actions[i];
        current = i;
        if (a.confirm && pending !== a.id) {
            pending = a.id;
            confirmTimer.restart();
            return;
        }
        Ui.closeModal();
        runTimer.action = a;
        runTimer.start();
    }

    // piccolo ritardo per lasciar chiudere l'animazione prima di bloccare/sospendere
    Timer {
        id: runTimer
        property var action: null
        interval: 220
        onTriggered: action.run()
    }
    Timer {
        id: confirmTimer
        interval: 4000
        onTriggered: root.pending = ""
    }

    Keys.onPressed: event => {
        const n = actions.length;
        if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
            current = (current + 1) % n;
            pending = "";
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
            current = (current - 1 + n) % n;
            pending = "";
        } else if (event.key === Qt.Key_Down) {
            current = (current + 3) % n;
            pending = "";
        } else if (event.key === Qt.Key_Up) {
            current = (current - 3 + n) % n;
            pending = "";
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            trigger(current);
        } else if (event.key === Qt.Key_Escape) {
            Ui.closeModal();
        } else {
            const i = actions.findIndex(a => a.key === event.text.toUpperCase());
            if (i >= 0)
                trigger(i);
            else
                return;
        }
        event.accepted = true;
    }

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        spacing: 26

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 2
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Time.time
                font.family: Theme.font.mono
                font.pixelSize: Theme.font.display
                font.weight: Font.Bold
                color: Theme.primary
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.pending !== "" ? I18n.tr("Premi di nuovo per confermare") : I18n.tr("Arrivederci, Operatore  ·  attivo da ") + SysStats.uptime
                color: root.pending !== "" ? Theme.warning : Theme.textDim
            }
        }

        GridLayout {
            id: grid
            Layout.alignment: Qt.AlignHCenter
            columns: 3
            rowSpacing: 16
            columnSpacing: 16

            Repeater {
                model: root.actions

                delegate: StyledRect {
                    id: btn
                    required property var modelData
                    required property int index
                    readonly property bool sel: root.current === index
                    readonly property bool confirming: root.pending === modelData.id
                    readonly property bool danger: modelData.confirm

                    implicitWidth: 170
                    implicitHeight: 170
                    radius: sel ? Theme.radius.xl + 8 : Theme.radius.xl
                    color: confirming ? Theme.errorContainer : sel ? Theme.primaryContainer : Theme.alpha(Theme.surfaceContainer, 0.92)
                    border.width: sel ? 2 : 1
                    border.color: confirming ? Theme.errorContainer : sel ? Theme.primary : Theme.outlineVariant
                    scale: area.pressed ? 0.95 : sel ? 1.04 : 1

                    Behavior on radius {
                        Anim {}
                    }
                    Behavior on scale {
                        Anim {
                            easing.bezierCurve: Theme.anim.expressive
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 12

                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 64
                            implicitHeight: 64
                            Image {
                                id: svg
                                anchors.fill: parent
                                source: Quickshell.shellPath("assets/icons/session-" + btn.modelData.icon + ".svg")
                                sourceSize: Qt.size(128, 128)
                                visible: status === Image.Ready
                                opacity: btn.sel || btn.confirming ? 1 : 0.75
                            }
                            Icon {
                                anchors.centerIn: parent
                                visible: svg.status !== Image.Ready
                                text: btn.modelData.glyph
                                size: 48
                                color: btn.confirming ? Theme.error : btn.sel ? Theme.primary : Theme.text
                            }
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: btn.confirming ? I18n.tr("Conferma?") : btn.modelData.label
                            font.pixelSize: Theme.font.title
                            font.weight: Font.DemiBold
                            color: btn.confirming ? Theme.error : btn.sel ? Theme.fgPrimaryContainer : Theme.text
                        }
                        StyledRect {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 24
                            implicitHeight: 20
                            radius: 5
                            color: btn.confirming ? Theme.alpha(Theme.error, 0.2) : Theme.surfaceContainerHighest
                            StyledText {
                                anchors.centerIn: parent
                                text: btn.modelData.key
                                font.family: Theme.font.mono
                                font.pixelSize: Theme.font.tiny
                                font.weight: Font.Bold
                                color: btn.confirming ? Theme.error : Theme.textDim
                            }
                        }
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.current = btn.index
                        onClicked: root.trigger(btn.index)
                    }
                }
            }
        }

        StyledButton {
            Layout.alignment: Qt.AlignHCenter
            variant: "outline"
            icon: Icons.speedometer
            text: I18n.tr("Monitor di sistema")
            onClicked: {
                Ui.closeModal();
                Session.sysMonitor();
            }
        }
    }
}
