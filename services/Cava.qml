pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

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

        running: root.installed && Media.playing && !Perf.active
        command: ["cava", "-p", Quickshell.shellPath("assets/cava.conf")]
        stdout: SplitParser {
            onRead: line => root.values = line.split(";").filter(v => v !== "").map(v => Math.min(1, Number(v) / 100))
        }
        onRunningChanged: {
            if (!running)
                root.values = [];
        }
    }
}
