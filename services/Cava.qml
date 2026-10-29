pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// live audio levels from cava while music plays, the island meter falls back to a dance without it
Singleton {
    id: root

    property bool installed: false
    property bool live: false
    readonly property bool active: installed && proc.running && live
    // the levels are written in place without a change signal, readers sample them on their own slow timers
    // so 24 frames a second of audio never ripples through bindings
    readonly property var values: []

    // the low end on its own, what the backlight breathes to
    function bass(): real {
        const v = values;
        const n = Math.min(3, v.length);
        return n > 0 ? (v[0] + (v[1] ?? 0) + (v[2] ?? 0)) / n : 0;
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v cava"]
        onExited: code => root.installed = code === 0
    }

    Process {
        id: proc

        running: root.installed && Media.playing && !Perf.active && Config.options.media.visualizer
        command: ["cava", "-p", Quickshell.shellPath("assets/cava.conf")]
        stdout: SplitParser {
            // quick to rise and slow to fall, raw frames jump too much to read as a meter
            onRead: line => {
                const v = root.values;
                let i = 0, start = 0;
                for (let end = line.indexOf(";"); end >= 0; end = line.indexOf(";", start)) {
                    if (end > start) {
                        const n = Math.min(1, Number(line.substring(start, end)) / 100);
                        const p = i < v.length ? v[i] : n;
                        v[i++] = n > p ? p + (n - p) * 0.55 : p + (n - p) * 0.18;
                    }
                    start = end + 1;
                }
                v.length = i;
                if (!root.live && i > 0)
                    root.live = true;
            }
        }
        onRunningChanged: {
            if (!running) {
                root.values.length = 0;
                root.live = false;
            }
        }
    }
}
