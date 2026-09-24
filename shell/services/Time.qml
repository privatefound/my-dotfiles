pragma Singleton

import Quickshell
import QtQuick
import qs.config

Singleton {
    id: root

    readonly property date now: clock.date
    readonly property string time: Qt.formatTime(now, Settings.clock24h ? (Settings.clockSeconds ? "HH:mm:ss" : "HH:mm") : (Settings.clockSeconds ? "h:mm:ss AP" : "h:mm AP"))
    readonly property string dateShort: Qt.locale("it_IT").toString(now, "ddd d MMM")
    readonly property string longDate: Qt.locale("it_IT").toString(now, "dddd d MMMM yyyy")

    SystemClock {
        id: clock
        precision: Settings.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }
}
