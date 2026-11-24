import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.config
import qs.components
import qs.services

// Batteria: livello, profilo energetico, grafico delle ultime 24 ore (storico di UPower), consumo, luminosità.
Item {
    id: root

    readonly property int hours: 24
    readonly property int points: hours * 4 + 1      // un punto ogni 15 minuti
    property string cycles: ""
    property var samples: []                         // [[epoch, percentuale]] dal più vecchio
    readonly property color tint: Power.low ? Theme.error : Theme.primary

    // Campioni di UPower (irregolari) → punti equidistanti; il tratto prima del primo campione resta vuoto
    readonly property var values: {
        const now = Time.now.getTime() / 1000;
        const s = samples.filter(p => p[0] < now).concat([[now, Power.percentage * 100]]);
        const out = [];
        let j = 0;
        for (let i = 0; i < points; i++) {
            const t = now - (points - 1 - i) * 900;
            if (t < s[0][0])
                continue;
            while (j < s.length - 2 && s[j + 1][0] < t)
                j++;
            const a = s[j], b = s[j + 1] ?? a;
            out.push((b[0] > a[0] ? a[1] + (b[1] - a[1]) * (t - a[0]) / (b[0] - a[0]) : a[1]) / 100);
        }
        return out;
    }

    implicitWidth: 340
    implicitHeight: col.implicitHeight + 28

    Process {
        id: history
        command: ["sh", "-c", "d=$(upower -e | grep -m1 '/battery_BAT') && busctl --system --json=short call org.freedesktop.UPower \"$d\" org.freedesktop.UPower.Device GetHistory suu charge \"$1\" 300", "_", String(root.hours * 3600)]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    // stato 0 = sconosciuto (avvio/spegnimento): il valore è un finto 0%
                    root.samples = JSON.parse(text).data[0].filter(p => p[2] !== 0).map(p => [p[0], p[1]]).sort((a, b) => a[0] - b[0]);
                } catch (e) {
                    root.samples = [];
                }
            }
        }
    }
    Process {
        running: true
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/cycle_count"]
        stdout: StdioCollector {
            onStreamFinished: root.cycles = text.trim().split("\n")[0]
        }
    }
    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: history.running = true
    }

    component Stat: ColumnLayout {
        property string label
        property string value
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        spacing: 0
        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: parent.value
            font.family: Theme.font.mono
            font.weight: Font.Bold
        }
        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: parent.label
            font.pixelSize: Theme.font.tiny
            color: Theme.textFaint
        }
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Icon {
                text: Power.icon
                size: 26
                color: root.tint
            }
            StyledText {
                text: Power.percent + "%"
                font.family: Theme.font.mono
                font.pixelSize: Theme.font.headline
                font.weight: Font.Bold
                color: root.tint
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: Power.acPlugged ? I18n.tr("Alimentatore") : I18n.tr("Batteria")
                    font.pixelSize: Theme.font.small
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: text !== ""
                    horizontalAlignment: Text.AlignRight
                    text: Power.timeLabel
                    font.pixelSize: Theme.font.tiny
                    color: Theme.textDim
                }
            }
        }

        // ── Profilo energetico ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: Power.profiles
                delegate: StyledRect {
                    id: prof
                    required property var modelData
                    readonly property bool on: Power.profile === modelData.id
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: 52
                    radius: Theme.radius.normal
                    color: on ? Theme.primaryFill : Theme.surfaceContainerHigh
                    border.width: on ? 1 : 0
                    border.color: Theme.alpha(Theme.primary, 0.6)
                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Icon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: prof.modelData.icon
                            size: 18
                            color: prof.on ? Theme.primary : Theme.textDim
                        }
                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: prof.modelData.label
                            font.pixelSize: Theme.font.tiny
                            color: prof.on ? Theme.primary : Theme.textDim
                        }
                    }
                    StateLayer {
                        tint: prof.on ? Theme.primary : Theme.text
                        onClicked: Power.setProfile(prof.modelData.id)
                    }
                }
            }
        }

        // ── Grafico ──
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 120
            radius: Theme.radius.normal
            color: Theme.surfaceContainer
            clip: true

            Item {
                id: plot
                anchors.fill: parent
                anchors.topMargin: 10
                anchors.bottomMargin: 18

                Repeater {
                    model: [0, 0.5, 1]
                    Rectangle {
                        required property real modelData
                        y: Math.round(modelData * (plot.height - 1))
                        width: plot.width
                        height: 1
                        color: Theme.outlineVariant
                    }
                }
                Graph {
                    anchors.fill: parent
                    points: root.points
                    values: root.values
                    color: root.tint
                }
                Repeater {
                    model: ["100%", "50%"]
                    StyledText {
                        required property string modelData
                        required property int index
                        x: 6
                        y: index * plot.height / 2 + 1
                        text: modelData
                        font.pixelSize: Theme.font.tiny
                        color: Theme.textFaint
                    }
                }
            }
            Repeater {
                model: [root.hours, root.hours / 2, 0]
                StyledText {
                    required property int modelData
                    required property int index
                    x: index === 0 ? 6 : index === 1 ? (parent.width - width) / 2 : parent.width - width - 6
                    y: parent.height - height - 2
                    text: modelData ? "-" + modelData + "h" : I18n.tr("ora")
                    font.pixelSize: Theme.font.tiny
                    color: Theme.textFaint
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Stat {
                label: Power.charging ? I18n.tr("Ricarica") : I18n.tr("Consumo")
                value: Math.abs(Power.device?.changeRate ?? 0).toFixed(1) + " W"
            }
            Stat {
                label: I18n.tr("Energia residua")
                value: (Power.device?.energy ?? 0).toFixed(1) + " Wh"
            }
            Stat {
                visible: Power.health > 0
                label: I18n.tr("Salute")
                value: Math.round(Power.health) + "%"
            }
            Stat {
                visible: root.cycles !== ""
                label: I18n.tr("Cicli")
                value: root.cycles
            }
        }

        // ── Luminosità e caffeine: quello che incide di più sull'autonomia ──
        StyledSlider {
            Layout.fillWidth: true
            visible: Brightness.available
            icon: Brightness.value > 0.66 ? Icons.brightnessHigh : Brightness.value > 0.33 ? Icons.brightnessMid : Icons.brightnessLow
            value: Brightness.value
            onMoved: v => Brightness.set(v)
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Icon {
                text: Settings.caffeine ? Icons.coffee : Icons.coffeeOutline
                size: 18
                color: Settings.caffeine ? Theme.primary : Theme.textDim
            }
            StyledText {
                Layout.fillWidth: true
                text: I18n.tr("Schermo sempre acceso")
                font.pixelSize: Theme.font.small
            }
            Toggle {
                checked: Settings.caffeine
                onToggled: v => Settings.caffeine = v
            }
        }
    }
}
