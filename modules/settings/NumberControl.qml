import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components

// stepper for a number option
RowLayout {
    id: root

    property real value
    property real step: 1
    property real minimum: 0
    property real maximum: 100000

    signal changed(real value)

    function nudge(d: real): void {
        const v = Math.round((value + d) * 1000) / 1000;
        changed(Math.max(minimum, Math.min(maximum, v)));
    }

    spacing: Theme.spacing.xs

    IconButton {
        icon: "remove"
        filled: true
        size: 32
        onClicked: root.nudge(-root.step)
    }

    Label {
        Layout.preferredWidth: 64
        horizontalAlignment: Text.AlignHCenter
        text: Number.isInteger(root.step) ? Math.round(root.value) : root.value.toFixed(2)
        font.weight: Font.DemiBold
    }

    IconButton {
        icon: "add"
        filled: true
        size: 32
        onClicked: root.nudge(root.step)
    }
}
