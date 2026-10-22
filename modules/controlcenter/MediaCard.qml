import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.theme
import qs.services
import qs.components

// compact player card tinted by the cover art
ClippingRectangle {
    id: root

    implicitHeight: 72
    color: Theme.color.layer1
    radius: Theme.radius.large

    Image {
        anchors.fill: parent
        source: Media.art
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(64, 64)
        opacity: 0.22
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0.25
                color: Qt.alpha(Theme.color.layer1, 0.4)
            }

            GradientStop {
                position: 1
                color: Theme.color.layer1
            }
        }
    }

    StateLayer {
        onClicked: Actions.open("media")
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.small
        anchors.rightMargin: Theme.spacing.medium
        spacing: Theme.spacing.medium

        ClippingRectangle {
            implicitWidth: 56
            implicitHeight: 56
            radius: Theme.radius.medium
            color: Theme.color.secondaryContainer

            Icon {
                anchors.centerIn: parent
                visible: Media.art === ""
                name: "music_note"
                color: Theme.color.fgSecondaryContainer
            }

            Image {
                anchors.fill: parent
                source: Media.art
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(112, 112)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Label {
                Layout.fillWidth: true
                text: Media.title || "Unknown title"
                font.weight: Font.DemiBold
            }

            Label {
                Layout.fillWidth: true
                visible: text !== ""
                text: Media.artist
                font.pixelSize: Theme.font.small
                color: Theme.color.inkMeta
            }
        }

        IconButton {
            size: 32
            icon: "skip_previous"
            onClicked: Media.previous()
        }

        IconButton {
            icon: Media.playing ? "pause" : "play_arrow"
            checked: true
            onClicked: Media.toggle()
        }

        IconButton {
            size: 32
            icon: "skip_next"
            onClicked: Media.next()
        }
    }
}
