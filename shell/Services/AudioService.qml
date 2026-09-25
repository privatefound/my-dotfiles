pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.services as S

// AudioService di DMS (sottoinsieme) sopra il servizio audio della shell.
Singleton {
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property int sinkMaxVolume: 150
    readonly property int sinkVolumePercent: Math.round((sink?.audio?.volume ?? 0) * 100)
    property bool notificationsAudioMuted: false

    function setVolume(percentage) {
        S.Audio.setVolume(percentage / 100);
    }
    function toggleMute() {
        S.Audio.toggleMute();
    }
    function toggleMicMute() {
        S.Audio.toggleMicMute();
    }
    function playCriticalNotificationSound() {
    }
}
