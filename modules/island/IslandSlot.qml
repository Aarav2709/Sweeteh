import QtQuick
import QtQuick.Effects
import qs.theme
import qs.components
import qs.services

// content that fades, blurs and springs in when its state is active
Item {
    id: root

    property bool shown: false
    default property alias contents: holder.data

    anchors.centerIn: parent
    implicitWidth: holder.childrenRect.width
    implicitHeight: holder.childrenRect.height
    width: implicitWidth
    height: implicitHeight
    visible: opacity > 0
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.9
    enabled: shown
    // a blur that thins out with the fade, only layered while it moves so a resting slot costs nothing
    layer.enabled: Theme.anim.blur && !Perf.active && opacity > 0.01 && opacity < 0.99
    layer.effect: MultiEffect {
        blurEnabled: true
        blurMax: 32
        blur: 1 - root.opacity
    }

    Behavior on opacity {
        Anim {
            duration: root.shown ? Theme.anim.slow : Theme.anim.fast
        }
    }

    Behavior on scale {
        Anim {
            duration: Theme.anim.slow
            easing.bezierCurve: root.shown ? Theme.anim.spatial : Theme.anim.accel
        }
    }

    Item {
        id: holder

        anchors.fill: parent
    }
}
