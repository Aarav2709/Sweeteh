import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components

// titled group of option rows on a raised backlit card
ColumnLayout {
    id: root

    property string title
    property string subtitle
    property string icon
    default property alias rows: body.data

    spacing: Theme.spacing.small

    RowLayout {
        Layout.topMargin: Theme.spacing.large
        Layout.bottomMargin: Theme.spacing.xs
        spacing: Theme.spacing.medium

        Rectangle {
            visible: root.icon !== ""
            implicitWidth: 34
            implicitHeight: 34
            radius: Theme.radius.medium
            color: Theme.color.layer2
            border.width: Theme.depth.rim
            border.color: Theme.color.depthRim

            Depth {}

            Icon {
                anchors.centerIn: parent
                name: root.icon
                fill: 1
                color: Theme.color.backlight
            }
        }

        ColumnLayout {
            spacing: 0

            Label {
                text: root.title
                font.pixelSize: Theme.font.title
                font.weight: Font.DemiBold
            }

            Label {
                Layout.fillWidth: true
                visible: root.subtitle !== ""
                text: root.subtitle
                wrapMode: Text.Wrap
                font.pixelSize: Theme.font.small
                color: Theme.color.inkMeta
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: body.implicitHeight + Theme.spacing.small * 2
        Layout.bottomMargin: Theme.depth.offset
        color: Theme.color.layer1
        radius: Theme.radius.large
        border.width: Theme.depth.rim
        border.color: Theme.color.depthRim

        Depth {}

        ColumnLayout {
            id: body

            anchors.fill: parent
            anchors.margins: Theme.spacing.small
            anchors.leftMargin: Theme.spacing.medium
            anchors.rightMargin: Theme.spacing.medium
            spacing: Theme.spacing.xxs
        }
    }
}
