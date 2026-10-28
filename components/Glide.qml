import QtQuick
import qs.theme

// a decelerating glide for things that move or resize, lands without overshooting
NumberAnimation {
    duration: Theme.anim.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.anim.decel
}
