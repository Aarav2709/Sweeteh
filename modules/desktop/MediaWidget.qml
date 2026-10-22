import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.components

// now playing tile washed in its cover art
DeskCard {
    span: "wide"

    ClippingRectangle {
        anchors.fill: parent
        anchors.margins: Theme.depth.rim
        radius: parent.radius - Theme.depth.rim
        color: "transparent"

        Image {
            anchors.fill: parent
            visible: Media.art !== ""
            source: Media.art
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize: Qt.size(48, 48)
            opacity: 0.45
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1
                blurMax: 48
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.large
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.medium

            ClippingRectangle {
                implicitWidth: 48
                implicitHeight: 48
                radius: Theme.radius.medium
                color: Theme.color.secondaryContainer

                Image {
                    anchors.fill: parent
                    source: Media.art
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(96, 96)
                }

                Icon {
                    anchors.centerIn: parent
                    visible: Media.art === ""
                    name: "music_note"
                    color: Theme.color.fgSecondaryContainer
                }
            }

            Label {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                horizontalAlignment: Text.AlignRight
                text: Media.artist
                font.pixelSize: Theme.font.small
                font.weight: Font.DemiBold
                color: Theme.color.inkMeta
            }
        }

        Item {
            Layout.fillHeight: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.small

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Label {
                    Layout.fillWidth: true
                    text: Media.title
                    font.pixelSize: Theme.font.title
                    font.weight: Font.DemiBold
                }

                Label {
                    text: !Media.active ? "Play something to see it here." : Media.playing ? "Playing" : "Paused"
                    font.pixelSize: Theme.font.small
                    color: Theme.color.inkMeta
                }
            }

            IconButton {
                visible: Media.active
                icon: Media.playing ? "pause" : "play_arrow"
                checked: true
                onClicked: Media.toggle()
            }
        }
    }
}
