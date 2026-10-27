pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// synced lyrics from lrclib, cached per track
Singleton {
    id: root

    readonly property bool enabled: Config.options.media.lyrics
    readonly property string key: Media.active ? Media.artist + " " + Media.title : ""
    property var lines: []
    property string plain: ""
    property bool loading: false
    readonly property int index: {
        const t = Media.position + 0.3;
        let i = -1;
        for (let k = 0; k < lines.length; k++) {
            if (lines[k].time <= t)
                i = k;
            else
                break;
        }
        return i;
    }
    readonly property string current: index >= 0 ? lines[index].text : ""
    property var cache: ({})

    function parse(lrc: string): var {
        const out = [];
        for (const row of lrc.split("\n")) {
            const text = row.replace(/\[[^\]]*\]/g, "").trim();
            const tag = /\[(\d+):(\d+(?:\.\d+)?)\]/g;
            let t;
            while ((t = tag.exec(row)) !== null)
                out.push({
                    time: parseInt(t[1]) * 60 + parseFloat(t[2]),
                    text: text
                });
        }
        return out.sort((a, b) => a.time - b.time);
    }

    // titles from video sites carry noise that lrclib does not know about
    function clean(text: string): string {
        return String(text).replace(/\s*[\(\[][^\)\]]*(official|lyric|video|audio|visualizer|remaster|hd|4k|mv)[^\)\]]*[\)\]]/gi, "").replace(/\s*(ft\.|feat\.).*$/i, "").replace(/\s+-\s+topic$/i, "").replace(/vevo$/i, "").trim();
    }

    function request(params: string): void {
        fetcher.command = ["curl", "-sf", "--max-time", "15", "-A", "sweeteh", "https://lrclib.net/api/search?" + params];
        fetcher.running = true;
    }

    function fetch(): void {
        lines = [];
        plain = "";
        fetcher.running = false;
        if (!enabled || !Media.active || !Media.player?.trackTitle)
            return;
        if (cache[key]) {
            lines = cache[key].lines;
            plain = cache[key].plain;
            return;
        }
        let title = clean(Media.title);
        let artist = clean(Media.artist);
        // video titles often read artist then song
        if (title.includes(" - ") && (!artist || title.toLowerCase().startsWith(artist.toLowerCase()))) {
            const parts = title.split(" - ");
            artist = artist || parts[0].trim();
            title = parts.slice(1).join(" - ").trim();
        }
        fetcher.forKey = key;
        fetcher.fallback = artist ? "q=" + encodeURIComponent(title + " " + artist) : "";
        loading = true;
        request(artist ? `track_name=${encodeURIComponent(title)}&artist_name=${encodeURIComponent(artist)}` : "q=" + encodeURIComponent(title));
    }

    // synced lyrics first, then the closest length to the playing track
    function pick(results: var): var {
        const length = Media.length;
        const scored = results.filter(r => r.syncedLyrics || r.plainLyrics).map(r => ({
                    r: r,
                    score: (r.syncedLyrics ? 0 : 1000) + (length > 0 ? Math.abs((r.duration ?? 0) - length) : 0)
                }));
        scored.sort((a, b) => a.score - b.score);
        return scored.length > 0 ? scored[0].r : null;
    }

    onKeyChanged: {
        retry.left = 3;
        debounce.restart();
    }
    onEnabledChanged: fetch()

    Timer {
        id: retry

        property int left: 3

        interval: 4000
        onTriggered: {
            if (root.lines.length === 0 && root.plain === "")
                root.fetch();
        }
    }

    Timer {
        id: debounce

        interval: 400
        onTriggered: root.fetch()
    }

    Process {
        id: fetcher

        property string forKey
        property string fallback

        stdout: StdioCollector {
            onStreamFinished: {
                if (fetcher.forKey !== root.key) {
                    root.loading = false;
                    return;
                }
                let best = null;
                let answered = false;
                try {
                    best = root.pick(JSON.parse(text));
                    answered = true;
                } catch (e) {}
                // lrclib is often slow, a failed request is not an answer, so nothing is cached and it tries again
                if (!answered) {
                    root.loading = false;
                    if (retry.left > 0) {
                        retry.left--;
                        retry.restart();
                    }
                    return;
                }
                if (!best && fetcher.fallback !== "") {
                    const next = fetcher.fallback;
                    fetcher.fallback = "";
                    Qt.callLater(() => root.request(next));
                    return;
                }
                const entry = {
                    lines: best?.syncedLyrics ? root.parse(best.syncedLyrics) : [],
                    plain: best?.plainLyrics ?? ""
                };
                root.cache[fetcher.forKey] = entry;
                root.lines = entry.lines;
                root.plain = entry.plain;
                root.loading = false;
            }
        }
    }
}
