pragma Singleton

import QtQuick
import Quickshell

// user directories the shell reads and writes
Singleton {
    readonly property string home: Quickshell.env("HOME")
    readonly property string config: (Quickshell.env("XDG_CONFIG_HOME") || home + "/.config") + "/sweeteh"
    readonly property string state: (Quickshell.env("XDG_STATE_HOME") || home + "/.local/state") + "/sweeteh"
    readonly property string data: (Quickshell.env("XDG_DATA_HOME") || home + "/.local/share") + "/sweeteh"
    readonly property string cache: (Quickshell.env("XDG_CACHE_HOME") || home + "/.cache") + "/sweeteh"
    readonly property string runtime: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/sweeteh"

    // turn a leading tilde into the home directory
    function expand(path: string): string {
        return path.startsWith("~") ? home + path.slice(1) : path;
    }

    function url(path: string): string {
        return path.startsWith("file://") ? path : "file://" + expand(path);
    }

    function shell(path: string): string {
        return Quickshell.shellPath(path);
    }

    // quote a value for safe use inside sh command strings
    function quote(value: string): string {
        return "'" + String(value).replace(/'/g, "'\\''") + "'";
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", config, state, data, cache, runtime])
}
