pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.services as S

Singleton {
    readonly property var availablePlayers: Mpris.players.values
    readonly property var activePlayer: S.Media.active
    readonly property string stableTitle: activePlayer?.trackTitle ?? ""
    readonly property string stableArtist: activePlayer?.trackArtist ?? ""
    readonly property string stableAlbum: activePlayer?.trackAlbum ?? ""
}
