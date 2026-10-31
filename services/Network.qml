pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// network state from networkmanager, the wifi list comes from nmcli since scans through dbus miss most networks
Singleton {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevice: devices.find(d => d.type === DeviceType.Wired) ?? null
    readonly property bool wired: wiredDevice?.connected ?? false
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property var active: wifiDevice ? wifiDevice.networks.values.find(n => n.connected) ?? null : null
    readonly property bool connected: wired || active !== null
    readonly property real strength: active?.signalStrength ?? 0
    readonly property string name: wired ? "Ethernet" : active?.name ?? ""
    readonly property string icon: wired ? "lan" : !wifiEnabled ? "wifi_off" : !active ? "signal_wifi_statusbar_not_connected" : strength > 0.75 ? "network_wifi" : strength > 0.5 ? "network_wifi_3_bar" : strength > 0.25 ? "network_wifi_2_bar" : "network_wifi_1_bar"

    // scanned networks, one entry per name with the strongest signal
    property var networks: []
    property var known: []
    // saved vpn and wireguard connections, each with whether it is up
    property var vpns: []
    property string vpnBusy: ""
    property bool scanning: false
    property string connecting: ""
    property string failed: ""

    signal connectFailed(string ssid)

    function setWifi(on: bool): void {
        Networking.wifiEnabled = on;
    }

    // keep scanning while a wifi list is on screen
    function scan(on: bool): void {
        scanning = on;
        if (on)
            refresh();
    }

    function refresh(): void {
        if (!lister.running)
            lister.running = true;
        if (!saved.running)
            saved.running = true;
    }

    function connect(ssid: string, password: string): void {
        connecting = ssid;
        failed = "";
        joiner.ssid = ssid;
        joiner.command = known.includes(ssid) && password === "" ? ["nmcli", "connection", "up", "id", ssid] : password === "" ? ["nmcli", "device", "wifi", "connect", ssid] : ["nmcli", "device", "wifi", "connect", ssid, "password", password];
        joiner.running = true;
    }

    function disconnect(): void {
        if (wifiDevice)
            Quickshell.execDetached(["nmcli", "device", "disconnect", wifiDevice.name]);
    }

    function setVpn(name: string, on: bool): void {
        vpnBusy = name;
        vpnSwitch.command = ["nmcli", "connection", on ? "up" : "down", "id", name];
        vpnSwitch.running = true;
    }

    function forget(ssid: string): void {
        Quickshell.execDetached(["nmcli", "connection", "delete", "id", ssid]);
        saved.running = true;
    }

    Process {
        id: lister

        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "auto"]
        stdout: StdioCollector {
            onStreamFinished: {
                const byName = {};
                for (const line of text.split("\n")) {
                    // ssids may contain escaped colons
                    const parts = line.replace(/\\:/g, "\u0001").split(":").map(p => p.replace(/\u0001/g, ":"));
                    if (parts.length < 4 || parts[1] === "")
                        continue;
                    const entry = {
                        name: parts[1],
                        connected: parts[0] === "*",
                        strength: Number(parts[2]) / 100,
                        secured: parts[3] !== "" && parts[3] !== "--"
                    };
                    const prev = byName[entry.name];
                    if (!prev || entry.connected || (!prev.connected && entry.strength > prev.strength))
                        byName[entry.name] = entry;
                }
                root.networks = Object.values(byName).sort((a, b) => (b.connected - a.connected) || (b.strength - a.strength));
            }
        }
    }

    Process {
        id: saved

        command: ["nmcli", "-t", "-f", "NAME,TYPE,ACTIVE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                // names may hold escaped colons, the type and state are always the last two fields
                const rows = text.split("\n").filter(l => l !== "").map(l => {
                    const b = l.lastIndexOf(":"), a = l.lastIndexOf(":", b - 1);
                    return { name: l.slice(0, a).replace(/\\:/g, ":"), type: l.slice(a + 1, b), active: l.slice(b + 1) === "yes" };
                });
                root.known = rows.filter(c => c.type === "802-11-wireless").map(c => c.name);
                root.vpns = rows.filter(c => c.type === "vpn" || c.type === "wireguard").map(c => ({ name: c.name, active: c.active }));
            }
        }
    }

    Process {
        id: vpnSwitch

        onExited: code => {
            if (code !== 0)
                Actions.say("vpn_key_off", "Could not switch " + root.vpnBusy);
            root.vpnBusy = "";
            saved.running = true;
        }
    }

    Process {
        id: joiner

        property string ssid

        onExited: code => {
            root.connecting = "";
            if (code !== 0) {
                root.failed = ssid;
                root.connectFailed(ssid);
            }
            root.refresh();
        }
    }

    Timer {
        running: root.scanning && root.wifiEnabled
        repeat: true
        interval: 8000
        onTriggered: root.refresh()
    }
}
