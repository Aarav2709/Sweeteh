import QtQuick
import qs.theme

// material switch, the knob grows and shows a check when on
Rectangle {
    id: root

    property bool checked: false
    property bool disabled: false

    signal toggled(bool value)

    implicitWidth: 52
    implicitHeight: 32
    radius: height / 2
    color: checked ? Theme.color.primary : Theme.color.layer3
    border.width: checked ? 0 : 2
    border.color: Theme.color.outline
    opacity: disabled ? Theme.state.disabled : 1

    Rectangle {
        id: knob

        property real d: area.pressed ? 28 : root.checked ? 24 : 16

        width: d
        height: d
        radius: d / 2
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - d - (root.height - d) / 2 : (root.height - d) / 2
        color: root.checked ? Theme.color.fgPrimary : Theme.color.outline

        Icon {
            anchors.centerIn: parent
            name: "check"
            size: 16
            weight: 600
            color: Theme.color.primary
            opacity: root.checked ? 1 : 0

            Behavior on opacity {
                Anim {
                    duration: Theme.anim.fast
                }
            }
        }

        Behavior on x {
            Anim {
                easing.bezierCurve: Theme.anim.spatial
            }
        }

        Behavior on d {
            Anim {
                duration: Theme.anim.fast
            }
        }

        Behavior on color {
            ColorAnim {}
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

    Behavior on color {
        ColorAnim {}
    }
}
