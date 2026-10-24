import QtQuick
import qs.theme
import qs.services
import qs.components

// analog dial with twelve ticks
DeskCard {
    id: root

    readonly property real minutes: Time.now.getMinutes()
    readonly property real hours: Time.now.getHours() % 12 + minutes / 60

    Repeater {
        model: 12

        Item {
            required property int index

            anchors.centerIn: parent
            width: parent.width - Theme.spacing.large * 2
            height: width
            rotation: index * 30

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: index % 3 === 0 ? 3 : 2
                height: index % 3 === 0 ? 10 : 6
                radius: width / 2
                color: index % 3 === 0 ? Theme.wall.ink : Theme.wall.inkFaint
            }
        }
    }

    Hand {
        length: 0.26
        thickness: 5
        angle: root.hours * 30
        color: Theme.wall.ink
    }

    Hand {
        length: 0.38
        thickness: 3
        angle: root.minutes * 6
        color: Theme.wall.primary
    }

    Rectangle {
        anchors.centerIn: parent
        width: 9
        height: 9
        radius: 4.5
        color: Theme.wall.primary
        border.width: 2
        border.color: Theme.wallpaperSurface
    }

    component Hand: Item {
        property real length
        property real thickness
        property real angle
        property color color

        anchors.centerIn: parent
        width: root.width
        height: root.height
        rotation: angle

        Rectangle {
            x: (parent.width - width) / 2
            y: parent.height / 2 - height + width / 2
            width: parent.thickness
            height: parent.width * parent.length
            radius: width / 2
            color: parent.color
        }

        Behavior on rotation {
            Anim {
                easing.bezierCurve: Theme.anim.spatial
            }
        }
    }
}
