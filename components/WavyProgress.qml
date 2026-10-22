import QtQuick
import QtQuick.Shapes
import qs.theme

// expressive progress bar, the played part ripples while moving and lies flat when still
Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 1
    property bool moving: false
    readonly property real ratio: area.pressed ? area.dragRatio : Math.max(0, Math.min(1, (value - from) / Math.max(0.0001, to - from)))
    readonly property real stroke: 4
    readonly property real amplitude: 3 * calm
    readonly property real wavelength: 26
    readonly property real handleX: stroke / 2 + (width - stroke) * ratio
    property real phase: 0
    property real calm: moving ? 1 : 0

    signal moved(real value)

    implicitWidth: 200
    implicitHeight: 20

    Behavior on calm {
        Anim {
            duration: Theme.anim.slow
        }
    }

    NumberAnimation on phase {
        running: root.moving && root.visible
        from: 0
        to: Math.PI * 2
        duration: 1600
        loops: Animation.Infinite
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: Theme.color.primary
            strokeWidth: root.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathPolyline {
                path: {
                    const end = Math.max(root.stroke / 2, root.handleX - root.stroke - 3);
                    const mid = root.height / 2;
                    const pts = [];
                    for (let x = root.stroke / 2; x < end; x += 2)
                        pts.push(Qt.point(x, mid + Math.sin(x / root.wavelength * Math.PI * 2 - root.phase) * root.amplitude));
                    pts.push(Qt.point(end, mid + Math.sin(end / root.wavelength * Math.PI * 2 - root.phase) * root.amplitude));
                    return pts;
                }
            }
        }

        ShapePath {
            strokeColor: Theme.color.secondaryContainer
            strokeWidth: root.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            startX: Math.min(root.width - root.stroke / 2, root.handleX + root.stroke + 3)
            startY: root.height / 2

            PathLine {
                x: root.width - root.stroke / 2
                y: root.height / 2
            }
        }
    }

    Rectangle {
        x: root.handleX - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: root.stroke
        height: root.height - 2
        radius: width / 2
        color: Theme.color.primary
    }

    MouseArea {
        id: area

        property real dragRatio: 0

        function update(x: real): void {
            dragRatio = Math.max(0, Math.min(1, x / width));
        }

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: e => update(e.x)
        onPositionChanged: e => update(e.x)
        onReleased: root.moved(root.from + dragRatio * (root.to - root.from))
    }
}
