pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config as G

// Lingua per i plugin DMS: I18n.tr(testo, contesto) restituisce il testo originale
// (i plugin sono in inglese); locale segue la lingua scelta nella shell.
Singleton {
    readonly property bool isRtl: false
    readonly property string currentLocale: G.I18n.lang
    readonly property var locale: G.I18n.locale

    function tr(term, context) {
        return term;
    }
    function trFor(pluginId, term, context) {
        return term;
    }
}
