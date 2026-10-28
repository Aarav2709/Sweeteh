import QtQuick
import QtQuick.Shapes
import qs.theme

// notch hanging from the top edge, the top corners flare outward so it melts into the edge
Shape {
    id: root

    property color color: Theme.color.panel
    property real radius: Theme.radius.xl
    property real flare: Theme.radius.flare
    // optional outline along the shape
    property real rimWidth: 0
    property color rim: Theme.color.depthRim
    // a gradient takes over from the plain color when set
    property ShapeGradient gradient: null

    // clamped once per size change, the path below binds straight to these instead of parsing a string every frame
    readonly property real r: Math.max(0, Math.min(radius, width / 2, height / 2))
    readonly property real f: Math.max(0, Math.min(flare, height / 2))

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.color
        fillGradient: root.gradient
        strokeWidth: root.rimWidth > 0 ? root.rimWidth : -1
        strokeColor: root.rimWidth > 0 ? root.rim : "transparent"
        startX: -root.f
        startY: 0

        PathLine {
            x: root.width + root.f
            y: 0
        }

        PathArc {
            x: root.width
            y: root.f
            radiusX: root.f
            radiusY: root.f
            direction: PathArc.Counterclockwise
        }

        PathLine {
            x: root.width
            y: root.height - root.r
        }

        PathArc {
            x: root.width - root.r
            y: root.height
            radiusX: root.r
            radiusY: root.r
        }

        PathLine {
            x: root.r
            y: root.height
        }

        PathArc {
            x: 0
            y: root.height - root.r
            radiusX: root.r
            radiusY: root.r
        }

        PathLine {
            x: 0
            y: root.f
        }

        PathArc {
            x: -root.f
            y: 0
            radiusX: root.f
            radiusY: root.f
            direction: PathArc.Counterclockwise
        }
    }
}
