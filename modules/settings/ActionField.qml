import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.components

// action text with suggestions from the known actions, arrows and enter pick one
ColumnLayout {
    id: root

    property alias text: field.text
    readonly property var matches: Keybinds.actions.filter(a => a.includes(field.text.trim()) && a !== field.text)

    signal committed(string value)

    spacing: Theme.spacing.xxs

    Field {
        id: field

        Layout.fillWidth: true
        implicitHeight: 36
        implicitWidth: 160
        color: Theme.color.layer2
        placeholder: "Action"
        onAccepted: {
            if (field.input.activeFocus && list.currentIndex >= 0 && root.matches[list.currentIndex])
                text = root.matches[list.currentIndex];
            root.committed(text);
            field.input.focus = false;
        }
        input.onActiveFocusChanged: {
            list.currentIndex = -1;
            if (!input.activeFocus)
                root.committed(text);
        }
        input.Keys.onDownPressed: list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1)
        input.Keys.onUpPressed: list.currentIndex = Math.max(-1, list.currentIndex - 1)
    }

    Rectangle {
        Layout.fillWidth: true
        visible: field.input.activeFocus && list.count > 0
        implicitHeight: Math.min(list.contentHeight + Theme.spacing.xs * 2, 200)
        color: Theme.color.layer3
        radius: Theme.radius.medium

        ListView {
            id: list

            anchors.fill: parent
            anchors.margins: Theme.spacing.xs
            clip: true
            currentIndex: -1
            model: root.matches
            highlightMoveDuration: 0
            highlight: Rectangle {
                radius: Theme.radius.small
                color: Theme.color.secondaryContainer
            }

            delegate: Label {
                required property string modelData

                width: list.width
                height: 28
                leftPadding: Theme.spacing.small
                text: modelData
                font.pixelSize: Theme.font.small

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: {
                        field.text = parent.modelData;
                        root.committed(parent.modelData);
                    }
                }
            }
        }
    }
}
