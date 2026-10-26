import QtQuick
import qs.theme

// the ledge behind a rounded parent for the raised look, dark at the top and lit at the bottom when backlit
// the parent sinks onto it by translating down by its shift, a pressed key flashes its light
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
    gradient: Gradient {
        GradientStop {
            position: 0
            color: Theme.color.depthShadow
        }

        GradientStop {
            position: 0.7
            color: Theme.color.depthShadow
        }

        GradientStop {
            position: 1
            color: Theme.mix(Theme.color.depthLit, "#ffffff", 0.35 * root.sink)
        }
    }

    Behavior on sink {
        Anim {
            duration: Theme.anim.fast / 2
        }
    }
}
