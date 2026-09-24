import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.config
import qs.components
import qs.services

// Scheda di una notifica: usata sia nei popup sia nel centro notifiche.
StyledRect {
    id: root

    required property var notification
    property bool popup: false
    property real progress: 1       // barra del timeout (solo popup)
    readonly property bool critical: notification?.urgency === NotificationUrgency.Critical
    readonly property string imageSrc: Notifs.iconFor(notification)
    readonly property string appIcon: Notifs.appIconFor(notification)
    property bool expanded: false
    readonly property bool hovered: hover.hovered

    signal dismissed

    implicitWidth: 380
    implicitHeight: content.implicitHeight + 24
    radius: Theme.radius.large
    color: popup ? Theme.alpha(Theme.surface, Settings.panelOpacity) : Theme.surfaceContainer
    border.width: popup || critical ? 1 : 0
    border.color: critical ? Theme.error : Theme.outline
    clip: true

    HoverHandler {
        id: hover
    }

    // click = azione predefinita
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton)
                root.dismissed();
            else
                Notifs.invokeDefault(root.notification);
        }
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Immagine / icona
            Item {
                Layout.alignment: Qt.AlignTop
                implicitWidth: 44
                implicitHeight: 44

                ClippingRectangle {
                    anchors.fill: parent
                    radius: Theme.radius.normal
                    color: root.critical ? Theme.errorContainer : Theme.primaryContainer

                    Image {
                        id: img
                        anchors.fill: parent
                        source: root.imageSrc
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(88, 88)
                        asynchronous: true
                        visible: status === Image.Ready
                    }
                    Image {
                        anchors.fill: parent
                        anchors.margins: 6
                        visible: img.status !== Image.Ready
                        source: Quickshell.shellPath("assets/icons/notification.svg")
                        sourceSize: Qt.size(64, 64)
                    }
                }
                // Icona app piccola in basso a destra se c'è un'immagine
                IconImage {
                    visible: img.status === Image.Ready && root.appIcon !== "" && root.appIcon !== root.imageSrc
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: -4
                    implicitSize: 18
                    source: root.appIcon
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    StyledText {
                        text: root.notification?.appName || I18n.tr("Sistema")
                        font.pixelSize: Theme.font.tiny
                        font.weight: Font.Bold
                        font.letterSpacing: 0.6
                        color: root.critical ? Theme.error : Theme.primary
                    }
                    StyledText {
                        text: "· " + Notifs.timeAgo(root.notification)
                        font.pixelSize: Theme.font.tiny
                        color: Theme.textFaint
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.notification?.summary ?? ""
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                }

                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.notification?.body ?? ""
                    textFormat: Text.StyledText
                    color: Theme.textDim
                    linkColor: Theme.primary
                    font.family: Theme.font.sans
                    font.pixelSize: Theme.font.small
                    wrapMode: Text.Wrap
                    maximumLineCount: root.expanded ? 20 : 3
                    elide: Text.ElideRight
                    onLinkActivated: link => Qt.openUrlExternally(link)

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                spacing: 0
                IconButton {
                    size: 28
                    icon: Icons.close
                    iconColor: Theme.textDim
                    onClicked: root.dismissed()
                }
                IconButton {
                    visible: !root.popup && (root.notification?.body?.length ?? 0) > 120
                    size: 28
                    icon: root.expanded ? Icons.chevronUp : Icons.chevronDown
                    iconColor: Theme.textDim
                    onClicked: root.expanded = !root.expanded
                }
            }
        }

        // Azioni
        RowLayout {
            Layout.fillWidth: true
            visible: actions.count > 0
            spacing: 6

            Repeater {
                id: actions
                model: (root.notification?.actions ?? []).filter(a => a.identifier !== "default" || (root.notification?.actions?.length ?? 0) === 1)
                delegate: StyledButton {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 32
                    variant: "tonal"
                    text: modelData.text || I18n.tr("Apri")
                    onClicked: Notifs.invoke(root.notification, modelData)
                }
            }
        }
    }

    // Barra del timeout
    Rectangle {
        visible: root.popup && !root.critical
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: root.radius / 2
        height: 2
        radius: 1
        width: (parent.width - root.radius) * root.progress
        color: Theme.primary
        opacity: 0.7
    }
}
