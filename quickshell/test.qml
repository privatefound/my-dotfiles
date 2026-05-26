import QtQuick
import QtQuick.Layouts
import Quickshell

ShellRoot {
    PanelWindow {
        anchors.top: true
        anchors.left: true
        anchors.right: true
        height: 30
        color: "#0a0a0a"

        // Linea decorativa
        Rectangle { 
            anchors.bottom: parent.bottom; width: parent.width; height: 2; color: "#B026FF" 
        }

        // --- MOTORE DEI DATI ---

        // Processo per leggere il volume reale (PipeWire)
        Process {
            id: getVolume
            command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}'"]
            running: true
            onStdoutLine: (line) => {
                volumeText.text = " " + line + "%"
            }
        }

        // Loop che fa ripartire il controllo del volume ogni 2 secondi
        Timer {
            interval: 2000; running: true; repeat: true
            onTriggered: { getVolume.running = false; getVolume.running = true }
        }

        // --- INTERFACCIA VISIVA ---
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 15
            anchors.rightMargin: 15
            spacing: 15

            // Logo fisso a sinistra
            Text { text: "󰣇"; color: "#B026FF"; font.pixelSize: 16; font.family: "Symbols Nerd Font" }
            
            // Spazio centrale elastico
            Item { Layout.fillWidth: true }

            // Orologio reale
            Text {
                id: clockText
                color: "#B026FF"
                font.family: "Symbols Nerd Font"
                font.pixelSize: 13
                
                Timer {
                    interval: 1000; running: true; repeat: true
                    onTriggered: clockText.text = " " + new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})
                }
                Component.onCompleted: clockText.text = " " + new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})
            }

            Rectangle { width: 1; height: 15; color: "#333333" }

            // Testo del volume che viene sovrascritto dal processo in background
            Text {
                id: volumeText
                text: " --%"
                color: "#B026FF"
                font.family: "Symbols Nerd Font"
                font.pixelSize: 13
            }
        }
    }
}