pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// live audio levels from cava while music plays, the island meter falls back to a dance without it
Singleton {
    id: root

    property bool installed: false
    readonly property bool active: installed && proc.running && values.length > 0
    property list<real> values: []

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
                const prev = root.values;
                root.values = line.split(";").filter(v => v !== "").map((v, i) => {
                    const n = Math.min(1, Number(v) / 100);
                    const p = prev[i] ?? n;
                    return n > p ? p + (n - p) * 0.55 : p + (n - p) * 0.18;
                });
            }
        }
        onRunningChanged: {
            if (!running)
                root.values = [];
        }
    }
}
