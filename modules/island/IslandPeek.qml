import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.theme
import qs.services
import qs.components

// small player that opens while the resting island is hovered during music
RowLayout {
    id: root

    readonly property color tint: Theme.color.primary
    readonly property real progress: Math.min(1, Media.position / Math.max(1, Media.length))

    spacing: Theme.spacing.medium

    // scrolling anywhere on the player seeks five seconds at a time
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: e => {
            if (Media.length > 0)
                Media.seek(Math.max(0, Math.min(Media.length, Media.position + (e.angleDelta.y > 0 ? 5 : -5))));
        }
    }

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

        // the line being sung, when lyrics are found
        Label {
            id: lyric

            Layout.fillWidth: true
            visible: Lyrics.enabled && Config.options.island.peekLyrics && Lyrics.current !== ""
            text: Lyrics.current
            font.pixelSize: Theme.font.small
            font.weight: Font.Medium
            color: root.tint

            Behavior on text {
                SequentialAnimation {
                    Anim {
                        target: lyric
                        property: "opacity"
                        to: 0
                        duration: Theme.anim.fast
                    }

                    PropertyAction {}

                    Anim {
                        target: lyric
                        property: "opacity"
                        to: 1
                        duration: Theme.anim.fast
                    }
                }
            }
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
