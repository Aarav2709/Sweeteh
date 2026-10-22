pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// merged options from config json over defaults, hot reloaded
Singleton {
    id: root

    readonly property string path: Paths.config + "/config.json"
    property var user: ({})
    property var options: Defaults.values

    function merge(def: var, usr: var, at: string): var {
        if (Array.isArray(def))
            return Array.isArray(usr) ? usr : def;
        if (def !== null && typeof def === "object") {
            const src = usr && typeof usr === "object" && !Array.isArray(usr) ? usr : {};
            const out = {};
            for (const k in def)
                out[k] = merge(def[k], src[k], at ? at + "." + k : k);
            return out;
        }
        if (usr === undefined || usr === null)
            return def;
        return typeof usr === typeof def ? usr : def;
    }

    function apply(text: string): void {
        let parsed = {};
        try {
            parsed = text.trim() ? JSON.parse(text) : {};
        } catch (e) {
            console.warn("config json is invalid, keeping previous options:", e);
            return;
        }
        user = parsed;
        options = merge(Defaults.values, parsed, "");
    }

    function get(key: string): var {
        return key.split(".").reduce((o, k) => o === undefined || o === null ? undefined : o[k], options);
    }

    // write one dotted key into the user file, the watcher applies it
    function set(key: string, value: var): void {
        const next = JSON.parse(JSON.stringify(user));
        const parts = key.split(".");
        let node = next;
        for (let i = 0; i < parts.length - 1; i++) {
            if (typeof node[parts[i]] !== "object" || node[parts[i]] === null || Array.isArray(node[parts[i]]))
                node[parts[i]] = {};
            node = node[parts[i]];
        }
        node[parts[parts.length - 1]] = value;
        save(next);
    }

    function reset(key: string): void {
        const next = JSON.parse(JSON.stringify(user));
        const parts = key.split(".");
        let node = next;
        for (let i = 0; i < parts.length - 1 && node; i++)
            node = node[parts[i]];
        if (node)
            delete node[parts[parts.length - 1]];
        save(next);
    }

    function save(next: var): void {
        user = next;
        options = merge(Defaults.values, next, "");
        file.setText(JSON.stringify(next, null, 2) + "\n");
    }

    FileView {
        id: file

        path: root.path
        watchChanges: true
        blockLoading: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.apply(text())
        onLoadFailed: root.apply("{}")
    }

    IpcHandler {
        target: "config"

        function get(key: string): string {
            return JSON.stringify(root.get(key));
        }

        function set(key: string, value: string): void {
            let parsed = value;
            try {
                parsed = JSON.parse(value);
            } catch (e) {}
            root.set(key, parsed);
        }

        function reset(key: string): void {
            root.reset(key);
        }
    }
}
