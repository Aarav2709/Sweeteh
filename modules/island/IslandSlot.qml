import QtQuick
import qs.theme
import qs.components

// content that fades and scales in when its state is active
Item {
    id: root

    property bool shown: false
    default property alias contents: holder.data

    anchors.centerIn: parent
    implicitWidth: holder.childrenRect.width
    implicitHeight: holder.childrenRect.height
    width: implicitWidth
    height: implicitHeight
    visible: opacity > 0
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.9
    enabled: shown

    Behavior on opacity {
        Anim {
            duration: root.shown ? Theme.anim.slow : Theme.anim.fast
        }
    }

    Behavior on scale {
        Anim {
            duration: Theme.anim.slow
            easing.bezierCurve: Theme.anim.decel
        }
    }

    Item {
        id: holder

        anchors.fill: parent
    }
}
