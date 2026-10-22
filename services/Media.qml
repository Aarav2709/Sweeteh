pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

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
