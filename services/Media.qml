pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.theme

// active mpris player and its position
Singleton {
    id: root

    readonly property list<MprisPlayer> players: Mpris.players.values
    property MprisPlayer manual: null
    readonly property MprisPlayer player: (manual && players.includes(manual)) ? manual : players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property bool active: player !== null
    readonly property bool playing: player?.isPlaying ?? false
    readonly property string title: player?.trackTitle || "Nothing playing"
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string album: player?.trackAlbum ?? ""
    readonly property string art: player?.trackArtUrl ?? ""
    readonly property real length: player?.length ?? 0
    property real position: 0
    readonly property real volume: player?.volume ?? 0
    readonly property bool volumeSupported: player?.volumeSupported ?? false
    // covers from the web are fetched once into the runtime dir, the quantizer only reads local files
    property string cachedArt: ""
    readonly property string artFile: art.startsWith("http") ? cachedArt : art

    signal volumeNudged

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

    // the whole shell follows the cover while the song plays
    Binding {
        target: Theme
        property: "song"
        value: root.accent
        when: root.hasAccent
    }

    Binding {
        target: Theme
        property: "songOn"
        value: root.playing && root.hasAccent
    }

    ColorQuantizer {
        id: quantizer

        source: root.artFile
        depth: 0
        rescaleSize: 48
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

    function cycle(): void {
        if (players.length > 1)
            manual = players[(players.indexOf(player) + 1) % players.length];
    }

    function format(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
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
