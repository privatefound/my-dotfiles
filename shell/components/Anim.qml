import QtQuick
import qs.config

NumberAnimation {
    duration: Theme.anim.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.anim.emphasized
}
