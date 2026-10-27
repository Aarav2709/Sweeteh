import QtQuick
import Quickshell.Widgets
import qs.config
import qs.theme
import qs.services
import qs.components

// one workspace scaled down, accepts dropped windows
Item {
    id: root

    required property int workspaceId
    required property var overview
    readonly property bool current: Hypr.activeWorkspace === workspaceId
    readonly property bool selected: overview.selected === workspaceId
    readonly property var monitor: Hypr.focusedMonitor
    readonly property var windows: Hypr.toplevels.values.filter(t => t.workspace?.id === workspaceId)
    // the space the windows really use, gaps and the island's strip left out, so previews fill the cell
    readonly property rect area: {
        const placed = windows.map(t => t.lastIpcObject).filter(o => o?.at && o?.size);
        if (placed.length === 0)
            return Qt.rect(monitor?.x ?? 0, monitor?.y ?? 0, monitor?.width ?? 1920, monitor?.height ?? 1080);
        const x1 = Math.min(...placed.map(o => o.at[0])), y1 = Math.min(...placed.map(o => o.at[1]));
        const x2 = Math.max(...placed.map(o => o.at[0] + o.size[0])), y2 = Math.max(...placed.map(o => o.at[1] + o.size[1]));
        return Qt.rect(x1, y1, Math.max(1, x2 - x1), Math.max(1, y2 - y1));
    }

    implicitWidth: overview.cellWidth
    implicitHeight: overview.cellHeight

    // clipped to its rounded shape, a plain clip is square and left previews poking out at the corners
    ClippingRectangle {
        id: body

        anchors.fill: parent
        // a number before the theme settles, undefined here logged a warning per cell
        radius: Theme.radius.large ?? 20
        color: Theme.color.layer2

        // the wallpaper behind each workspace, dimmed so previews stand out
        Image {
            anchors.fill: parent
            source: Wallpapers.still !== "" ? Paths.url(Wallpapers.still) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 360
            opacity: drop.containsDrag ? 0.3 : 0.75
        }

        Repeater {
            model: root.windows

            WindowPreview {
                required property var modelData

                toplevel: modelData
                workspaceId: root.workspaceId
                scaleFactor: root.width / root.area.width
                scaleY: root.height / root.area.height
                originX: root.area.x
                originY: root.area.y
                dragLayer: root.overview.dragLayer
            }
        }
    }

    // the outline sits outside the clip on the very same rounded rect, so it traces the edge exactly
    Rectangle {
        anchors.fill: parent
        radius: body.radius
        color: "transparent"
        border.width: root.selected || drop.containsDrag ? 3 : root.current ? 1 : 0
        border.color: root.selected || drop.containsDrag ? Theme.color.primary : Theme.color.inkMeta
        z: 50

        Behavior on border.width {
            Anim {
                duration: Theme.anim.fast
            }
        }
    }

    Rectangle {
        x: Theme.spacing.small
        y: Theme.spacing.small
        z: 60
        width: Math.max(height, number.implicitWidth + Theme.spacing.small * 2)
        height: 22
        radius: height / 2
        color: root.current ? Theme.color.primary : Theme.color.panel

        Label {
            id: number

            anchors.centerIn: parent
            text: root.workspaceId
            font.pixelSize: Theme.font.small
            font.weight: Font.DemiBold
            color: parent.color.hslLightness > 0.55 ? Theme.color.abyss : Theme.color.glint
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.overview.selected = root.workspaceId
        onClicked: root.overview.go(root.workspaceId)
    }

    DropArea {
        id: drop

        anchors.fill: parent
        keys: ["sweeteh-window"]
        onDropped: e => {
            const address = e.source.address;
            if (address && e.source.workspaceId !== root.workspaceId)
                Hypr.moveWindow(address, root.workspaceId);
        }
    }
}
