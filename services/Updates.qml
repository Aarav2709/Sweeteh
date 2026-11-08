pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// checks the repository for a newer release tag now and then and offers it
Singleton {
    id: root

    readonly property string command: Quickshell.shellPath("bin/sweeteh")
    property string available: ""
    property bool checking: false
    property bool updating: false
    property string announced: ""
    // packages a newer release needs that an update could not install, the installer leaves their names
    property string missing: ""
    property string toldMissing: ""

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
                root.announce();
            }
        }
    }

    // never over a fullscreen game or video, it waits until that closes
    function announce(): void {
        if (available === "" || available === announced || Perf.fullscreen)
            return;
        announced = available;
        Actions.say("system_update", "Sweeteh " + available + " is out, update it from settings.");
    }

    function tellMissing(): void {
        if (missing === "" || missing === toldMissing || Perf.fullscreen || !settled.ready)
            return;
        toldMissing = missing;
        Actions.say("download", "Some features need " + missing + ", install them from the launcher.");
    }

    // the same run an update does, the password is asked in the island
    function installMissing(): void {
        Quickshell.execDetached([command, "update"]);
    }

    onMissingChanged: tellMissing()

    FileView {
        path: Paths.state + "/missing-packages"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.missing = text().trim()
        onLoadFailed: root.missing = ""
    }

    // after a restart into a new release the island is still sliding in, the notice waits a little
    Timer {
        id: settled

        property bool ready: false

        running: true
        interval: 8000
        onTriggered: {
            ready = true;
            root.tellMissing();
        }
    }

    Connections {
        target: Perf

        function onFullscreenChanged(): void {
            root.announce();
            root.tellMissing();
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
