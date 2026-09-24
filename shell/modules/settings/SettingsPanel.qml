import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.config
import qs.components
import qs.services

// Impostazioni della shell (salvate in ~/.config/hypr/settings.json).
StyledRect {
    id: root

    property string section: "look"
    readonly property var sections: [
        { id: "look", label: "Aspetto", icon: Icons.palette },
        { id: "bar", label: "Barra", icon: Icons.dotsHorizontal },
        { id: "notif", label: "Notifiche", icon: Icons.bell },
        { id: "apps", label: "App & AI", icon: Icons.apps },
        { id: "about", label: "Info", icon: Icons.information }
    ]

    implicitWidth: 820
    implicitHeight: 620
    radius: Theme.radius.xl
    color: Theme.alpha(Theme.surface, Settings.panelOpacity)
    border.width: 1
    border.color: Theme.outline
    clip: true

    focus: true
    Keys.onEscapePressed: Ui.closeModal()

    MouseArea {
        anchors.fill: parent
    }

    component Row_: RowLayout {
        id: r
        property string title
        property string subtitle
        default property alias control: holder.data
        Layout.fillWidth: true
        Layout.minimumHeight: 52
        spacing: 16
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            StyledText {
                Layout.fillWidth: true
                text: r.title
            }
            StyledText {
                Layout.fillWidth: true
                visible: r.subtitle !== ""
                text: r.subtitle
                font.pixelSize: Theme.font.small
                color: Theme.textDim
                wrapMode: Text.Wrap
            }
        }
        RowLayout {
            id: holder
            spacing: 6
        }
    }

    component ToggleRow: Row_ {
        id: tr
        property bool checked
        signal toggled(bool v)
        Toggle {
            checked: tr.checked
            onToggled: v => tr.toggled(v)
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── Navigazione ──
        StyledRect {
            Layout.fillHeight: true
            implicitWidth: 210
            color: Theme.alpha(Theme.surfaceContainerLow, 0.8)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 4

                RowLayout {
                    Layout.bottomMargin: 14
                    Layout.leftMargin: 6
                    spacing: 10
                    Icon {
                        text: Icons.cog
                        size: 22
                        color: Theme.primary
                    }
                    StyledText {
                        text: "Impostazioni"
                        font.pixelSize: Theme.font.title
                        font.weight: Font.Bold
                    }
                }

                Repeater {
                    model: root.sections
                    delegate: StyledRect {
                        required property var modelData
                        readonly property bool sel: root.section === modelData.id
                        Layout.fillWidth: true
                        implicitHeight: 42
                        radius: 21
                        color: sel ? Theme.primaryContainer : "transparent"
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            spacing: 12
                            Icon {
                                text: modelData.icon
                                size: 18
                                color: sel ? Theme.primary : Theme.textDim
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.label
                                font.weight: sel ? Font.DemiBold : Font.Normal
                                color: sel ? Theme.fgPrimaryContainer : Theme.text
                            }
                        }
                        StateLayer {
                            onClicked: root.section = modelData.id
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                StyledButton {
                    Layout.fillWidth: true
                    variant: "outline"
                    icon: Icons.textBox
                    text: "Apri settings.json"
                    onClicked: Quickshell.execDetached(["xdg-open", Settings.rootDir + "/settings.json"])
                }
            }
        }

        // ── Contenuto ──
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: content.implicitHeight + 40
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: StyledScrollBar {}

            ColumnLayout {
                id: content
                x: 24
                y: 20
                width: parent.width - 48
                spacing: 6

                // ═══ Aspetto ═══
                ColumnLayout {
                    visible: root.section === "look"
                    Layout.fillWidth: true
                    spacing: 6

                    SectionHeader {
                        text: "Colore d'accento"
                        icon: Icons.palette
                    }
                    Flow {
                        Layout.fillWidth: true
                        Layout.topMargin: 6
                        Layout.bottomMargin: 10
                        spacing: 10
                        Repeater {
                            model: Theme.accentKeys
                            delegate: ColumnLayout {
                                required property string modelData
                                spacing: 4
                                StyledRect {
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: 52
                                    implicitHeight: 52
                                    radius: Settings.accent === modelData ? 16 : 26
                                    color: Theme.accents[modelData].color
                                    border.width: Settings.accent === modelData ? 3 : 0
                                    border.color: Theme.text
                                    Behavior on radius {
                                        Anim {}
                                    }
                                    Icon {
                                        anchors.centerIn: parent
                                        visible: Settings.accent === modelData
                                        text: Icons.check
                                        size: 22
                                        color: "#000000"
                                    }
                                    StateLayer {
                                        tint: "#000000"
                                        onClicked: Settings.accent = modelData
                                    }
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: Theme.accents[modelData].name
                                    font.pixelSize: Theme.font.tiny
                                    color: Theme.textDim
                                }
                            }
                        }
                    }

                    SectionHeader {
                        text: "Superfici"
                        icon: Icons.opacity
                    }
                    Row_ {
                        title: "Opacità barra"
                        StyledSlider {
                            implicitWidth: 220
                            implicitHeight: 32
                            icon: Icons.opacity
                            value: Settings.barOpacity
                            onMoved: v => Settings.barOpacity = Math.round(v * 100) / 100
                        }
                    }
                    Row_ {
                        title: "Opacità pannelli"
                        StyledSlider {
                            implicitWidth: 220
                            implicitHeight: 32
                            icon: Icons.opacity
                            value: Settings.panelOpacity
                            onMoved: v => Settings.panelOpacity = Math.max(0.15, Math.round(v * 100) / 100)
                        }
                    }
                    Row_ {
                        title: "Dimensione testo"
                        subtitle: Math.round(Settings.fontScale * 100) + "%"
                        StyledSlider {
                            implicitWidth: 220
                            implicitHeight: 32
                            icon: Icons.formatText
                            showValue: false
                            to: 1
                            step: 0.05
                            value: (Settings.fontScale - 0.8) / 0.5
                            onMoved: v => Settings.fontScale = Math.round((0.8 + v * 0.5) * 20) / 20
                        }
                    }
                    ToggleRow {
                        title: "Effetto CRT"
                        subtitle: "Righe di scansione e raggio verde sulla barra"
                        checked: Settings.scanlineEffect
                        onToggled: v => Settings.scanlineEffect = v
                    }
                    ToggleRow {
                        title: "Animazioni"
                        checked: Settings.animations
                        onToggled: v => Settings.animations = v
                    }
                    ToggleRow {
                        title: "Trasparenza finestre"
                        subtitle: "Finestre leggermente trasparenti (come il vecchio toggle)"
                        checked: Settings.windowTransparency
                        onToggled: v => Settings.windowTransparency = v
                    }
                }

                // ═══ Barra ═══
                ColumnLayout {
                    visible: root.section === "bar"
                    Layout.fillWidth: true
                    spacing: 6

                    SectionHeader {
                        text: "Barra"
                        icon: Icons.dotsHorizontal
                    }
                    ToggleRow {
                        title: "Barra flottante"
                        subtitle: "Staccata dai bordi, con angoli arrotondati"
                        checked: Settings.barFloating
                        onToggled: v => Settings.barFloating = v
                    }
                    ToggleRow {
                        title: "Titolo finestra"
                        checked: Settings.showWindowTitle
                        onToggled: v => Settings.showWindowTitle = v
                    }
                    ToggleRow {
                        title: "CPU / RAM / temperatura"
                        checked: Settings.showSysStats
                        onToggled: v => Settings.showSysStats = v
                    }
                    ToggleRow {
                        title: "Lettore multimediale"
                        checked: Settings.showMedia
                        onToggled: v => Settings.showMedia = v
                    }

                    SectionHeader {
                        Layout.topMargin: 10
                        text: "Workspace"
                        icon: Icons.grid
                    }
                    Row_ {
                        title: "Modalità"
                        subtitle: Settings.workspaceMode === "fixed" ? "Sempre 1–" + Settings.workspaceCount + " su ogni monitor (come prima)" : "Solo i workspace del monitor"
                        StyledButton {
                            implicitHeight: 32
                            variant: Settings.workspaceMode === "fixed" ? "filled" : "tonal"
                            text: "Fissi"
                            onClicked: Settings.workspaceMode = "fixed"
                        }
                        StyledButton {
                            implicitHeight: 32
                            variant: Settings.workspaceMode === "monitor" ? "filled" : "tonal"
                            text: "Per monitor"
                            onClicked: Settings.workspaceMode = "monitor"
                        }
                    }
                    Row_ {
                        title: "Numero di workspace"
                        visible: Settings.workspaceMode === "fixed"
                        IconButton {
                            icon: Icons.minus
                            onClicked: Settings.workspaceCount = Math.max(1, Settings.workspaceCount - 1)
                        }
                        StyledText {
                            text: Settings.workspaceCount
                            font.family: Theme.font.mono
                            font.weight: Font.Bold
                        }
                        IconButton {
                            icon: Icons.plus
                            onClicked: Settings.workspaceCount = Math.min(20, Settings.workspaceCount + 1)
                        }
                    }
                    ToggleRow {
                        title: "Icone delle app nei workspace"
                        checked: Settings.workspaceIcons
                        onToggled: v => Settings.workspaceIcons = v
                    }

                    SectionHeader {
                        Layout.topMargin: 10
                        text: "Orologio"
                        icon: Icons.clock
                    }
                    ToggleRow {
                        title: "Formato 24 ore"
                        checked: Settings.clock24h
                        onToggled: v => Settings.clock24h = v
                    }
                    ToggleRow {
                        title: "Mostra i secondi"
                        checked: Settings.clockSeconds
                        onToggled: v => Settings.clockSeconds = v
                    }
                    ToggleRow {
                        title: "Mostra la data"
                        checked: Settings.showDate
                        onToggled: v => Settings.showDate = v
                    }
                }

                // ═══ Notifiche ═══
                ColumnLayout {
                    visible: root.section === "notif"
                    Layout.fillWidth: true
                    spacing: 6

                    SectionHeader {
                        text: "Notifiche"
                        icon: Icons.bell
                    }
                    ToggleRow {
                        title: "Non disturbare"
                        subtitle: "Solo le notifiche critiche compaiono a schermo"
                        checked: Settings.dnd
                        onToggled: Notifs.toggleDnd()
                    }
                    ToggleRow {
                        title: "Suono"
                        checked: Settings.notifSound
                        onToggled: v => Settings.notifSound = v
                    }
                    Row_ {
                        title: "Durata popup"
                        subtitle: (Settings.notifTimeout / 1000).toFixed(0) + " secondi"
                        IconButton {
                            icon: Icons.minus
                            onClicked: Settings.notifTimeout = Math.max(2000, Settings.notifTimeout - 1000)
                        }
                        IconButton {
                            icon: Icons.plus
                            onClicked: Settings.notifTimeout = Math.min(30000, Settings.notifTimeout + 1000)
                        }
                    }
                    StyledButton {
                        Layout.topMargin: 8
                        variant: "tonal"
                        icon: Icons.bellRing
                        text: "Invia notifica di prova"
                        onClicked: Quickshell.execDetached(["notify-send", "-a", "greenshell", "Wake up, Neo…", "The Matrix has you. Segui il coniglio bianco 🐇", "-A", "ok=Seguilo"])
                    }
                }

                // ═══ App & AI ═══
                ColumnLayout {
                    visible: root.section === "apps"
                    Layout.fillWidth: true
                    spacing: 6

                    SectionHeader {
                        text: "Applicazioni predefinite"
                        icon: Icons.apps
                    }
                    Row_ {
                        title: "Terminale"
                        TextField {
                            implicitWidth: 240
                            text: Settings.terminal
                            onAccepted: Settings.terminal = text
                            onActiveFocusChanged: if (!activeFocus) Settings.terminal = text
                        }
                    }
                    Row_ {
                        title: "Monitor di sistema"
                        TextField {
                            implicitWidth: 240
                            text: Settings.sysMonitor
                            onAccepted: Settings.sysMonitor = text
                        }
                    }
                    Row_ {
                        title: "Cartella sfondi"
                        TextField {
                            implicitWidth: 320
                            text: Settings.wallpaperDir
                            onAccepted: {
                                Settings.wallpaperDir = text;
                                Wallpaper.refresh();
                            }
                        }
                    }

                    SectionHeader {
                        Layout.topMargin: 10
                        text: "Morpheus (IA locale)"
                        icon: Icons.sparkle
                    }
                    Row_ {
                        title: "Modello"
                        subtitle: Ai.modelLabel + "  ·  cambialo dal menu della chat"
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: "Prompt di sistema"
                        color: Theme.textDim
                        font.pixelSize: Theme.font.small
                    }
                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: 130
                        radius: Theme.radius.normal
                        color: Theme.surfaceContainerHighest
                        border.width: prompt.activeFocus ? 2 : 1
                        border.color: prompt.activeFocus ? Theme.primary : Theme.outlineVariant
                        Flickable {
                            anchors.fill: parent
                            anchors.margins: 10
                            contentHeight: prompt.implicitHeight
                            clip: true
                            TextEdit {
                                id: prompt
                                width: parent.width
                                text: Settings.aiSystemPrompt
                                wrapMode: TextEdit.Wrap
                                color: Theme.text
                                font.family: Theme.font.sans
                                font.pixelSize: Theme.font.small
                                selectionColor: Theme.alpha(Theme.primary, 0.35)
                                onActiveFocusChanged: if (!activeFocus) Settings.aiSystemPrompt = text
                            }
                        }
                    }
                }

                // ═══ Info ═══
                ColumnLayout {
                    visible: root.section === "about"
                    Layout.fillWidth: true
                    spacing: 10

                    Icon {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 20
                        text: Icons.arch
                        size: 96
                        color: Theme.primary
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "green-hyprtheme · shell"
                        font.family: Theme.font.mono
                        font.pixelSize: Theme.font.large
                        font.weight: Font.Bold
                        color: Theme.primary
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Quickshell · Hyprland " + (Hypr.activeClass !== undefined ? "" : "")
                        color: Theme.textDim
                    }
                    StyledText {
                        Layout.fillWidth: true
                        Layout.topMargin: 16
                        wrapMode: Text.Wrap
                        color: Theme.textDim
                        font.family: Theme.font.mono
                        font.pixelSize: Theme.font.small
                        text: "SUPER+D / `      launcher\nSUPER+Z           appunti\nSUPER+X           comandi\nSUPER+N           notifiche\nSUPER+A           control center\nSUPER+ESC         menu sessione\nSUPER+W           sfondi\nSUPER+I           chat Morpheus\nSUPER+,           impostazioni\nSUPER+SHIFT+W     ricarica shell"
                    }
                }
            }
        }
    }
}
