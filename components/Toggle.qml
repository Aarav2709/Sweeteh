import QtQuick
import qs.theme

// backlit switch, a keycap slides along a sunken track that lights up underneath when on
Rectangle {
    id: root

    property bool checked: false
    property bool disabled: false

    signal toggled(bool value)

    implicitWidth: 54
    implicitHeight: 30
    radius: height / 2
    opacity: disabled ? Theme.state.disabled : 1
    // the track is sunk into the surface, its light comes up from below when on
    gradient: Gradient {
        GradientStop {
            position: 0
            color: Theme.color.depthShadow
        }

        GradientStop {
            position: 1
            color: Theme.mix(Theme.color.layer3, Theme.color.backlight, root.lit)
        }
    }
    border.width: 1
    border.color: Qt.alpha(root.checked ? Theme.color.backlight : Theme.color.outlineVariant, 0.6)

    property real lit: checked ? 1 : 0

    Behavior on lit {
        Anim {}
    }

    // the keycap, it squashes while held and lands with a bounce
    Rectangle {
        id: knob

        readonly property real d: root.height - 6

        width: area.pressed ? d + 6 : d
        height: d
        radius: d / 2
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -1
        x: root.checked ? root.width - width - 3 : 3
        color: Theme.mix(Theme.color.layer2, Theme.color.glint, root.lit * 0.85)
        border.width: Theme.depth.rim
        border.color: Theme.color.depthRim

        Rectangle {
            z: -1
            y: 2
            width: parent.width
            height: parent.height
            radius: parent.radius
            color: Theme.color.depthShadow
        }

        Behavior on x {
            enabled: Theme.anim.speed > 0

            Spring {}
        }

        Behavior on width {
            Anim {
                duration: Theme.anim.fast
            }
        }
    }

    activeFocusOnTab: !disabled
    Keys.onPressed: e => {
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) {
            root.toggled(!root.checked);
            e.accepted = true;
        }
    }

    FocusRing {}

    MouseArea {
        id: area

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: !root.disabled
        onClicked: root.toggled(!root.checked)
    }
}
