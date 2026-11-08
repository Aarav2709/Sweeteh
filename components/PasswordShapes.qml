import QtQuick
import qs.theme

// the password as a row of little filled shapes in the wallpaper's hues, one per key
// the shape follows the position, never the letter, so nothing about the password shows
Item {
    id: root

    property int count: 0
    property real size: 18
    readonly property var glyphs: ["favorite", "star", "hexagon", "circle", "spa", "change_history", "cookie", "pentagon", "eco", "diamond", "square", "brightness_7"]
    readonly property var tints: [Theme.color.primary, Theme.color.tertiary, Theme.color.secondary]

    implicitHeight: size
    clip: true

    // the model grows and shrinks one at a time, so only the new shape animates in
    onCountChanged: {
        while (shapes.count < count)
            shapes.append({ slot: shapes.count });
        while (shapes.count > count)
            shapes.remove(shapes.count - 1);
    }

    ListModel {
        id: shapes
    }

    Row {
        id: row

        anchors.verticalCenter: parent.verticalCenter
        // the newest shape stays in view, older ones slide off the left
        x: Math.min(0, root.width - width)
        spacing: Math.round(root.size * 0.35)

        Behavior on x {
            enabled: Theme.anim.speed > 0

            Glide {}
        }

        Repeater {
            model: shapes

            Icon {
                required property int slot

                name: root.glyphs[(slot * 5 + 2) % root.glyphs.length]
                fill: 1
                size: root.size
                color: root.tints[slot % root.tints.length]
                transformOrigin: Item.Center

                NumberAnimation on scale {
                    from: 0.3
                    to: 1
                    duration: Theme.anim.fast
                    easing.type: Easing.OutCubic
                }

                NumberAnimation on opacity {
                    from: 0
                    to: 1
                    duration: Theme.anim.fast
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
