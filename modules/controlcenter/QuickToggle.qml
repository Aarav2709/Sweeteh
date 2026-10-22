import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components

// tile toggle with a title, subtitle and optional detail button
// off tiles are round pills, on tiles fill with the accent and square off
Rectangle {
    id: root

    property string icon
    property string title
    property string subtitle
    property bool checked: false
    property bool hasDetail: false
    readonly property color foreground: checked ? Theme.color.fgPrimary : Theme.color.ink

    signal toggled
    signal detail

    implicitHeight: Theme.size.toggle
    radius: layer.pressed ? Theme.radius.medium : checked ? Theme.radius.large : height / 2
    color: checked ? Theme.color.primary : Theme.color.layer1

    Behavior on color {
        ColorAnim {}
    }

    Behavior on radius {
        Anim {
            duration: Theme.anim.fast
        }
    }

    activeFocusOnTab: true
    Keys.onPressed: e => {
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) {
            root.toggled();
            e.accepted = true;
        } else if (e.key === Qt.Key_Right && root.hasDetail) {
            root.detail();
            e.accepted = true;
        }
    }

    FocusRing {}

    StateLayer {
        id: layer

        tint: root.foreground
        onClicked: root.toggled()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing.small
        anchors.rightMargin: root.hasDetail ? Theme.spacing.xs : Theme.spacing.medium
        spacing: Theme.spacing.small

        Rectangle {
            implicitWidth: 40
            implicitHeight: 40
            radius: root.checked ? Theme.radius.medium : width / 2
            color: root.checked ? Qt.alpha(Theme.color.fgPrimary, 0.14) : Theme.color.layer2

            Icon {
                anchors.centerIn: parent
                name: root.icon
                fill: root.checked ? 1 : 0
                color: root.foreground
            }

            Behavior on radius {
                Anim {}
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: -1

            Label {
                Layout.fillWidth: true
                text: root.title
                font.weight: Font.DemiBold
                color: root.foreground
            }

            Label {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.subtitle
                font.pixelSize: Theme.font.small
                color: root.checked ? Qt.alpha(Theme.color.fgPrimary, 0.8) : Theme.color.inkMeta
            }
        }

        IconButton {
            visible: root.hasDetail
            size: 30
            icon: "chevron_right"
            foreground: root.foreground
            onClicked: root.detail()
        }
    }
}
