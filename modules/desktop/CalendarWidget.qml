import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.components

// today in big type with the week beside it
DeskCard {
    id: root

    readonly property int weekday: (Time.now.getDay() + 6) % 7

    span: "wide"

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.large
        spacing: Theme.spacing.large

        ColumnLayout {
            Layout.fillHeight: true
            spacing: 0

            Icon {
                name: "calendar_month"
                size: 26
                color: Theme.wall.primary
            }

            Item {
                Layout.fillHeight: true
            }

            Label {
                text: Time.now.getDate()
                font.pixelSize: Theme.font.display
                font.weight: Font.DemiBold
            }

            Label {
                text: Qt.formatDate(Time.now, "dddd")
                font.pixelSize: Theme.font.small
                color: Theme.wall.inkMeta
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spacing.small

            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: Qt.formatDate(Time.now, "MMMM")
                font.pixelSize: Theme.font.small
                font.weight: Font.DemiBold
                color: Theme.wall.inkMeta
            }

            Item {
                Layout.fillHeight: true
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 7
                rowSpacing: Theme.spacing.xs
                columnSpacing: 0

                Repeater {
                    model: ["M", "T", "W", "T", "F", "S", "S"]

                    Label {
                        required property string modelData
                        required property int index

                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        font.pixelSize: Theme.font.tiny
                        font.weight: Font.DemiBold
                        color: index === root.weekday ? Theme.wall.primary : Theme.wall.inkFaint
                    }
                }

                Repeater {
                    model: 7

                    Item {
                        id: day

                        required property int index
                        readonly property date date: new Date(Time.now.getFullYear(), Time.now.getMonth(), Time.now.getDate() - root.weekday + index)
                        readonly property bool today: index === root.weekday

                        Layout.fillWidth: true
                        implicitHeight: 24

                        Rectangle {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            radius: 12
                            visible: day.today
                            color: Theme.wall.primary
                        }

                        Label {
                            anchors.centerIn: parent
                            text: day.date.getDate()
                            font.pixelSize: Theme.font.small
                            font.weight: day.today ? Font.DemiBold : Font.Medium
                            color: day.today ? Theme.wall.fgPrimary : Theme.wall.ink
                        }
                    }
                }
            }
        }
    }
}
