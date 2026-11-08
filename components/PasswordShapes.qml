import QtQuick
import qs.theme

// the password as a row of material 3 shapes, one per key, the way end-4 draws it
// the shape follows the position, never the letter, so nothing about the password shows
// each one lands in the accent and settles into the text color
Item {
    id: root

    property int count: 0
    property real size: 18
    readonly property var shapes: ["clover", "pill", "softburst", "diamond", "flower", "pentagon", "cookie4"]

    implicitHeight: size
    clip: true

    // the model grows and shrinks one at a time, so only the new shape animates in
    onCountChanged: {
        while (keys.count < count)
            keys.append({ slot: keys.count });
        while (keys.count > count)
            keys.remove(keys.count - 1);
    }

    ListModel {
        id: keys
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        // the newest shape stays in view, older ones slide off the left
        x: Math.min(0, root.width - width)

        Behavior on x {
            enabled: Theme.anim.speed > 0

            Glide {}
        }

        Repeater {
            model: keys

            Item {
                id: key

                required property int slot

                implicitWidth: Math.round(root.size * 1.15)
                implicitHeight: root.size

                Blob {
                    id: blob

                    anchors.centerIn: parent
                    size: Math.round(root.size * 0.9)
                    shape: root.shapes[key.slot % root.shapes.length]
                    color: Theme.color.ink
                    opacity: 0
                    scale: 0.5

                    Component.onCompleted: appear.start()

                    ParallelAnimation {
                        id: appear

                        NumberAnimation {
                            target: blob
                            property: "opacity"
                            to: 1
                            duration: 60
                        }

                        NumberAnimation {
                            target: blob
                            property: "scale"
                            to: 1
                            duration: 220
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.anim.decel
                        }

                        ColorAnimation {
                            target: blob
                            property: "color"
                            from: Theme.color.primary
                            to: Theme.color.ink
                            duration: 1000
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }
}
