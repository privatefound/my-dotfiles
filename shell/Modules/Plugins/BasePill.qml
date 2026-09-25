import QtQuick
import qs.Common

// "Pillola" in barra per i widget dei plugin DMS, nello stile della barra della shell.
Item {
    id: root

    property var axis: null
    property string section: "right"
    property var popoutTarget: null
    property var parentScreen: null
    property real widgetThickness: 30
    property real barThickness: 40
    property real barSpacing: 4
    property var barConfig: null
    property var blurBarWindow: null
    property alias content: contentLoader.sourceComponent
    property bool isVerticalOrientation: false
    property bool isFirst: false
    property bool isLast: false
    property string segmentRole: "solo"
    property bool isLeftBarEdge: false
    property bool isRightBarEdge: false
    property bool isTopBarEdge: false
    property bool isBottomBarEdge: false
    property real sectionSpacing: 0
    property real crossEdgeExtension: 0

    readonly property real horizontalPadding: 8
    readonly property real visualWidth: contentLoader.item ? contentLoader.item.implicitWidth + horizontalPadding * 2 : 0
    readonly property real visualHeight: widgetThickness
    readonly property alias visualContent: visualContent
    readonly property bool isMouseHovered: mouse.containsMouse

    signal clicked
    signal pressedAt(real rootX, real rootY)
    signal rightClicked(real rootX, real rootY)
    signal wheel(var wheelEvent)

    implicitWidth: visualWidth
    implicitHeight: visualHeight
    width: visualWidth
    height: visualHeight

    Rectangle {
        id: visualContent
        anchors.fill: parent
        radius: height / 2
        color: mouse.pressed ? Theme.withAlpha(Theme.primary, 0.16) : mouse.containsMouse ? Theme.withAlpha(Theme.primary, 0.1) : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }

        Loader {
            id: contentLoader
            anchors.centerIn: parent
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: m => root.pressedAt(m.x, m.y)
        onClicked: m => {
            if (m.button === Qt.RightButton)
                root.rightClicked(m.x, m.y);
            else
                root.clicked();
        }
        onWheel: w => root.wheel(w)
    }
}
