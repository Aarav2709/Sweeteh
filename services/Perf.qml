pragma Singleton

import QtQuick
import Quickshell
import qs.config

// a fullscreen window on the focused workspace, a game or a video, quiets the shell's busy work
Singleton {
    readonly property bool active: Config.options.performance.auto && (Hypr.focusedWorkspace?.hasFullscreen ?? false)
}
