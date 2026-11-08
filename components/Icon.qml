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

    // sharp at small sizes: outlined glyphs are hinted onto the pixel grid, filled ones drawn as curves
    // so they stay smooth while they scale, and a glyph gets bolder as it fills like material 3 asks
    Text {
        anchors.fill: parent
        text: root.name
        color: root.color
        renderType: root.fill > 0 ? Text.CurveRendering : Text.NativeRendering
        font.family: Theme.font.icon
        font.pixelSize: Math.round(root.size)
        font.hintingPreference: Font.PreferFullHinting
        font.variableAxes: ({
                "FILL": Math.round(root.fill * 100) / 100,
                "wght": root.weight + Math.max(0, 600 - root.weight) * root.fill,
                "opsz": Math.max(20, Math.min(48, Math.round(root.size))),
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
