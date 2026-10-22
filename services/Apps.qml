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
                    score: s + Math.min(200, (usage[app.id] ?? 0) * 15)
                });
        }
        scored.sort((a, b) => b.score - a.score || a.app.name.localeCompare(b.app.name));
        return scored.slice(0, limit).map(s => s.app);
    }

    function launch(app: DesktopEntry): void {
        const next = Object.assign({}, usage);
        next[app.id] = (next[app.id] ?? 0) + 1;
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
