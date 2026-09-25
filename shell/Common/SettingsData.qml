pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config as G

Singleton {
    id: root

    enum AnimationSpeed {
        None,
        Short,
        Medium,
        Long,
        Custom
    }

    enum TextRenderType {
        Qt,
        Native,
        Curve
    }

    enum Position {
        Top,
        Bottom,
        Left,
        Right,
        TopCenter,
        BottomCenter,
        LeftCenter,
        RightCenter
    }

    enum TextRenderQuality {
        Default,
        Low,
        Normal,
        High,
        VeryHigh
    }

    property int animationSpeed: SettingsData.AnimationSpeed.Short
    property bool reduceMotion: !G.Settings.animations
    property bool blurBorderEnabled: false
    property real blurLayerOutlineOpacity: 0
    property real blurBorderOpacity: 0.35
    property string blurBorderColor: "outline"
    property string blurBorderCustomColor: "#ffffff"
    property int springBounce: 1
    property bool enableRippleEffects: true
    property bool powerActionConfirm: true
    property real powerActionHoldDuration: 0.5
    property var powerMenuActions: ["reboot", "logout", "poweroff", "lock", "suspend", "restart"]
    property string powerMenuDefaultAction: "logout"
    property bool powerMenuGridLayout: false
    property bool popoutElevationEnabled: true
    property int textRenderType: SettingsData.TextRenderType.Qt
    property int textRenderQuality: SettingsData.TextRenderQuality.Default

    // ── Impostazioni dei plugin DMS (state/plugin-settings.json, non versionato) ──
    readonly property bool use24HourClock: G.Settings.clock24h
    readonly property bool padHours12Hour: false
    readonly property bool soundsEnabled: G.Settings.notifSound
    readonly property bool audioVisualizerEnabled: false
    readonly property bool scrollTitleEnabled: false
    readonly property int mediaSize: 1
    property var pluginSettings: ({})

    function getPluginSetting(pluginId, key, defaultValue) {
        const p = pluginSettings[pluginId];
        return p && p[key] !== undefined ? p[key] : defaultValue;
    }
    function setPluginSetting(pluginId, key, value) {
        const updated = JSON.parse(JSON.stringify(pluginSettings));
        if (!updated[pluginId])
            updated[pluginId] = {};
        updated[pluginId][key] = value;
        pluginSettings = updated;
        pluginFile.setText(JSON.stringify(pluginSettings, null, 2));
    }
    function getPluginSettingsForPlugin(pluginId) {
        const p = pluginSettings[pluginId];
        return p ? JSON.parse(JSON.stringify(p)) : {};
    }
    function removePluginSettings(pluginId) {
        const updated = JSON.parse(JSON.stringify(pluginSettings));
        delete updated[pluginId];
        pluginSettings = updated;
        pluginFile.setText(JSON.stringify(pluginSettings, null, 2));
    }
    function getScreenDisplayName(screen) {
        return screen?.name ?? "";
    }
    function getPopupTriggerPosition(pos, screen, barThickness, widgetWidth) {
        return { x: pos.x, y: barThickness, width: widgetWidth };
    }

    FileView {
        id: pluginFile
        path: G.Settings.rootDir + "/state/plugin-settings.json"
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                root.pluginSettings = JSON.parse(text() || "{}");
            } catch (e) {
                root.pluginSettings = {};
            }
        }
    }
}
