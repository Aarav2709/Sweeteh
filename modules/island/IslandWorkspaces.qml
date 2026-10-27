import QtQuick
import Quickshell.Wayland
import qs.theme
import qs.services
import qs.components

// the workspaces in use as small cards with a still of each window, click one to go there
Row {
    id: root

    readonly property var monitor: Hypr.focusedMonitor
    readonly property real screenW: Math.max(1, (monitor?.width ?? 1920) / (monitor?.scale ?? 1))
    readonly property real screenH: Math.max(1, (monitor?.height ?? 1080) / (monitor?.scale ?? 1))
    readonly property int cardW: 168
    readonly property real factor: cardW / screenW
    // occupied workspaces and the current one, up to six
    readonly property var ids: Array.from(new Set(Hypr.toplevels.values.map(t => t.workspace?.id ?? 0).concat([Hypr.activeWorkspace]))).filter(id => id > 0).sort((a, b) => a - b).slice(0, 6)

    signal picked

    spacing: Theme.spacing.small

    Repeater {
        model: root.ids

        Rectangle {
            id: card

            required property int modelData
            readonly property bool current: Hypr.activeWorkspace === modelData

            width: root.cardW
            height: Math.round(root.screenH * root.factor)
            radius: Theme.radius.small
            color: Theme.color.layer2
            border.width: current ? 2 : 0
            border.color: Theme.color.primary
            clip: true

            Repeater {
                model: Hypr.toplevels.values.filter(t => t.workspace?.id === card.modelData && t.wayland)

                ScreencopyView {
                    required property var modelData
                    readonly property var ipc: modelData.lastIpcObject

                    x: ((ipc?.at?.[0] ?? 0) - (root.monitor?.x ?? 0)) * root.factor
                    y: ((ipc?.at?.[1] ?? 0) - (root.monitor?.y ?? 0)) * root.factor
                    width: Math.max(8, (ipc?.size?.[0] ?? 0) * root.factor)
                    height: Math.max(8, (ipc?.size?.[1] ?? 0) * root.factor)
                    captureSource: modelData.wayland
                    // one still per peek, a live feed of every window would cost far more than it is worth
                    live: false
                }
            }

            Rectangle {
                x: Theme.spacing.xs
                y: Theme.spacing.xs
                implicitWidth: Math.max(implicitHeight, num.implicitWidth + Theme.spacing.small)
                implicitHeight: 18
                radius: height / 2
                color: card.current ? Theme.color.primary : Theme.color.layer3

                Label {
                    id: num

                    anchors.centerIn: parent
                    text: card.modelData
                    font.pixelSize: Theme.font.tiny
                    font.weight: Font.DemiBold
                    color: card.current ? Theme.color.fgPrimary : Theme.color.ink
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Hypr.focusWorkspace(card.modelData);
                    root.picked();
                }
            }
        }
    }
}
