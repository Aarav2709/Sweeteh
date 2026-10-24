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

    function search(query: string, limit: int): list<var> {
        const q = query.trim();
        const scored = [];
        for (const app of apps) {
            const s = q === "" ? 1 : Fuzzy.best(q, [app.name, app.genericName, app.keywords.join(" "), app.comment]);
            if (s > 0)
                scored.push({
                    app: app,
                    score: s + rank(app.id)
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
