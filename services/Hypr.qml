pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// hyprland state and dispatch through the lua api
Singleton {
    id: root

    readonly property HyprlandMonitor focusedMonitor: Hyprland.focusedMonitor
    readonly property string focusedScreenName: focusedMonitor?.name ?? (Quickshell.screens[0]?.name ?? "")
    readonly property HyprlandWorkspace focusedWorkspace: Hyprland.focusedWorkspace
    readonly property int activeWorkspace: focusedWorkspace?.id ?? 1
    readonly property HyprlandToplevel activeToplevel: Hyprland.activeToplevel
    readonly property var workspaces: Hyprland.workspaces
    readonly property var toplevels: Hyprland.toplevels

    function screenFor(name: string): var {
        return Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0];
    }

    function dispatch(lua: string): void {
        Hyprland.dispatch(lua);
    }

    function focusWorkspace(id: int): void {
        dispatch(`hl.dsp.focus({ workspace = ${id} })`);
    }

    function focusWindow(address: string): void {
        dispatch(`hl.dsp.focus({ window = "address:0x${address}" })`);
    }

    function closeWindow(address: string): void {
        dispatch(`hl.dsp.window.close({ window = "address:0x${address}" })`);
    }

    function moveWindow(address: string, workspace: int): void {
        dispatch(`hl.dsp.window.move({ workspace = ${workspace}, follow = false, window = "address:0x${address}" })`);
    }

    function toplevelsOn(workspace: int): list<var> {
        return toplevels.values.filter(t => t.workspace?.id === workspace);
    }

    function exit(): void {
        dispatch("hl.dsp.exit()");
    }

    function reloadConfig(): void {
        Quickshell.execDetached(["hyprctl", "reload"]);
    }

    // window geometry lives in the ipc object, refresh it on changes
    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            if (["openwindow", "closewindow", "movewindow", "movewindowv2", "changefloatingmode", "fullscreen", "resizewindow"].includes(event.name))
                Hyprland.refreshToplevels();
        }
    }
}
