import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.theme
import qs.services
import qs.components
import "../../services/Fuzzy.js" as Fuzzy
import "../../services/Calc.js" as Calc

// search field and results, shared by the launcher panel and the island
Item {
    id: root

    property string query: ""
    // results only build while the view can be seen, a hidden launcher should not rerank on every clipboard change
    property bool active: true
    property int current: 0
    // an app opened up to show its own actions, like a private window, cleared by typing
    property var expanded: null
    // a first character that turns the search into the palette, emoji, windows, the clipboard, files or ssh
    readonly property bool prefixed: /^[>:@"\/$]/.test(query.trim())
    readonly property var sum: active && !prefixed ? Calc.evaluate(query) : null
    readonly property var results: active ? build().map(r => Object.assign(r, { key: r.kind + "\u0001" + (r.id ?? r.title) + "\u0001" + (r.subtitle ?? "") })) : []

    signal done

    function reset(): void {
        field.text = "";
        query = "";
        expanded = null;
        current = 0;
        field.focusInput();
    }

    function setQuery(text: string): void {
        field.text = text;
        query = text;
        field.input.cursorPosition = text.length;
        field.focusInput();
    }

    function build(): var {
        const q = query.trim();
        const limit = Config.options.launcher.maxResults;
        const out = [];
        if (expanded) {
            const app = expanded;
            out.push({ kind: "app", image: Apps.icon(app.icon || app.id), title: app.name, subtitle: "Open", run: () => Apps.launch(app) });
            for (const a of app.actions)
                out.push({ kind: "action", icon: "subdirectory_arrow_right", title: a.name, subtitle: app.name, run: () => a.execute() });
            return out;
        }
        // ? lists what each prefix does
        if (q === "?")
            return [
                { kind: "prefix", icon: "terminal", title: "> Commands", subtitle: "Every shell action, timers, dates, colors and more", keep: true, run: () => root.setQuery(">") },
                { kind: "prefix", icon: "mood", title: ": Emoji and symbols", subtitle: "Search by name, Enter copies", keep: true, run: () => root.setQuery(":") },
                { kind: "prefix", icon: "select_window", title: "@ Windows", subtitle: "Switch to an open window, Ctrl Enter closes it", keep: true, run: () => root.setQuery("@") },
                { kind: "prefix", icon: "content_paste", title: "\" Clipboard", subtitle: "Search what you copied, Enter copies it again", keep: true, run: () => root.setQuery("\"") },
                { kind: "prefix", icon: "history", title: "/ Files", subtitle: "Opened lately, or type to search your home folder", keep: true, run: () => root.setQuery("/") },
                { kind: "prefix", icon: "dns", title: "$ SSH", subtitle: "Connect to a host from your ssh config", keep: true, run: () => root.setQuery("$") }
            ];
        if (sum !== null)
            out.push({ kind: "sum", icon: "calculate", title: String(sum), subtitle: "Press enter to copy", run: () => Actions.copy(String(sum)) });
        // conversions like 10 km to mi or 20 usd in eur come back from qalc a moment later
        else if (Qalc.answer !== "" && Qalc.answerFor === q) {
            const a = Qalc.answer;
            out.push({ kind: "sum", icon: "calculate", title: a, subtitle: "Press enter to copy", run: () => Actions.copy(a.replace(/^.*=\s*/, "")) });
        } else if (!Qalc.installed && Qalc.looksLikeConversion(q)) {
            out.push({ kind: "sum", icon: "calculate", title: "Conversions need libqalculate", subtitle: "Press enter to install it", run: () => Packages.install(["libqalculate"]) });
        }
        // > is the command palette, every shell action plus dates to copy, with a shell run as the last resort
        if (q.startsWith(">")) {
            const cmd = q.slice(1).trim();
            out.length = 0;
            out.push(...Commands.answers(cmd));
            const pool = cmd === "" ? Commands.all() : Commands.all().concat(Commands.wallpapers());
            const hits = pool.map(c => ({ c: c, s: (cmd === "" ? 1 : Fuzzy.best(cmd, [c.title, c.keywords])) })).filter(x => x.s > 0).map(x => ({ c: x.c, s: x.s + Commands.boost(x.c.title) })).sort((a, b) => b.s - a.s).slice(0, cmd === "" ? pool.length : 12);
            for (const x of hits)
                out.push({ kind: "action", icon: x.c.icon, title: x.c.title, subtitle: Commands.boost(x.c.title) > 0 && cmd === "" ? "Recent" : "", keywords: x.c.keywords, remember: true, run: x.c.run });
            if (cmd)
                out.push({ kind: "run", icon: "terminal", title: cmd, subtitle: "Run in a shell", run: () => Actions.shell(cmd) });
            return out;
        }
        // : picks an emoji or symbol to copy
        if (q.startsWith(":")) {
            out.length = 0;
            for (const e of Emoji.search(q.slice(1), Math.max(limit, 12)))
                out.push({ kind: "emoji", emoji: e.c, title: e.n.charAt(0).toUpperCase() + e.n.slice(1), subtitle: q.length === 1 && Emoji.recent.includes(e.c) ? "Recent" : "", run: () => {
                        Emoji.used(e.c);
                        Actions.copy(e.c);
                    } });
            return out;
        }
        // @ switches to an open window, the one in front comes last so Enter goes somewhere else
        if (q.startsWith("@")) {
            const want = q.slice(1).trim();
            out.length = 0;
            const wins = Hypr.toplevels.values.map(t => {
                const cls = t.wayland?.appId ?? t.lastIpcObject?.class ?? "";
                return { t: t, cls: cls, s: want === "" ? (t.activated ? 1 : 2) : Fuzzy.best(want, [t.title ?? "", cls]) };
            }).filter(w => w.s > 0).sort((a, b) => b.s - a.s);
            for (const w of wins.slice(0, 20))
                out.push({ kind: "window", id: w.t.address, image: Apps.icon(w.cls), title: w.t.title || w.cls || "Window", subtitle: (w.cls ? w.cls + ", " : "") + "workspace " + (w.t.workspace?.name ?? w.t.workspace?.id ?? ""), run: () => Hypr.focusWindow(w.t.address), alt: () => Hypr.closeWindow(w.t.address) });
            return out;
        }
        // " searches the clipboard history
        if (q.startsWith("\"")) {
            const want = q.slice(1).trim();
            out.length = 0;
            const clips = Clipboard.entries.filter(e => !e.image).map(e => ({ e: e, s: want === "" ? 1 : Fuzzy.score(want, e.text) })).filter(x => x.s > 0);
            if (want !== "")
                clips.sort((a, b) => b.s - a.s);
            for (const x of clips.slice(0, 30))
                out.push({ kind: "clip", id: String(x.e.id), icon: "content_paste", title: x.e.text.replace(/\s+/g, " ").trim().slice(0, 140), run: () => Clipboard.copy(x.e) });
            return out;
        }
        // / lists files opened lately, and searches the home folder once something is typed
        if (q.startsWith("/")) {
            const want = q.slice(1).trim();
            out.length = 0;
            for (const f of (want === "" ? Recents.files : Files.results).slice(0, 20))
                out.push({ kind: "file", id: f, icon: want === "" ? "history" : "description", title: f.slice(f.lastIndexOf("/") + 1), subtitle: f.replace(Paths.home, "~"), run: () => Files.open(f), alt: () => Files.reveal(f) });
            return out;
        }
        // $ connects to a host from the ssh config, or to whatever was typed
        if (q.startsWith("$")) {
            const want = q.slice(1).trim();
            out.length = 0;
            const hosts = Recents.hosts.map(h => ({ h: h, s: want === "" ? 1 : Fuzzy.score(want, h) })).filter(x => x.s > 0);
            if (want !== "")
                hosts.sort((a, b) => b.s - a.s);
            for (const x of hosts.slice(0, 20))
                out.push({ kind: "host", icon: "dns", title: x.h, subtitle: "From your ssh config", run: () => Recents.connect(x.h) });
            if (want !== "" && !/\s/.test(want) && !Recents.hosts.includes(want))
                out.push({ kind: "host", icon: "terminal", title: want, subtitle: "Connect to this host", run: () => Recents.connect(want) });
            return out;
        }
        // with nothing typed, what was just copied can be acted on
        if (q === "" && Config.options.launcher.clipboardActions) {
            // the watcher's copy, asking wayland for the clipboard blocks the whole shell while the app that owns it stalls
            const clip = Clipboard.lastCopy.trim();
            const clipSum = clip.length < 80 ? Calc.evaluate(clip) : null;
            if (/^https?:\/\/\S+$/.test(clip))
                out.push({ kind: "action", icon: "open_in_new", title: "Open copied link", subtitle: clip, run: () => Qt.openUrlExternally(clip) });
            else if (clipSum !== null && String(clipSum) !== clip)
                out.push({ kind: "sum", icon: "calculate", title: String(clipSum), subtitle: "Copied " + clip, run: () => Actions.copy(String(clipSum)) });
            else if (clip.startsWith("/") && clip.indexOf("\n") < 0)
                out.push({ kind: "file", icon: "folder_open", title: "Open copied path", subtitle: clip, run: () => Files.open(clip) });
        }
        for (const app of Apps.search(q, limit))
            out.push({ kind: "app", image: Apps.icon(app.icon || app.id), title: app.name, subtitle: app.comment || app.genericName, more: app.actions.length > 0, run: () => Apps.launch(app), alt: app.actions.length > 0 ? () => root.expand(app) : undefined });
        if (q !== "") {
            const cmds = Commands.all().map(c => ({ c: c, s: Fuzzy.best(q, [c.title, c.keywords]) })).filter(x => x.s > 0).sort((a, b) => b.s - a.s).slice(0, 4);
            for (const x of cmds)
                out.push({ kind: "action", icon: x.c.icon, title: x.c.title, subtitle: "Shell action", run: x.c.run });
            if (Config.options.launcher.files)
                for (const f of Files.results.slice(0, 5))
                    out.push({ kind: "file", icon: "description", title: f.slice(f.lastIndexOf("/") + 1), subtitle: f.replace(Paths.home, "~"), run: () => Files.open(f), alt: () => Files.reveal(f) });
            if (Config.options.launcher.web)
                out.push({ kind: "web", icon: "travel_explore", title: q, subtitle: "Search the web", run: () => Qt.openUrlExternally(Config.options.general.webSearch + encodeURIComponent(q)) });
        }
        return out;
    }

    function expand(app: var): void {
        expanded = app;
        current = 1;
    }

    function activate(index: int, alt: bool): void {
        const r = results[index];
        if (!r)
            return;
        if (r.remember)
            Commands.used(r.title);
        alt && r.alt ? r.alt() : r.run();
        // opening an app's actions or picking a prefix keeps the launcher up
        if (!r.keep && !(alt && r.more))
            done();
    }

    // the last word typed after > grows into the first longer word the top results know
    function complete(): bool {
        if (!query.startsWith(">"))
            return false;
        const m = query.match(/(\S+)$/);
        if (!m || query.endsWith(" "))
            return false;
        const part = m[1].toLowerCase().replace(/^>/, "");
        if (part === "")
            return false;
        for (const r of results) {
            const words = (r.title + " " + (r.keywords ?? "")).toLowerCase().split(/\s+/);
            const word = words.find(w => w.length > part.length && w.startsWith(part));
            if (word) {
                field.text = query.slice(0, query.length - part.length) + word + " ";
                query = field.text;
                field.input.cursorPosition = field.text.length;
                return true;
            }
        }
        return false;
    }

    implicitWidth: Theme.size.launcherWidth
    implicitHeight: column.implicitHeight

    onQueryChanged: {
        current = 0;
        expanded = null;
        Actions.keystroke();
        const q = query.trim();
        // each prefix reads its list as it is first typed, so the rows are fresh
        if (q === "\"")
            Clipboard.refresh();
        else if (q === "/")
            Recents.refreshFiles();
        else if (q === "$")
            Recents.refreshHosts();
        if (q.startsWith("/"))
            Files.search(q.slice(1).trim());
        else if (Config.options.launcher.files)
            Files.search(prefixed ? "" : query);
        if (!prefixed && Calc.evaluate(query) === null)
            Qalc.ask(query);
    }

    ColumnLayout {
        id: column

        width: parent.width
        spacing: Theme.spacing.small

        Field {
            id: field

            Layout.fillWidth: true
            color: Theme.color.layer1
            outlineOnFocus: false
            icon: "search"
            placeholder: "Search apps, files and sums, or ? for more"
            onEdited: root.query = text
            onAccepted: root.activate(root.current, false)
            input.Keys.onPressed: e => {
                // ctrl and a digit runs that row, tab in the palette finishes the word first
                if ((e.modifiers & Qt.ControlModifier) && e.key >= Qt.Key_1 && e.key <= Qt.Key_9) {
                    root.activate(e.key - Qt.Key_1, false);
                    e.accepted = true;
                } else if (e.key === Qt.Key_Tab && !(e.modifiers & Qt.ShiftModifier) && root.complete()) {
                    e.accepted = true;
                } else if (e.key === Qt.Key_Down || (e.key === Qt.Key_Tab && !(e.modifiers & Qt.ShiftModifier))) {
                    root.current = Math.min(root.results.length - 1, root.current + 1);
                    e.accepted = true;
                } else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab) {
                    root.current = Math.max(0, root.current - 1);
                    e.accepted = true;
                } else if ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter) && (e.modifiers & Qt.ControlModifier)) {
                    root.activate(root.current, true);
                    e.accepted = true;
                } else if (e.key === Qt.Key_Escape) {
                    root.done();
                    e.accepted = true;
                }
            }
        }

        ListView {
            id: list

            readonly property int rowHeight: 54

            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, (rowHeight + spacing) * Config.options.launcher.maxResults)
            visible: count > 0
            clip: true
            spacing: Theme.spacing.xxs
            // rows keep their delegates while typing, only the ones that change are created or removed
            model: ScriptModel {
                values: root.results
                objectProp: "key"
            }
            currentIndex: root.current
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: Theme.anim.fast
            highlightResizeDuration: 0
            highlight: Rectangle {
                radius: Theme.radius.medium
                color: Theme.color.layer2
            }

            delegate: Item {
                id: row

                required property var modelData
                required property int index
                readonly property bool selected: index === root.current
                readonly property string hint: modelData.more ? "Ctrl Enter, more" : ({ sum: "Copy", copy: "Copy", emoji: "Copy", clip: "Copy", window: "Switch", host: "SSH", run: "Shell", action: "Action", file: "File", web: "Web" })[modelData.kind] ?? ""

                width: list.width
                height: list.rowHeight

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacing.small
                    anchors.rightMargin: Theme.spacing.medium
                    spacing: Theme.spacing.medium

                    Item {
                        implicitWidth: 38
                        implicitHeight: 38

                        Text {
                            anchors.centerIn: parent
                            visible: !!row.modelData.emoji
                            text: row.modelData.emoji ?? ""
                            font.pixelSize: 26
                        }

                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            visible: !!row.modelData.image
                            source: row.modelData.image ?? ""
                            sourceSize: Qt.size(72, 72)
                            asynchronous: true
                        }

                        Rectangle {
                            anchors.fill: parent
                            visible: !row.modelData.image && !row.modelData.emoji
                            radius: row.modelData.kind === "sum" || row.modelData.swatch ? Theme.radius.medium : width / 2
                            color: row.modelData.swatch ?? (row.modelData.kind === "sum" ? Theme.color.primary : Theme.color.layer2)

                            Icon {
                                anchors.centerIn: parent
                                visible: !row.modelData.swatch
                                name: row.modelData.icon ?? ""
                                fill: row.modelData.kind === "sum" ? 1 : 0
                                color: row.modelData.kind === "sum" ? Theme.color.fgPrimary : Theme.color.inkMeta
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Label {
                            Layout.fillWidth: true
                            text: row.modelData.title
                            font.pixelSize: row.modelData.kind === "sum" ? Theme.font.title : Theme.font.body
                            font.weight: row.modelData.kind === "sum" ? Font.DemiBold : Font.Medium
                        }

                        Label {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: row.modelData.subtitle ?? ""
                            font.pixelSize: Theme.font.small
                            color: Theme.color.inkMeta
                        }
                    }

                    Label {
                        visible: row.hint !== ""
                        text: row.index < 9 && row.selected ? "Ctrl " + (row.index + 1) + "  ·  " + row.hint : row.hint
                        font.pixelSize: Theme.font.small
                        color: Theme.color.inkFaint
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onEntered: root.current = row.index
                    // a right click opens an app's own actions
                    onClicked: e => root.activate(row.index, e.button === Qt.RightButton)
                }
            }
        }

        Label {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacing.small
            Layout.bottomMargin: Theme.spacing.small
            visible: list.count === 0 && root.query.trim() !== ""
            horizontalAlignment: Text.AlignHCenter
            text: "No results."
            color: Theme.color.inkMeta
        }
    }
}
