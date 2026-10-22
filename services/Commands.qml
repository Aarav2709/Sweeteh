pragma Singleton

import QtQuick
import Quickshell
import qs.config

// shell actions searchable from the launcher
Singleton {
    id: root

    readonly property list<var> list: {
        const out = [];
        for (const name of Modes.names) {
            const m = Modes.modes[name];
            out.push({
                icon: m.icon,
                title: "Switch to " + m.name + " mode",
                keywords: "mode layout " + name,
                run: () => Modes.set(name)
            });
        }
        const pages = [["Appearance", "palette", "theme color dark light font round"], ["Layout", "view_quilt", "bar island layout islands"], ["Keybinds", "keyboard", "shortcuts keys"], ["Wallpaper", "wallpaper", "background"], ["General", "tune", "options apps"]];
        for (const p of pages)
            out.push({
                icon: p[1],
                title: p[0] + " settings",
                keywords: "settings preferences " + p[2],
                run: () => Actions.openSettings(p[0])
            });
        return out.concat([
            { icon: "lock", title: "Lock screen", keywords: "lock", run: () => Actions.lock() },
            { icon: "wallpaper", title: "Pick a wallpaper", keywords: "wallpaper background", run: () => Actions.open("wallpaper") },
            { icon: "shuffle", title: "Random wallpaper", keywords: "wallpaper shuffle", run: () => Wallpapers.random() },
            { icon: "screenshot_region", title: "Capture a region", keywords: "screenshot capture", run: () => Actions.screenshot("region") },
            { icon: "screenshot_monitor", title: "Capture the screen", keywords: "screenshot capture full", run: () => Actions.screenshot("screen") },
            { icon: "content_paste", title: "Clipboard history", keywords: "clipboard paste copy", run: () => Actions.open("clipboard") },
            { icon: "overview", title: "Workspace overview", keywords: "overview windows", run: () => Actions.open("overview") },
            { icon: "keyboard", title: "Keybind cheat sheet", keywords: "keys shortcuts", run: () => Actions.open("cheatsheet") },
            { icon: "monitoring", title: "System monitor", keywords: "task manager cpu memory processes", run: () => Actions.open("monitor") },
            { icon: "widgets", title: "Edit desktop widgets", keywords: "desktop widgets", run: () => Actions.editDesktop() },
            { icon: "do_not_disturb_on", title: "Toggle do not disturb", keywords: "dnd notifications quiet", run: () => Notifs.setDnd(!Config.options.notifications.dnd) },
            { icon: "dark_mode", title: "Toggle dark theme", keywords: "dark light theme", run: () => Config.set("theme.dark", !Config.options.theme.dark) },
            { icon: "coffee", title: "Toggle caffeine", keywords: "idle awake caffeine", run: () => Session.caffeine = !Session.caffeine },
            { icon: "logout", title: "Log out", keywords: "exit logout session", run: () => Session.logout() },
            { icon: "bedtime", title: "Suspend", keywords: "sleep suspend", run: () => Session.suspend() },
            { icon: "restart_alt", title: "Reboot", keywords: "restart reboot", run: () => Session.reboot() },
            { icon: "power_settings_new", title: "Shut down", keywords: "poweroff shutdown", run: () => Session.poweroff() }
        ]);
    }
}
