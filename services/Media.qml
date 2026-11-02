pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.config
import qs.theme

// active mpris player and its position
Singleton {
    id: root

    // playerctld only mirrors other players, and with the plasma browser bridge running the browser's own player is a copy too
    readonly property bool bridged: Mpris.players.values.some(p => (p.dbusName ?? "").includes("plasma-browser-integration"))
    readonly property list<MprisPlayer> players: Mpris.players.values.filter(p => {
        const bus = p.dbusName ?? "";
        return !bus.includes("playerctld") && !(bridged && /MediaPlayer2\.(firefox|chromium|zen|brave)/.test(bus));
    })
    property MprisPlayer manual: null
    readonly property MprisPlayer player: (manual && players.includes(manual)) ? manual : players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property bool active: player !== null
    readonly property bool playing: player?.isPlaying ?? false
    // browser tabs carry an unread count in front and the site name behind
    readonly property string title: (player?.trackTitle ?? "").replace(/^\(\d+\)\s*/, "").replace(/\s+[-–]\s+YouTube$/, "") || "Nothing playing"
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string album: player?.trackAlbum ?? ""
    readonly property string art: player?.trackArtUrl ?? ""
    // some players only put the length in the metadata, in microseconds
    readonly property real length: player?.length || Number(player?.metadata?.["mpris:length"] ?? 0) / 1000000
    // firefox and its forks always report position 0 over mpris, so their time is only a count from when the shell noticed
    // the plasma browser bridge reports the real one
    readonly property bool guessedPosition: !bridged && /firefox|zen|librewolf|floorp|waterfox|mozilla/i.test((player?.identity ?? "") + " " + (player?.desktopEntry ?? ""))
    // a progress bar and times only when both ends are real
    readonly property bool timed: length > 0 && !guessedPosition
    property real position: 0
    // the page a browser player is on, empty for music apps
    readonly property string url: player?.metadata?.["xesam:url"] ?? ""
    // the video site behind a browser player, youtube music and official music uploads still count as songs
    readonly property string site: {
        const u = url;
        if (/music\.youtube\.com/.test(u))
            return "";
        // the url can be the bare site while a video plays, so any youtube page counts
        if (/(youtube\.com|youtu\.be)/.test(u))
            return "YouTube";
        const sites = [["twitch.tv", "Twitch"], ["netflix.com", "Netflix"], ["vimeo.com", "Vimeo"], ["primevideo.com", "Prime Video"], ["disneyplus.com", "Disney+"], ["max.com", "Max"], ["crunchyroll.com", "Crunchyroll"], ["dailymotion.com", "Dailymotion"]];
        return sites.find(s => u.includes(s[0]))?.[1] ?? "";
    }
    readonly property bool musicUpload: / - Topic$|VEVO$/i.test(artist) || /official (music )?(video|audio)|\(lyrics?\)|lyric video|\(audio\)|\[audio\]|visuali[sz]er/i.test(title)
    readonly property bool video: site !== "" && !musicUpload
    // who made it, the channel for a video and the artist for a song
    readonly property string source: video ? site : (player?.identity ?? "")
    readonly property real volume: player?.volume ?? 0
    readonly property bool volumeSupported: player?.volumeSupported ?? false
    // covers from the web are fetched once into the runtime dir, the quantizer only reads local files
    property string cachedArt: ""
    readonly property string artFile: art.startsWith("http") ? cachedArt : art

    signal volumeNudged

    // recently played tracks, newest first, kept across restarts
    property var history: []

    // a track counts once it has played for a few seconds
    onTitleChanged: remember.restart()

    function resume(item: var): void {
        const open = players.find(p => (p.desktopEntry || p.identity) === item.app);
        if (open) {
            manual = open;
            if (!open.isPlaying && open.canPlay)
                open.play();
        } else if (item.app) {
            Quickshell.execDetached(["gtk-launch", item.app]);
        }
    }

    Timer {
        id: remember

        interval: 4000
        onTriggered: {
            // videos are not tracks, the history is for music
            if (!Config.options.media.history || !root.playing || !root.player?.trackTitle || root.video)
                return;
            const item = { title: root.title, artist: root.artist, art: root.art.startsWith("http") || root.art.startsWith("file:") ? root.art : "", app: root.player.desktopEntry || root.player.identity || "" };
            root.history = [item].concat(root.history.filter(h => h.title !== item.title || h.artist !== item.artist)).slice(0, 20);
            historyFile.setText(JSON.stringify(root.history));
        }
    }

    FileView {
        id: historyFile

        path: Paths.state + "/media-history.json"
        printErrors: false
        onLoaded: {
            try {
                root.history = JSON.parse(text()) || [];
            } catch (e) {
                root.history = [];
            }
        }
    }

    onArtChanged: {
        cachedArt = "";
        if (art.startsWith("http")) {
            fetch.running = false;
            fetch.command = ["sh", "-c", "d=\"${XDG_RUNTIME_DIR:-/tmp}/sweeteh/art\"; mkdir -p \"$d\"; f=\"$d/$(printf %s \"$1\" | md5sum | cut -c1-16)\"; [ -s \"$f\" ] || curl -sfL --max-time 10 -o \"$f\" \"$1\"; [ -s \"$f\" ] && echo \"$f\"", "sh", art];
            fetch.running = true;
        }
    }

    // the player's own volume when it has one, the system volume otherwise
    function setVolume(v: real): void {
        if (volumeSupported) {
            player.volume = Math.max(0, Math.min(1, v));
            volumeNudged();
        } else {
            Audio.setVolume(v);
        }
    }

    Process {
        id: fetch

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    root.cachedArt = "file://" + text.trim();
            }
        }
    }

    // the strongest color of the cover, evened out so it reads as a tint in either theme
    readonly property bool hasAccent: artFile !== "" && quantizer.colors.length > 0
    readonly property color accent: {
        const c = quantizer.colors[0];
        return c ? Qt.hsla(c.hslHue, Math.min(1, c.hslSaturation * 1.3 + 0.1), 0.55, 1) : "#7c9cff";
    }

    ColorQuantizer {
        id: quantizer

        source: root.artFile
        depth: 0
        rescaleSize: 48
    }

    function play(): void {
        if (player?.canPlay)
            player.play();
    }

    function pause(): void {
        if (player?.canPause)
            player.pause();
    }

    function toggle(): void {
        if (player?.canTogglePlaying)
            player.togglePlaying();
    }

    function next(): void {
        if (player?.canGoNext)
            player.next();
    }

    function previous(): void {
        if (player?.canGoPrevious)
            player.previous();
    }

    function seek(seconds: real): void {
        if (player?.canSeek) {
            player.position = seconds;
            position = seconds;
        }
    }

    function shuffle(): void {
        if (player?.shuffleSupported)
            player.shuffle = !player.shuffle;
    }

    // off, then the whole list, then the one track
    function loop(): void {
        if (!player?.loopSupported)
            return;
        player.loopState = player.loopState === MprisLoopState.None ? MprisLoopState.Playlist : player.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None;
    }

    function cycle(): void {
        if (players.length > 1)
            manual = players[(players.indexOf(player) + 1) % players.length];
    }

    function format(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        if (s >= 3600)
            return Math.floor(s / 3600) + ":" + String(Math.floor(s / 60) % 60).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0");
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    // mpris does not push position, so sample it only while playing
    Timer {
        running: root.playing
        repeat: true
        interval: 500
        triggeredOnStart: true
        onTriggered: root.position = root.player?.position ?? 0
    }

    onPlayerChanged: position = player?.position ?? 0

    IpcHandler {
        target: "player"

        function toggle(): void {
            root.toggle();
        }

        function next(): void {
            root.next();
        }

        function previous(): void {
            root.previous();
        }

        function cycle(): void {
            root.cycle();
        }

        function current(): string {
            return root.active ? root.title + "\n" + root.artist : "";
        }
    }
}
