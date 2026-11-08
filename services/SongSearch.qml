pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// what is this song, a few seconds of whatever is playing go to songrec, which asks shazam
// only the audio fingerprint leaves the machine, the recording is deleted right after
Singleton {
    id: root

    property bool listening: false

    function recognize(): void {
        if (listening)
            return;
        listening = true;
        Actions.offered({
            kind: "song",
            icon: "graphic_eq",
            title: "Listening",
            sub: "What's this song?",
            ms: 11000
        });
        finder.running = true;
    }

    Process {
        id: finder

        command: ["sh", "-c", `command -v songrec >/dev/null || { echo __none__; exit; }
f="$0/song.wav"
mkdir -p "$0"
timeout 8 parecord -d "$(pactl get-default-sink).monitor" --file-format=wav "$f" 2>/dev/null
songrec audio-file-to-recognized-song "$f" 2>/dev/null
rm -f "$f"`, Paths.runtime]
        stdout: StdioCollector {
            onStreamFinished: {
                root.listening = false;
                const out = text.trim();
                if (out === "__none__") {
                    Actions.needs(["songrec"], "music_note", "Song search");
                    return;
                }
                let track = null;
                try {
                    track = JSON.parse(out).track ?? null;
                } catch (e) {}
                if (!track) {
                    Actions.offered({
                        kind: "song",
                        icon: "music_off",
                        title: "No match",
                        sub: "Try again with the music louder"
                    });
                    return;
                }
                const url = track.url ?? "";
                Actions.offered({
                    kind: "song",
                    icon: "music_note",
                    title: track.title ?? "Unknown",
                    sub: (track.subtitle ?? "") + (url ? "  ·  click to open" : ""),
                    run: url ? () => Qt.openUrlExternally(url) : undefined
                });
            }
        }
    }

    IpcHandler {
        target: "song"

        function recognize(): void {
            root.recognize();
        }
    }
}
