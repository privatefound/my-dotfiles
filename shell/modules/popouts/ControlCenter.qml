import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.components
import qs.services

// Control Center: intestazione + pagina principale o sotto-pagina (rete, bluetooth, audio).
Item {
    id: root

    required property string screenName

    implicitWidth: 440
    implicitHeight: col.implicitHeight + 32

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        // ── Intestazione ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            StyledRect {
                implicitWidth: 44
                implicitHeight: 44
                radius: 22
                color: Theme.primaryContainer

                Image {
                    id: avatar
                    anchors.fill: parent
                    anchors.margins: 4
                    source: Quickshell.shellPath("assets/icons/avatar.svg")
                    sourceSize: Qt.size(72, 72)
                    visible: status === Image.Ready
                }
                Icon {
                    anchors.centerIn: parent
                    visible: avatar.status !== Image.Ready
                    text: Icons.account
                    size: 26
                    color: Theme.primary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                StyledText {
                    text: (Quickshell.env("USER") ?? "operatore") + "@" + hostFile.text().trim()
                    font.family: Theme.font.mono
                    font.pixelSize: Theme.font.body
                    font.weight: Font.Bold
                    color: Theme.primary
                }
                StyledText {
                    text: "attivo da " + SysStats.uptime
                    font.pixelSize: Theme.font.small
                    color: Theme.textDim
                }
            }

            IconButton {
                icon: Icons.wallpaper
                onClicked: Ui.openModal("wallpaper")
            }
            IconButton {
                icon: Icons.cog
                onClicked: Ui.openModal("settings")
            }
            IconButton {
                icon: Icons.lock
                onClicked: {
                    Ui.closeAll();
                    Session.lock();
                }
            }
            IconButton {
                icon: Icons.power
                iconColor: Theme.error
                onClicked: Ui.openModal("session")
            }
        }

        // ── Pagina ──
        Loader {
            id: page
            Layout.fillWidth: true
            sourceComponent: {
                switch (Ui.controlPage) {
                case "network": return netPage;
                case "bluetooth": return btPage;
                case "audio": return audioPage;
                }
                return mainPage;
            }
            onLoaded: slide.restart()

            ParallelAnimation {
                id: slide
                NumberAnimation {
                    target: page.item
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Theme.anim.normal
                }
                NumberAnimation {
                    target: page.item
                    property: "x"
                    from: Ui.controlPage === "" ? -24 : 24
                    to: 0
                    duration: Theme.anim.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.emphasized
                }
            }
        }
    }

    FileView {
        id: hostFile
        path: "/etc/hostname"
        blockLoading: true
    }

    Component { id: mainPage; CcMain {} }
    Component { id: netPage; CcNetwork {} }
    Component { id: btPage; CcBluetooth {} }
    Component { id: audioPage; CcAudio {} }
}
