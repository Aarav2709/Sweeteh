pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// backlight level, updated from udev events instead of polling
Singleton {
    id: root

    property string device: ""
    property int current: 0
    property int max: 1
    readonly property bool available: device !== ""
    readonly property real value: max > 0 ? current / max : 0
    readonly property string icon: value < 0.34 ? "brightness_low" : value < 0.67 ? "brightness_medium" : "brightness_high"

    signal changed

    function set(v: real): void {
        if (!available)
            return;
        const pct = Math.round(Math.max(0.01, Math.min(1, v)) * 100);
        Quickshell.execDetached(["brightnessctl", "-q", "-d", device, "set", pct + "%"]);
    }

    function step(delta: real): void {
        set(value + delta);
    }

    function read(): void {
        if (available)
            level.reload();
    }

    Process {
        running: true
        command: ["sh", "-c", "ls /sys/class/backlight | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: root.device = text.trim()
        }
    }

    FileView {
        path: root.available ? `/sys/class/backlight/${root.device}/max_brightness` : ""
        onLoaded: root.max = parseInt(text()) || 1
    }

    FileView {
        id: level

        path: root.available ? `/sys/class/backlight/${root.device}/brightness` : ""
        onLoaded: {
            const v = parseInt(text()) || 0;
            if (v !== root.current) {
                const first = root.current === 0;
                root.current = v;
                if (!first)
                    root.changed();
            }
        }
    }

    Process {
        running: root.available
        command: ["udevadm", "monitor", "--udev", "-s", "backlight"]
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("change"))
                    root.read();
            }
        }
    }

    IpcHandler {
        target: "brightness"

        function up(): void {
            root.step(0.05);
        }

        function down(): void {
            root.step(-0.05);
        }

        function set(percent: int): void {
            root.set(percent / 100);
        }

        function get(): int {
            return Math.round(root.value * 100);
        }
    }
}
