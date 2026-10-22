import QtQuick
import qs.theme
import qs.services
import qs.components

BarItem {
    id: root

    padding: 0
    active: Actions.isOpen("power")
    onClicked: Actions.toggle("power")

    Icon {
        name: "power_settings_new"
        weight: 600
        color: root.active ? root.tint : Theme.color.error
    }
}
