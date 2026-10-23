pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.config

// browser downloads in progress, seen as their partial files in the downloads folder
Singleton {
    id: root

    readonly property bool enabled: Config.options.island.downloads
    readonly property string folder: (Quickshell.env("XDG_DOWNLOAD_DIR") || Quickshell.env("HOME") + "/Downloads")
    readonly property bool active: partials.count > 0
    // the newest partial file, without its .part or .crdownload ending
    property string name: ""
    property real bytes: 0
    property real speed: 0
    // 0 to 1 when the browser reports it through the launcher entry api, -1 when only the size is known
    property real progress: -1
    property string launcherKey: ""
    readonly property string sizeText: format(bytes) + (speed > 0 ? "  ·  " + format(speed) + "/s" : "")

    signal finished(string name)
    signal cancelled(string name)

    function format(b: real): string {
        return b >= 1e9 ? (b / 1e9).toFixed(1) + " GB" : b >= 1e6 ? (b / 1e6).toFixed(1) + " MB" : Math.round(b / 1e3) + " KB";
    }

    function clean(file: string): string {
        return file.replace(/\.(part|crdownload)$/, "");
    }

    // the folder model watches the directory, so nothing runs while no download is going
    FolderListModel {
        id: partials

        folder: root.enabled ? "file://" + root.folder : ""
        nameFilters: ["*.part", "*.crdownload"]
        showDirs: false
        sortField: FolderListModel.Time
        onCountChanged: {
            if (count > 0) {
                root.name = root.clean(get(0, "fileName"));
            } else if (root.name !== "") {
                done.command = ["sh", "-c", "[ -s \"$1/$2\" ] && { echo \"$2\"; exit; }; find \"$1\" -maxdepth 1 -type f -newermt '-8 seconds' -size +0 ! -name '*.part' ! -name '*.crdownload' -printf '%f\\n' | head -1", "sh", root.folder, root.name];
                done.pending = root.name;
                done.running = true;
                root.name = "";
                root.progress = -1;
                root.bytes = 0;
                root.speed = 0;
            }
        }
    }

    // a cancelled download leaves no finished file behind, a renamed one shows up as a fresh file
    Process {
        id: done

        property string pending: ""

        stdout: StdioCollector {
            onStreamFinished: text.trim() ? root.finished(text.trim()) : root.cancelled(done.pending)
        }
    }

    Process {
        running: root.enabled
        command: ["dbus-monitor", "--session", "type='signal',interface='com.canonical.Unity.LauncherEntry',member='Update'"]
        stdout: SplitParser {
            onRead: line => {
                const key = line.match(/string "(progress|progress-visible)"/);
                if (key) {
                    root.launcherKey = key[1];
                    return;
                }
                const num = line.match(/variant\s+double\s+([0-9.eE+-]+)/);
                if (num && root.launcherKey === "progress")
                    root.progress = Math.max(0, Math.min(1, Number(num[1])));
                const flag = line.match(/variant\s+boolean\s+(true|false)/);
                if (flag && root.launcherKey === "progress-visible" && flag[1] === "false")
                    root.progress = -1;
            }
        }
    }

    Timer {
        running: root.active
        repeat: true
        interval: 1000
        onTriggered: size.running = true
    }

    Process {
        id: size

        command: ["sh", "-c", "stat -c %s -- \"$1\"/*.part \"$1\"/*.crdownload 2>/dev/null | sort -n | tail -1", "sh", root.folder]
        stdout: StdioCollector {
            onStreamFinished: {
                const b = Number(text.trim()) || 0;
                root.speed = root.bytes > 0 && b >= root.bytes ? b - root.bytes : 0;
                root.bytes = b;
            }
        }
    }
}
