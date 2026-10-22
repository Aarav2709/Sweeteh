import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.config
import qs.theme
import qs.services

// grid of quick toggles
GridLayout {
    id: root

    signal page(string name)

    columns: 2
    rowSpacing: Theme.spacing.small
    columnSpacing: Theme.spacing.small

    QuickToggle {
        Layout.fillWidth: true
        icon: Network.icon
        title: "Wifi"
        subtitle: Network.wired ? "Ethernet" : Network.wifiEnabled ? (Network.name || "Not connected") : "Off"
        checked: Network.wifiEnabled
        hasDetail: true
        onToggled: Network.setWifi(!Network.wifiEnabled)
        onDetail: root.page("network")
    }

    QuickToggle {
        Layout.fillWidth: true
        icon: BluetoothState.icon
        title: "Bluetooth"
        subtitle: BluetoothState.starting ? "Starting" : !BluetoothState.available ? "Tap to start" : !BluetoothState.enabled ? "Off" : BluetoothState.connectedDevices.length > 0 ? BluetoothState.connectedDevices[0].name : "On"
        checked: BluetoothState.enabled
        hasDetail: true
        onToggled: BluetoothState.setEnabled(!BluetoothState.enabled)
        onDetail: root.page("bluetooth")
    }

    QuickToggle {
        Layout.fillWidth: true
        icon: "do_not_disturb_on"
        title: "Do not disturb"
        subtitle: Notifs.dnd ? "On" : "Off"
        checked: Notifs.dnd
        onToggled: Notifs.setDnd(!Config.options.notifications.dnd)
    }

    QuickToggle {
        Layout.fillWidth: true
        icon: "coffee"
        title: "Caffeine"
        subtitle: Session.caffeine ? "Staying awake" : "Off"
        checked: Session.caffeine
        onToggled: Session.caffeine = !Session.caffeine
    }

    QuickToggle {
        Layout.fillWidth: true
        icon: Theme.dark ? "dark_mode" : "light_mode"
        title: "Dark theme"
        subtitle: Theme.dark ? "On" : "Off"
        checked: Theme.dark
        onToggled: Config.set("theme.dark", !Theme.dark)
    }

    QuickToggle {
        Layout.fillWidth: true
        icon: Audio.micIcon
        title: "Microphone"
        subtitle: Audio.micMuted ? "Muted" : "On"
        checked: !Audio.micMuted
        onToggled: Audio.toggleMic()
    }

    QuickToggle {
        Layout.fillWidth: true
        icon: Modes.mode.icon
        title: "Mode"
        subtitle: Modes.mode.name
        checked: true
        onToggled: Actions.open("modeswitcher")
    }

    QuickToggle {
        Layout.fillWidth: true
        icon: Battery.profile === PowerProfile.Performance ? "bolt" : Battery.profile === PowerProfile.PowerSaver ? "eco" : "balance"
        title: "Power"
        subtitle: Battery.profile === PowerProfile.Performance ? "Performance" : Battery.profile === PowerProfile.PowerSaver ? "Power saver" : "Balanced"
        checked: Battery.profile !== PowerProfile.Balanced
        onToggled: Battery.setProfile(Battery.profile === PowerProfile.Balanced ? PowerProfile.PowerSaver : Battery.profile === PowerProfile.PowerSaver ? PowerProfile.Performance : PowerProfile.Balanced)
    }
}
