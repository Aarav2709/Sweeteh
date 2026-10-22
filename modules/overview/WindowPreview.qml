import QtQuick
import Quickshell.Wayland
import Quickshell.Widgets
import qs.theme
import qs.services

// live scaled window, drag to move it, click to focus, middle click to close
Item {
    id: root

    required property var toplevel
    required property int workspaceId
    required property real scaleFactor
    required property real originX
    required property real originY
    required property Item dragLayer
    property Item home: null
    readonly property var ipc: toplevel.lastIpcObject
    readonly property string address: toplevel.address
    readonly property real homeX: ((ipc?.at?.[0] ?? 0) - originX) * scaleFactor
    readonly property real homeY: ((ipc?.at?.[1] ?? 0) - originY) * scaleFactor

    x: homeX
    y: homeY
    width: Math.max(24, (ipc?.size?.[0] ?? 200) * scaleFactor)
    height: Math.max(24, (ipc?.size?.[1] ?? 120) * scaleFactor)
    z: area.drag.active ? 10 : (ipc?.floating ? 2 : 1)

    Drag.active: area.drag.active
    Drag.keys: ["sweeteh-window"]
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2

    ClippingRectangle {
        anchors.fill: parent
        radius: Theme.radius.small
        color: Theme.color.surfaceContainerHighest
        border.width: area.containsMouse ? 2 : 0
        border.color: Theme.color.primary

        ScreencopyView {
            anchors.fill: parent
            captureSource: root.toplevel.wayland
            live: true
        }

        IconImage {
            anchors.centerIn: parent
            implicitSize: Math.min(parent.width, parent.height) * 0.4
            source: Apps.icon(root.toplevel.wayland?.appId ?? root.ipc?.class ?? "")
            opacity: 0.9
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        drag.target: root
        drag.threshold: 6
        drag.onActiveChanged: {
            if (drag.active) {
                const p = root.mapToItem(root.dragLayer, 0, 0);
                root.home = root.parent;
                root.parent = root.dragLayer;
                root.x = p.x;
                root.y = p.y;
            }
        }
        onReleased: {
            if (!root.home)
                return;
            root.Drag.drop();
            root.parent = root.home;
            root.home = null;
            root.x = Qt.binding(() => root.homeX);
            root.y = Qt.binding(() => root.homeY);
        }
        onClicked: e => {
            if (e.button === Qt.MiddleButton) {
                Hypr.closeWindow(root.address);
                return;
            }
            Hypr.focusWindow(root.address);
            Actions.close("overview");
        }
    }
}
