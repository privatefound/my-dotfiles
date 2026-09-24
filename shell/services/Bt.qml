pragma Singleton

import Quickshell
import Quickshell.Bluetooth
import QtQuick
import qs.config

// Bluetooth via BlueZ D-Bus (Quickshell.Bluetooth). Niente bluetoothctl.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property bool discovering: adapter?.discovering ?? false

    readonly property var devices: (adapter ? adapter.devices.values : []).slice().sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || ((a.name || "").localeCompare(b.name || "")))
    readonly property var connectedDevices: devices.filter(d => d.connected)
    readonly property var pairedDevices: devices.filter(d => d.paired || d.bonded)
    readonly property var otherDevices: devices.filter(d => !d.paired && !d.bonded && d.name && d.name !== d.address.replace(/:/g, "-"))

    readonly property string icon: !enabled ? Icons.bluetoothOff : connectedDevices.length > 0 ? Icons.bluetoothConnect : Icons.bluetooth
    readonly property string label: !available ? I18n.tr("Spento") : !enabled ? I18n.tr("Spento") : connectedDevices.length === 1 ? deviceName(connectedDevices[0]) : connectedDevices.length > 1 ? connectedDevices.length + I18n.tr(" dispositivi") : I18n.tr("Acceso")

    readonly property bool blocked: !adapter || adapter.state === BluetoothAdapterState.Blocked

    // Accende/spegne; se la radio è bloccata (rfkill) la sblocca prima
    function setEnabled(on) {
        if (on && blocked) {
            Quickshell.execDetached(["rfkill", "unblock", "bluetooth"]);
            powerOnLater.restart();
            return;
        }
        if (adapter)
            adapter.enabled = on;
    }

    Timer {
        id: powerOnLater
        interval: 900
        onTriggered: if (root.adapter) root.adapter.enabled = true
    }
    function setDiscovering(on) {
        if (adapter)
            adapter.discovering = on;
    }
    function deviceName(d) {
        return d?.name || d?.deviceName || d?.address || I18n.tr("Dispositivo");
    }
    function deviceIcon(d) {
        const i = d?.icon ?? "";
        if (i.includes("headset") || i.includes("headphone") || i.includes("audio"))
            return Icons.headphones;
        if (i.includes("keyboard"))
            return Icons.keyboard;
        if (i.includes("mouse") || i.includes("input"))
            return Icons.gauge;
        if (i.includes("phone"))
            return Icons.message;
        return Icons.bluetooth;
    }
    function toggleConnection(d) {
        if (d.connected) {
            d.disconnect();
        } else if (!d.paired && !d.bonded) {
            d.trusted = true;
            d.pair();
        } else {
            d.connect();
        }
    }
    function stateLabel(d) {
        if (d.pairing)
            return I18n.tr("Associazione…");
        switch (d.state) {
        case BluetoothDeviceState.Connecting:
            return I18n.tr("Connessione…");
        case BluetoothDeviceState.Disconnecting:
            return I18n.tr("Disconnessione…");
        case BluetoothDeviceState.Connected:
            return d.batteryAvailable ? `Connesso · ${Math.round(d.battery * 100)}%` : I18n.tr("Connesso");
        }
        return d.paired || d.bonded ? I18n.tr("Associato") : I18n.tr("Disponibile");
    }
}
