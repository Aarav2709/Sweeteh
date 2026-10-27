pragma Singleton

import QtQuick
import Quickshell
import qs.config

// a fullscreen window on the focused workspace, a game or a video, quiets the shell's busy work
Singleton {
    // only true fullscreen counts, hyprland also flags a maximized window (super d) as fullscreen mode 1
    readonly property bool fullscreen: Hypr.focusedWorkspace?.toplevels.values.some(t => (t.lastIpcObject?.fullscreen ?? 0) >= 2) ?? false
    readonly property bool active: Config.options.performance.auto && fullscreen
}
