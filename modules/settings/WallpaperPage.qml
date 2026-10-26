import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.theme
import qs.services
import qs.components

ColumnLayout {
    spacing: Theme.spacing.small

    Label {
        text: "Wallpaper"
        font.pixelSize: Theme.font.headline
        font.weight: Font.DemiBold
    }

    ClippingRectangle {
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacing.medium
        Layout.preferredHeight: width * 0.4
        radius: Theme.radius.large
        color: Theme.color.surfaceContainerHigh

        Image {
            anchors.fill: parent
            source: Wallpapers.still ? Paths.url(Wallpapers.still) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 900
        }

        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.spacing.medium
            spacing: Theme.spacing.small

            Button {
                variant: "filled"
                icon: "wallpaper"
                text: "Pick"
                onClicked: Actions.open("wallpaper")
            }

            Button {
                icon: "shuffle"
                text: "Random"
                onClicked: Wallpapers.random()
            }
        }
    }

    Section {
        Layout.fillWidth: true
        title: "Options"
        icon: "wallpaper"

        AutoOption {
            key: "general.wallpaperDir"
        }

        AutoOption {
            key: "wallpaper.transition"
        }

        AutoOption {
            key: "wallpaper.duration"
        }

        AutoOption {
            key: "wallpaper.pauseWithWindows"
        }

        AutoOption {
            key: "wallpaper.path"
        }
    }
}
