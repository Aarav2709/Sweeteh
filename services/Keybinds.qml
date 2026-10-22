pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.config

// shell keybinds and rules applied to hyprland at runtime, your hyprland.lua is never edited
// combos your own config already uses are skipped and listed in conflicts
Singleton {
    id: root

    readonly property list<var> binds: Config.options.keybinds
    readonly property string ipcPrefix: `qs -p ${Quickshell.shellPath("")} ipc call `
    property var live: []
    property list<string> applied: []
    property list<string> conflicts: []
    property bool syncing: false
    property bool submapReady: false

    readonly property var actions: [
        "launcher toggle", "island toggle", "overview toggle", "clipboard toggle", "power toggle", "lock lock",
        "wallpaper toggle", "wallpapers random", "cheatsheet toggle", "modeswitcher toggle", "mode cycle", "settings toggle",
        "monitor toggle", "media toggle", "screenshot region", "screenshot screen", "screenshot window", "screenshot record",
        "desktop edit", "notifs clear", "notifs dnd", "player toggle", "player next", "player previous",
        "brightness up", "brightness down", "mode set islands", "mode set island",
        "app terminal", "app files", "app browser", "window close", "window float", "window fullscreen", "window maximize",
        "window split", "focus left", "focus right", "focus up", "focus down", "scratchpad toggle", "scratchpad send", "session logout"
    ]

    // blur for translucent surfaces and a floating settings window
    readonly property string rules: `
hl.layer_rule({ name = "sweeteh-blur", match = { namespace = "^sweeteh-(bar|island|wallpaper)$" }, blur = true, ignore_alpha = 0.4 })
hl.layer_rule({ name = "sweeteh-blur-dim", match = { namespace = "^sweeteh-(power|modeswitcher|cheatsheet|overview)$" }, blur = true, ignore_alpha = 0.01 })
hl.layer_rule({ name = "sweeteh-no-anim", match = { namespace = "^sweeteh-.*$" }, no_anim = true })
hl.window_rule({ name = "sweeteh-settings", match = { title = "^Sweeteh settings$" }, float = true, size = "980 640", center = true })`

    function luaString(s: string): string {
        return "\"" + String(s).replace(/\\/g, "\\\\").replace(/"/g, "\\\"").replace(/\n/g, " ") + "\"";
    }

    // hyprland actions for windows, focus and apps, everything else is a shell ipc call or exec
    readonly property var dispatchers: ({
            "window close": "hl.dsp.window.close()",
            "window float": "hl.dsp.window.float({ action = \"toggle\" })",
            "window fullscreen": "hl.dsp.window.fullscreen({ mode = \"fullscreen\", action = \"toggle\" })",
            "window maximize": "hl.dsp.window.fullscreen({ mode = \"maximized\", action = \"toggle\" })",
            "window split": "hl.dsp.layout(\"togglesplit\")",
            "focus left": "hl.dsp.focus({ direction = \"left\" })",
            "focus right": "hl.dsp.focus({ direction = \"right\" })",
            "focus up": "hl.dsp.focus({ direction = \"up\" })",
            "focus down": "hl.dsp.focus({ direction = \"down\" })",
            "scratchpad toggle": "hl.dsp.workspace.toggle_special(\"magic\")",
            "scratchpad send": "hl.dsp.window.move({ workspace = \"special:magic\" })",
            "session logout": "hl.dsp.exit()"
        })
    readonly property var apps: ({
            "app terminal": () => Config.options.general.terminal,
            "app files": () => Config.options.general.fileManager,
            "app browser": () => "sh -c 'gtk-launch \"$(xdg-settings get default-web-browser)\"'"
        })
    // binds that keep working when the shell is down are written here and loaded by hyprland.lua
    readonly property string persistPath: (Quickshell.env("XDG_CONFIG_HOME") || Paths.home + "/.config") + "/hypr/sweeteh/binds.lua"

    // lua for what a bind does
    function dispatchFor(action: string): string {
        if (dispatchers[action])
            return dispatchers[action];
        if (apps[action])
            return `hl.dsp.exec_cmd(${luaString(apps[action]())})`;
        return `hl.dsp.exec_cmd(${luaString(commandFor(action))})`;
    }

    // shell actions die with the shell, the rest are worth keeping
    function needsShell(action: string): bool {
        return !dispatchers[action] && !apps[action] && !action.startsWith("exec ");
    }

    // exec actions run a raw command, the rest are shell ipc calls
    function commandFor(action: string): string {
        return action.startsWith("exec ") ? action.slice(5) : ipcPrefix + action;
    }

    // compare combos as a modifier mask plus a lowercase key
    function comboId(keys: string): string {
        const masks = { super: 64, win: 64, mod4: 64, shift: 1, ctrl: 4, control: 4, alt: 8, mod1: 8 };
        let mask = 0;
        let key = "";
        for (const part of keys.split("+").map(p => p.trim().toLowerCase()).filter(p => p !== "")) {
            if (part in masks)
                mask |= masks[part];
            else
                key = part;
        }
        return mask + ":" + key;
    }

    function modsText(mask: int): string {
        const names = [];
        if (mask & 64)
            names.push("Super");
        if (mask & 4)
            names.push("Ctrl");
        if (mask & 8)
            names.push("Alt");
        if (mask & 1)
            names.push("Shift");
        return names.join(" ");
    }

    // while recording a shortcut every key goes to the shell, even ones hyprland has bound
    function capture(on: bool): void {
        Hypr.dispatch(`hl.dsp.submap("${on ? "sweeteh-capture" : "reset"}")`);
    }

    function save(list: var): void {
        Config.set("keybinds", list);
    }

    function refresh(): void {
        reader.running = true;
    }

    // read live binds, drop ours, then bind everything that is still free
    function sync(): void {
        syncing = true;
        reader.running = true;
    }

    function apply(raw: var): void {
        const mine = binds.filter(b => b.keys && b.action);
        const ours = new Set(applied.map(comboId));
        // a bind with our combo and our description is a leftover from an earlier run
        const stale = new Set(mine.map(b => comboId(b.keys) + "|" + (b.description ?? "")));
        const taken = new Set(raw.filter(b => {
            const id = b.modmask + ":" + String(b.key).toLowerCase();
            return !ours.has(id) && !stale.has(id + "|" + b.description);
        }).map(b => b.modmask + ":" + String(b.key).toLowerCase()));

        const lua = [];
        const leftovers = raw.filter(b => stale.has(b.modmask + ":" + String(b.key).toLowerCase() + "|" + b.description));
        for (const keys of applied)
            lua.push(`hl.unbind(${luaString(keys)})`);
        for (const b of leftovers)
            lua.push(`hl.unbind(${luaString((modsText(b.modmask).toUpperCase().split(" ").filter(m => m !== "").concat([b.key])).join(" + "))})`);

        const bound = [];
        const skipped = [];
        const lines = [];
        for (const b of mine) {
            if (taken.has(comboId(b.keys))) {
                skipped.push(b.keys);
                continue;
            }
            bound.push(b);
            // release binds fire when the key comes back up, so a lone super can open things
            lines.push(`hl.bind(${luaString(b.keys)}, ${dispatchFor(b.action)}, { description = ${luaString(b.description ?? "")}${b.release ? ", release = true" : ""} })`);
        }
        lua.push(...lines, rules);
        // the empty capture submap only needs defining once per config load
        if (!submapReady) {
            lua.push(`hl.define_submap("sweeteh-capture", function() hl.bind("SUPER + SHIFT + CTRL + ALT + F24", hl.dsp.submap("reset")) end)`);
            submapReady = true;
        }
        applied = bound.map(b => b.keys);
        conflicts = skipped;
        persist.setText("-- written by sweeteh from its keybind settings, edit them there\n" + lines.join("\n") + "\n");
        cleanup.setText(bound.filter(b => needsShell(b.action)).map(b => `hl.unbind(${luaString(b.keys)})`).join("\n") + "\n");
        Quickshell.execDetached(["hyprctl", "eval", lua.join("\n")]);
        refreshTimer.restart();
    }

    function unbindAll(): void {
        if (applied.length > 0)
            Quickshell.execDetached(["hyprctl", "eval", applied.map(k => `hl.unbind(${luaString(k)})`).join("\n")]);
    }

    onBindsChanged: sync()
    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", persistPath.slice(0, persistPath.lastIndexOf("/"))]);
        sync();
    }
    Component.onDestruction: unbindAll()

    // a config reload wipes runtime binds and rules, so put them back
    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "configreloaded") {
                root.submapReady = false;
                root.sync();
            }
        }
    }

    // sweeteh run and stop feed this to hyprctl once the shell is gone, even after a crash
    FileView {
        id: persist

        path: root.persistPath
        printErrors: false
    }

    FileView {
        id: cleanup

        path: Paths.runtime + "/unbind.lua"
        printErrors: false
    }

    Timer {
        id: refreshTimer

        interval: 300
        onTriggered: root.refresh()
    }

    Process {
        id: reader

        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let raw = [];
                try {
                    raw = JSON.parse(text);
                } catch (e) {}
                root.live = raw.filter(b => b.has_description).map(b => ({
                            mods: root.modsText(b.modmask),
                            key: /^(super|shift|control|ctrl|alt)_[lr]$/i.test(b.key) ? "" : b.key,
                            description: b.description
                        }));
                if (root.syncing) {
                    root.syncing = false;
                    root.apply(raw);
                }
            }
        }
    }
}
