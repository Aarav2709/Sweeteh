import QtQuick
import qs.theme

// a filled glyph sitting in a material 3 shape, the baked look for icons that stand on their own
Item {
    id: root

    property string name
    property string shape: "cookie9"
    property real size: 30
    property color color: Theme.color.primary
    property color glyph: Theme.color.fgPrimary
    // the shape turns slowly behind a still glyph, only while something is showing
    property bool spin: false

    implicitWidth: size
    implicitHeight: size

    Blob {
        id: shape

        anchors.fill: parent
        size: root.size
        shape: root.shape
        color: root.color

        RotationAnimator on rotation {
            from: 0
            to: 360
            duration: 9000
            loops: Animation.Infinite
            running: root.spin && root.visible && Theme.anim.speed > 0
        }
    }

    Icon {
        anchors.centerIn: parent
        name: root.name
        fill: 1
        size: Math.round(root.size * 0.58)
        color: root.glyph
    }
}
