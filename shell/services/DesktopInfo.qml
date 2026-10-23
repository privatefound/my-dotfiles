pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Dati del widget sul desktop (al posto di conky): sistema, disco, processi, memoria, reti.
// Raccoglie solo mentre il widget è attivo.
Singleton {
    id: root

    readonly property bool active: Settings.desktopWidget

    // ── sistema (letto una volta) ──
    property string osName: ""
    property string hostname: ""
    property string kernel: ""
    property string arch: ""
    property string installed: ""
    readonly property string uptime: SysStats.uptime

    // ── disco, memoria, CPU ──
    property real rootUsed: 0
    property real rootSize: 0
    property real swapUsed: 0
    property real swapTotal: 0
    property real cpuGhz: 0
    property int gpuMhz: 0           // frequenza attuale della GPU (pp_dpm_sclk, AMD)

    // ── processi: [{ name, value }] ──
    property var topMem: []
    property var topCpu: []

    // ── reti attive: [{ dev, kind, ip, rxTotal, txTotal, rxSpeed, txSpeed, rxHist, txHist }] ──
    property var nets: []
    property string publicIp: ""
    property string dns: ""
    property string gateway: ""
    property var _lastNet: ({})
    property var _hist: ({})
    readonly property int histPoints: 40

    function bytes(b) {
        const u = ["B", "KiB", "MiB", "GiB", "TiB"];
        let i = 0;
        while (b >= 1024 && i < u.length - 1) {
            b /= 1024;
            i++;
        }
        return (i === 0 ? Math.round(b) : b.toFixed(b < 10 ? 2 : 1)) + " " + u[i];
    }
    function speed(b) {
        return bytes(b) + "/s";
    }

    // ── una tantum ──
    Process {
        running: root.active
        command: ["sh", "-c", ". /etc/os-release 2>/dev/null; echo \"OS:${PRETTY_NAME:-Linux}\"; echo \"HOST:$(cat /etc/hostname 2>/dev/null || uname -n)\"; echo \"KER:$(uname -r)\"; echo \"ARCH:$(uname -m)\"; echo \"INST:$(head -n1 /var/log/pacman.log 2>/dev/null | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -n1)\""]
        stdout: SplitParser {
            onRead: line => {
                const v = line.slice(line.indexOf(":") + 1);
                if (line.startsWith("OS:")) root.osName = v;
                else if (line.startsWith("HOST:")) root.hostname = v;
                else if (line.startsWith("KER:")) root.kernel = v;
                else if (line.startsWith("ARCH:")) root.arch = v;
                else if (line.startsWith("INST:")) root.installed = v;
            }
        }
    }

    // ── ogni 2 s: reti, swap, frequenza ──
    FileView {
        id: netDev
        path: "/proc/net/dev"
    }
    FileView {
        id: memInfo
        path: "/proc/meminfo"
    }
    FileView {
        id: cpuInfo
        path: "/proc/cpuinfo"
    }
    // GPU AMD: la scheda che espone gpu_busy_percent (trovata una volta)
    property string _gpuDir: ""
    Process {
        running: root.active && root._gpuDir === ""
        command: ["sh", "-c", "for c in /sys/class/drm/card*/device; do [ -f \"$c/gpu_busy_percent\" ] && [ -f \"$c/pp_dpm_sclk\" ] && { echo \"$c\"; break; }; done"]
        stdout: StdioCollector {
            onStreamFinished: root._gpuDir = text.trim()
        }
    }
    FileView {
        id: gpuClock
        path: root._gpuDir ? root._gpuDir + "/pp_dpm_sclk" : ""
    }

    function sample() {
        // swap
        memInfo.reload();
        const mi = {};
        for (const l of memInfo.text().split("\n")) {
            const m = l.match(/^(\w+):\s+(\d+)/);
            if (m)
                mi[m[1]] = parseInt(m[2]) * 1024;
        }
        swapTotal = mi.SwapTotal ?? 0;
        swapUsed = Math.max(0, swapTotal - (mi.SwapFree ?? 0));

        // frequenza media
        cpuInfo.reload();
        const f = cpuInfo.text().split("\n").filter(l => l.startsWith("cpu MHz")).map(l => parseFloat(l.split(":")[1]));
        cpuGhz = f.length ? f.reduce((a, b) => a + b, 0) / f.length / 1000 : 0;

        // frequenza GPU: la riga con l'asterisco è quella attiva ("1: 1312Mhz *")
        if (_gpuDir) {
            gpuClock.reload();
            const m = gpuClock.text().match(/(\d+)\s*Mhz\s*\*/i);
            gpuMhz = m ? parseInt(m[1]) : 0;
        }

        // reti
        netDev.reload();
        const now = Date.now();
        const out = [];
        const last = Object.assign({}, _lastNet);
        const hist = Object.assign({}, _hist);
        for (const l of netDev.text().split("\n").slice(2)) {
            const p = l.trim().split(/[:\s]+/);
            if (p.length < 10)
                continue;
            const dev = p[0];
            const kind = /^(wl|wlan)/.test(dev) ? "wifi" : /^(en|eth)/.test(dev) ? "ethernet" : /^(tun|wg|tap|ppp)/.test(dev) ? "vpn" : "";
            if (!kind)
                continue;
            const rx = parseInt(p[1]), tx = parseInt(p[9]);
            const ip = root._ips[dev] ?? "";
            let rs = 0, ts = 0;
            if (last[dev]) {
                const dt = (now - last[dev].t) / 1000;
                rs = Math.max(0, (rx - last[dev].rx) / dt);
                ts = Math.max(0, (tx - last[dev].tx) / dt);
            }
            last[dev] = { rx, tx, t: now };
            const h = hist[dev] ?? { rx: [], tx: [] };
            h.rx = h.rx.concat([rs]).slice(-histPoints);
            h.tx = h.tx.concat([ts]).slice(-histPoints);
            hist[dev] = h;
            // solo le interfacce con un indirizzo (cioè collegate)
            if (ip)
                out.push({ dev, kind, ip, rxTotal: rx, txTotal: tx, rxSpeed: rs, txSpeed: ts, rxHist: h.rx, txHist: h.tx });
        }
        _lastNet = last;
        _hist = hist;
        const order = { ethernet: 0, wifi: 1, vpn: 2 };
        nets = out.sort((a, b) => order[a.kind] - order[b.kind] || a.dev.localeCompare(b.dev));
    }

    Timer {
        interval: 2000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: root.sample()
    }

    // ── ogni 5 s: processi; ogni 30 s: disco, indirizzi, DNS, gateway ──
    property var _ips: ({})
    Process {
        id: procProc
        // per app (processi con lo stesso nome sommati); CPU istantanea da top, non la media di ps
        // (che faceva apparire al 100% i comandi brevissimi, compresi quelli di questo widget)
        command: ["sh", "-c", "echo MEM; ps -eo comm,rss --no-headers | awk '{m[$1]+=$2} END {for (n in m) print n, m[n]}' | sort -k2 -nr | head -n 3; echo CPU; top -b -n 2 -d 0.5 -o %CPU -w 200 | awk '/^ *PID/{f++; next} f==2 && $1 ~ /^[0-9]+$/ && $12 !~ /^(top|ps|sh|awk|sort|head)$/ {c[$12]+=$9} END {for (n in c) if (c[n] > 0) print n, c[n]}' | sort -k2 -nr | head -n 3"]
        stdout: StdioCollector {
            onStreamFinished: {
                const mem = [], cpu = [];
                let sect = "";
                for (const l of text.split("\n")) {
                    const t = l.trim();
                    if (t === "MEM" || t === "CPU") {
                        sect = t;
                        continue;
                    }
                    const m = t.match(/^(.*\S)\s+([\d.]+)$/);
                    if (!m)
                        continue;
                    if (sect === "MEM")
                        mem.push({ name: m[1], value: root.bytes(parseInt(m[2]) * 1024) });
                    else
                        cpu.push({ name: m[1], value: parseFloat(m[2]).toFixed(1) + "%" });
                }
                root.topMem = mem;
                root.topCpu = cpu;
            }
        }
    }
    Timer {
        interval: 5000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: procProc.running = true
    }

    Process {
        id: slowProc
        command: ["sh", "-c", "df -B1 --output=size,used / | tail -n1 | awk '{print \"ROOT:\" $1 \" \" $2}'; ip -o -4 addr show | awk '{print \"IP:\" $2 \" \" $4}'; echo \"GW:$(ip route show default 2>/dev/null | awk 'NR==1{print $3}')\"; echo \"DNS:$( (resolvectl dns 2>/dev/null | awk '{for(i=4;i<=NF;i++) if ($i ~ /^[0-9.]+$/) {print $i; exit}}') ; grep -m1 '^nameserver' /etc/resolv.conf | awk '{print $2}' | head -n1)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const ips = {};
                for (const l of text.split("\n")) {
                    const v = l.slice(l.indexOf(":") + 1).trim();
                    if (l.startsWith("ROOT:")) {
                        const [size, used] = v.split(" ").map(Number);
                        root.rootSize = size;
                        root.rootUsed = used;
                    } else if (l.startsWith("IP:")) {
                        const [dev, cidr] = v.split(" ");
                        ips[dev] = (cidr || "").split("/")[0];
                    } else if (l.startsWith("GW:"))
                        root.gateway = v;
                    else if (l.startsWith("DNS:"))
                        root.dns = v.split(/\s+/)[0] ?? "";
                }
                root._ips = ips;
            }
        }
    }
    Timer {
        interval: 30000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: slowProc.running = true
    }
    // l'indirizzo cambia quando ci si collega a una rete: si rilegge subito
    Connections {
        target: Network
        function onDefaultIfaceChanged() {
            slowProc.running = true;
            pubProc.running = true;
        }
    }

    // IP pubblico (come la vecchia conky), ogni 30 minuti
    Process {
        id: pubProc
        command: ["sh", "-c", "curl -fs --max-time 6 https://ipinfo.io/ip"]
        stdout: StdioCollector {
            onStreamFinished: root.publicIp = text.trim()
        }
    }
    Timer {
        interval: 30 * 60 * 1000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: pubProc.running = true
    }
}
