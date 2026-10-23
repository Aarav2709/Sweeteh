pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// who is using the microphone, the camera or the screen
Singleton {
    id: root

    // capture streams that record a sink monitor, like the island meter, are not the microphone
    readonly property var micStreams: Pipewire.nodes.values.filter(n => n.isStream && n.isSink && n.audio && n.properties?.["stream.capture.sink"] !== "true" && !["cava", "Quickshell", "quickshell"].includes(n.properties?.["application.name"] ?? ""))
    readonly property bool mic: micStreams.length > 0
    readonly property string micApp: micStreams[0]?.properties?.["application.name"] ?? ""
    // the portal names its screencast nodes after itself
    readonly property bool screen: Pipewire.nodes.values.some(n => (n.name ?? "").startsWith("xdph"))
    property bool camera: false
    property string cameraApp: ""
    // the webcam's usb power state, active while something streams from it, empty when it cannot be used
    property string powerPath: ""

    Process {
        running: true
        command: ["sh", "-c", "for v in /sys/class/video4linux/video*; do d=$(dirname \"$(readlink -f \"$v/device\")\"); [ \"$(cat \"$d/power/control\" 2>/dev/null)\" = auto ] && { echo \"$d/power/runtime_status\"; exit; }; done"]
        stdout: StdioCollector {
            onStreamFinished: root.powerPath = text.trim()
        }
    }

    FileView {
        id: power

        path: root.powerPath
        printErrors: false
        onLoaded: {
            const on = text().trim() === "active";
            if (on && !root.camera)
                who.running = true;
            if (!on) {
                root.camera = false;
                root.cameraApp = "";
            }
        }
    }

    // sysfs never notifies, but a read of one small file is far cheaper than scanning processes
    Timer {
        running: !Perf.active
        repeat: true
        interval: 2000
        onTriggered: root.powerPath ? power.reload() : who.running = true
    }

    // the name of the app holding the camera, asked once as it turns on
    Process {
        id: who

        command: ["sh", "-c", "for d in /dev/video*; do [ -e \"$d\" ] || continue; p=$(fuser \"$d\" 2>/dev/null | awk '{print $1}'); [ -n \"$p\" ] && { cat /proc/$p/comm; exit; }; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.cameraApp = text.trim();
                root.camera = root.cameraApp !== "" || (root.powerPath !== "" && power.text().trim() === "active");
            }
        }
    }
}
