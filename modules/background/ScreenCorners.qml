import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.theme

// rounds the four corners of the screen, drawn above everything and never takes input
PanelWindow {
    id: root

    required property var modelData
    readonly property int size: Theme.radius.large

    screen: modelData
    visible: Config.options.theme.screenCorners
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "sweeteh-corners"
    WlrLayershell.layer: WlrLayer.Overlay
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    mask: Region {}

    Repeater {
        model: 4

        Shape {
            required property int index

            x: index % 2 === 0 ? 0 : root.width - root.size
            y: index < 2 ? 0 : root.height - root.size
            width: root.size
            height: root.size
            rotation: [0, 90, 270, 180][index]
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "black"
                strokeWidth: -1

                PathSvg {
                    path: `M 0 0 L ${root.size} 0 A ${root.size} ${root.size} 0 0 0 0 ${root.size} Z`
                }
            }
        }
    }
}
