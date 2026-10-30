import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.theme

// every option label on every settings page, read from the page files so it never drifts from them
QtObject {
    id: root

    property var pages: []
    readonly property var entries: {
        const out = [];
        for (const p of pages) {
            out.push({ page: p.name, label: p.name, hint: p.hint, row: "" });
            const text = files[p.name]?.text() ?? "";
            for (const m of all(text, /\blabel: "([^"]+)"/g))
                out.push({ page: p.name, label: m[1], hint: p.name, row: m[1] });
            for (const m of all(text, /\bkey: "([a-zA-Z]+)\.([a-zA-Z]+)"/g))
                out.push({ page: p.name, label: Theme.humanize(m[2]), hint: p.name + ", " + Theme.humanize(m[1]), row: Theme.humanize(m[2]) });
            // the general page builds a row for each plain option in these config sections
            const sections = text.match(/property var sections: \[([^\]]*)\]/);
            if (sections)
                for (const s of sections[1].match(/"[a-zA-Z]+"/g) ?? []) {
                    const sec = s.slice(1, -1);
                    const vals = Defaults.values[sec] ?? {};
                    out.push({ page: p.name, label: Theme.humanize(sec), hint: p.name, row: "" });
                    for (const k of Object.keys(vals))
                        if (typeof vals[k] !== "object")
                            out.push({ page: p.name, label: Theme.humanize(k), hint: p.name + ", " + Theme.humanize(sec), row: Theme.humanize(k), section: Theme.humanize(sec) });
                }
        }
        const seen = {};
        return out.filter(e => {
            const id = e.page + "|" + e.label + "|" + e.hint;
            return seen[id] ? false : (seen[id] = true);
        });
    }

    property var files: ({})

    // every match of a global regex, the engine has no matchAll
    function all(text: string, re: var): var {
        const out = [];
        re.lastIndex = 0;
        for (let m = re.exec(text); m; m = re.exec(text))
            out.push(m);
        return out;
    }

    function search(query: string): var {
        const q = query.trim().toLowerCase();
        if (q === "")
            return [];
        const hits = [];
        for (const e of entries) {
            const l = e.label.toLowerCase();
            const i = l.indexOf(q);
            if (i >= 0)
                hits.push({ e: e, s: (i === 0 ? 3 : l[i - 1] === " " ? 2 : 1) - l.length / 1000 });
            else if (e.hint.toLowerCase().includes(q))
                hits.push({ e: e, s: 0.5 });
        }
        return hits.sort((a, b) => b.s - a.s).slice(0, 8).map(h => h.e);
    }

    property Instantiator loader: Instantiator {
        model: root.pages

        FileView {
            required property var modelData

            path: Quickshell.shellPath("modules/settings/" + modelData.name + "Page.qml")
            blockLoading: true
            Component.onCompleted: {
                const next = Object.assign({}, root.files);
                next[modelData.name] = this;
                root.files = next;
            }
        }
    }
}
