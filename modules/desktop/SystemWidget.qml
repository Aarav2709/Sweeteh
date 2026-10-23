import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.components

// processor and memory load at a glance
DeskCard {
    Component.onCompleted: System.watchers++
    Component.onDestruction: System.watchers--

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.large
        spacing: Theme.spacing.small

        Icon {
            name: "monitoring"
            size: 26
            color: Theme.wall.primary
        }

        Item {
            Layout.fillHeight: true
        }

        Repeater {
            model: [
                {
                    label: "CPU",
                    value: System.cpu
                },
                {
                    label: "RAM",
                    value: System.memRatio
                }
            ]

            ColumnLayout {
                required property var modelData

                Layout.fillWidth: true
                spacing: Theme.spacing.xxs

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        Layout.fillWidth: true
                        text: modelData.label
                        font.pixelSize: Theme.font.small
                        font.weight: Font.DemiBold
                        color: Theme.wall.inkMeta
                    }

                    Label {
                        text: Math.round(modelData.value * 100) + "%"
                        font.pixelSize: Theme.font.small
                        font.weight: Font.DemiBold
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 6
                    radius: 3
                    color: Theme.wall.layer3

                    Rectangle {
                        width: parent.width * Math.min(1, modelData.value)
                        height: parent.height
                        radius: 3
                        color: Theme.wall.primary

                        Behavior on width {
                            Anim {}
                        }
                    }
                }
            }
        }
    }
}
