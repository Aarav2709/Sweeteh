import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.components

// small player that opens while the resting island is hovered during music
RowLayout {
    id: root

    readonly property color tint: Media.hasAccent ? Media.accent : Theme.color.primary
    readonly property real progress: Math.min(1, Media.position / Math.max(1, Media.length))

    spacing: Theme.spacing.medium

    ClippingRectangle {
        implicitWidth: 48
        implicitHeight: 48
        radius: Theme.radius.small
        color: Theme.color.layer2

        Image {
            anchors.fill: parent
            source: Media.art
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize: Qt.size(96, 96)
        }
    }

    ColumnLayout {
        Layout.preferredWidth: 240
        spacing: Theme.spacing.xxs

        Label {
            Layout.fillWidth: true
            text: Media.title
            font.weight: Font.DemiBold
        }

        Label {
            Layout.fillWidth: true
            visible: text !== ""
            text: Media.artist
            font.pixelSize: Theme.font.small
            color: Theme.color.inkMeta
        }

        // click or drag along it to seek
        Item {
            Layout.fillWidth: true
            implicitHeight: 12
            visible: Media.length > 0

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: Theme.color.layer2

                Rectangle {
                    width: parent.width * root.progress
                    height: parent.height
                    radius: 2
                    color: root.tint
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPressed: e => Media.seek(Media.length * Math.max(0, Math.min(1, e.x / width)))
                onPositionChanged: e => {
                    if (pressed)
                        Media.seek(Media.length * Math.max(0, Math.min(1, e.x / width)));
                }
            }
        }
    }

    IconButton {
        icon: "skip_previous"
        size: 32
        onClicked: Media.previous()
    }

    IconButton {
        icon: Media.playing ? "pause" : "play_arrow"
        size: 36
        checked: true
        onClicked: Media.toggle()
    }

    IconButton {
        icon: "skip_next"
        size: 32
        onClicked: Media.next()
    }
}
