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

    readonly property string path: {
        const w = width, h = height;
        if (w <= 0 || h <= 0)
            return "";
        const r = Math.max(0, Math.min(radius, w / 2, h / 2));
        const f = Math.max(0, Math.min(flare, h / 2));
        const arc = (rad, sweep, x, y) => `A ${rad} ${rad} 0 0 ${sweep} ${x} ${y}`;
        return [`M ${-f} 0`, `L ${w + f} 0`, arc(f, 0, w, f), `L ${w} ${h - r}`, arc(r, 1, w - r, h), `L ${r} ${h}`, arc(r, 1, 0, h - r), `L 0 ${f}`, arc(f, 0, -f, 0), "Z"].join(" ");
    }

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.color
        strokeWidth: root.rimWidth > 0 ? root.rimWidth : -1
        strokeColor: root.rimWidth > 0 ? root.rim : "transparent"

        PathSvg {
            path: root.path
        }
    }
}
