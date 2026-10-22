import QtQuick
import qs.theme

// rounded themed container
Rectangle {
    property bool outlined: false

    color: Theme.color.surfaceContainer
    radius: Theme.radius.medium
    border.width: outlined ? Theme.size.border : 0
    border.color: Theme.color.outlineVariant

    Behavior on color {
        ColorAnim {}
    }
}
