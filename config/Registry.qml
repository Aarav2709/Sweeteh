pragma Singleton

import QtQuick
import Quickshell

// every module the shell knows about
// entry means it has a module file, widget means it can sit in a bar slot
// panel means toggle, open and close drive a panel, own means it ships its own ipc handler
Singleton {
    readonly property var modules: [
        { id: "bar", name: "Bar", icon: "toolbar", entry: true, widget: false, panel: false, own: false, description: "Bar that hosts widgets in slots." },
        { id: "island", name: "Island", icon: "pill", entry: true, widget: false, panel: false, own: true, description: "Shape shifting island for launcher, notifications, media and OSD." },
        { id: "background", name: "Wallpaper", icon: "image", entry: true, widget: false, panel: false, own: false, description: "Draws the wallpaper with transitions." },
        { id: "workspaces", name: "Workspaces", icon: "grid_view", entry: false, widget: true, panel: false, own: false, description: "Workspace dots with app icons." },
        { id: "tray", name: "System tray", icon: "apps", entry: false, widget: true, panel: false, own: false, description: "Tray icons from running apps." },
        { id: "indicators", name: "Indicators", icon: "wifi", entry: false, widget: true, panel: false, own: false, description: "Audio, network, bluetooth and battery status." },
        { id: "media", name: "Media", icon: "music_note", entry: false, widget: false, panel: true, own: false, description: "Player controls and synced lyrics in the island." },
        { id: "notifications", name: "Notifications", icon: "notifications", entry: false, widget: false, panel: false, own: false, description: "Notifications shown by the island." },
        { id: "osd", name: "OSD", icon: "volume_up", entry: false, widget: false, panel: false, own: false, description: "Volume and brightness shown by the island." },
        { id: "launcher", name: "Launcher", icon: "search", entry: false, widget: false, panel: true, own: false, description: "Search apps, files, actions and sums in the island." },
        { id: "controlcenter", name: "Quick settings", icon: "tune", entry: false, widget: false, panel: true, own: false, description: "Toggles, sliders and notifications in the island." },
        { id: "power", name: "Power", icon: "power_settings_new", entry: false, widget: true, panel: true, own: false, description: "Lock, log out, suspend, reboot and shut down." },
        { id: "lock", name: "Lockscreen", icon: "lock", entry: true, widget: false, panel: false, own: true, description: "Lockscreen with password unlock." },
        { id: "wallpaper", name: "Wallpaper picker", icon: "wallpaper", entry: false, widget: false, panel: true, own: false, description: "Pick wallpapers and recolor the shell." },
        { id: "clipboard", name: "Clipboard", icon: "content_paste", entry: false, widget: false, panel: true, own: false, description: "Clipboard history in the island." },
        { id: "overview", name: "Overview", icon: "overview", entry: false, widget: false, panel: true, own: false, description: "Workspace overview with live previews." },
        { id: "screenshot", name: "Screenshot", icon: "screenshot_region", entry: true, widget: false, panel: false, own: true, description: "Region, window and screen capture." },
        { id: "cheatsheet", name: "Cheat sheet", icon: "keyboard", entry: false, widget: false, panel: true, own: false, description: "Keybinds with their descriptions." },
        { id: "modeswitcher", name: "Mode switcher", icon: "swap_horiz", entry: false, widget: false, panel: true, own: false, description: "Switch between shell modes." },
        { id: "desktop", name: "Desktop widgets", icon: "widgets", entry: true, widget: false, panel: false, own: true, description: "Widgets on the desktop with an edit mode." },
        { id: "monitor", name: "System monitor", icon: "monitoring", entry: false, widget: false, panel: true, own: false, description: "Processor, memory, disk, network and the busiest processes in the island." },
        { id: "settings", name: "Settings", icon: "settings", entry: true, widget: false, panel: false, own: true, description: "Settings for every option." }
    ]

    function byId(id: string): var {
        return modules.find(m => m.id === id) ?? null;
    }

    // folder and file stem for a module id
    function stem(id: string): string {
        const names = { controlcenter: "ControlCenter", modeswitcher: "ModeSwitcher" };
        return names[id] ?? id.charAt(0).toUpperCase() + id.slice(1);
    }
}
