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
    property int current: 0
    readonly property var sum: Calc.evaluate(query)
    readonly property var results: build()

    signal done

    function reset(): void {
        field.text = "";
        query = "";
        current = 0;
        field.focusInput();
    }

    function build(): var {
        const q = query.trim();
        const limit = Config.options.launcher.maxResults;
        const out = [];
        if (sum !== null)
            out.push({ kind: "sum", icon: "calculate", title: String(sum), subtitle: "Press enter to copy", run: () => Quickshell.clipboardText = String(sum) });
        if (q.startsWith(">")) {
            const cmd = q.slice(1).trim();
            if (cmd)
                out.push({ kind: "run", icon: "terminal", title: cmd, subtitle: "Run command", run: () => Actions.shell(cmd) });
            return out;
        }
        for (const app of Apps.search(q, limit))
            out.push({ kind: "app", image: Apps.icon(app.icon || app.id), title: app.name, subtitle: app.comment || app.genericName, run: () => Apps.launch(app) });
        if (q !== "") {
            const cmds = Commands.list.map(c => ({ c: c, s: Fuzzy.best(q, [c.title, c.keywords]) })).filter(x => x.s > 0).sort((a, b) => b.s - a.s).slice(0, 4);
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

    function activate(index: int, alt: bool): void {
        const r = results[index];
        if (!r)
            return;
        alt && r.alt ? r.alt() : r.run();
        done();
    }

    implicitWidth: Theme.size.launcherWidth
    implicitHeight: column.implicitHeight

    onQueryChanged: {
        current = 0;
        if (Config.options.launcher.files)
            Files.search(query.startsWith(">") ? "" : query);
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
            placeholder: "Search apps, files, actions and sums"
            onEdited: root.query = text
            onAccepted: root.activate(root.current, false)
            input.Keys.onPressed: e => {
                if (e.key === Qt.Key_Down || (e.key === Qt.Key_Tab && !(e.modifiers & Qt.ShiftModifier))) {
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
            model: root.results
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
                readonly property string hint: ({ sum: "Copy", run: "Run", action: "Action", file: "File", web: "Web" })[modelData.kind] ?? ""

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
                            visible: !row.modelData.image
                            radius: row.modelData.kind === "sum" ? Theme.radius.medium : width / 2
                            color: row.modelData.kind === "sum" ? Theme.color.primary : Theme.color.layer2

                            Icon {
                                anchors.centerIn: parent
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
                        text: row.hint
                        font.pixelSize: Theme.font.small
                        color: Theme.color.inkFaint
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.current = row.index
                    onClicked: root.activate(row.index, false)
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
