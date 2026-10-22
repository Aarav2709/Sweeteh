pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// the current mode, islands or island, switched live through config
Singleton {
    id: root

    readonly property var modes: Config.options.modes
    readonly property list<string> names: Object.keys(modes)
    readonly property string current: modes[Config.options.mode] ? Config.options.mode : names[0]
    readonly property var mode: modes[current]
    readonly property list<string> enabledIds: mode.modules
    // the bar splits into floating pills around the island
    readonly property bool islands: mode.bar

    // the mode alone decides whether the bar exists, the island is always there
    function enabled(id: string): bool {
        if (id === "bar")
            return mode.bar;
        if (id === "island")
            return true;
        return enabledIds.includes(id);
    }

    function set(name: string): bool {
        if (!modes[name])
            return false;
        Config.set("mode", name);
        return true;
    }

    function cycle(): void {
        set(names[(names.indexOf(current) + 1) % names.length]);
    }

    // enable or disable a module inside the current mode
    function setModule(id: string, on: bool): void {
        const list = enabledIds.filter(m => m !== id);
        if (on)
            list.push(id);
        Config.set("modes." + current + ".modules", list);
    }

    IpcHandler {
        target: "mode"

        function set(name: string): string {
            return root.set(name) ? "" : "Unknown mode.";
        }

        function cycle(): void {
            root.cycle();
        }

        function get(): string {
            return root.current;
        }

        function list(): string {
            return root.names.join("\n");
        }
    }

    IpcHandler {
        target: "modules"

        function enable(id: string): void {
            root.setModule(id, true);
        }

        function disable(id: string): void {
            root.setModule(id, false);
        }

        function toggle(id: string): void {
            root.setModule(id, !root.enabledIds.includes(id));
        }

        function list(): string {
            return Registry.modules.map(m => (root.enabled(m.id) ? "on  " : "off ") + m.id).join("\n");
        }
    }
}
