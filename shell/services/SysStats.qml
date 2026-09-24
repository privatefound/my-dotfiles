pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Statistiche di sistema leggendo /proc e /sys direttamente (FileView, niente processi).
// I dettagli costosi (processi, dischi) vengono aggiornati solo quando il popout è aperto.
Singleton {
    id: root

    property real cpu: 0            // 0..1
    property real mem: 0            // 0..1
    property real memUsedGb: 0
    property real memTotalGb: 0
    property real swap: 0
    property real cpuTemp: 0        // °C
    property real gpuTemp: 0
    property real gpuBusy: 0        // 0..1
    property int fanRpm: 0
    property string load: ""
    property string uptime: ""
    property var cpuHistory: []
    property var memHistory: []
    property var gpuHistory: []

    // dettagli
    property bool detailed: false
    property var processes: []      // [{ pid, name, cpu, memMb }]
    property var disks: []          // [{ mount, used, size, pct }]
    property real netRx: 0          // byte/s
    property real netTx: 0

    property var _lastCpu: null
    property var _lastNet: null
    property string _cpuTempPath: ""
    property string _gpuTempPath: ""
    property string _gpuBusyPath: ""
    property string _fanPath: ""

    function push(arr, v) {
        const a = arr.slice(-59);
        a.push(v);
        return a;
    }

    function formatBytes(b) {
        if (b < 1024)
            return b.toFixed(0) + " B";
        if (b < 1048576)
            return (b / 1024).toFixed(1) + " KB";
        if (b < 1073741824)
            return (b / 1048576).toFixed(1) + " MB";
        return (b / 1073741824).toFixed(1) + " GB";
    }

    Process {
        running: true
        command: ["sh", "-c", `for h in /sys/class/hwmon/hwmon*; do n=$(cat $h/name); case $n in k10temp|coretemp|zenpower) echo "cpu=$h/temp1_input";; amdgpu) echo "gpu=$h/temp1_input";; cros_ec) echo "fan=$h/fan1_input";; esac; done; for c in /sys/class/drm/card*/device/gpu_busy_percent; do [ -f "$c" ] && echo "busy=$c" && break; done`]
        stdout: SplitParser {
            onRead: line => {
                const [k, v] = line.split("=");
                if (k === "cpu" && !root._cpuTempPath) root._cpuTempPath = v;
                if (k === "gpu" && !root._gpuTempPath) root._gpuTempPath = v;
                if (k === "fan" && !root._fanPath) root._fanPath = v;
                if (k === "busy" && !root._gpuBusyPath) root._gpuBusyPath = v;
            }
        }
    }

    FileView { id: statFile; path: "/proc/stat" }
    FileView { id: memFile; path: "/proc/meminfo" }
    FileView { id: loadFile; path: "/proc/loadavg" }
    FileView { id: upFile; path: "/proc/uptime" }
    FileView { id: netFile; path: "/proc/net/dev" }
    FileView { id: cpuTempFile; path: root._cpuTempPath }
    FileView { id: gpuTempFile; path: root._gpuTempPath }
    FileView { id: gpuBusyFile; path: root._gpuBusyPath }
    FileView { id: fanFile; path: root._fanPath }

    function sample() {
        statFile.reload();
        memFile.reload();
        loadFile.reload();
        upFile.reload();

        // CPU
        const line = statFile.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        if (line.length >= 4) {
            const idle = line[3] + (line[4] || 0);
            const total = line.reduce((a, b) => a + b, 0);
            if (_lastCpu) {
                const dt = total - _lastCpu.total;
                const di = idle - _lastCpu.idle;
                cpu = dt > 0 ? Math.max(0, Math.min(1, 1 - di / dt)) : 0;
            }
            _lastCpu = { total, idle };
        }

        // RAM
        const mi = {};
        for (const l of memFile.text().split("\n")) {
            const m = l.match(/^(\w+):\s+(\d+)/);
            if (m)
                mi[m[1]] = parseInt(m[2]);
        }
        if (mi.MemTotal) {
            const used = mi.MemTotal - (mi.MemAvailable ?? mi.MemFree);
            mem = used / mi.MemTotal;
            memUsedGb = used / 1048576;
            memTotalGb = mi.MemTotal / 1048576;
            swap = mi.SwapTotal ? (mi.SwapTotal - mi.SwapFree) / mi.SwapTotal : 0;
        }

        load = loadFile.text().split(" ").slice(0, 3).join("  ");
        const up = parseFloat(upFile.text());
        if (up) {
            const d = Math.floor(up / 86400), h = Math.floor(up % 86400 / 3600), m = Math.floor(up % 3600 / 60);
            uptime = (d > 0 ? d + "g " : "") + (h > 0 ? h + "h " : "") + m + "m";
        }

        if (_cpuTempPath) {
            cpuTempFile.reload();
            cpuTemp = (parseInt(cpuTempFile.text()) || 0) / 1000;
        }
        if (_gpuTempPath) {
            gpuTempFile.reload();
            gpuTemp = (parseInt(gpuTempFile.text()) || 0) / 1000;
        }
        if (_gpuBusyPath) {
            gpuBusyFile.reload();
            gpuBusy = (parseInt(gpuBusyFile.text()) || 0) / 100;
        }
        if (_fanPath) {
            fanFile.reload();
            fanRpm = parseInt(fanFile.text()) || 0;
        }

        cpuHistory = push(cpuHistory, cpu);
        memHistory = push(memHistory, mem);
        gpuHistory = push(gpuHistory, gpuBusy);

        if (detailed)
            sampleNet();
    }

    function sampleNet() {
        netFile.reload();
        let rx = 0, tx = 0;
        for (const l of netFile.text().split("\n").slice(2)) {
            const p = l.trim().split(/[:\s]+/);
            if (p.length < 10 || p[0] === "lo")
                continue;
            rx += parseInt(p[1]);
            tx += parseInt(p[9]);
        }
        const now = Date.now();
        if (_lastNet) {
            const dt = (now - _lastNet.t) / 1000;
            netRx = Math.max(0, (rx - _lastNet.rx) / dt);
            netTx = Math.max(0, (tx - _lastNet.tx) / dt);
        }
        _lastNet = { rx, tx, t: now };
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.sample()
    }

    // ── Dettagli (solo col popout aperto) ──
    onDetailedChanged: if (detailed) {
        _lastNet = null;
        procProc.running = true;
        diskProc.running = true;
    }

    Timer {
        interval: 3000
        running: root.detailed
        repeat: true
        onTriggered: procProc.running = true
    }

    Process {
        id: procProc
        command: ["sh", "-c", "ps -eo pid,comm,%cpu,rss --sort=-%cpu --no-headers | head -n 7"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.processes = text.trim().split("\n").filter(l => l).map(l => {
                    const p = l.trim().split(/\s+/);
                    return { pid: p[0], name: p[1], cpu: parseFloat(p[2]), memMb: parseInt(p[3]) / 1024 };
                });
            }
        }
    }

    Process {
        id: diskProc
        command: ["df", "-B1", "--output=target,size,used", "-x", "tmpfs", "-x", "devtmpfs", "-x", "efivarfs", "-x", "overlay"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                root.disks = text.trim().split("\n").slice(1).map(l => l.trim().split(/\s+/)).filter(p => p.length === 3 && !p[0].startsWith("/boot") && !p[0].startsWith("/run") && !p[0].startsWith("/var/lib")).filter(p => {
                    if (seen[p[1]]) return false;
                    seen[p[1]] = true;
                    return true;
                }).slice(0, 4).map(p => ({ mount: p[0], size: parseInt(p[1]), used: parseInt(p[2]), pct: parseInt(p[2]) / Math.max(1, parseInt(p[1])) }));
            }
        }
    }
}
