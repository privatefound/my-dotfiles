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

    // ── Ethernet: posti fissi (expansion card 1/2, docking station) riconosciuti dal MAC ──
    // La prima scheda vista diventa "Expansion card 1", la successiva "2"; una scheda collegata
    // tramite un hub USB (la porta contiene un punto, es. "7-1.2.1") è la docking station.
    // L'associazione MAC → posto è salvata in state/ethernet-cards.json (personale, non in git).
    readonly property var ethSlotDefs: [
        { id: "card1", label: "Expansion card 1", icon: Icons.ethernet },
        { id: "card2", label: "Expansion card 2", icon: Icons.ethernet },
        { id: "dock", label: "Docking station", icon: Icons.lan }
    ]
    readonly property var ethSlots: ethSlotDefs.map(s => Object.assign({}, s, {
        iface: interfaces.find(i => i.type === "ethernet" && i.mac && cards.map[i.mac] === s.id) ?? null
    }))
    // tutte le altre schede ethernet: senza un posto (es. una terza expansion card) oppure con il
    // posto già occupato da un'altra scheda collegata (es. due schede "dock" insieme)
    readonly property var otherEthernet: interfaces.filter(i => i.type === "ethernet" && !ethSlots.some(s => s.iface === i))
    // profili da offrire su ogni scheda: quelli non legati a una scheda precisa, DHCP per primo
    readonly property var ethProfiles: wiredProfiles.filter(p => !p.bound).sort((a, b) => (/dhcp/i.test(b.name) - /dhcp/i.test(a.name)) || a.name.localeCompare(b.name))

    function _isBehindHub(port) {
        return /^\d+-[\d.]*\.[\d.]+:/.test(port);
    }
    function _learnCards(eths) {
        const map = Object.assign({}, cards.map);
        let changed = false;
        for (const i of eths) {
            if (map[i.mac])
                continue;
            const used = Object.values(map);
            const slot = _isBehindHub(i.port) ? "dock" : ["card1", "card2"].find(s => !used.includes(s));
            if (slot) {
                map[i.mac] = slot;
                changed = true;
            }
        }
        if (changed)
            cards.map = map;
    }
    function forgetCard(mac) {
        const map = Object.assign({}, cards.map);
        delete map[mac];
        cards.map = map;
    }

    // applica un profilo proprio a quella scheda
    // (prima abilita multi-connect sul profilo, se manca: l'editor grafico di NetworkManager non lo
    // mostra, e senza lo stesso profilo non potrebbe restare attivo su due schede insieme)
    function applyProfile(iface, profile) {
        nmAction.command = ["sh", "-c", "case \"$(nmcli -g connection.multi-connect connection show uuid \"$1\")\" in 3|multiple) ;; *) nmcli connection modify uuid \"$1\" connection.multi-connect multiple;; esac; nmcli connection up uuid \"$1\" ifname \"$2\"", "_", profile.uuid, iface.device];
        nmBusy = true;
        nmAction.running = true;
    }
    function disconnectInterface(iface) {
        nmAction.command = ["nmcli", "device", "disconnect", iface.device];
        nmBusy = true;
        nmAction.running = true;
    }

    FileView {
        path: Settings.rootDir + "/state/ethernet-cards.json"
        // modifiche a mano al file (scambio card1/card2…) prese subito, senza riavviare la shell
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                writeAdapter();
        }
        JsonAdapter {
            id: cards
            property var map: ({})
        }
    }

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
        command: ["sh", "-c", "echo \"DEF:$(ip route show default 2>/dev/null | awk '{print $5; exit}')\"; nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device 2>/dev/null | sed 's/^/DEV:/'; nmcli -t -f NAME,UUID,TYPE,DEVICE,ACTIVE connection show 2>/dev/null | sed 's/^/CON:/'; ip -o -4 addr show 2>/dev/null | awk '{print \"IP:\" $2 \":\" $4}'; for d in $(nmcli -t -f DEVICE,TYPE device 2>/dev/null | awk -F: '$2==\"ethernet\"{print $1}'); do echo \"ETH:$d|$(cat /sys/class/net/$d/address 2>/dev/null)|$(basename \"$(readlink -f /sys/class/net/$d/device)\")\"; done; nmcli -t -f UUID,TYPE connection show 2>/dev/null | awk -F: '$2==\"802-3-ethernet\"{print $1}' | while read u; do echo \"PIF:$u|$(nmcli -g connection.interface-name,802-3-ethernet.mac-address connection show uuid $u 2>/dev/null | paste -sd'|')\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                let def = "";
                const ifs = [], cons = [], ips = {}, eth = {}, bound = {};
                for (const line of text.split("\n")) {
                    if (line.startsWith("DEF:"))
                        def = line.slice(4).trim();
                    else if (line.startsWith("ETH:")) {
                        // device|mac|porta USB (es. "6-1:1.0" diretta, "7-1.2.1:1.0" dietro un hub)
                        const [dev, mac, port] = line.slice(4).split("|");
                        eth[dev] = { mac: (mac || "").toLowerCase(), port: port || "" };
                    } else if (line.startsWith("PIF:")) {
                        // profilo ethernet legato a una scheda (per nome o MAC) oppure libero
                        const [uuid, ifname, mac] = line.slice(4).split("|");
                        bound[uuid] = !!(ifname || mac);
                    }
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
                    i.mac = eth[i.device]?.mac ?? "";
                    i.port = eth[i.device]?.port ?? "";
                }
                for (const c of cons)
                    c.bound = bound[c.uuid] === true;
                root._learnCards(ifs.filter(i => i.type === "ethernet" && i.mac));
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

    // ── Condivisione Wi‑Fi (come Android): QR code + password della rete salvata ──
    // Lo fa scripts/wifi-share: la password non passa mai dalla riga di comando di un processo.
    // Il QR (SVG) resta in memoria; chiudendo la scheda si cancella tutto.
    property string shareSsid: ""
    property string sharePassword: ""
    property string shareQr: ""          // SVG del QR code
    property string shareError: ""
    readonly property bool shareBusy: shareProc.running

    function shareWifi(network) {
        clearShare();
        shareSsid = network.name;
        shareProc.command = [Settings.rootDir + "/scripts/wifi-share", network.name];
        shareProc.running = true;
    }
    function clearShare() {
        shareSsid = "";
        sharePassword = "";
        shareQr = "";
        shareError = "";
    }

    Process {
        id: shareProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.startsWith("ERR:")) {
                    root.shareError = text.slice(4).trim();
                    return;
                }
                const i = text.indexOf("\nSVG:\n");
                if (i < 0 || !text.startsWith("PSK:")) {
                    root.shareError = I18n.tr("Impossibile creare il QR code (qrencode installato?)");
                    return;
                }
                root.sharePassword = text.slice(4, i);
                root.shareQr = text.slice(i + 6);
            }
        }
    }

    // ── Connessione da QR code letto con la webcam (il contrario della condivisione) ──
    // zbarcam apre l'anteprima, legge un solo codice ed esce; la password resta nella shell e va a
    // NetworkManager via D‑Bus (connectWithPsk), come quando la si digita nel pannello.
    readonly property bool qrScanning: qrProc.running
    function scanWifiQr() {
        if (!qrProc.running)
            qrProc.running = true;
    }
    function cancelQrScan() {
        if (qrProc.running)
            qrProc.signal(15);
    }
    Process {
        id: qrProc
        command: ["zbarcam", "--oneshot", "--raw", "--prescale=640x480"]
        stdout: StdioCollector {
            onStreamFinished: {
                const code = text.trim();
                if (code)
                    root._connectFromQr(code);
            }
        }
        onExited: code => {
            if (code !== 0 && code !== 15 && code !== 143)
                root._notify(I18n.tr("Webcam non disponibile"), I18n.tr("zbarcam non è riuscito ad aprire la fotocamera"));
        }
    }

    // formato "WIFI:T:WPA;S:nome;P:password;H:true;;" — \ ; , : " sono preceduti da una barra
    function parseWifiQr(text) {
        if (!/^WIFI:/i.test(text))
            return null;
        const f = {};
        let key = "", val = "", inKey = true, esc = false;
        for (const ch of text.slice(5)) {
            if (esc) {
                if (inKey) key += ch; else val += ch;
                esc = false;
            } else if (ch === "\\") {
                esc = true;
            } else if (inKey && ch === ":") {
                inKey = false;
            } else if (ch === ";") {
                if (key)
                    f[key.toUpperCase()] = val;
                key = "";
                val = "";
                inKey = true;
            } else if (inKey) {
                key += ch;
            } else {
                val += ch;
            }
        }
        if (key)
            f[key.toUpperCase()] = val;
        return f.S ? { ssid: f.S, password: f.P ?? "", type: (f.T ?? "").toUpperCase(), hidden: f.H === "true" } : null;
    }

    function _notify(title, body) {
        Quickshell.execDetached(["notify-send", "-a", "Wi‑Fi", "-i", "network-wireless", title, body]);
    }

    function _connectFromQr(code) {
        const info = parseWifiQr(code);
        if (!info) {
            _notify(I18n.tr("QR code non valido"), I18n.tr("Non è il QR code di una rete Wi‑Fi"));
            return;
        }
        if (!wifiEnabled)
            setWifiEnabled(true);
        if (activeNetwork && activeNetwork.name === info.ssid) {
            _notify(info.ssid, I18n.tr("Sei già connesso a questa rete"));
            return;
        }
        // scripts/wifi-join: crea il profilo se serve (anche per reti nascoste) e si connette;
        // la password gli arriva su stdin, non sulla riga di comando.
        // (connectWithPsk di Quickshell scollegava il Wi‑Fi senza poi connettersi alla rete nuova)
        _joinPsk = info.password;
        joinProc.command = [Settings.rootDir + "/scripts/wifi-join", info.ssid, info.type || "WPA", info.hidden ? "true" : "false"];
        joinProc.running = true;
        _notify(I18n.tr("Connessione a") + " " + info.ssid, I18n.tr("Dati letti dal QR code"));
    }
    property string _joinPsk: ""
    readonly property bool qrJoining: joinProc.running
    Process {
        id: joinProc
        stdinEnabled: true
        onStarted: {
            write(root._joinPsk + "\n");
            root._joinPsk = "";
            stdinEnabled = false;   // chiude lo stdin: lo script ha letto la password
        }
        onExited: stdinEnabled = true
        stdout: StdioCollector {
            onStreamFinished: {
                const out = text.trim();
                if (out.startsWith("OK:"))
                    root._notify(I18n.tr("Wi‑Fi connesso"), out.slice(3));
                else
                    root._notify(I18n.tr("Connessione non riuscita"), out.startsWith("ERR:") ? out.slice(4) : out);
                nmRefresh.restart();
            }
        }
    }

    function openEditor() {
        Quickshell.execDetached(["nm-connection-editor"]);
    }
}
