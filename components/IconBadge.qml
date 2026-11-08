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

    implicitWidth: size
    implicitHeight: size

    Blob {
        anchors.fill: parent
        size: root.size
        shape: root.shape
        color: root.color
    }

    Icon {
        anchors.centerIn: parent
        name: root.name
        fill: 1
        size: Math.round(root.size * 0.58)
        color: root.glyph
    }
}
