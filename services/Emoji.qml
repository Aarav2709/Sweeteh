pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// the bundled emoji and symbol names, loaded the first time the launcher asks for them
Singleton {
    id: root

    readonly property var entries: file.text().split("\n").filter(l => l !== "").map(l => {
        const t = l.indexOf("\t");
        return { c: l.slice(0, t), n: l.slice(t + 1) };
    })

    // whole word starts rank first, then any word start, then anywhere in the name
    function search(query: string, limit: int): var {
        const q = query.trim().toLowerCase();
        if (q === "")
            return entries.slice(0, limit);
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
        id: file

        path: Quickshell.shellPath("assets/emoji.tsv")
        // small, so it loads at once and the first : already has results
        blockLoading: true
    }
}
