pragma Singleton

import QtQuick
import Quickshell
import qs.services as S

Singleton {
    readonly property string resolvedArtUrl: S.Media.art
    readonly property string _bgArtSource: S.Media.art

    function loadArtwork(url) {
    }
    function artReadyFor(url) {
        return true;
    }
}
