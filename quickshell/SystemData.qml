import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root
    property int cpuUsage: 0
    property int memUsage: 0
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0

    // CPU Process
    Process {
        id: cpuProc
        command: ["sh", "-c", "cat /proc/stat | grep '^cpu '"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                var idle = parseInt(parts[4]) || 0
                var total = parts.slice(1).reduce((a, b) => a + (parseInt(b) || 0), 0)

                if (root.lastCpuTotal > 0) {
                    var diffTotal = total - root.lastCpuTotal
                    var diffIdle = idle - root.lastCpuIdle
                    root.cpuUsage = Math.round(100 * (diffTotal - diffIdle) / diffTotal)
                }

                root.lastCpuTotal = total
                root.lastCpuIdle = idle
            }
        }
        Component.onCompleted: running = true
    }

    // Memoria Process
    Process {
        id: memProc
        command: ["sh", "-c", "free | grep Mem"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                var total = parseInt(parts[1]) || 1
                var used = parseInt(parts[2]) || 0
                root.memUsage = Math.round(100 * used / total)
            }
        }
        Component.onCompleted: running = true
    }

    // Timer per aggiornare ogni 2 secondi
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            cpuProc.running = true
            memProc.running = true
        }
    }
}