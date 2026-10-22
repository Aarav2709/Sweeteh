import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components

// label on the left and a control on the right
RowLayout {
    id: root

    property string label
    property string hint
    default property alias control: slot.data

    Layout.fillWidth: true
    Layout.minimumHeight: 48
    spacing: Theme.spacing.large

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.spacing.small
        spacing: 0

        Label {
            Layout.fillWidth: true
            text: root.label
            font.weight: Font.Medium
        }

        Label {
            Layout.fillWidth: true
            visible: root.hint !== ""
            text: root.hint
            wrapMode: Text.Wrap
            font.pixelSize: Theme.font.small
            color: Theme.color.inkMeta
        }
    }

    RowLayout {
        id: slot

        Layout.rightMargin: Theme.spacing.small
    }
}
