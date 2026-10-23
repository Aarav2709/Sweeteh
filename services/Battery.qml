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
    // what is flowing in or out right now, in watts
    readonly property real watts: Math.abs(device?.changeRate ?? 0)
    readonly property bool saver: profile === PowerProfile.PowerSaver
    readonly property bool low: available && !plugged && percent <= Config.options.power.lowBattery
    readonly property string icon: charging ? "battery_charging_full" : percent > 90 ? "battery_full" : "battery_" + Math.max(0, Math.min(6, Math.floor(level * 7))) + "_bar"
    // watts sampled on battery over the last ten minutes
    property var drain: []
    readonly property real avgWatts: drain.length > 0 ? drain.reduce((a, b) => a + b, 0) / drain.length : 0
    readonly property string timeText: {
        const energy = device?.energy ?? 0;
        const s = charging ? device?.timeToFull : Config.options.power.smartTime && drain.length >= 3 && energy > 0 && avgWatts > 0.3 ? energy / avgWatts * 3600 : device?.timeToEmpty;
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
    // battery saver switched on by the low battery step, undone by the charger
    property bool autoSaver: false
    property int savedProfile: PowerProfile.Balanced

    signal dropped(bool critical)

    function check(): void {
        const p = Config.options.power;
        const next = !available || plugged ? 0 : percent <= p.criticalBattery ? 2 : percent <= p.lowBattery ? 1 : 0;
        if (next > 0 && stage === 0 && p.autoSaver && profile !== PowerProfile.PowerSaver) {
            savedProfile = profile;
            autoSaver = true;
            setProfile(PowerProfile.PowerSaver);
        } else if (plugged && autoSaver) {
            autoSaver = false;
            setProfile(savedProfile);
        }
        if (next > stage)
            dropped(next === 2);
        stage = next;
    }

    onPercentChanged: check()
    onPluggedChanged: {
        drain = [];
        check();
    }
    onAvailableChanged: check()

    Timer {
        running: root.available && !root.plugged
        repeat: true
        triggeredOnStart: true
        interval: 30000
        onTriggered: {
            if (root.watts > 0.3)
                root.drain = root.drain.concat([root.watts]).slice(-20);
        }
    }
}
