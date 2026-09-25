pragma Singleton

import Quickshell
import QtQuick

// Design system: colori (derivati dall'accento), tipografia, raggi,
// spaziature e curve di animazione. Tutta la UI legge da qui.
Singleton {
    id: root

    // ── Accenti disponibili ──
    readonly property var accents: ({
        matrix:  { name: "Matrix",   color: "#00ff41" },
        emerald: { name: I18n.tr("Smeraldo"), color: "#3ddc97" },
        cyan:    { name: I18n.tr("Ciano"),    color: "#00e5ff" },
        ice:     { name: I18n.tr("Ghiaccio"), color: "#8ab4f8" },
        violet:  { name: I18n.tr("Viola"),    color: "#b388ff" },
        rose:    { name: I18n.tr("Rosa"),     color: "#ff6e9c" },
        amber:   { name: I18n.tr("Ambra"),    color: "#ffb000" },
        red:     { name: I18n.tr("Rosso"),    color: "#ff4d4d" }
    })
    readonly property var accentKeys: ["matrix", "emerald", "cyan", "ice", "violet", "rose", "amber", "red"]

    // Accento temporaneo (es. plugin "Music Theme": colore della copertina). Trasparente = nessuno.
    property color accentOverride: "transparent"
    readonly property color accentBase: (accents[Settings.accent] ?? accents.matrix).color
    readonly property color primary: accentOverride.a > 0 ? accentOverride : accentBase

    Behavior on accentOverride {
        ColorAnimation {
            duration: 600
        }
    }

    // ── Basi neutre ──
    readonly property color _black: Qt.rgba(0, 0, 0, 1)
    readonly property color _white: Qt.rgba(1, 1, 1, 1)
    readonly property color _n0: "#060807"
    readonly property color _n1: "#0b0e0c"
    readonly property color _n2: "#101411"
    readonly property color _n3: "#151a16"
    readonly property color _n4: "#1b211c"
    readonly property color _n5: "#232a24"
    readonly property color _text: "#e4ece6"
    readonly property color _textDim: "#97a39a"
    readonly property color _textFaint: "#5b665e"

    function mix(a, b, t) {
        return Qt.rgba(a.r * (1 - t) + b.r * t, a.g * (1 - t) + b.g * t, a.b * (1 - t) + b.b * t, a.a * (1 - t) + b.a * t);
    }
    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    // ── Palette (stile Material 3, tinta sull'accento) ──
    readonly property color background: mix(_n0, primary, 0.015)
    readonly property color surface: mix(_n1, primary, 0.025)
    readonly property color surfaceContainerLow: mix(_n2, primary, 0.03)
    readonly property color surfaceContainer: mix(_n3, primary, 0.035)
    readonly property color surfaceContainerHigh: mix(_n4, primary, 0.04)
    readonly property color surfaceContainerHighest: mix(_n5, primary, 0.05)

    // Elementi "attivi": verde brillante su verde scuro (stile neon), mai nero su verde
    readonly property color primaryFill: mix(_n2, primary, 0.2)
    readonly property color primaryFillStrong: mix(_n2, primary, 0.28)
    readonly property color fgPrimary: mix(_white, primary, 0.9)
    readonly property color primaryContainer: mix(_n2, primary, 0.13)
    readonly property color fgPrimaryContainer: mix(_white, primary, 0.5)
    readonly property color primaryDim: mix(_n1, primary, 0.55)

    readonly property color text: mix(_text, primary, 0.05)
    readonly property color textDim: mix(_textDim, primary, 0.08)
    readonly property color textFaint: mix(_textFaint, primary, 0.05)

    readonly property color outline: alpha(primary, 0.18)
    readonly property color outlineVariant: alpha(_white, 0.07)

    // Opacità dei pannelli (popout, launcher, notifiche, OSD…): segue la barra se richiesto
    readonly property real panelOpacity: Math.max(0.15, Settings.panelsFollowBar ? Settings.barOpacity : Settings.panelOpacity)

    readonly property color error: "#ff5c6c"
    readonly property color errorContainer: mix(_n2, error, 0.22)
    readonly property color warning: "#ffc857"
    readonly property color success: "#3ddc84"

    // Livello di "state layer" (hover/pressed) come in Material
    readonly property real hoverOpacity: 0.08
    readonly property real pressOpacity: 0.14

    // ── Tipografia ──
    readonly property QtObject font: QtObject {
        readonly property string sans: "Adwaita Sans"
        readonly property string mono: "JetBrainsMono Nerd Font"
        readonly property string icon: "JetBrainsMono Nerd Font Propo"
        readonly property real scale: Settings.fontScale
        readonly property int tiny: Math.round(10 * scale)
        readonly property int small: Math.round(11.5 * scale)
        readonly property int body: Math.round(13 * scale)
        readonly property int title: Math.round(15 * scale)
        readonly property int large: Math.round(18 * scale)
        readonly property int headline: Math.round(26 * scale)
        readonly property int display: Math.round(44 * scale)
    }

    // ── Forme ──
    readonly property QtObject radius: QtObject {
        readonly property int xs: 6
        readonly property int small: 10
        readonly property int normal: 14
        readonly property int large: 20
        readonly property int xl: 28
        readonly property int full: 999
    }

    readonly property QtObject spacing: QtObject {
        readonly property int xs: 4
        readonly property int small: 8
        readonly property int normal: 12
        readonly property int large: 16
        readonly property int xl: 24
    }

    // ── Barra ──
    readonly property int barHeight: 40
    readonly property int barMargin: Settings.barFloating ? 6 : 0
    readonly property int barTotal: barHeight + barMargin

    // ── Animazioni (curve Material 3) ──
    readonly property QtObject anim: QtObject {
        readonly property bool enabled: Settings.animations
        readonly property int fast: enabled ? 140 : 0
        readonly property int normal: enabled ? 260 : 0
        readonly property int slow: enabled ? 420 : 0
        readonly property int slower: enabled ? 600 : 0
        readonly property var emphasized: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property var emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property var standard: [0.2, 0, 0, 1, 1, 1]
        readonly property var expressive: [0.38, 1.21, 0.22, 1, 1, 1]
    }
}
