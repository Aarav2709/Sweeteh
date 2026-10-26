import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.theme
import qs.services
import qs.components

// workspace grid with live window previews in the island, drag windows between workspaces
Item {
    id: root

    readonly property bool open: Actions.isOpen("overview")
    readonly property var screen: Hypr.screenFor(Actions.screen)
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

    // the island calls this as it opens
    function reset(): void {
        Hyprland.refreshToplevels();
        Hyprland.refreshMonitors();
        selected = Hypr.activeWorkspace;
        content.forceActiveFocus();
    }

    implicitWidth: content.width
    implicitHeight: content.height

    Item {
        id: content

        width: board.implicitWidth
        height: board.implicitHeight
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

        GridLayout {
            id: board

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
