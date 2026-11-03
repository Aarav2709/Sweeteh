import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.components

// the music's levels as tall bars lit in the wallpaper's hue, resting low when nothing plays
DeskCard {
    id: root

    span: "wide"

    property var levels: [0, 0, 0, 0, 0]

    // cava's levels are sampled here a few times a second instead of on every frame it prints
    Timer {
        running: Cava.active && root.visible
        repeat: true
        interval: 90
        onTriggered: root.levels = Cava.values.slice(0, 5)
        onRunningChanged: {
            if (!running)
                root.levels = [0, 0, 0, 0, 0];
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.large
        spacing: Theme.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.xs

            Icon {
                name: "graphic_eq"
                size: 18
                color: Theme.wall.primary
            }

            Label {
                Layout.fillWidth: true
                text: Media.active ? Media.title : "Nothing playing"
                font.pixelSize: Theme.font.small
                font.weight: Font.DemiBold
                color: Theme.wall.inkMeta
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spacing.small

            Repeater {
                model: 5

                Item {
                    id: slot

                    required property int index

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(width, parent.height * (root.levels[slot.index] ?? 0))
                        radius: Math.min(width / 2, Theme.radius.medium)
                        color: Theme.wall.primary
                        opacity: 0.35 + 0.65 * (root.levels[slot.index] ?? 0)

                        Behavior on height {
                            NumberAnimation {
                                duration: 90
                            }
                        }
                    }
                }
            }
        }
    }
}
