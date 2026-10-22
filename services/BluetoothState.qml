pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

// bluez adapter and devices
Singleton {
    id: root

    // only touch bluez once it is known to be on the bus
    property bool present: false
    readonly property BluetoothAdapter adapter: present ? Bluetooth.defaultAdapter : null
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property var devices: adapter ? adapter.devices.values.slice().sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired)) : []
    readonly property var connectedDevices: devices.filter(d => d.connected)
    readonly property string icon: !enabled ? "bluetooth_disabled" : connectedDevices.length > 0 ? "bluetooth_connected" : "bluetooth"

    property bool starting: false

    Process {
        id: probe

        running: true
        command: ["sh", "-c", "busctl --system --no-pager --acquired list | grep -q '^org.bluez '"]
        onExited: code => root.present = code === 0
    }

    // bluez is off on some installs, starting it asks for a password through the island
    Process {
        id: starter

        command: ["systemctl", "start", "bluetooth.service"]
        onExited: code => {
            root.starting = false;
            if (code === 0)
                probe.running = true;
            else
                Actions.say("bluetooth_disabled", "Bluetooth could not be started.");
        }
    }

    property string busy: ""

    // bluetoothctl pairs, trusts and connects in one go, trusting is what keeps a device from dropping right away
    function connect(device: var): void {
        const mac = device.address;
        busy = mac;
        // the radio has to be powered first, then unpaired devices pair before they are trusted
        const steps = ["rfkill unblock bluetooth 2>/dev/null; bluetoothctl power on >/dev/null"];
        if (!device.paired)
            steps.push(`bluetoothctl --timeout 25 pair ${mac}`);
        steps.push(`bluetoothctl trust ${mac}`, `bluetoothctl --timeout 15 connect ${mac}`);
        linker.command = ["sh", "-c", steps.join(" && ")];
        linker.running = true;
    }

    function disconnect(device: var): void {
        busy = device.address;
        linker.command = ["bluetoothctl", "disconnect", device.address];
        linker.running = true;
    }

    function forget(device: var): void {
        Quickshell.execDetached(["bluetoothctl", "remove", device.address]);
    }

    Process {
        id: linker

        onExited: code => {
            if (code !== 0 && root.busy !== "")
                Actions.say("bluetooth_disabled", "Could not connect, make sure the device is in pairing mode.");
            root.busy = "";
        }
    }

    function setEnabled(on: bool): void {
        if (adapter)
            Quickshell.execDetached(["sh", "-c", on ? "rfkill unblock bluetooth 2>/dev/null; bluetoothctl power on" : "bluetoothctl power off"]);
        else if (on && !starting) {
            starting = true;
            starter.running = true;
        }
    }

    function discover(on: bool): void {
        if (adapter && adapter.enabled)
            adapter.discovering = on;
    }
}
