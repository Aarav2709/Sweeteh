import QtQuick
import qs.theme
import qs.components

// raised tile on the desk, small is square and wide spans two smalls
Rectangle {
    id: root

    property string span: "small"
    readonly property int unit: 150
    readonly property int gutter: Theme.spacing.large

    implicitWidth: span === "wide" ? unit * 2 + gutter : unit
    implicitHeight: span === "tall" ? unit * 2 + gutter : unit
    radius: Theme.radius.xl
    color: Theme.wallpaperSurface
    border.width: Theme.depth.rim
    border.color: Theme.wall.depthRim

    Depth {
        color: Theme.wall.depthShadow
    }
}
