import QtQuick
import QtQuick.Shapes
import qs.theme

// small area graph of values between zero and one, newest on the right
Shape {
    id: root

    property var values: []
    property int capacity: 40
    property color color: Theme.color.primary

    readonly property var points: {
        const n = Math.max(2, capacity);
        const step = width / (n - 1);
        const start = n - values.length;
        return values.map((v, i) => Qt.point((start + i) * step, height - Math.max(0, Math.min(1, v)) * (height - 2) - 1));
    }

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeWidth: -1
        fillGradient: LinearGradient {
            x1: 0
            y1: 0
            x2: 0
            y2: root.height

            GradientStop {
                position: 0
                color: Qt.alpha(root.color, 0.35)
            }

            GradientStop {
                position: 1
                color: Qt.alpha(root.color, 0)
            }
        }

        PathPolyline {
            path: root.points.length > 1 ? [Qt.point(root.points[0].x, root.height)].concat(root.points).concat([Qt.point(root.width, root.height)]) : []
        }
    }

    ShapePath {
        strokeColor: root.color
        strokeWidth: 2
        fillColor: "transparent"
        joinStyle: ShapePath.RoundJoin
        capStyle: ShapePath.RoundCap

        PathPolyline {
            path: root.points
        }
    }
}
