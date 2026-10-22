pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.theme

// window borders painted from the wallpaper palette, set at runtime so hyprland.lua is never edited
Singleton {
    id: root

    readonly property bool enabled: Config.options.theme.windowBorders
    readonly property string active: hex(Theme.color.primary, 0.93) + hex(Theme.color.tertiary, 0.93)
    readonly property string inactive: hex(Theme.color.outlineVariant, 0.67)

    // hyprland wants rgba(rrggbbaa)
    function hex(c: color, alpha: real): string {
        const h = v => Math.round(v * 255).toString(16).padStart(2, "0");
        return `rgba(${h(c.r)}${h(c.g)}${h(c.b)}${h(alpha)})`;
    }

    function apply(): void {
        if (!enabled)
            return;
        const a = active.match(/rgba\([0-9a-f]+\)/g);
        Quickshell.execDetached(["hyprctl", "eval", `hl.config({ general = { col = { active_border = { colors = { "${a[0]}", "${a[1]}" }, angle = 45 }, inactive_border = "${inactive}" } } })`]);
    }

    onActiveChanged: debounce.restart()
    onInactiveChanged: debounce.restart()

    // turning it off hands the borders back to hyprland.lua
    onEnabledChanged: enabled ? debounce.restart() : Quickshell.execDetached(["hyprctl", "reload"])

    Component.onCompleted: debounce.restart()

    Timer {
        id: debounce

        interval: 300
        onTriggered: root.apply()
    }

    // a config reload resets the borders, so paint them again
    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "configreloaded")
                debounce.restart();
        }
    }
}
