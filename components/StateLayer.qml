import QtQuick
import qs.theme

// hover and press feedback, fills its parent
MouseArea {
    id: root

    property color tint: Theme.color.ink
    property real radius: typeof parent?.radius === "number" ? parent.radius : 0
    property bool disabled: false

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
    enabled: !disabled

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.tint
        opacity: root.pressed ? Theme.state.press : root.containsMouse ? Theme.state.hover : 0

        Behavior on opacity {
            Anim {
                duration: Theme.anim.fast
            }
        }
    }
}
