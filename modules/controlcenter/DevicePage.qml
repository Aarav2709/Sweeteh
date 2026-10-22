import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components

// header with back button and a list of rows
ColumnLayout {
    id: root

    property string title
    property string icon
    property bool on: true
    property alias model: list.model
    property alias delegate: list.delegate
    property string empty: "Nothing found."
    property bool busy: false

    signal back
    signal switched(bool on)

    spacing: Theme.spacing.medium

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing.small

        IconButton {
            icon: "arrow_back"
            filled: true
            onClicked: root.back()
        }

        Label {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacing.xs
            text: root.title
            font.pixelSize: Theme.font.title
            font.weight: Font.DemiBold
        }

        Toggle {
            checked: root.on
            onToggled: v => root.switched(v)
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Theme.radius.large
        color: Theme.color.layer1

        ListView {
            id: list

            anchors.fill: parent
            anchors.margins: Theme.spacing.xs
            clip: true
            spacing: Theme.spacing.xxs
        }

        Column {
            anchors.centerIn: parent
            visible: list.count === 0
            spacing: Theme.spacing.small

            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: root.icon
                size: Theme.size.iconLarge
                color: Theme.color.inkFaint
            }

            Label {
                text: root.empty
                color: Theme.color.inkMeta
            }
        }
    }
}
