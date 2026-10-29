pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "Fuzzy.js" as Fuzzy

// desktop entries with fuzzy search ranked by use
Singleton {
    id: root

    readonly property list<DesktopEntry> apps: DesktopEntries.applications.values.filter(a => !a.noDisplay)
    property var usage: ({})

    // the searchable text and the usage rank of every app, built once per app list, launch or hour instead of per keystroke
    property var index: []
    property int indexHour: -1

    function rebuild(): void {
        indexHour = new Date().getHours();
        index = apps.map(app => ({
                    app: app,
                    fields: [app.name, app.genericName, app.keywords.join(" "), app.comment],
                    rank: rank(app.id)
                }));
    }

    onAppsChanged: rebuild()
    onUsageChanged: rebuild()

    function search(query: string, limit: int): list<var> {
        if (new Date().getHours() !== indexHour)
            rebuild();
        const q = query.trim();
        const scored = [];
        for (const it of index) {
            const s = q === "" ? 1 : Fuzzy.best(q, it.fields);
            if (s > 0)
                scored.push({
                    app: it.app,
                    score: s + it.rank
                });
        }
        scored.sort((a, b) => b.score - a.score || a.app.name.localeCompare(b.app.name));
        return scored.slice(0, limit).map(s => s.app);
    }

    // older files hold a plain count, newer ones also keep the hours and the last launch
    function entry(id: string): var {
        const u = usage[id];
        return typeof u === "number" ? { count: u, hours: [], last: 0 } : u ?? { count: 0, hours: [], last: 0 };
    }

    // how often, plus with smart ranking how often around this hour and how lately
    function rank(id: string): real {
        const e = entry(id);
        let score = Math.min(200, e.count * 15);
        if (Config.options.launcher.smartRanking) {
            const h = new Date().getHours();
            score += Math.min(150, e.hours.filter(x => Math.min(Math.abs(x - h), 24 - Math.abs(x - h)) <= 1).length * 30);
            const days = (Date.now() - e.last) / 86400000;
            score += e.last > 0 ? Math.max(0, 80 - days * 12) : 0;
        }
        return score;
    }

    function launch(app: DesktopEntry): void {
        const next = Object.assign({}, usage);
        const e = entry(app.id);
        next[app.id] = { count: e.count + 1, hours: e.hours.concat([new Date().getHours()]).slice(-30), last: Date.now() };
        usage = next;
        store.setText(JSON.stringify(next));
        if (app.runInTerminal)
            Quickshell.execDetached([Config.options.general.terminal, "-e", ...app.command]);
        else
            app.execute();
    }

    // icon path for an app id or window class
    function icon(name: string): string {
        if (!name)
            return "";
        const entry = DesktopEntries.heuristicLookup(name);
        return Quickshell.iconPath(entry?.icon || name.toLowerCase(), true) || Quickshell.iconPath("application-x-executable", true);
    }

    FileView {
        id: store

        path: Paths.state + "/apps.json"
        printErrors: false
        onLoaded: {
            try {
                root.usage = JSON.parse(text());
            } catch (e) {}
        }
    }
}
