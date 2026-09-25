pragma Singleton

import QtQuick
import Quickshell

// I "toast" dei plugin diventano notifiche della shell.
Singleton {
    readonly property int levelInfo: 0
    readonly property int levelWarn: 1
    readonly property int levelError: 2

    function showToast(message, level, details, command, category) {
        const urgency = level === levelError ? "critical" : level === levelWarn ? "normal" : "low";
        const args = ["notify-send", "-a", "Plugin", "-u", urgency, String(message)];
        if (details)
            args.push(String(details));
        Quickshell.execDetached(args);
    }
    function showInfo(message, details, command, category) {
        showToast(message, levelInfo, details);
    }
    function showSuccess(message, details, command, category) {
        showToast(message, levelInfo, details);
    }
    function showWarning(message, details, command, category) {
        showToast(message, levelWarn, details);
    }
    function showError(message, details, command, category) {
        showToast(message, levelError, details);
    }
}
