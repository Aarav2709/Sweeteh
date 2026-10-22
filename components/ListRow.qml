import QtQuick
import QtQuick.Layouts
import qs.theme

// list row with a leading badge, two lines of text and trailing slots
Rectangle {
    id: root

    property string icon
    property string title
    property string subtitle
    property bool selected: false
    property bool highlighted: false
    property color base: "transparent"
    property bool badge: true
    readonly property color foreground: selected ? Theme.color.fgSecondaryContainer : Theme.color.ink
    property alias leading: lead.data
    default property alias trailing: trail.data

    signal clicked
    signal rightClicked

    implicitHeight: subtitle !== "" ? 56 : 46
    radius: Theme.radius.medium
    color: selected ? Theme.color.secondaryContainer : highlighted ? Theme.color.layer2 : base

    Behavior on color {
        ColorAnim {
            duration: Theme.anim.fast
        }
    }

    activeFocusOnTab: true
    Keys.onPressed: e => {
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) {
            root.clicked();
            e.accepted = true;
        }
    }

    FocusRing {}

    StateLayer {
        tint: root.foreground
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: e => e.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing.small
        anchors.rightMargin: Theme.spacing.medium
        spacing: Theme.spacing.medium

        Item {
            id: lead

            implicitWidth: 36
            implicitHeight: 36

            Rectangle {
                anchors.fill: parent
                visible: root.icon !== ""
                radius: root.selected ? Theme.radius.medium : width / 2
                color: !root.badge ? "transparent" : root.selected ? Theme.color.primary : Theme.color.layer2

                Icon {
                    anchors.centerIn: parent
                    name: root.icon
                    fill: root.selected ? 1 : 0
                    color: root.selected && root.badge ? Theme.color.fgPrimary : Theme.color.inkMeta
                }

                Behavior on radius {
                    Anim {}
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Label {
                Layout.fillWidth: true
                text: root.title
                font.weight: Font.Medium
                color: root.foreground
            }

            Label {
                Layout.fillWidth: true
                visible: root.subtitle !== ""
                text: root.subtitle
                font.pixelSize: Theme.font.small
                color: root.selected ? Theme.color.fgSecondaryContainer : Theme.color.inkMeta
            }
        }

        Row {
            id: trail

            spacing: Theme.spacing.small
        }
    }
}
