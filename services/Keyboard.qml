pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// caps lock from the keyboard led and the layout from hyprland
Singleton {
    id: root

    property string capsPath: ""
    property bool caps: false
    property string layout: ""

    // the led sits under an input number that changes between boots, so look it up once
    Process {
        running: true
        command: ["sh", "-c", "ls -d /sys/class/leds/*::capslock 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: root.capsPath = text.trim()
        }
    }

    FileView {
        id: led

        path: root.capsPath ? root.capsPath + "/brightness" : ""
        onLoaded: root.caps = text().trim() !== "0"
    }

    // sysfs never notifies, a read of one small file is cheap enough to poll
    Timer {
        running: root.capsPath !== ""
        repeat: true
        interval: 300
        onTriggered: led.reload()
    }

    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            // virtual keyboards, like the on screen keyboard's wtype, come and go with every key and say error
            if (event.name === "activelayout" && !/virtual|wtype/i.test(event.data.slice(0, event.data.lastIndexOf(","))) && !/^error$/i.test(event.data.slice(event.data.lastIndexOf(",") + 1)))
                root.layout = event.data.slice(event.data.lastIndexOf(",") + 1);
        }
    }
}
