import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components

// titled group of option rows on a card
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
            color: Theme.color.secondaryContainer

            Icon {
                anchors.centerIn: parent
                name: root.icon
                fill: 1
                color: Theme.color.fgSecondaryContainer
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
        color: Theme.color.layer1
        radius: Theme.radius.large

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
