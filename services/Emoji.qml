pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// the bundled emoji and symbol names, loaded the first time the launcher asks for them
Singleton {
    id: root

    // parsed on the first search and not while the service is created, a collection in the middle of that brings the shell down
    // held in a plain object so filling it does not wake the binding that asked
    readonly property var store: ({ entries: null })

    function load(): var {
        return store.entries = file.text().split("\n").filter(l => l !== "").map(l => {
            const t = l.indexOf("\t");
            return { c: l.slice(0, t), n: l.slice(t + 1) };
        });
    }

    // the last few picked come first when nothing is typed yet
    property list<string> recent: []

    function used(c: string): void {
        recent = [c].concat(recent.filter(x => x !== c)).slice(0, 16);
        recentFile.setText(JSON.stringify(recent));
    }

    // whole word starts rank first, then any word start, then anywhere in the name
    function search(query: string, limit: int): var {
        const entries = store.entries ?? load();
        const q = query.trim().toLowerCase();
        if (q === "") {
            const first = recent.map(c => entries.find(e => e.c === c)).filter(e => e);
            return first.concat(entries.filter(e => !recent.includes(e.c))).slice(0, limit);
        }
        const hits = [];
        for (const e of entries) {
            const i = e.n.indexOf(q);
            if (i < 0)
                continue;
            const score = i === 0 ? 3 : e.n[i - 1] === " " ? 2 : 1;
            hits.push({ e: e, s: score - e.n.length / 1000 });
        }
        hits.sort((a, b) => b.s - a.s);
        return hits.slice(0, limit).map(h => h.e);
    }

    FileView {
        id: recentFile

        path: Paths.state + "/emoji.json"
        printErrors: false
        onLoaded: {
            try {
                root.recent = JSON.parse(text());
            } catch (e) {}
        }
    }

    FileView {
        id: file

        path: Quickshell.shellPath("assets/emoji.tsv")
        // small, so the first : already has results
        blockLoading: true
    }
}
