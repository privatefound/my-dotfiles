import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Item {
    id: wsRoot
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 10
    property color activeColor: "#00ff41"
    property color inactiveColor: "#008f11"
    property color emptyColor: "#1a1a1a"

    implicitWidth: pillRow.width
    implicitHeight: 22
    clip: false

    property int activeWs: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0
    property int prevWs: 0

    onActiveWsChanged: {
        if (prevWs > 0 && prevWs !== activeWs && prevWs >= 1 && prevWs <= 9 && activeWs >= 1 && activeWs <= 9) {
            morphAnim.trigger(prevWs - 1, activeWs - 1)
        }
        prevWs = activeWs
    }

    function calcPillCenter(pillIndex, activeIndex) {
        var x = 0
        for (var i = 0; i < pillIndex; i++) {
            x += (i === activeIndex ? 28 : 8) + 4
        }
        return x + (pillIndex === activeIndex ? 28 : 8) / 2
    }

    Row {
        id: pillRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
            id: wsRepeater
            model: 9

            delegate: Item {
                id: pillDelegate
                property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                property bool isActive: wsRoot.activeWs === (index + 1)
                property bool hasWindows: ws !== undefined

                width: isActive ? 28 : 8
                height: isActive ? 16 : 8
                anchors.verticalCenter: parent ? parent.verticalCenter : undefined

                Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                // Glow behind active
                Rectangle {
                    visible: isActive
                    anchors.centerIn: parent
                    width: parent.width + 6
                    height: parent.height + 6
                    radius: height / 2
                    color: activeColor
                    opacity: 0.1
                }

                // Main pill
                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: isActive ? activeColor : (hasWindows ? inactiveColor : emptyColor)
                    opacity: isActive ? 1.0 : (hasWindows ? 0.7 : 0.2)

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: index + 1
                        color: "#000000"
                        font { family: wsRoot.fontFamily; pixelSize: wsRoot.fontSize; bold: true }
                        visible: isActive
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -3
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + (index + 1))
                }
            }
        }
    }

    // ── Morph light ──
    Rectangle {
        id: morphLight
        width: 12
        height: 12
        radius: 6
        color: wsRoot.activeColor
        opacity: 0
        y: pillRow.y + (pillRow.height - height) / 2
        z: 20

        // White-hot core
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.4
            height: parent.height * 0.4
            radius: width / 2
            color: "#ffffff"
            opacity: 0.9
        }

        // Outer glow
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 12
            height: parent.height + 12
            radius: width / 2
            color: wsRoot.activeColor
            opacity: 0.25
            z: -1
        }

        // Wide ambient glow
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 24
            height: parent.height + 20
            radius: width / 2
            color: wsRoot.activeColor
            opacity: 0.08
            z: -2
        }
    }

    SequentialAnimation {
        id: morphAnim

        property real fromX: 0
        property real toX: 0
        property real travelDist: 0

        function trigger(fromIdx, toIdx) {
            stop()
            morphLight.opacity = 0

            var fc = wsRoot.calcPillCenter(fromIdx, fromIdx)
            var tc = wsRoot.calcPillCenter(toIdx, toIdx)

            fromX = fc - morphLight.width / 2
            toX = tc - morphLight.width / 2
            travelDist = Math.abs(toX - fromX)

            morphLight.x = fromX
            morphLight.width = 12
            morphLight.height = 12
            morphLight.radius = 6
            start()
        }

        // Flash in at origin
        NumberAnimation {
            target: morphLight; property: "opacity"
            from: 0; to: 0.95; duration: 40
        }

        // Travel + stretch
        ParallelAnimation {
            NumberAnimation {
                target: morphLight; property: "x"
                from: morphAnim.fromX; to: morphAnim.toX
                duration: 250; easing.type: Easing.InOutCubic
            }
            // Stretch horizontally during travel
            SequentialAnimation {
                NumberAnimation {
                    target: morphLight; property: "width"
                    to: Math.min(12 + morphAnim.travelDist * 0.3, 50)
                    duration: 125; easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: morphLight; property: "width"
                    to: 12; duration: 125; easing.type: Easing.InQuad
                }
            }
            // Squash vertically during travel
            SequentialAnimation {
                NumberAnimation {
                    target: morphLight; property: "height"
                    to: 8; duration: 125; easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: morphLight; property: "height"
                    to: 12; duration: 125; easing.type: Easing.InQuad
                }
            }
        }

        // Brief hold at target
        PauseAnimation { duration: 60 }

        // Fade out
        NumberAnimation {
            target: morphLight; property: "opacity"
            to: 0; duration: 400; easing.type: Easing.OutCubic
        }
    }
}
