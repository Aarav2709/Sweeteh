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
    // a quick settings page the island dashboard should open on, taken once it shows
    property string dashboardPage: ""

    // short status lines shown by the island or a toast
    signal message(string icon, string text)
    signal lockRequested
    signal unlocked
    // the bar's workspace pill is hovered, the island shows the workspace peek
    property bool barWorkspaceHover: false
    // settings asks the island to show a sample moment
    signal momentPreview(string kind)
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

    // copy text and let the island say so, the clipboard watcher says it by itself when it runs
    function copy(text: string): void {
        Quickshell.clipboardText = text;
        if (!Clipboard.watching)
            Clipboard.copied(text.length > 60 ? text.slice(0, 60) + "…" : text, false);
    }

    function openPage(page: string): void {
        dashboardPage = page;
        open("island");
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
