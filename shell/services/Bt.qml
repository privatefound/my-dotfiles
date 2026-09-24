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
    readonly property string label: !available ? "Non disponibile" : !enabled ? "Spento" : connectedDevices.length === 1 ? deviceName(connectedDevices[0]) : connectedDevices.length > 1 ? connectedDevices.length + " dispositivi" : "Acceso"

    function setEnabled(on) {
        if (adapter)
            adapter.enabled = on;
    }
    function setDiscovering(on) {
        if (adapter)
            adapter.discovering = on;
    }
    function deviceName(d) {
        return d?.name || d?.deviceName || d?.address || "Dispositivo";
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
            return "Associazione…";
        switch (d.state) {
        case BluetoothDeviceState.Connecting:
            return "Connessione…";
        case BluetoothDeviceState.Disconnecting:
            return "Disconnessione…";
        case BluetoothDeviceState.Connected:
            return d.batteryAvailable ? `Connesso · ${Math.round(d.battery * 100)}%` : "Connesso";
        }
        return d.paired || d.bonded ? "Associato" : "Disponibile";
    }
}
