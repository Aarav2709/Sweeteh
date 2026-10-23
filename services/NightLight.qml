pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// warmer screen in the evening through hyprsunset, quitting it hands the gamma back
Singleton {
    id: root

    readonly property var opts: Config.options.nightLight
    property bool installed: false
    // auto follows the schedule, on and off force it until the next change of schedule
    property string forced: ""
    readonly property bool scheduled: {
        const now = Time.now.getHours() * 60 + Time.now.getMinutes();
        const from = minutes(opts.from), to = minutes(opts.to);
        return from <= to ? now >= from && now < to : now >= from || now < to;
    }
    readonly property bool active: installed && (forced === "on" || (forced === "" && opts.auto && scheduled))

    onScheduledChanged: forced = ""

    function minutes(t: string): int {
        const [h, m] = t.split(":").map(Number);
        return (h || 0) * 60 + (m || 0);
    }

    function toggle(): void {
        forced = active ? "off" : "on";
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v hyprsunset"]
        onExited: code => root.installed = code === 0
    }

    Process {
        running: root.active
        command: ["hyprsunset", "-t", String(root.opts.temperature)]
    }

    IpcHandler {
        target: "nightlight"

        function toggle(): void {
            root.toggle();
        }
    }
}
