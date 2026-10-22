import QtQuick
import qs.theme

// expressive material slider, a filled track and a quiet one split by a thin handle
Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 1
    property string icon
    property bool showValue: true
    readonly property real ratio: Math.max(0, Math.min(1, (value - from) / (to - from)))
    readonly property real visualRatio: area.pressed ? area.dragRatio : shownRatio
    property real shownRatio: ratio

    readonly property real trackHeight: height - 8
    readonly property real handleWidth: area.pressed ? 3 : 5
    readonly property real gap: 4
    readonly property real handleX: handleWidth / 2 + (width - handleWidth) * visualRatio
    readonly property real iconSpace: trackHeight

    signal moved(real value)

    implicitWidth: 200
    implicitHeight: Theme.size.slider

    Behavior on shownRatio {
        Anim {
            duration: Theme.anim.fast
        }
    }

    Rectangle {
        id: active

        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, root.handleX - root.handleWidth / 2 - root.gap)
        height: root.trackHeight
        topLeftRadius: height / 2
        bottomLeftRadius: height / 2
        topRightRadius: Theme.radius.xs / 2 + 1
        bottomRightRadius: Theme.radius.xs / 2 + 1
        color: Theme.color.primary
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: root.handleX + root.handleWidth / 2 + root.gap
        width: Math.max(0, root.width - x)
        height: root.trackHeight
        topRightRadius: height / 2
        bottomRightRadius: height / 2
        topLeftRadius: Theme.radius.xs / 2 + 1
        bottomLeftRadius: Theme.radius.xs / 2 + 1
        color: Theme.color.secondaryContainer
    }

    Rectangle {
        x: root.handleX - width / 2
        width: root.handleWidth
        height: root.height
        radius: width / 2
        color: Theme.color.primary

        Behavior on width {
            Anim {
                duration: Theme.anim.fast
            }
        }
    }

    Icon {
        visible: root.icon !== ""
        x: (root.iconSpace - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        fill: 1
        size: Theme.size.icon
        color: active.width > root.iconSpace ? Theme.color.fgPrimary : Theme.color.fgSecondaryContainer
    }

    Label {
        visible: root.showValue
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacing.medium
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(root.visualRatio * 100)
        font.pixelSize: Theme.font.small
        font.weight: Font.DemiBold
        font.features: ({
                "tnum": 1
            })
        color: root.handleX > root.width - 44 ? Theme.color.fgPrimary : Theme.color.fgSecondaryContainer
        opacity: root.handleX > root.width - 44 && root.handleX < root.width - 8 ? 0 : 1
    }

    MouseArea {
        id: area

        property real dragRatio: 0

        function update(x: real): void {
            dragRatio = Math.max(0, Math.min(1, (x - root.handleWidth / 2) / (width - root.handleWidth)));
            root.moved(root.from + dragRatio * (root.to - root.from));
        }

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: e => update(e.x)
        onPositionChanged: e => update(e.x)
        onWheel: e => {
            const step = (root.to - root.from) * 0.05;
            root.moved(Math.max(root.from, Math.min(root.to, root.value + (e.angleDelta.y > 0 ? step : -step))));
        }
    }
}
