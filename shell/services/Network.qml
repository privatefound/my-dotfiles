pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick
import QtQml
import qs.config

// Rete via Quickshell.Networking (NetworkManager su D-Bus). VPN via nmcli (solo su richiesta).
Singleton {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevice: devices.find(d => d.type === DeviceType.Wired) ?? null

    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wiredConnected: wiredDevice?.connected ?? false
    readonly property var networks: wifiDevice ? wifiDevice.networks.values.filter(n => n.name !== "").sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength)) : []
    readonly property var activeNetwork: networks.find(n => n.connected) ?? null
    readonly property bool wifiConnected: activeNetwork !== null
    readonly property bool connected: wifiConnected || wiredConnected
    readonly property bool scanning: wifiDevice?.scannerEnabled ?? false

    readonly property string label: wiredConnected ? "Ethernet" : wifiConnected ? activeNetwork.name : wifiEnabled ? I18n.tr("Disconnesso") : I18n.tr("Wi‑Fi spento")
    readonly property string icon: wiredConnected ? Icons.ethernet : !wifiEnabled ? Icons.wifiOff : wifiConnected ? strengthIcon(activeNetwork.signalStrength) : Icons.wifi0
    readonly property bool limited: Networking.connectivity === NetworkConnectivity.Limited || Networking.connectivity === NetworkConnectivity.Portal

    // Rete per cui stiamo chiedendo la password
    property var pendingNetwork: null
    property string lastError: ""

    function strength(s) {
        return s > 1 ? s / 100 : s;
    }
    function strengthIcon(s) {
        const v = strength(s);
        return v > 0.75 ? Icons.wifi4 : v > 0.5 ? Icons.wifi3 : v > 0.25 ? Icons.wifi2 : Icons.wifi1;
    }
    function isSecure(n) {
        return n && n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Unknown;
    }

    function setWifiEnabled(on) {
        Networking.wifiEnabled = on;
    }
    function setScanning(on) {
        if (wifiDevice)
            wifiDevice.scannerEnabled = on;
    }

    function connectTo(n) {
        lastError = "";
        if (n.connected) {
            n.disconnect();
            return;
        }
        if (!n.known && isSecure(n)) {
            pendingNetwork = n;
            return;
        }
        n.connect();
    }
    function connectWithPassword(n, psk) {
        lastError = "";
        pendingNetwork = null;
        n.connectWithPsk(psk);
    }
    function forget(n) {
        n.forget();
    }

    // Se NM chiede i segreti (password cambiata / non salvata) chiediamo all'utente
    Instantiator {
        model: root.wifiDevice ? root.wifiDevice.networks : []
        delegate: Connections {
            required property var modelData
            target: modelData
            function onConnectionFailed(reason) {
                if (reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiAuthTimeout || reason === ConnectionFailReason.WifiClientFailed) {
                    root.pendingNetwork = modelData;
                    root.lastError = I18n.tr("Password errata o mancante");
                } else {
                    root.lastError = I18n.tr("Connessione non riuscita");
                }
            }
        }
    }

    // ── Schede di rete e profili (nmcli, solo all'apertura / al cambio di stato) ──
    property string defaultIface: ""
    property var interfaces: []   // [{ device, type, state, connection, ip, isDefault }]
    property var profiles: []     // [{ name, uuid, type, device, active }]  (ethernet, vpn, wireguard, ...)
    readonly property var vpns: profiles.filter(p => p.type === "vpn" || p.type === "wireguard" || p.type === "tun")
    readonly property var wiredProfiles: profiles.filter(p => p.type === "802-3-ethernet" || p.type === "ethernet")
    readonly property bool vpnActive: vpns.some(v => v.active)
    property bool nmBusy: false

    function refreshNm() {
        nmProc.running = true;
    }
    function toggleProfile(p) {
        nmAction.command = ["nmcli", "connection", p.active ? "down" : "up", "uuid", p.uuid];
        nmBusy = true;
        nmAction.running = true;
    }
    function toggleVpn(v) {
        toggleProfile(v);
    }
    function toggleInterface(i) {
        const up = i.state.startsWith("connected");
        nmAction.command = ["nmcli", "device", up ? "disconnect" : "connect", i.device];
        nmBusy = true;
        nmAction.running = true;
    }

    function splitNm(line) {
        return line.replace(/\\:/g, "\u0001").split(":").map(p => p.replace(/\u0001/g, ":"));
    }

    Process {
        id: nmProc
        command: ["sh", "-c", "echo \"DEF:$(ip route show default 2>/dev/null | awk '{print $5; exit}')\"; nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device 2>/dev/null | sed 's/^/DEV:/'; nmcli -t -f NAME,UUID,TYPE,DEVICE,ACTIVE connection show 2>/dev/null | sed 's/^/CON:/'; ip -o -4 addr show 2>/dev/null | awk '{print \"IP:\" $2 \":\" $4}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let def = "";
                const ifs = [], cons = [], ips = {};
                for (const line of text.split("\n")) {
                    if (line.startsWith("DEF:"))
                        def = line.slice(4).trim();
                    else if (line.startsWith("IP:")) {
                        const i = line.indexOf(":", 3);
                        ips[line.slice(3, i)] = line.slice(i + 1);
                    } else if (line.startsWith("DEV:")) {
                        const p = root.splitNm(line.slice(4));
                        if (p.length >= 4 && ["ethernet", "wifi", "wireguard", "tun", "bridge", "vpn", "gsm", "bond", "vlan"].includes(p[1]))
                            ifs.push({ device: p[0], type: p[1], state: p[2], connection: p[3] });
                    } else if (line.startsWith("CON:")) {
                        const p = root.splitNm(line.slice(4));
                        if (p.length >= 5 && p[2] !== "loopback")
                            cons.push({ name: p[0], uuid: p[1], type: p[2], device: p[3], active: p[4] === "yes" });
                    }
                }
                for (const i of ifs) {
                    i.ip = ips[i.device] ?? "";
                    i.isDefault = i.device === def;
                }
                root.defaultIface = def;
                root.interfaces = ifs;
                root.profiles = cons.sort((a, b) => b.active - a.active);
                root.nmBusy = false;
            }
        }
    }

    Process {
        id: nmAction
        onExited: nmRefresh.restart()
    }
    Timer {
        id: nmRefresh
        interval: 700
        onTriggered: root.refreshNm()
    }

    // Aggiorna quando cambia lo stato delle connessioni, e ogni 30s come rete di sicurezza
    onWifiConnectedChanged: nmRefresh.restart()
    onWiredConnectedChanged: nmRefresh.restart()
    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshNm()
    }

    // L'interfaccia su cui passa la route di default (evidenziata nella barra, come prima)
    readonly property string defaultKind: {
        const d = interfaces.find(i => i.isDefault);
        return d ? d.type : "";
    }

    function openEditor() {
        Quickshell.execDetached(["nm-connection-editor"]);
    }
}
