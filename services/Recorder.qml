pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// screen recording through wf recorder, a region or a whole monitor
Singleton {
    id: root

    readonly property bool recording: proc.running
    property real startedAt: 0
    property real now: 0
    property string file: ""
    readonly property string elapsed: {
        const s = Math.max(0, Math.floor((now - startedAt) / 1000));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    // geometry is x,y wxh in layout pixels, empty records the focused monitor
    function start(geometry: string): void {
        if (recording)
            return;
        const dir = Paths.expand(Config.options.recording.dir);
        file = dir + "/Recording_" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") + ".mp4";
        // matroska survives an abrupt stop, it becomes an mp4 once recording ends
        const args = ["wf-recorder", "-y", "-x", "yuv420p", "-p", "crf=18", "-p", "preset=veryfast", "-f", file.replace(/\.mp4$/, ".mkv")];
        if (geometry !== "")
            args.push("-g", geometry);
        else
            args.push("-o", Hypr.focusedScreenName);
        // the sound the speakers play, not the microphone, it is a screen recording
        const audio = Config.options.recording.audio ? ` --audio="$(pactl get-default-sink).monitor"` : "";
        proc.command = ["sh", "-c", `mkdir -p ${Paths.quote(dir)} && exec ${args.map(Paths.quote).join(" ")}${audio}`];
        startedAt = Date.now();
        now = startedAt;
        proc.running = true;
    }

    function stop(): void {
        if (recording)
            proc.signal(2);
    }

    Process {
        id: proc

        onExited: code => {
            if (Date.now() - root.startedAt < 800) {
                Actions.say("error", "Recording needs wf recorder installed.");
                return;
            }
            const mkv = root.file.replace(/\.mp4$/, ".mkv");
            Quickshell.execDetached(["sh", "-c", `ffmpeg -loglevel error -y -i ${Paths.quote(mkv)} -c copy -movflags +faststart ${Paths.quote(root.file)} && rm -f ${Paths.quote(mkv)} || mv ${Paths.quote(mkv)} ${Paths.quote(root.file.replace(/\.mp4$/, ".mkv"))}; notify-send -a Sweeteh -i ${Paths.quote(Quickshell.shellPath("assets/icons/sweeteh.svg"))} 'Recording saved' ${Paths.quote(root.file.replace(Paths.home, "~"))}`]);
            Actions.say("videocam", "Recording saved.");
        }
    }

    Timer {
        running: root.recording
        repeat: true
        interval: 1000
        onTriggered: root.now = Date.now()
    }

    IpcHandler {
        target: "recorder"

        // the focused monitor, or a region as x,y wxh in layout pixels
        function start(geometry: string): void {
            root.start(geometry);
        }

        function stop(): void {
            root.stop();
        }

        function file(): string {
            return root.file;
        }
    }
}
