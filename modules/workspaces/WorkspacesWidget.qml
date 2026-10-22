import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.theme
import qs.services
import qs.components

// workspace pill, occupied runs share a backdrop and the active marker stretches between cells
Rectangle {
    id: root

    readonly property int count: Config.options.bar.workspaceCount
    readonly property int base: Math.floor((Hypr.activeWorkspace - 1) / count) * count
    readonly property int pad: Theme.spacing.xs - 1
    readonly property int cell: Theme.size.barWidget - pad * 2
    readonly property var occupied: {
        const out = [];
        for (let i = 0; i < count; i++)
            out.push(Hypr.toplevels.values.some(t => t.workspace?.id === base + i + 1));
        return out;
    }

    implicitWidth: grid.implicitWidth + pad * 2
    implicitHeight: Theme.size.barWidget
    radius: Theme.radius.full
    color: Theme.color.panel
    border.width: Theme.depth.rim
    border.color: Theme.color.depthRim

    Depth {}

    // one backdrop per run of occupied workspaces
    Repeater {
        model: repeater.count > 0 ? root.count : 0

        Rectangle {
            required property int index
            readonly property bool startsRun: root.occupied[index] && (index === 0 || !root.occupied[index - 1])
            readonly property int runEnd: {
                let end = index;
                while (end + 1 < root.count && root.occupied[end + 1])
                    end++;
                return end;
            }
            readonly property Item first: repeater.itemAt(index)
            readonly property Item last: repeater.itemAt(runEnd)

            visible: startsRun && first !== null && last !== null
            x: root.pad + (first?.x ?? 0)
            y: root.pad + (first?.y ?? 0)
            width: (last?.x ?? 0) + (last?.width ?? 0) - (first?.x ?? 0)
            height: root.cell
            radius: Theme.radius.full
            color: Theme.color.layer3
        }
    }

    // active marker, its leading edge moves first so it stretches like a worm
    Rectangle {
        id: marker

        readonly property Item target: repeater.count > 0 ? repeater.itemAt(Hypr.activeWorkspace - 1 - root.base) : null
        readonly property real targetStart: root.pad + (target?.x ?? 0)
        readonly property real targetEnd: targetStart + (target?.width ?? 0)
        property bool forward: true
        property real start: targetStart
        property real end: targetEnd

        onTargetStartChanged: forward = targetStart >= start

        x: start
        y: root.pad
        width: end - start
        height: root.cell
        radius: Theme.radius.full
        color: Theme.color.primary

        Behavior on start {
            Anim {
                duration: marker.forward ? Theme.anim.slow : Theme.anim.normal
                easing.bezierCurve: Theme.anim.emphasized
            }
        }

        Behavior on end {
            Anim {
                duration: marker.forward ? Theme.anim.normal : Theme.anim.slow
                easing.bezierCurve: Theme.anim.emphasized
            }
        }
    }

    Row {
        id: grid

        x: root.pad
        y: root.pad

        Repeater {
            id: repeater

            model: root.count

            Item {
                id: ws

                required property int index
                readonly property int wsId: root.base + index + 1
                readonly property bool current: Hypr.activeWorkspace === wsId
                readonly property var windows: Hypr.toplevels.values.filter(t => t.workspace?.id === wsId)
                readonly property string appClass: windows.map(t => t.wayland?.appId ?? t.lastIpcObject?.class ?? "").find(c => c !== "") ?? ""
                readonly property bool showIcon: Config.options.bar.showAppIcons && appClass !== ""

                implicitWidth: root.cell + 2
                implicitHeight: root.cell

                Label {
                    anchors.centerIn: parent
                    visible: !ws.showIcon
                    text: ws.wsId
                    font.pixelSize: Theme.font.small
                    font.weight: ws.current ? Font.DemiBold : Font.Medium
                    font.features: ({
                            "tnum": 1
                        })
                    color: ws.current ? Theme.color.fgPrimary : ws.windows.length > 0 ? Theme.color.ink : Theme.color.inkFaint
                }

                IconImage {
                    anchors.centerIn: parent
                    visible: ws.showIcon
                    implicitSize: Math.round(root.cell * 0.7)
                    source: ws.showIcon ? Apps.icon(ws.appClass) : ""
                    asynchronous: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hypr.focusWorkspace(ws.wsId)
                }
            }
        }
    }

    WheelHandler {
        onWheel: e => Hypr.focusWorkspace(Math.max(1, Hypr.activeWorkspace + (e.angleDelta.y > 0 ? -1 : 1)))
    }
}
