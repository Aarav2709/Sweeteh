pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// checks the repository for a newer release tag now and then and offers it
Singleton {
    id: root

    readonly property string command: Quickshell.shellPath("bin/sweeteh")
    property string available: ""
    property bool checking: false
    property bool updating: false
    property string announced: ""

    function check(): void {
        if (checking)
            return;
        checking = true;
        checker.running = true;
    }

    // runs detached so it survives the shell restarting into the new version
    function update(): void {
        updating = true;
        Quickshell.execDetached([command, "update"]);
    }

    Process {
        id: checker

        command: [root.command, "check"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.checking = false;
                root.available = text.trim();
                if (root.available !== "" && root.available !== root.announced) {
                    root.announced = root.available;
                    Actions.say("system_update", "Sweeteh " + root.available + " is out, update it from settings.");
                }
            }
        }
    }

    // first look a minute after login, then every six hours
    Timer {
        running: true
        repeat: true
        interval: 6 * 60 * 60 * 1000
        onTriggered: root.check()
    }

    Timer {
        running: true
        interval: 60 * 1000
        onTriggered: root.check()
    }
}
