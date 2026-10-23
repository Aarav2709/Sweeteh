pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

// browser downloads in progress, seen as their partial files in the downloads folder
Singleton {
    id: root

    readonly property string folder: (Quickshell.env("XDG_DOWNLOAD_DIR") || Quickshell.env("HOME") + "/Downloads")
    readonly property bool active: partials.count > 0
    // the newest partial file, without its .part or .crdownload ending
    property string name: ""
    property real bytes: 0
    property real speed: 0
    readonly property string sizeText: format(bytes) + (speed > 0 ? "  ·  " + format(speed) + "/s" : "")

    signal finished(string name)

    function format(b: real): string {
        return b >= 1e9 ? (b / 1e9).toFixed(1) + " GB" : b >= 1e6 ? (b / 1e6).toFixed(1) + " MB" : Math.round(b / 1e3) + " KB";
    }

    function clean(file: string): string {
        return file.replace(/\.(part|crdownload)$/, "");
    }

    // the folder model watches the directory, so nothing runs while no download is going
    FolderListModel {
        id: partials

        folder: "file://" + root.folder
        nameFilters: ["*.part", "*.crdownload"]
        showDirs: false
        sortField: FolderListModel.Time
        onCountChanged: {
            if (count > 0) {
                root.name = root.clean(get(0, "fileName"));
            } else if (root.name !== "") {
                root.finished(root.name);
                root.name = "";
                root.bytes = 0;
                root.speed = 0;
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
