pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// Lettori multimediali (MPRIS).
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    property var selected: null
    readonly property var active: (selected && players.includes(selected)) ? selected : (players.find(p => p.isPlaying) ?? players[0] ?? null)
    readonly property bool hasPlayer: active !== null
    readonly property bool playing: active?.isPlaying ?? false
    readonly property string title: active?.trackTitle || "Nessun brano"
    readonly property string artist: active?.trackArtist || active?.identity || ""
    readonly property string art: active?.trackArtUrl ?? ""

    function toggle() {
        if (active?.canTogglePlaying)
            active.togglePlaying();
    }
    function next() {
        if (active?.canGoNext)
            active.next();
    }
    function previous() {
        if (active?.canGoPrevious)
            active.previous();
    }
    function formatTime(s) {
        if (!s || s < 0 || !isFinite(s))
            return "0:00";
        s = Math.floor(s);
        const m = Math.floor(s / 60);
        const sec = s % 60;
        return m + ":" + (sec < 10 ? "0" : "") + sec;
    }

    // La posizione MPRIS non si aggiorna da sola: la ricalcoliamo mentre suona
    Timer {
        running: root.playing
        interval: 1000
        repeat: true
        onTriggered: root.active?.positionChanged()
    }
}
