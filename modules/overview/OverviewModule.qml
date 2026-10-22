import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.theme
import qs.services
import qs.components

// workspace grid with live window previews, drag windows between workspaces
PanelWindow {
    id: root

    readonly property bool open: Actions.isOpen("overview")
    readonly property int rows: Config.options.overview.rows
    readonly property int columns: Config.options.overview.columns
    readonly property int perPage: rows * columns
    readonly property int page: Math.floor((Hypr.activeWorkspace - 1) / perPage)
    readonly property real cellScale: Config.options.overview.scale * (Config.options.overview.columns > 4 ? 1 : 1.3)
    readonly property real cellWidth: (screen?.width ?? 1920) * cellScale
    readonly property real cellHeight: (screen?.height ?? 1080) * cellScale
    readonly property Item dragLayer: layer
    // the workspace arrows and numbers point at, enter goes there
    property int selected: 1

    function move(delta: int): void {
        const first = page * perPage + 1;
        selected = Math.max(first, Math.min(first + perPage - 1, selected + delta));
    }

    function go(id: int): void {
        Hypr.focusWorkspace(id);
        Actions.close("overview");
    }

    screen: Hypr.screenFor(Actions.screen)
    visible: open || content.opacity > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "sweeteh-overview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    onOpenChanged: {
        if (open) {
            Hyprland.refreshToplevels();
            Hyprland.refreshMonitors();
            selected = Hypr.activeWorkspace;
            content.forceActiveFocus();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.color.scrim
        opacity: root.open ? 0.45 : 0

        Behavior on opacity {
            Anim {}
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Actions.close("overview")
        }
    }

    Item {
        id: content

        anchors.centerIn: parent
        width: board.implicitWidth + Theme.spacing.large * 2
        height: board.implicitHeight + Theme.spacing.large * 2
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.9
        focus: true
        Keys.onEscapePressed: Actions.close("overview")
        Keys.onLeftPressed: root.move(-1)
        Keys.onRightPressed: root.move(1)
        Keys.onUpPressed: root.move(-root.columns)
        Keys.onDownPressed: root.move(root.columns)
        Keys.onTabPressed: root.move(1)
        Keys.onBacktabPressed: root.move(-1)
        Keys.onReturnPressed: root.go(root.selected)
        Keys.onEnterPressed: root.go(root.selected)
        Keys.onSpacePressed: root.go(root.selected)
        // number keys jump straight to a workspace
        Keys.onPressed: e => {
            const n = e.key - Qt.Key_0;
            if (n >= 0 && n <= 9) {
                root.go(root.page * root.perPage + (n === 0 ? 10 : n));
                e.accepted = true;
            }
        }

        Behavior on opacity {
            Anim {}
        }

        Behavior on scale {
            Anim {
                easing.bezierCurve: root.open ? Theme.anim.decel : Theme.anim.accel
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius.xl
            color: Theme.color.panel
            border.width: Theme.depth.rim
            border.color: Theme.color.depthRim

            Depth {}
        }

        GridLayout {
            id: board

            anchors.centerIn: parent
            columns: root.columns
            rowSpacing: Theme.spacing.medium
            columnSpacing: Theme.spacing.medium

            Repeater {
                model: root.open ? root.perPage : 0

                WorkspaceCell {
                    required property int index

                    workspaceId: root.page * root.perPage + index + 1
                    overview: root
                }
            }
        }

        // dragged previews move here so cells do not clip them
        Item {
            id: layer

            anchors.fill: parent
            z: 100
        }
    }
}
