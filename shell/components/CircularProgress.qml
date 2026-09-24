import QtQuick
import QtQuick.Shapes
import qs.config

// Anello di avanzamento (0..1).
Item {
    id: root

    property real value: 0
    property int thickness: 4
    property color color: Theme.primary
    property color trackColor: Theme.surfaceContainerHighest

    implicitWidth: 36
    implicitHeight: 36

    Behavior on value {
        Anim {}
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.trackColor
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.width / 2 - root.thickness / 2
                radiusY: root.height / 2 - root.thickness / 2
                startAngle: -90
                sweepAngle: 360
            }
        }

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.width / 2 - root.thickness / 2
                radiusY: root.height / 2 - root.thickness / 2
                startAngle: -90
                sweepAngle: 360 * Math.max(0, Math.min(1, root.value))
            }
        }
    }
}
