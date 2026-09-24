import QtQuick
import qs.config

ColorAnimation {
    duration: Theme.anim.fast
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.anim.standard
}
