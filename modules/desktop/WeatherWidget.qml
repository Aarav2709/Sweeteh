import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.components

// current temperature and sky
DeskCard {
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.large
        spacing: 0

        RowLayout {
            Layout.fillWidth: true

            Icon {
                Layout.alignment: Qt.AlignTop
                name: Weather.icon
                fill: 1
                size: 30
                color: Theme.wall.primary
            }

            Label {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                horizontalAlignment: Text.AlignRight
                text: Weather.place
                font.pixelSize: Theme.font.small
                font.weight: Font.DemiBold
                color: Theme.wall.inkMeta
            }
        }

        Item {
            Layout.fillHeight: true
        }

        Label {
            text: Weather.ready ? Weather.temp : "No data"
            font.pixelSize: Weather.ready ? Theme.font.display * 0.85 : Theme.font.body
            font.weight: Font.DemiBold
        }

        Label {
            Layout.fillWidth: true
            text: Weather.condition
            font.pixelSize: Theme.font.small
            color: Theme.wall.inkMeta
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Weather.refresh()
    }
}
