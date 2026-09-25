pragma Singleton

import QtQuick
import Quickshell
import qs.config as G

// Sottoinsieme di SessionData di DMS usato dai plugin, collegato alla shell.
Singleton {
    readonly property bool doNotDisturb: G.Settings.dnd
    readonly property string locale: G.I18n.lang
    readonly property string wallpaperPath: G.Settings.wallpaper

    function setDoNotDisturb(on) {
        G.Settings.dnd = on;
    }
    function setWallpaper(path) {
        G.Settings.wallpaper = path;
        Quickshell.execDetached(["awww", "img", path, "--transition-type", G.Settings.wallpaperTransition]);
    }
    function suppressOSDTemporarily() {
    }
}
