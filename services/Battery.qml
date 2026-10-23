pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.config

// battery and power profile from upower
Singleton {
    id: root

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property bool available: device?.isLaptopBattery ?? false
    readonly property real level: device?.percentage ?? 0
    // the charger itself, a full or held battery still counts as plugged
    readonly property bool plugged: !UPower.onBattery
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

    // 0 fine, 1 low, 2 critical, only rises while unplugged so each step warns once
    property int stage: 0

    signal dropped(bool critical)

    function check(): void {
        const p = Config.options.power;
        const next = !available || plugged ? 0 : percent <= p.criticalBattery ? 2 : percent <= p.lowBattery ? 1 : 0;
        if (next > stage)
            dropped(next === 2);
        stage = next;
    }

    onPercentChanged: check()
    onPluggedChanged: check()
    onAvailableChanged: check()
}
