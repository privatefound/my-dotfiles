import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

// Launcher stile spotlight con 3 modalità: App · Appunti · Comandi.
// Prefissi nella ricerca app:  "=" calcolatrice · ">" esegui comando · "?" chiedi a Morpheus
StyledRect {
    id: root

    readonly property var modes: [
        { id: "apps", label: "App", icon: Icons.apps },
        { id: "clipboard", label: "Appunti", icon: Icons.clipboard },
        { id: "commands", label: "Comandi", icon: Icons.cli }
    ]
    property string mode: Ui.launcherMode
    readonly property string query: search.text
    readonly property bool calcMode: mode === "apps" && query.startsWith("=")
    readonly property bool runMode: mode === "apps" && query.startsWith(">")
    readonly property bool askMode: mode === "apps" && query.startsWith("?")

    implicitWidth: 680
    implicitHeight: 560
    radius: Theme.radius.xl
    color: Theme.alpha(Theme.surface, Settings.panelOpacity)
    border.width: 1
    border.color: Theme.outline
    clip: true

    Component.onCompleted: {
        search.focusInput();
        if (mode === "clipboard")
            Clipboard.refresh();
    }
    onModeChanged: {
        search.text = "";
        list.currentIndex = 0;
        if (mode === "clipboard")
            Clipboard.refresh();
        search.focusInput();
    }

    // ── Calcolatrice ──
    readonly property string calcResult: {
        if (!calcMode)
            return "";
        let e = query.slice(1).trim().toLowerCase();
        if (e === "")
            return "";
        if (!/^[0-9+\-*/().,%^\s a-z]*$/.test(e))
            return "";
        e = e.replace(/,/g, ".").replace(/\^/g, "**").replace(/\bpi\b/g, "Math.PI").replace(/\be\b/g, "Math.E");
        e = e.replace(/\b(sqrt|sin|cos|tan|asin|acos|atan|abs|round|floor|ceil|log2|log10|exp|pow|min|max)\b/g, "Math.$1").replace(/\bln\b/g, "Math.log");
        if (/[a-z]/i.test(e.replace(/Math\.[A-Za-z0-9]+/g, "")))
            return "";
        try {
            const v = Function("'use strict'; return (" + e + ")")();
            if (typeof v !== "number" || !isFinite(v))
                return "";
            return String(Math.round(v * 1e10) / 1e10);
        } catch (err) {
            return "";
        }
    }

    // ── Comandi (ex rofi-control + azioni di sessione) ──
    readonly property var commands: [
        { name: "Blocca schermo", icon: Icons.lock, run: () => Session.lock() },
        { name: "Sospendi", icon: Icons.sleep, run: () => Session.suspend() },
        { name: "Iberna", icon: Icons.snowflake, run: () => Session.hibernate() },
        { name: "Riavvia", icon: Icons.restart, run: () => Ui.openModal("session") },
        { name: "Spegni", icon: Icons.power, run: () => Ui.openModal("session") },
        { name: "Esci dalla sessione", icon: Icons.logout, run: () => Ui.openModal("session") },
        { name: "Volume +5%", icon: Icons.volumeHigh, run: () => Audio.changeVolume(0.05), keep: true },
        { name: "Volume -5%", icon: Icons.volumeLow, run: () => Audio.changeVolume(-0.05), keep: true },
        { name: "Muto audio", icon: Icons.volumeOff, run: () => Audio.toggleMute(), keep: true },
        { name: "Muto microfono", icon: Icons.micOff, run: () => Audio.toggleMicMute(), keep: true },
        { name: "Luminosità +10%", icon: Icons.brightnessHigh, run: () => Brightness.change(0.1), keep: true },
        { name: "Luminosità -10%", icon: Icons.brightnessLow, run: () => Brightness.change(-0.1), keep: true },
        { name: "Wi‑Fi on/off", icon: Icons.wifi4, run: () => Network.setWifiEnabled(!Network.wifiEnabled), keep: true },
        { name: "Bluetooth on/off", icon: Icons.bluetooth, run: () => Bt.setEnabled(!Bt.enabled), keep: true },
        { name: "Non disturbare on/off", icon: Icons.bellOff, run: () => Notifs.toggleDnd(), keep: true },
        { name: "Caffeine on/off", icon: Icons.coffee, run: () => Settings.caffeine = !Settings.caffeine, keep: true },
        { name: "Trasparenza finestre on/off", icon: Icons.opacity, run: () => Settings.windowTransparency = !Settings.windowTransparency, keep: true },
        { name: "Cambia sfondo", icon: Icons.wallpaper, run: () => Ui.openModal("wallpaper") },
        { name: "Sfondo casuale", icon: Icons.imageMulti, run: () => Wallpaper.random() },
        { name: "Impostazioni shell", icon: Icons.cog, run: () => Ui.openModal("settings") },
        { name: "Screenshot area", icon: Icons.screenshot, run: () => Quickshell.execDetached(["sh", "-c", "sleep 0.4; g=$(slurp) && sleep 0.05 && grim -g \"$g\" - | swappy -f -"]) },
        { name: "Screenshot schermo", icon: Icons.monitor, run: () => Quickshell.execDetached(["sh", "-c", "sleep 0.4; grim - | swappy -f -"]) },
        { name: "Selettore colore", icon: Icons.eyedropper, run: () => Quickshell.execDetached(["sh", "-c", "sleep 0.3; hyprpicker -a"]) },
        { name: "Trasmetti schermo", icon: Icons.cast, run: () => Session.castScreen() },
        { name: "Gestione monitor (Monique)", icon: Icons.monitorMulti, run: () => Session.monitors() },
        { name: "Mixer audio", icon: Icons.tune, run: () => Session.audioMixer() },
        { name: "Connessioni di rete", icon: Icons.lan, run: () => Network.openEditor() },
        { name: "Monitor di sistema", icon: Icons.speedometer, run: () => Session.sysMonitor() },
        { name: "Calcolatore subnet", icon: Icons.ipNetwork, run: () => Ui.openPopout("subnet", Ui.focusedScreen, 200) },
        { name: "Chat con Morpheus", icon: Icons.sparkle, run: () => Ui.openPopout("ai", Ui.focusedScreen, 200) },
        { name: "Pulisci cronologia appunti", icon: Icons.trash, run: () => Clipboard.wipe() },
        { name: "Ricarica shell", icon: Icons.refresh, run: () => Quickshell.reload(true) }
    ]

    readonly property var items: {
        if (mode === "clipboard") {
            const q = query.toLowerCase();
            return Clipboard.entries.filter(e => q === "" || e.text.toLowerCase().includes(q));
        }
        if (mode === "commands") {
            const q = query.toLowerCase();
            return commands.filter(c => q === "" || c.name.toLowerCase().includes(q));
        }
        if (calcMode || runMode || askMode)
            return [];
        return Apps.search(query).slice(0, 60);
    }

    function activate(index) {
        const q = query;
        if (calcMode) {
            if (calcResult !== "")
                Quickshell.clipboardText = calcResult;
            Ui.closeModal();
            return;
        }
        if (runMode) {
            const cmd = q.slice(1).trim();
            if (cmd)
                Quickshell.execDetached(["sh", "-c", cmd]);
            Ui.closeModal();
            return;
        }
        if (askMode) {
            const text = q.slice(1).trim();
            Ui.openPopout("ai", Ui.focusedScreen, 200);
            if (text)
                Ai.send(text);
            return;
        }
        const it = items[index];
        if (!it)
            return;
        if (mode === "clipboard") {
            Clipboard.copy(it);
            Ui.closeModal();
        } else if (mode === "commands") {
            if (!it.keep)
                Ui.closeModal();
            it.run();
        } else {
            Apps.launch(it);
            Ui.closeModal();
        }
    }

    function cycleMode(dir) {
        const i = modes.findIndex(m => m.id === mode);
        Ui.launcherMode = modes[(i + dir + modes.length) % modes.length].id;
    }

    // blocca i click verso lo sfondo (che chiuderebbe il modale)
    MouseArea {
        anchors.fill: parent
    }

    Scanlines {
        anchors.fill: parent
        strength: 0.02
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Barra di ricerca
        TextField {
            id: search
            Layout.fillWidth: true
            implicitHeight: 52
            icon: root.mode === "clipboard" ? Icons.clipboard : root.mode === "commands" ? Icons.cli : Icons.magnify
            placeholder: root.mode === "clipboard" ? "Cerca negli appunti…" : root.mode === "commands" ? "Cerca un comando…" : "Cerca app…   ( = calcola · > esegui · ? chiedi a Morpheus )"
            input.font.pixelSize: Theme.font.title
            onTextChanged: list.currentIndex = 0
            onAccepted: root.activate(list.currentIndex)
            onEscapePressed: Ui.closeModal()

            Keys.forwardTo: [keyHandler]
        }

        Item {
            id: keyHandler
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Down || (event.key === Qt.Key_J && event.modifiers & Qt.ControlModifier)) {
                    list.incrementCurrentIndex();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up || (event.key === Qt.Key_K && event.modifiers & Qt.ControlModifier)) {
                    list.decrementCurrentIndex();
                    event.accepted = true;
                } else if (event.key === Qt.Key_PageDown) {
                    list.currentIndex = Math.min(list.count - 1, list.currentIndex + 8);
                    event.accepted = true;
                } else if (event.key === Qt.Key_PageUp) {
                    list.currentIndex = Math.max(0, list.currentIndex - 8);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Tab) {
                    root.cycleMode(1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Backtab) {
                    root.cycleMode(-1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Delete && root.mode === "clipboard") {
                    const it = root.items[list.currentIndex];
                    if (it)
                        Clipboard.remove(it);
                    event.accepted = true;
                }
            }
        }

        // Schede modalità
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: root.modes
                delegate: StyledRect {
                    required property var modelData
                    readonly property bool sel: root.mode === modelData.id
                    implicitHeight: 32
                    implicitWidth: tabRow.implicitWidth + 24
                    radius: 16
                    color: sel ? Theme.primaryFillStrong : Theme.surfaceContainerHigh

                    RowLayout {
                        id: tabRow
                        anchors.centerIn: parent
                        spacing: 6
                        Icon {
                            text: modelData.icon
                            size: 15
                            color: sel ? Theme.primary : Theme.textDim
                        }
                        StyledText {
                            text: modelData.label
                            font.pixelSize: Theme.font.small
                            font.weight: Font.DemiBold
                            color: sel ? Theme.primary : Theme.text
                        }
                    }
                    StateLayer {
                        tint: sel ? Theme.primary : Theme.text
                        onClicked: Ui.launcherMode = modelData.id
                    }
                }
            }
            Item {
                Layout.fillWidth: true
            }
            StyledText {
                text: "Tab cambia modalità"
                font.pixelSize: Theme.font.tiny
                color: Theme.textFaint
            }
        }

        // Risultato calcolatrice / esegui / chiedi
        StyledRect {
            Layout.fillWidth: true
            visible: root.calcMode || root.runMode || root.askMode
            implicitHeight: 84
            radius: Theme.radius.large
            color: Theme.primaryContainer

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14
                Icon {
                    text: root.calcMode ? Icons.calculator : root.runMode ? Icons.terminal : Icons.sparkle
                    size: 30
                    color: Theme.primary
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    StyledText {
                        Layout.fillWidth: true
                        text: root.calcMode ? (root.calcResult !== "" ? "= " + root.calcResult : "…") : root.runMode ? root.query.slice(1).trim() || "comando…" : root.query.slice(1).trim() || "domanda…"
                        font.family: Theme.font.mono
                        font.pixelSize: Theme.font.large
                        font.weight: Font.Bold
                        color: Theme.fgPrimaryContainer
                    }
                    StyledText {
                        text: root.calcMode ? "Invio per copiare il risultato" : root.runMode ? "Invio per eseguire" : "Invio per chiedere a Morpheus"
                        font.pixelSize: Theme.font.small
                        color: Theme.alpha(Theme.fgPrimaryContainer, 0.7)
                    }
                }
            }
        }

        // Lista risultati
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !(root.calcMode || root.runMode || root.askMode)
            clip: true
            model: root.items
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: Theme.anim.fast
            highlightFollowsCurrentItem: true
            keyNavigationEnabled: false
            ScrollBar.vertical: StyledScrollBar {}

            highlight: StyledRect {
                radius: Theme.radius.normal
                color: Theme.primaryContainer
                border.width: 1
                border.color: Theme.outline
            }

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                width: list.width - 8
                implicitHeight: root.mode === "clipboard" && modelData.isImage ? 84 : 52

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 14

                    // Icona
                    Item {
                        implicitWidth: 34
                        implicitHeight: 34
                        visible: !(root.mode === "clipboard" && row.modelData.isImage)
                        IconImage {
                            anchors.fill: parent
                            visible: root.mode === "apps"
                            source: root.mode === "apps" ? Apps.iconFor(row.modelData) : ""
                            asynchronous: true
                        }
                        Icon {
                            anchors.centerIn: parent
                            visible: root.mode !== "apps"
                            text: root.mode === "commands" ? row.modelData.icon : Icons.textBox
                            size: 22
                            color: row.ListView.isCurrentItem ? Theme.primary : Theme.textDim
                        }
                    }

                    // Anteprima immagine appunti
                    Image {
                        id: thumb
                        visible: root.mode === "clipboard" && row.modelData.isImage
                        Layout.preferredWidth: 110
                        Layout.preferredHeight: 72
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        sourceSize: Qt.size(220, 144)
                        Process {
                            running: root.mode === "clipboard" && row.modelData.isImage
                            command: ["sh", "-c", "mkdir -p \"$1\"; [ -s \"$2\" ] || cliphist decode \"$3\" > \"$2\"", "_", Clipboard.cacheDir, Clipboard.imagePath(row.modelData), row.modelData.id]
                            onExited: thumb.source = "file://" + Clipboard.imagePath(row.modelData)
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        StyledText {
                            Layout.fillWidth: true
                            text: root.mode === "apps" ? row.modelData.name : root.mode === "commands" ? row.modelData.name : (row.modelData.isImage ? "Immagine" : row.modelData.text.replace(/\s+/g, " "))
                            font.weight: root.mode === "clipboard" ? Font.Normal : Font.DemiBold
                            font.family: root.mode === "clipboard" && !row.modelData.isImage ? Theme.font.mono : Theme.font.sans
                            font.pixelSize: root.mode === "clipboard" ? Theme.font.small : Theme.font.body
                            color: row.ListView.isCurrentItem ? Theme.fgPrimaryContainer : Theme.text
                        }
                        StyledText {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: root.mode === "apps" ? (row.modelData.genericName || row.modelData.comment || "") : root.mode === "clipboard" && row.modelData.isImage ? row.modelData.text : ""
                            font.pixelSize: Theme.font.small
                            color: Theme.textDim
                        }
                    }

                    IconButton {
                        visible: root.mode === "clipboard" && row.ListView.isCurrentItem
                        size: 30
                        icon: Icons.trash
                        iconColor: Theme.textDim
                        onClicked: Clipboard.remove(row.modelData)
                    }
                    StyledText {
                        visible: row.ListView.isCurrentItem && root.mode !== "clipboard"
                        text: "↵"
                        color: Theme.primary
                        font.pixelSize: Theme.font.title
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    z: -1
                    onEntered: list.currentIndex = row.index
                    onClicked: root.activate(row.index)
                }
            }

            // Stato vuoto
            ColumnLayout {
                anchors.centerIn: parent
                visible: list.count === 0
                spacing: 8
                Icon {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.mode === "clipboard" ? Icons.clipboard : Icons.magnify
                    size: 40
                    color: Theme.primaryDim
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.mode === "clipboard" ? (Clipboard.loading ? "Carico…" : "Appunti vuoti (serve cliphist)") : "Nessun risultato"
                    color: Theme.textDim
                }
            }
        }
    }
}
