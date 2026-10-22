import QtQuick
import qs.theme

// round icon button, checked fills it and squares it off, pressing tightens the shape
Rectangle {
    id: root

    property string icon
    property bool checked: false
    property bool filled: false
    property bool disabled: false
    property real size: Theme.size.button
    property color foreground: checked ? Theme.color.fgPrimary : filled ? Theme.color.ink : Theme.color.inkMeta
    property color background: checked ? Theme.color.primary : filled ? Theme.color.layer2 : "transparent"

    signal clicked
    signal rightClicked

    implicitWidth: size
    implicitHeight: size
    radius: layer.pressed ? Theme.radius.small : checked ? Theme.radius.medium : size / 2
    color: background
    opacity: disabled ? Theme.state.disabled : 1

    Icon {
        anchors.centerIn: parent
        name: root.icon
        color: root.foreground
        fill: root.checked ? 1 : 0
        size: Math.round(root.size * 0.56)
    }

    activeFocusOnTab: !disabled
    Keys.onPressed: e => {
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) {
            root.clicked();
            e.accepted = true;
        }
    }

    FocusRing {}

    StateLayer {
        id: layer

        tint: root.foreground
        disabled: root.disabled
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: e => e.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }

    Behavior on radius {
        Anim {
            duration: Theme.anim.fast
        }
    }

    Behavior on color {
        ColorAnim {}
    }
}
