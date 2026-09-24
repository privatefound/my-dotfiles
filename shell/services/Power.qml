pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick
import qs.config

// Batteria via UPower (D-Bus).
Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool hasBattery: device?.isLaptopBattery ?? false
    readonly property real percentage: device?.percentage ?? 0
    readonly property int percent: Math.round(percentage * 100)
    readonly property bool charging: device?.state === UPowerDeviceState.Charging || device?.state === UPowerDeviceState.PendingCharge
    readonly property bool full: device?.state === UPowerDeviceState.FullyCharged
    readonly property bool acPlugged: !UPower.onBattery
    readonly property bool low: !charging && percent <= 15

    readonly property string icon: {
        if (!hasBattery)
            return Icons.powerPlug;
        if (full || (acPlugged && percent >= 99))
            return Icons.batteryCharging100;
        if (charging)
            return percent > 70 ? Icons.batteryCharging80 : percent > 35 ? Icons.batteryCharging50 : Icons.batteryCharging20;
        const steps = [Icons.batteryOutline, Icons.battery10, Icons.battery20, Icons.battery30, Icons.battery40, Icons.battery50, Icons.battery60, Icons.battery70, Icons.battery80, Icons.battery90, Icons.battery];
        return steps[Math.min(10, Math.max(0, Math.round(percent / 10)))];
    }

    readonly property string timeLabel: {
        const secs = charging ? device?.timeToFull : device?.timeToEmpty;
        if (!secs || secs <= 0)
            return full ? I18n.tr("Carica completa") : charging ? I18n.tr("In carica") : "";
        const h = Math.floor(secs / 3600);
        const m = Math.floor((secs % 3600) / 60);
        return (h > 0 ? `${h}h ${m}m` : `${m}m`) + (charging ? I18n.tr(" alla carica completa") : I18n.tr(" rimanenti"));
    }

}
