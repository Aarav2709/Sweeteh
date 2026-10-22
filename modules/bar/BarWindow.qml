import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.theme
import qs.components

// raised pills along the top edge, the island sits between them
PanelWindow {
    id: root

    required property var modelData
    readonly property int size: Config.options.bar.size
    readonly property int inset: Math.max(0, (size - Theme.size.barWidget) / 2)

    screen: modelData
    color: "transparent"
    WlrLayershell.namespace: "sweeteh-bar"
    WlrLayershell.layer: WlrLayer.Top
    exclusiveZone: size
    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: size + Theme.depth.offset

    // only the pills take clicks
    mask: Region {
        item: startSlot

        Region {
            item: endSlot
        }
    }

    BarSlot {
        id: startSlot

        ids: Modes.mode.slots.start
        x: root.inset
        y: root.inset
    }

    BarSlot {
        id: endSlot

        ids: Modes.mode.slots.end
        x: root.width - width - root.inset
        y: root.inset
    }
}
