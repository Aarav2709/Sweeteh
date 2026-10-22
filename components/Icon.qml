import QtQuick
import qs.theme

// material symbols glyph by ligature name, in a square box so it centers the same everywhere
Item {
    id: root

    property string name
    property real fill: 0
    property int weight: 400
    property real size: Theme.size.icon
    property color color: Theme.color.ink

    implicitWidth: Math.round(size)
    implicitHeight: Math.round(size)

    Text {
        anchors.centerIn: parent
        text: root.name
        color: root.color
        font.family: Theme.font.icon
        font.pixelSize: root.size
        font.variableAxes: ({
                "FILL": root.fill,
                "wght": root.weight,
                "opsz": Math.max(20, Math.min(48, root.size)),
                "GRAD": 0
            })
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Behavior on fill {
        Anim {
            duration: Theme.anim.fast
        }
    }

    Behavior on color {
        ColorAnim {}
    }
}
