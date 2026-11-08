pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// pending arch package updates from the repos and the aur, checked now and then without needing root
Singleton {
    id: root

    property var list: []
    readonly property int count: list.length
    property bool checking: false
    // the count last said out loud, so the island only speaks up when more arrive
    property int told: 0
    property bool installing: false

    // tools the shell uses, put in with the password asked in the island
    signal installed

    function install(packages: list<string>): void {
        if (installing || packages.length === 0)
            return;
        installing = true;
        installer.names = packages.join(", ");
        installer.command = ["sh", "-c", 'command -v pacman >/dev/null || exit 3; pkexec pacman -S --needed --noconfirm "$@"', "sh"].concat(packages);
        installer.running = true;
    }

    Process {
        id: installer

        property string names

        onExited: code => {
            root.installing = false;
            if (code === 0) {
                Actions.say("download_done", "Installed " + names);
                root.installed();
            } else if (code === 3) {
                Actions.say("download", "Install " + names + " with your package manager");
            } else {
                Actions.say("download", names + " was not installed");
            }
        }
    }

    function check(): void {
        if (!lister.running) {
            checking = true;
            lister.running = true;
        }
    }

    // runs in a terminal, a system upgrade asks for a password and may ask questions
    function upgrade(): void {
        Quickshell.execDetached([Config.options.general.terminal, "-e", "sh", "-c", "if command -v yay >/dev/null; then yay -Syu; elif command -v paru >/dev/null; then paru -Syu; else sudo pacman -Syu; fi; echo; read -p 'Done, press enter to close. ' _"]);
        told = 0;
        recheck.restart();
    }

    Process {
        id: lister

        command: ["sh", "-c", "command -v checkupdates >/dev/null || exit 3; checkupdates 2>/dev/null; if command -v yay >/dev/null; then yay -Qua 2>/dev/null; elif command -v paru >/dev/null; then paru -Qua 2>/dev/null; fi; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.list = text.split("\n").filter(l => l.trim() !== "").map(l => {
                    const p = l.trim().split(/\s+/);
                    return { name: p[0], from: p[1] ?? "", to: p[3] ?? "" };
                });
                if (root.count > root.told && root.count >= 10) {
                    Actions.say("system_update", root.count + " package updates");
                    root.told = root.count;
                }
            }
        }
        onExited: root.checking = false
    }

    // a first look a few minutes in, then every three hours
    Timer {
        running: true
        interval: 3 * 60 * 1000
        onTriggered: root.check()
    }

    Timer {
        running: true
        repeat: true
        interval: 3 * 60 * 60 * 1000
        onTriggered: root.check()
    }

    Timer {
        id: recheck

        interval: 10 * 60 * 1000
        onTriggered: root.check()
    }
}
