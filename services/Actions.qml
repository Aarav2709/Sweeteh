pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// cross module actions and the single open panel
Singleton {
    id: root

    property string panel: ""
    property string screen: ""
    property string lastClosed: ""
    property real closedAt: 0
    property string settingsPage: ""

    // short status lines shown by the island or a toast
    signal message(string icon, string text)
    signal lockRequested
    signal screenshotRequested(string kind)
    signal desktopEditRequested
    signal settingsRequested(string page)

    // the island and the control center do the same job, so the island wins when it is around
    function route(id: string): string {
        return id === "controlcenter" && Modes.enabled("island") ? "island" : id;
    }

    function open(id: string): void {
        screen = Hypr.focusedScreenName;
        panel = route(id);
    }

    function close(id: string): void {
        id = route(id);
        if (id !== "" && panel !== id)
            return;
        lastClosed = panel;
        closedAt = Date.now();
        panel = "";
    }

    // ignore a reopen right after a click outside closed the same panel
    function toggle(id: string): void {
        id = route(id);
        if (panel === id)
            close(id);
        else if (!(lastClosed === id && Date.now() - closedAt < 300))
            open(id);
    }

    function openSettings(page: string): void {
        close("");
        settingsPage = page;
        settingsRequested(page);
    }

    function isOpen(id: string): bool {
        return panel === route(id);
    }

    function say(icon: string, text: string): void {
        message(icon, text);
    }

    function lock(): void {
        close("");
        lockRequested();
    }

    function screenshot(kind: string): void {
        close("");
        screenshotRequested(kind);
    }

    function editDesktop(): void {
        close("");
        desktopEditRequested();
    }

    function run(command: list<string>): void {
        Quickshell.execDetached(command);
    }

    function shell(command: string): void {
        Quickshell.execDetached(["sh", "-c", command]);
    }

    IpcHandler {
        target: "panels"

        function current(): string {
            return root.panel;
        }

        function close(): void {
            root.close("");
        }
    }
}
