import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.services as S

// Contenitore dei widget dei plugin DMS, compatibile con l'API di DankMaterialShell.
// Il popup del plugin si apre nel sistema di popout della shell (Ui.popout = "plugin").
Item {
    id: root

    property string layerNamespacePlugin: "plugin"

    property var surfaceContext: null
    property var hostContext: null
    property string widgetInstanceId: ""
    property Component attachedContent: null
    property var axis: null
    property string section: "right"
    property var parentScreen: null
    property real widgetThickness: 30
    property real barThickness: 40
    property real barSpacing: 4
    property var barConfig: null
    property var blurBarWindow: null
    property string pluginId: ""
    property var pluginService: null
    property bool isFirst: false
    property bool isLast: false
    property bool isLeftBarEdge: false
    property bool isRightBarEdge: false
    property bool isTopBarEdge: false
    property bool isBottomBarEdge: false
    property real sectionSpacing: 0
    property string segmentRole: "solo"
    property real crossEdgeExtension: 0

    property string visibilityCommand: ""
    property int visibilityInterval: 0
    property bool conditionVisible: true
    property bool _visibilityOverride: false
    property bool _visibilityOverrideValue: true

    readonly property bool effectiveVisible: {
        if (_visibilityOverride)
            return _visibilityOverrideValue;
        if (!visibilityCommand)
            return true;
        return conditionVisible;
    }

    property Component horizontalBarPill: null
    property Component verticalBarPill: null
    property Component popoutContent: null
    property real popoutWidth: 400
    property real popoutHeight: 0
    property var pillClickAction: null
    property var pillRightClickAction: null

    // Control center dei plugin: non ancora supportato dalla shell (proprietà presenti per compatibilità)
    property Component controlCenterWidget: null
    property string ccWidgetIcon: ""
    property string ccWidgetPrimaryText: ""
    property string ccWidgetSecondaryText: ""
    property bool ccWidgetIsActive: false
    property bool ccWidgetIsToggle: true
    property Component ccExpandedContent: null
    property real ccExpandedMinimumHeight: 56
    property Component ccDetailContent: null
    property real ccDetailHeight: 250
    signal ccWidgetToggled
    signal ccWidgetExpanded

    property var pluginData: ({})
    property var variants: []

    readonly property bool isVertical: false
    readonly property bool hasHorizontalPill: horizontalBarPill !== null
    readonly property bool hasVerticalPill: verticalBarPill !== null
    readonly property bool hasPopout: popoutContent !== null
    readonly property bool interactionActive: popoutOpen
    readonly property bool popoutOpen: S.Ui.popout === "plugin" && S.Ui.popoutData === root

    readonly property int iconSize: Theme.barIconSize(barThickness, -4)
    readonly property int iconSizeLarge: Theme.barIconSize(barThickness)
    readonly property int textSize: Theme.barTextSize(barThickness)

    implicitWidth: hasHorizontalPill && effectiveVisible ? pill.width : 0
    implicitHeight: widgetThickness
    width: implicitWidth
    height: implicitHeight
    visible: hasHorizontalPill

    Component.onCompleted: {
        loadPluginData();
        if (visibilityCommand)
            Qt.callLater(checkVisibility);
    }
    onPluginServiceChanged: loadPluginData()
    onPluginIdChanged: loadPluginData()

    Connections {
        target: root.pluginService
        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId === root.pluginId)
                root.loadPluginData();
        }
    }

    function loadPluginData() {
        if (!pluginService || !pluginId) {
            pluginData = {};
            variants = [];
            return;
        }
        pluginData = SettingsData.getPluginSettingsForPlugin(pluginId);
        variants = pluginService.getPluginVariants(pluginId);
    }

    function checkVisibility() {
        if (!visibilityCommand) {
            conditionVisible = true;
            return;
        }
        visibilityProcess.running = true;
    }
    function setVisibilityOverride(v) {
        _visibilityOverride = true;
        _visibilityOverrideValue = v;
    }
    function clearVisibilityOverride() {
        _visibilityOverride = false;
        if (visibilityCommand)
            checkVisibility();
    }
    onVisibilityCommandChanged: visibilityCommand ? Qt.callLater(checkVisibility) : (conditionVisible = true)

    Timer {
        interval: Math.max(1, root.visibilityInterval) * 1000
        repeat: true
        running: root.visibilityInterval > 0 && root.visibilityCommand !== "" && !root._visibilityOverride
        onTriggered: root.checkVisibility()
    }
    Process {
        id: visibilityProcess
        command: ["sh", "-c", root.visibilityCommand]
        onExited: code => root.conditionVisible = (code === 0)
    }

    function createVariant(variantName, variantConfig) {
        return pluginService?.createPluginVariant(pluginId, variantName, variantConfig) ?? null;
    }
    function removeVariant(variantId) {
        pluginService?.removePluginVariant(pluginId, variantId);
    }
    function updateVariant(variantId, variantConfig) {
        pluginService?.updatePluginVariant(pluginId, variantId, variantConfig);
    }

    BasePill {
        id: pill
        opacity: root.effectiveVisible ? 1 : 0
        section: root.section
        parentScreen: root.parentScreen
        widgetThickness: root.widgetThickness
        barThickness: root.barThickness
        content: root.horizontalBarPill
        onClicked: root.triggerPopout()
        onRightClicked: root.runPillAction(root.pillRightClickAction)

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }
    }

    function pillCenterX() {
        return pill.mapToItem(null, pill.width / 2, 0).x;
    }

    function runPillAction(action) {
        if (!action)
            return;
        if (action.length === 0) {
            action();
            return;
        }
        const x = pill.mapToItem(null, 0, 0).x;
        action(x, barThickness, pill.width, section, parentScreen);
    }

    function triggerPopout() {
        if (pillClickAction) {
            runPillAction(pillClickAction);
            return;
        }
        if (hasPopout)
            S.Ui.togglePopout("plugin", parentScreen?.name ?? "", pillCenterX(), root);
    }

    function closePopout() {
        if (popoutOpen)
            S.Ui.closePopout();
    }
}
