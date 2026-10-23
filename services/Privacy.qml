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

    // browsers open the camera device directly, so look at who holds it open
    Timer {
        running: true
        repeat: true
        interval: 3000
        onTriggered: cam.running = true
    }

    Process {
        id: cam

        command: ["sh", "-c", "for d in /dev/video*; do [ -e \"$d\" ] || continue; p=$(fuser \"$d\" 2>/dev/null | awk '{print $1}'); [ -n \"$p\" ] && { cat /proc/$p/comm; exit; }; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.cameraApp = text.trim();
                root.camera = root.cameraApp !== "";
            }
        }
    }
}
