import QtQuick
import qs.theme

// single choice from a short list of options
Flow {
    id: root

    property var options: []
    property var labels: ({})
    property string current

    signal picked(string value)

    spacing: Theme.spacing.xs

    Repeater {
        model: root.options

        Rectangle {
            id: chip

            required property string modelData
            readonly property bool selected: root.current === modelData

            implicitWidth: row.implicitWidth + Theme.spacing.medium * 2
            implicitHeight: 32
            radius: Theme.radius.small
            color: selected ? Theme.color.secondaryContainer : "transparent"
            border.width: selected ? 0 : Theme.size.border
            border.color: Theme.color.outlineVariant

            Behavior on color {
                ColorAnim {}
            }

            Row {
                id: row

                anchors.centerIn: parent
                spacing: Theme.spacing.xs

                Icon {
                    visible: chip.selected
                    anchors.verticalCenter: parent.verticalCenter
                    name: "check"
                    size: Theme.font.large
                    weight: 600
                    color: Theme.color.fgSecondaryContainer
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.labels[chip.modelData] ?? Theme.humanize(chip.modelData)
                    font.pixelSize: Theme.font.small
                    font.weight: Font.DemiBold
                    color: chip.selected ? Theme.color.fgSecondaryContainer : Theme.color.inkMeta
                }
            }

            StateLayer {
                onClicked: root.picked(chip.modelData)
            }
        }
    }
}
