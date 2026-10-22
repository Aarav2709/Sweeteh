import QtQuick
import qs.theme

// number animation using the shared motion tokens
NumberAnimation {
    duration: Theme.anim.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.anim.standard
}
