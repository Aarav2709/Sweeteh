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
            // fd is far faster and skips what git ignores, find is the fallback when it is missing
            const q = Paths.quote(root.query);
            finder.command = ["sh", "-c", `if command -v fd >/dev/null; then timeout 2 fd -i -F -d 5 --max-results 12 --exclude node_modules -- ${q} "$HOME"; else timeout 2 find "$HOME" -maxdepth 5 \\( -name '.*' -o -name node_modules -o -name refs \\) -prune -o -iname ${Paths.quote("*" + root.query + "*")} -print | head -n 12; fi 2>/dev/null`];
            finder.running = true;
        }
    }

    Process {
        id: finder

        property string forQuery

        stdout: StdioCollector {
            onStreamFinished: {
                if (finder.forQuery === root.query)
                    root.results = text.split("\n").filter(l => l !== "").map(l => l.replace(/\/$/, ""));
            }
        }
    }
}
