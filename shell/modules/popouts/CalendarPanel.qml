import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components
import qs.services

// Orologio grande + calendario mensile + lettore multimediale.
Item {
    id: root

    property int monthOffset: 0
    readonly property date today: Time.now
    readonly property date shownMonth: new Date(today.getFullYear(), today.getMonth() + monthOffset, 1)
    readonly property var locale: I18n.locale

    implicitWidth: 400
    implicitHeight: col.implicitHeight + 32

    // Celle: 6 settimane × 7 giorni, a partire da lunedì
    readonly property var cells: {
        const first = new Date(shownMonth);
        const startDow = (first.getDay() + 6) % 7;
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(first.getFullYear(), first.getMonth(), 1 - startDow + i);
            out.push({
                day: d.getDate(),
                inMonth: d.getMonth() === first.getMonth(),
                isToday: d.toDateString() === today.toDateString(),
                weekend: d.getDay() === 0 || d.getDay() === 6
            });
        }
        return out;
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        // Orologio grande
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            StyledText {
                text: Qt.formatTime(Time.now, Settings.clock24h ? "HH:mm" : "h:mm AP")
                font.family: Theme.font.mono
                font.pixelSize: Theme.font.display
                font.weight: Font.Bold
                color: Theme.primary
            }
            StyledText {
                text: Time.longDate
                font.capitalization: Font.Capitalize
                color: Theme.textDim
            }
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: cal.implicitHeight + 24
            radius: Theme.radius.large
            color: Theme.surfaceContainer

            ColumnLayout {
                id: cal
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        Layout.fillWidth: true
                        text: root.locale.toString(root.shownMonth, "MMMM yyyy")
                        font.capitalization: Font.Capitalize
                        font.weight: Font.DemiBold
                        font.pixelSize: Theme.font.title
                    }
                    IconButton {
                        visible: root.monthOffset !== 0
                        size: 30
                        icon: Icons.calendar
                        iconColor: Theme.primary
                        onClicked: root.monthOffset = 0
                    }
                    IconButton {
                        size: 30
                        icon: Icons.chevronLeft
                        onClicked: root.monthOffset--
                    }
                    IconButton {
                        size: 30
                        icon: Icons.chevronRight
                        onClicked: root.monthOffset++
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    rowSpacing: 2
                    columnSpacing: 2

                    Repeater {
                        model: [1, 2, 3, 4, 5, 6, 0].map(d => root.locale.dayName(d, Locale.ShortFormat).slice(0, 2).toLowerCase())
                        delegate: StyledText {
                            required property string modelData
                            required property int index
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            font.pixelSize: Theme.font.tiny
                            font.weight: Font.Bold
                            color: index >= 5 ? Theme.primaryDim : Theme.textFaint
                        }
                    }

                    Repeater {
                        model: root.cells
                        delegate: StyledRect {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 38
                            radius: 19
                            color: modelData.isToday ? Theme.primaryFillStrong : "transparent"
                            border.width: modelData.isToday ? 1 : 0
                            border.color: Theme.primary

                            StyledText {
                                anchors.centerIn: parent
                                text: modelData.day
                                font.family: Theme.font.mono
                                font.pixelSize: Theme.font.small
                                font.weight: modelData.isToday ? Font.Bold : Font.Normal
                                color: modelData.isToday ? Theme.primary : !modelData.inMonth ? Theme.textFaint : modelData.weekend ? Theme.primaryDim : Theme.text
                                opacity: modelData.inMonth ? 1 : 0.5
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: wheel => root.monthOffset += wheel.angleDelta.y > 0 ? -1 : 1
            }
        }

        MediaCard {
            Layout.fillWidth: true
            large: true
            visible: Media.hasPlayer
        }
    }
}
