pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// wallpapers from wallhaven, general and safe only, picked ones are saved into the wallpaper folder
Singleton {
    id: root

    property var results: []
    property bool loading: false
    property bool failed: false
    property string query: ""
    // the id being downloaded, empty when idle
    property string fetching: ""

    // the top of the month with nothing typed, otherwise the best matches
    function search(q: string): void {
        query = q.trim();
        loading = true;
        failed = false;
        const params = "categories=100&purity=100&atleast=1920x1080&ratios=landscape&" + (query === "" ? "sorting=toplist&topRange=1M" : "sorting=relevance&q=" + encodeURIComponent(query));
        lister.forQuery = query;
        lister.command = ["curl", "-sf", "--max-time", "15", "https://wallhaven.cc/api/v1/search?" + params];
        lister.running = true;
    }

    function pick(item: var): void {
        if (fetching !== "")
            return;
        const ext = item.full.slice(item.full.lastIndexOf("."));
        const file = Wallpapers.dir + "/wallhaven-" + item.id + ext;
        fetching = item.id;
        getter.file = file;
        getter.command = ["sh", "-c", `mkdir -p ${Paths.quote(Wallpapers.dir)} && { [ -s ${Paths.quote(file)} ] || curl -sfL --max-time 60 -o ${Paths.quote(file)} ${Paths.quote(item.full)}; }`];
        getter.running = true;
    }

    Process {
        id: lister

        property string forQuery

        stdout: StdioCollector {
            onStreamFinished: {
                if (lister.forQuery !== root.query)
                    return;
                try {
                    root.results = JSON.parse(text).data.map(d => ({
                                id: d.id,
                                thumb: d.thumbs.small,
                                full: d.path,
                                size: d.resolution
                            }));
                } catch (e) {
                    root.results = [];
                    root.failed = true;
                }
            }
        }
        onExited: code => {
            root.loading = false;
            if (code !== 0)
                root.failed = true;
        }
    }

    Process {
        id: getter

        property string file

        onExited: code => {
            root.fetching = "";
            if (code === 0) {
                Wallpapers.refresh();
                Wallpapers.set(file);
            } else {
                Actions.say("wifi_off", "Could not download that wallpaper");
            }
        }
    }
}
