import QtQuick
import qs.theme

// hard offset shadow behind a rounded parent for the raised look
// the parent sinks onto it by translating down by its shift
Rectangle {
    id: root

    property real sink: 0
    readonly property real shift: Theme.depth.offset * sink

    z: -1
    visible: Theme.depth.on
    y: Theme.depth.offset - shift
    width: parent.width
    height: parent.height
    radius: parent.radius ?? 0
    color: Theme.color.depthShadow

    Behavior on sink {
        Anim {
            duration: Theme.anim.fast / 2
        }
    }
}
