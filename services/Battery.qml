pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// battery and power profile from upower
Singleton {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool available: device?.isLaptopBattery ?? false
    readonly property real level: device?.percentage ?? 0
    readonly property bool charging: device?.state === UPowerDeviceState.Charging || device?.state === UPowerDeviceState.FullyCharged
    readonly property int percent: Math.round(level * 100)
    readonly property string icon: charging ? "battery_charging_full" : percent > 90 ? "battery_full" : "battery_" + Math.max(0, Math.min(6, Math.floor(level * 7))) + "_bar"
    readonly property string timeText: {
        const s = charging ? device?.timeToFull : device?.timeToEmpty;
        if (!s)
            return "";
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        return (h > 0 ? h + " h " : "") + m + " min";
    }
    readonly property int profile: PowerProfiles.profile

    function setProfile(p: int): void {
        PowerProfiles.profile = p;
    }

    property bool warned: false

    onPercentChanged: {
        if (!available || charging)
            warned = false;
        else if (percent <= 10 && !warned) {
            warned = true;
            Actions.say("battery_alert", "Battery is low, plug in soon.");
        }
    }
}
