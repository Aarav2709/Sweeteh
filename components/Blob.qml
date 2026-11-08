import QtQuick
import QtQuick.Shapes
import qs.theme

// a material 3 expressive shape, clover, cookie, burst and the rest, drawn as one smooth outline
Item {
    id: root

    property string shape: "circle"
    property color color: Theme.color.primary
    property real size: 18

    // the outline in unit space, sampled once per shape and fitted to a square
    readonly property var unit: {
        const n = 120;
        const pts = [];
        const lobes = { cookie4: [4, 0.16], cookie6: [6, 0.11], cookie9: [9, 0.07], clover: [4, 0.3], flower: [8, 0.14], softburst: [10, 0.09] }[shape];
        if (lobes) {
            for (let i = 0; i < n; i++) {
                const t = i / n * Math.PI * 2;
                const r = 1 - lobes[1] + lobes[1] * Math.cos(lobes[0] * t);
                pts.push([r * Math.cos(t), r * Math.sin(t)]);
            }
        } else if (shape === "pentagon" || shape === "triangle") {
            // a sharp polygon with its corners worn round by averaging the radius around them
            const k = shape === "pentagon" ? 5 : 3;
            const raw = [];
            for (let i = 0; i < n; i++) {
                const t = i / n * Math.PI * 2;
                const a = ((t + Math.PI / 2) % (Math.PI * 2 / k) + Math.PI * 2 / k) % (Math.PI * 2 / k);
                raw.push(Math.cos(Math.PI / k) / Math.cos(a - Math.PI / k));
            }
            const w = 7;
            for (let i = 0; i < n; i++) {
                let sum = 0;
                for (let j = -w; j <= w; j++)
                    sum += raw[(i + j + n) % n];
                const t = i / n * Math.PI * 2;
                const r = sum / (w * 2 + 1);
                pts.push([r * Math.cos(t), r * Math.sin(t)]);
            }
        } else if (shape === "pill" || shape === "diamond" || shape === "square") {
            // superellipses, a slanted capsule, a soft diamond and a squircle
            const e = { pill: 6, diamond: 1.5, square: 4 }[shape];
            const h = shape === "pill" ? 0.56 : 1;
            const turn = shape === "pill" ? -Math.PI / 4 : 0;
            for (let i = 0; i < n; i++) {
                const t = i / n * Math.PI * 2;
                const c = Math.cos(t), s = Math.sin(t);
                const x = Math.sign(c) * Math.pow(Math.abs(c), 2 / e);
                const y = h * Math.sign(s) * Math.pow(Math.abs(s), 2 / e);
                pts.push([x * Math.cos(turn) - y * Math.sin(turn), x * Math.sin(turn) + y * Math.cos(turn)]);
            }
        } else if (shape === "heart") {
            for (let i = 0; i < n; i++) {
                const t = i / n * Math.PI * 2;
                pts.push([16 * Math.pow(Math.sin(t), 3), -(13 * Math.cos(t) - 5 * Math.cos(2 * t) - 2 * Math.cos(3 * t) - Math.cos(4 * t))]);
            }
        } else {
            for (let i = 0; i < n; i++) {
                const t = i / n * Math.PI * 2;
                pts.push([Math.cos(t), Math.sin(t)]);
            }
        }
        // shapes drawn around their middle stay there, so a glyph on top and a turn both sit true
        // an odd cookie or a pentagon reaches further on one side, centering its box would shift it
        // only the heart, which has no middle of its own, is centered by its box
        const xs = pts.map(p => p[0]), ys = pts.map(p => p[1]);
        const boxed = shape === "heart";
        const cx = boxed ? (Math.max(...xs) + Math.min(...xs)) / 2 : 0;
        const cy = boxed ? (Math.max(...ys) + Math.min(...ys)) / 2 : 0;
        const half = Math.max(...pts.map(p => Math.max(Math.abs(p[0] - cx), Math.abs(p[1] - cy))));
        return pts.map(p => [(p[0] - cx) / half, (p[1] - cy) / half]);
    }

    implicitWidth: size
    implicitHeight: size

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            strokeWidth: 0

            PathPolyline {
                path: {
                    const half = root.width / 2;
                    const out = root.unit.map(p => Qt.point(half + p[0] * half, root.height / 2 + p[1] * half));
                    out.push(out[0]);
                    return out;
                }
            }
        }
    }
}
