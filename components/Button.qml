import QtQuick
import QtQuick.Layouts
import qs.theme

// text button with optional icon, the shape tightens while pressed
// variants are filled, tonal, neutral and text
Rectangle {
    id: root

    property string text
    property string icon
    property string variant: "tonal"
    property bool disabled: false
    readonly property color foreground: variant === "filled" ? Theme.color.fgPrimary : variant === "tonal" ? Theme.color.fgSecondaryContainer : variant === "neutral" ? Theme.color.ink : Theme.color.primary

    signal clicked

    implicitHeight: Theme.size.button
    implicitWidth: row.implicitWidth + (variant === "text" ? Theme.spacing.medium : Theme.spacing.large) * 2
    radius: layer.pressed ? Theme.radius.small : height / 2
    color: variant === "filled" ? Theme.color.primary : variant === "tonal" ? Theme.color.secondaryContainer : variant === "neutral" ? Theme.color.layer2 : "transparent"
    opacity: disabled ? Theme.state.disabled : 1

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Theme.spacing.small

        Icon {
            visible: root.icon !== ""
            name: root.icon
            color: root.foreground
            size: Theme.size.icon
        }

        Label {
            text: root.text
            color: root.foreground
            font.weight: Font.DemiBold
        }
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
        onClicked: root.clicked()
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
