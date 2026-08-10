import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Item {
    id: wsRoot
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 11
    property color activeColor: "#00ff41"
    property color inactiveColor: "#00ff41"
    property color emptyColor: "#333333"

    implicitWidth: wsRow.width
    implicitHeight: 24
    clip: false

    property int activeWs: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    property int prevWs: 1
    
    property real globalTime: 0
    Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: wsRoot.globalTime += 0.016
    }

    onActiveWsChanged: {
        if (prevWs !== activeWs) {
            // Trigger ripple from change
            rippleAnim.restart()
        }
        prevWs = activeWs
    }

    // === SLIDING INDICATOR LINE ===
    Rectangle {
        id: slideIndicator
        
        property int targetIndex: wsRoot.activeWs - 1
        property real targetX: wsRow.x + targetIndex * 28 + 11 - width/2
        
        x: targetX
        y: wsRow.y + wsRow.height + 2
        width: 20
        height: 2
        radius: 1
        color: wsRoot.activeColor
        
        Behavior on x {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutCubic
            }
        }
        
        // Glow under the line
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 8
            height: 6
            radius: 3
            color: wsRoot.activeColor
            opacity: 0.3
            z: -1
        }
        
        // Pulse animation
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { to: 0.7; duration: 1000; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InOutSine }
        }
    }

    // === RIPPLE ON CHANGE ===
    Rectangle {
        id: ripple
        property real progress: 0
        
        x: wsRow.x + (wsRoot.activeWs - 1) * 28 + 11 - width/2
        y: wsRow.y + wsRow.height / 2 - height/2
        width: progress * 60
        height: width
        radius: width / 2
        color: "transparent"
        border.color: wsRoot.activeColor
        border.width: 1
        opacity: (1 - progress) * 0.5
        visible: progress > 0 && progress < 1
        
        SequentialAnimation {
            id: rippleAnim
            
            PropertyAction { target: ripple; property: "progress"; value: 0 }
            NumberAnimation {
                target: ripple
                property: "progress"
                to: 1
                duration: 400
                easing.type: Easing.OutQuad
            }
        }
    }

    // === WORKSPACE NUMBERS ===
    Row {
        id: wsRow
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: 9

            delegate: Item {
                id: wsDelegate
                property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                property bool isActive: wsRoot.activeWs === (index + 1)
                property bool hasWindows: ws !== undefined
                property bool isHovered: wsMouse.containsMouse

                width: 22
                height: 22

                // Number text
                Text {
                    id: wsText
                    anchors.centerIn: parent
                    text: index + 1
                    color: isActive ? wsRoot.activeColor : 
                           (hasWindows ? Qt.rgba(wsRoot.activeColor.r, wsRoot.activeColor.g, wsRoot.activeColor.b, 0.6) : 
                           wsRoot.emptyColor)
                    font { 
                        family: wsRoot.fontFamily
                        pixelSize: wsRoot.fontSize
                        bold: isActive
                    }
                    
                    // Scale on active
                    scale: isActive ? 1.15 : (isHovered ? 1.1 : 1.0)
                    
                    Behavior on scale {
                        NumberAnimation { 
                            duration: 150
                            easing.type: Easing.OutBack
                        }
                    }
                    
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                    
                    // Subtle glow for active
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.paintedWidth + 12
                        height: parent.paintedHeight + 8
                        radius: 4
                        color: wsRoot.activeColor
                        opacity: isActive ? 0.15 : 0
                        z: -1
                        
                        Behavior on opacity {
                            NumberAnimation { duration: 200 }
                        }
                    }
                }
                
                // Activity dot indicator
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -4
                    width: 3
                    height: 3
                    radius: 1.5
                    color: wsRoot.activeColor
                    opacity: hasWindows && !isActive ? 0.5 : 0
                    visible: opacity > 0
                    
                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }
                }

                MouseArea {
                    id: wsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + (index + 1))
                }
            }
        }
    }

    // === ACTIVE WORKSPACE BREATHING GLOW ===
    Rectangle {
        id: activeGlow
        
        property int targetIndex: wsRoot.activeWs - 1
        
        x: wsRow.x + targetIndex * 28 + 11 - width/2
        y: wsRow.y + (wsRow.height - height) / 2
        width: 30
        height: 24
        radius: 6
        color: wsRoot.activeColor
        opacity: 0.08
        z: -2
        
        Behavior on x {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutCubic
            }
        }
        
        // Breathing
        SequentialAnimation on scale {
            loops: Animation.Infinite
            NumberAnimation { to: 1.1; duration: 1200; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 1200; easing.type: Easing.InOutSine }
        }
    }
}
