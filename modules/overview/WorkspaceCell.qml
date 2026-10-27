import QtQuick
import Quickshell.Widgets
import qs.config
import qs.theme
import qs.services
import qs.components

// one workspace scaled down, accepts dropped windows
// clipped to its rounded shape, a plain clip is square and left previews poking out at the corners
ClippingRectangle {
    id: root

    required property int workspaceId
    required property var overview
    readonly property bool current: Hypr.activeWorkspace === workspaceId
    readonly property bool selected: overview.selected === workspaceId
    readonly property var monitor: Hypr.focusedMonitor
    readonly property var windows: Hypr.toplevels.values.filter(t => t.workspace?.id === workspaceId)

    implicitWidth: overview.cellWidth
    implicitHeight: overview.cellHeight
    radius: Theme.radius.large
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

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.width: root.selected || drop.containsDrag ? 3 : root.current ? 1 : 0
        border.color: root.selected || drop.containsDrag ? Theme.color.primary : Theme.color.inkMeta

        Behavior on border.width {
            Anim {
                duration: Theme.anim.fast
            }
        }
        z: 50
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
            color: root.current ? Theme.color.fgPrimary : Theme.color.ink
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

    Repeater {
        model: root.windows

        WindowPreview {
            required property var modelData

            toplevel: modelData
            workspaceId: root.workspaceId
            scaleFactor: root.overview.cellScale
            originX: root.monitor?.x ?? 0
            originY: root.monitor?.y ?? 0
            dragLayer: root.overview.dragLayer
        }
    }
}
