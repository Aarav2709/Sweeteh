import QtQuick
import qs.theme
import qs.services
import qs.components

// status icons, scroll for volume and middle click to mute, the island opens the dashboard
BarItem {
    id: root

    clickable: false
    onScrolled: delta => Audio.setVolume(Audio.volume + delta * 0.05)
    onMiddleClicked: Audio.toggleMute()

    itemSpacing: Theme.spacing.xs + 2

    Icon {
        visible: Notifs.dnd
        name: "do_not_disturb_on"
        color: root.tint
    }

    Icon {
        visible: Audio.micMuted
        name: "mic_off"
        color: root.tint
    }

    Icon {
        visible: Session.caffeine
        name: "coffee"
        color: root.tint
    }

    Icon {
        name: Audio.icon
        color: root.tint
    }

    Icon {
        name: Network.icon
        color: root.tint
    }

    Icon {
        visible: BluetoothState.available
        name: BluetoothState.icon
        color: root.tint
    }

    Icon {
        visible: Battery.available
        name: Battery.icon
        color: Battery.percent <= 15 && !Battery.charging ? Theme.color.error : root.tint
    }

    Label {
        visible: Battery.available
        text: Battery.percent + "%"
        font.pixelSize: Theme.font.bar
        font.weight: Font.DemiBold
        color: root.tint
    }
}
