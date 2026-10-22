import QtQuick
import QtQuick.Layouts
import qs.theme

// raised pill on the bar that lays its children out in a row
Item {
    id: root

    property bool active: false
    // widgets hide through this so the slot can skip them
    property bool shown: true
    property bool interactive: true
    // pills that only scroll skip the hover look so they do not read as buttons
    property bool clickable: true
    property int padding: Theme.spacing.medium
    // trailing side, for pills that lead with a round badge
    property int endPadding: padding
    property int itemSpacing: Theme.spacing.small
    readonly property color tint: active ? Theme.color.fgSecondaryContainer : Theme.color.ink
    default property alias contents: flow.data

    signal clicked
    signal rightClicked
    signal middleClicked
    signal scrolled(int delta)

    visible: shown
    implicitWidth: Math.max(Theme.size.barWidget, flow.implicitWidth + padding + endPadding)
    implicitHeight: Theme.size.barWidget

    transform: Translate {
        y: depth.shift
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius.full
        color: root.active ? Theme.color.secondaryContainer : Theme.color.panel
        border.width: Theme.depth.rim
        border.color: Theme.color.depthRim

        Depth {
            id: depth

            sink: area.pressed ? 1 : 0
        }

        Behavior on color {
            ColorAnim {}
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.tint
            opacity: !area ? 0 : area.pressed ? Theme.state.press : area.containsMouse && root.interactive && root.clickable ? Theme.state.hover : 0

            Behavior on opacity {
                Anim {
                    duration: Theme.anim.fast
                }
            }
        }
    }

    RowLayout {
        id: flow

        x: Math.max(root.padding, (parent.width - width) / 2 + (root.padding - root.endPadding) / 2)
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.itemSpacing
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        enabled: root.interactive
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: e => e.button === Qt.RightButton ? root.rightClicked() : e.button === Qt.MiddleButton ? root.middleClicked() : root.clicked()
        onWheel: e => root.scrolled(e.angleDelta.y > 0 ? 1 : -1)
    }
}
