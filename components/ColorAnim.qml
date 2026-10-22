import QtQuick
import qs.theme

ColorAnimation {
    duration: Theme.anim.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.anim.standard
}
