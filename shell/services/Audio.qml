pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import qs.config

// Audio via Pipewire nativo: niente pamixer, niente polling.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? false

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.audio && n.isStream && !n.isSink)

    readonly property string icon: muted ? Icons.volumeOff : volume <= 0.001 ? Icons.volumeMute : volume < 0.34 ? Icons.volumeLow : volume < 0.67 ? Icons.volumeMedium : Icons.volumeHigh
    readonly property string micIcon: micMuted ? Icons.micOff : Icons.mic

    // Emesso quando l'utente cambia volume/mute (per l'OSD)
    signal volumeTouched

    PwObjectTracker {
        objects: [root.sink, root.source].concat(root.sinks, root.sources, root.streams).filter(n => n)
    }

    function clamp(v) {
        return Math.max(0, Math.min(1.5, v));
    }

    // Il volume si scrive con wpctl, non con sink.audio.volume: con alcune uscite (es. cuffie
    // Bluetooth) parte delle scritture di Quickshell non arrivava a PipeWire e il volume visto
    // dalla shell si scollegava da quello reale, così i tasti sembravano non fare nulla.
    function setVolume(v) {
        if (!sink?.audio)
            return;
        _pendingVolume = clamp(v);
        volumeWrite.restart();
    }
    property real _pendingVolume: -1
    Timer {
        id: volumeWrite
        interval: 30   // durante il trascinamento dello slider scrive solo l'ultimo valore
        onTriggered: {
            Quickshell.execDetached(["sh", "-c", "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ " + root._pendingVolume.toFixed(3)]);
        }
    }
    function changeVolume(delta) {
        if (!sink?.audio)
            return;
        // passo relativo sul valore reale; oltre il 100% solo se ci si era già (boost fino a 150%)
        const limit = delta > 0 && volume < 0.999 ? 1.0 : 1.5;
        const step = Math.round(Math.abs(delta) * 100) + "%" + (delta > 0 ? "+" : "-");
        Quickshell.execDetached(["sh", "-c", "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l " + limit + " @DEFAULT_AUDIO_SINK@ " + step]);
    }
    function toggleMute() {
        if (sink?.audio)
            Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
    }
    function setMicVolume(v) {
        if (source?.audio) {
            source.audio.muted = false;
            source.audio.volume = clamp(v);
        }
    }
    function toggleMicMute() {
        if (source?.audio)
            source.audio.muted = !source.audio.muted;
    }
    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }
    function setDefaultSource(node) {
        Pipewire.preferredDefaultAudioSource = node;
    }

    function nodeName(n) {
        if (!n)
            return "—";
        return n.description || n.nickname || n.name;
    }
    function streamName(n) {
        const p = n?.properties ?? {};
        return p["application.name"] || n?.description || n?.name || "App";
    }
    function streamDetail(n) {
        const p = n?.properties ?? {};
        return p["media.name"] || "";
    }
    function streamIcon(n) {
        const p = n?.properties ?? {};
        const name = p["application.icon-name"] || p["application.process.binary"] || "";
        return name ? Quickshell.iconPath(name, "audio-x-generic") : Quickshell.iconPath("audio-x-generic");
    }
    function sinkIcon(n) {
        const d = (nodeName(n) + " " + (n?.name ?? "")).toLowerCase();
        if (d.includes("bluez") || d.includes("headphone") || d.includes("headset") || d.includes("buds"))
            return Icons.headphones;
        if (d.includes("hdmi") || d.includes("displayport"))
            return Icons.monitor;
        return Icons.speaker;
    }

    // Rileva cambi di volume "veri" (non quelli dovuti al cambio di dispositivo)
    property int _lastSinkId: -1
    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() {
            if (root.sink?.id === root._lastSinkId)
                root.volumeTouched();
            root._lastSinkId = root.sink?.id ?? -1;
        }
        function onMutedChanged() {
            if (root.sink?.id === root._lastSinkId)
                root.volumeTouched();
            root._lastSinkId = root.sink?.id ?? -1;
        }
    }
    onSinkChanged: settle.restart()
    Timer {
        id: settle
        interval: 400
        onTriggered: root._lastSinkId = root.sink?.id ?? -1
    }
}
