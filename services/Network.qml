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

        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: root.known = text.split("\n").filter(l => l.endsWith(":802-11-wireless")).map(l => l.slice(0, l.lastIndexOf(":")).replace(/\\:/g, ":"))
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
