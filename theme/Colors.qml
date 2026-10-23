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
    property var previous: null
    property real blend: 1

    NumberAnimation on blend {
        id: fade

        running: false
        from: 0
        to: 1
        duration: 900
        easing.type: Easing.InOutQuad
    }
    readonly property string mode: Config.options.theme.dark ? "dark" : "light"

    function raw(set: var, name: string): color {
        const entry = set?.[name];
        return entry ? entry[mode].color : "transparent";
    }

    function pick(name: string): color {
        const now = raw(palette, name);
        if (blend >= 1 || !previous)
            return now;
        const was = raw(previous, name);
        return Qt.rgba(was.r + (now.r - was.r) * blend, was.g + (now.g - was.g) * blend, was.b + (now.b - was.b) * blend, was.a + (now.a - was.a) * blend);
    }

    function load(text: string): bool {
        try {
            const parsed = JSON.parse(text);
            if (!parsed.colors)
                return false;
            // the first palette lands as is, later ones fade in
            const first = Object.keys(palette).length === 0;
            previous = first ? null : palette;
            palette = parsed.colors;
            if (!first) {
                blend = 0;
                fade.restart();
            }
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
