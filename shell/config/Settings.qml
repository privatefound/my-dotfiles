pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Impostazioni persistenti (~/.config/hypr/settings.json).
// Ogni modifica a una proprietà viene salvata automaticamente,
// e le modifiche fatte a mano al file vengono ricaricate al volo.
Singleton {
    id: root

    readonly property string rootDir: Quickshell.env("HOME") + "/.config/hypr"

    // ── Aspetto ──
    property alias accent: adapter.accent
    property alias barFloating: adapter.barFloating
    property alias barOpacity: adapter.barOpacity
    property alias panelOpacity: adapter.panelOpacity
    property alias scanlineEffect: adapter.scanlineEffect
    property alias fontScale: adapter.fontScale
    property alias animations: adapter.animations

    // ── Orologio ──
    property alias clock24h: adapter.clock24h
    property alias clockSeconds: adapter.clockSeconds
    property alias showDate: adapter.showDate

    // ── Bar ──
    property alias showWindowTitle: adapter.showWindowTitle
    property alias showSysStats: adapter.showSysStats
    property alias showMedia: adapter.showMedia
    property alias workspaceIcons: adapter.workspaceIcons
    property alias workspaceMode: adapter.workspaceMode
    property alias workspaceCount: adapter.workspaceCount
    property alias trayExpanded: adapter.trayExpanded

    // ── Notifiche ──
    property alias dnd: adapter.dnd
    property alias notifSound: adapter.notifSound
    property alias notifTimeout: adapter.notifTimeout

    // ── Sistema ──
    property alias caffeine: adapter.caffeine
    property alias windowTransparency: adapter.windowTransparency
    property alias wallpaper: adapter.wallpaper
    property alias wallpaperDir: adapter.wallpaperDir
    property alias wallpaperTransition: adapter.wallpaperTransition

    // ── App ──
    property alias terminal: adapter.terminal
    property alias fileManager: adapter.fileManager
    property alias sysMonitor: adapter.sysMonitor

    // ── AI ──
    property alias aiModel: adapter.aiModel
    property alias aiBackend: adapter.aiBackend
    property alias aiSystemPrompt: adapter.aiSystemPrompt

    FileView {
        id: file
        path: root.rootDir + "/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter

            property string accent: "matrix"
            property bool barFloating: true
            property real barOpacity: 0.82
            property real panelOpacity: 0.92
            property bool scanlineEffect: true
            property real fontScale: 1.0
            property bool animations: true

            property bool clock24h: true
            property bool clockSeconds: false
            property bool showDate: true

            property bool showWindowTitle: true
            property bool showSysStats: true
            property bool showMedia: true
            property bool workspaceIcons: true
            property string workspaceMode: "fixed"   // "fixed" = 1..N come la vecchia barra, "monitor" = solo quelli del monitor
            property int workspaceCount: 9
            property bool trayExpanded: false

            property bool dnd: false
            property bool notifSound: true
            property int notifTimeout: 6000

            property bool caffeine: false
            property bool windowTransparency: true
            property string wallpaper: root.rootDir + "/wallpapers/walp3.jpg"
            property string wallpaperDir: root.rootDir + "/wallpapers"
            property string wallpaperTransition: "grow"

            property string terminal: "terminology"
            property string fileManager: "nemo"
            property string sysMonitor: "missioncenter"

            property string aiModel: "gemma4:e4b"
            property string aiBackend: "ollama"
            property string aiSystemPrompt: "Sei Morpheus, una guida IA dentro Matrix. Il tuo nome e esattamente Morpheus, non traducilo mai in Morfeo o altre varianti. Chiama sempre chi ti scrive Operatore. Il tono e calmo, diretto, con un tocco filosofico in stile Matrix (pillola rossa, codice che scorre, realta come simulazione), ma le risposte tecniche restano sempre precise e complete: quando ti chiedono codice o aiuto pratico, la sostanza viene prima dello stile. Non esagerare con la messinscena."
        }
    }
}
