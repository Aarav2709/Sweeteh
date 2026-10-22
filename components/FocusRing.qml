import QtQuick
import qs.theme

// outline that shows which control the keyboard is on
Rectangle {
    property Item target: parent
    // the item whose keyboard focus shows the ring, usually the target itself
    property bool shown: target?.activeFocus ?? false
    readonly property real gap: 3

    anchors.fill: target
    anchors.margins: -gap
    radius: (typeof target?.radius === "number" ? target.radius : 0) + gap
    color: "transparent"
    border.width: 2
    border.color: Theme.color.primary
    visible: shown
    z: 10
}
