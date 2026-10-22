import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.theme
import qs.services

// raised card bound to one id in the actions singleton
// edge panels slide in from their side, center panels float over a scrim
PanelWindow {
    id: root

    required property string panelId
    // top, bottom, left, right or center
    property string edge: "center"
    property bool exclusiveKeyboard: false
    property bool suppressed: false
    property int padding: Theme.spacing.large
    property color background: Theme.color.panel
    property bool dim: edge === "center"
    // panels whose content resizes while open keep a full height window and animate inside it
    property bool tall: false
    readonly property bool open: Actions.panel === panelId && !suppressed
    property real progress: open ? 1 : 0
    readonly property bool shown: open || progress > 0
    default property alias contents: content.data

    readonly property bool centered: edge === "center"
    readonly property bool side: edge === "left" || edge === "right"
    readonly property int shadowPad: Theme.size.shadow
    readonly property int gap: centered ? 0 : Theme.spacing.small
    readonly property int reserved: Modes.islands ? Config.options.bar.size : Config.options.island.height
    // room a panel may take before it runs off the screen
    readonly property real availableHeight: (screen ? screen.height : 720) - reserved - shadowPad * 2 - gap
    // panels hold one root item that sets the size
    readonly property Item main: content.children.length > 0 ? content.children[0] : null
    readonly property real fullWidth: (main?.width ?? 0) + padding * 2
    readonly property real fullHeight: (main?.height ?? 0) + padding * 2
    property real shownHeight: fullHeight
    readonly property real travel: Theme.spacing.xl * (1 - progress)

    signal opened

    screen: Hypr.screenFor(Actions.screen)
    visible: shown
    color: "transparent"
    exclusionMode: centered ? ExclusionMode.Ignore : ExclusionMode.Normal
    WlrLayershell.namespace: "sweeteh-" + panelId
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? (exclusiveKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand) : WlrKeyboardFocus.None

    anchors.top: centered || edge === "top" || side
    anchors.bottom: centered || edge === "bottom"
    anchors.left: centered || edge === "left"
    anchors.right: centered || edge === "right"
    margins.top: gap
    margins.bottom: gap
    margins.left: gap
    margins.right: gap

    implicitWidth: fullWidth + shadowPad * 2
    implicitHeight: (tall ? Math.max(fullHeight, availableHeight) : fullHeight) + shadowPad * 2

    mask: Region {
        item: root.dim ? scrim : body
    }

    Behavior on shownHeight {
        enabled: root.progress >= 1

        Anim {
            easing.bezierCurve: Theme.anim.emphasized
        }
    }

    Behavior on progress {
        Anim {
            duration: root.open ? Theme.anim.slow : Theme.anim.normal
            easing.bezierCurve: root.open ? Theme.anim.decel : Theme.anim.accel
        }
    }

    // move focus off text fields on close so the input method lets go
    onOpenChanged: {
        body.forceActiveFocus();
        if (open)
            opened();
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.open && root.visible
        onCleared: Actions.close(root.panelId)
    }

    Rectangle {
        id: scrim

        anchors.fill: parent
        visible: root.dim
        color: Theme.color.scrim
        opacity: 0.4 * root.progress

        MouseArea {
            anchors.fill: parent
            onClicked: Actions.close(root.panelId)
        }
    }

    Item {
        anchors.fill: parent
        opacity: root.progress
        scale: 0.94 + 0.06 * root.progress
        transformOrigin: root.edge === "bottom" ? Item.Bottom : root.edge === "left" ? Item.Left : root.edge === "right" ? Item.Right : Item.Top

        // soft shadow, kept apart from content so text casts none
        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.alpha(Theme.color.shadow, Theme.dark ? 0.55 : 0.25)
                shadowBlur: 0.8
                blurMax: root.shadowPad
                shadowVerticalOffset: 2
            }

            // hard shadow for the raised look
            Rectangle {
                x: body.x
                y: body.y + Theme.depth.offset
                width: body.width
                height: body.height
                visible: Theme.depth.on
                radius: Theme.radius.xl
                color: Theme.color.depthShadow
            }

            Rectangle {
                x: body.x
                y: body.y
                width: body.width
                height: body.height
                radius: Theme.radius.xl
                color: root.background
                border.width: Theme.depth.rim
                border.color: Theme.color.depthRim
            }
        }

        FocusScope {
            id: body

            x: root.centered ? (root.width - width) / 2 : root.shadowPad + (root.edge === "left" ? -root.travel : root.edge === "right" ? root.travel : 0)
            y: {
                if (root.centered)
                    return (root.height - height) / 2 + root.travel;
                if (root.edge === "bottom")
                    return root.height - root.shadowPad - height + root.travel;
                return root.shadowPad - (root.edge === "top" ? root.travel : 0);
            }
            width: root.fullWidth
            height: root.shownHeight
            focus: true
            Keys.onEscapePressed: Actions.close(root.panelId)

            // swallow clicks so the scrim under the card does not close it
            MouseArea {
                anchors.fill: parent
                visible: root.dim
            }

            Item {
                id: content

                x: root.padding
                y: root.padding
            }
        }
    }
}
