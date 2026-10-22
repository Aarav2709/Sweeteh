import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// screenshot and recording overlay host and its ipc
Scope {
    id: root

    property string kind: ""

    function start(k: string): void {
        kind = "";
        kind = k;
    }

    Connections {
        target: Actions

        function onScreenshotRequested(kind: string): void {
            root.start(kind);
        }
    }

    LazyLoader {
        active: root.kind !== ""

        CaptureOverlay {
            kind: root.kind
            onFinished: root.kind = ""
        }
    }

    IpcHandler {
        target: "screenshot"

        function region(): void {
            root.start("region");
        }

        function screen(): void {
            root.start("screen");
        }

        function window(): void {
            root.start("window");
        }

        // stops a running recording, otherwise picks what to record
        function record(): void {
            if (Recorder.recording)
                Recorder.stop();
            else
                root.start("record");
        }

        function toggle(): void {
            root.kind === "" ? root.start("region") : root.kind = "";
        }

        function open(): void {
            root.start("region");
        }

        function close(): void {
            root.kind = "";
        }
    }
}
