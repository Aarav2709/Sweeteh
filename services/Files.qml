pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// file name search in the home folder for the launcher
Singleton {
    id: root

    property string query: ""
    property list<string> results: []

    function search(q: string): void {
        query = q.trim();
        finder.running = false;
        if (query.length < 3) {
            results = [];
            return;
        }
        debounce.restart();
    }

    function open(path: string): void {
        Quickshell.execDetached(["xdg-open", path]);
    }

    function reveal(path: string): void {
        Quickshell.execDetached([Config.options.general.fileManager, path.slice(0, path.lastIndexOf("/"))]);
    }

    Timer {
        id: debounce

        interval: 250
        onTriggered: {
            finder.forQuery = root.query;
            finder.command = ["sh", "-c", `timeout 2 find "$HOME" -maxdepth 5 \\( -name '.*' -o -name node_modules -o -name refs \\) -prune -o -iname ${Paths.quote("*" + root.query + "*")} -print 2>/dev/null | head -n 12`];
            finder.running = true;
        }
    }

    Process {
        id: finder

        property string forQuery

        stdout: StdioCollector {
            onStreamFinished: {
                if (finder.forQuery === root.query)
                    root.results = text.split("\n").filter(l => l !== "");
            }
        }
    }
}
