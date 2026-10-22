pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// material colors from matugen output, falling back to the bundled palette
Singleton {
    id: root

    readonly property string generatedPath: Paths.state + "/colors.json"
    property var palette: ({})
    readonly property string mode: Config.options.theme.dark ? "dark" : "light"

    function pick(name: string): color {
        const entry = palette[name];
        return entry ? entry[mode].color : "transparent";
    }

    function load(text: string): bool {
        try {
            const parsed = JSON.parse(text);
            if (!parsed.colors)
                return false;
            palette = parsed.colors;
            return true;
        } catch (e) {
            return false;
        }
    }

    FileView {
        id: generated

        path: root.generatedPath
        watchChanges: true
        blockLoading: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            if (!root.load(text()))
                root.load(fallback.text());
        }
        onLoadFailed: root.load(fallback.text())
    }

    FileView {
        id: fallback

        path: Quickshell.shellPath("theme/fallback.json")
        blockLoading: true
    }
}
