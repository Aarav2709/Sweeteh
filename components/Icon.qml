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

    // drawn the way end-4 draws material symbols: native rendering without hinting, the fill rounded
    // to a tenth so the font is not remapped every frame, and the glyph turns semibold as it fills
    Text {
        anchors.centerIn: parent
        text: root.name
        color: root.color
        renderType: Text.NativeRendering
        font.family: Theme.font.icon
        font.pixelSize: root.size
        font.hintingPreference: Font.PreferNoHinting
        font.weight: root.weight + (Font.DemiBold - root.weight) * Math.round(root.fill * 10) / 10
        font.variableAxes: ({
                "FILL": Math.round(root.fill * 10) / 10,
                "opsz": Math.max(20, Math.min(48, root.size))
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
