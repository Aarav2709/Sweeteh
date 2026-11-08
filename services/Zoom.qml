pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// magnifies the screen around the cursor with hyprland's own zoom, for small text or a tablet held close
Singleton {
    id: root

    property real level: 1

    function set(value: real): void {
        const next = Math.max(1, Math.min(6, Math.round(value * 4) / 4));
        if (next === level)
            return;
        level = next;
        Quickshell.execDetached(["hyprctl", "eval", `hl.config({ cursor = { zoom_factor = ${level} } })`]);
        Actions.say(level > 1 ? "zoom_in" : "zoom_out", level > 1 ? "Zoom " + Math.round(level * 100) + "%" : "Zoom off");
    }

    // each step is a quarter, so a few scrolls go a long way without jumping
    function zoomIn(): void {
        set(level + 0.25);
    }

    function zoomOut(): void {
        set(level - 0.25);
    }

    function reset(): void {
        set(1);
    }

    IpcHandler {
        target: "zoom"

        function zoomIn(): void {
            root.zoomIn();
        }

        function zoomOut(): void {
            root.zoomOut();
        }

        function reset(): void {
            root.reset();
        }
    }
}
