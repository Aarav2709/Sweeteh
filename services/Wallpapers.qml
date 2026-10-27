pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.theme

// wallpaper list, current wallpaper and matugen recolor
Singleton {
    id: root

    readonly property string dir: Paths.expand(Config.options.general.wallpaperDir)
    readonly property string current: Config.options.wallpaper.path
    // a still frame of the current wallpaper, for colors, the lockscreen and transitions
    readonly property string still: !isVideo(current) ? current : stillFor === current ? poster(current) : ""
    property string stillFor: ""

    // the wallpaper's own average color, unmuted, for the desktop widgets
    ColorQuantizer {
        id: quantizer

        source: root.still ? "file://" + root.still.replace(/^file:\/\//, "") : ""
        depth: 3
        rescaleSize: 96
    }

    Binding {
        target: Theme
        property: "wallpaper"
        value: root.signature(quantizer.colors)
        when: quantizer.colors.length > 0
    }
    // the wallpaper's signature color, the most colorful of its main colors that is neither near black nor near white
    // an average would turn a red and black wallpaper into mud, a grey wallpaper still gives grey
    function signature(colors: list<color>): color {
        let best = colors[0] ?? "#000000", score = -1;
        for (const c of colors) {
            const s = c.hslSaturation * (1 - Math.min(1, Math.abs(c.hslLightness - 0.5) * 1.6));
            if (s > score) {
                score = s;
                best = c;
            }
        }
        return best;
    }

    // video wallpapers need the multimedia module, checked once at start
    property bool videoSupport: false
    property list<string> files: []
    property bool generating: false
    // bumped when new poster frames land so thumbnails reload
    property int posters: 0

    function isVideo(path: string): bool {
        return /\.(mp4|webm|mkv|mov|avi)$/i.test(path);
    }

    function isAnimated(path: string): bool {
        return /\.gif$/i.test(path);
    }

    function isLive(path: string): bool {
        return isVideo(path) || isAnimated(path);
    }

    function poster(path: string): string {
        return Paths.cache + "/posters/" + path.replace(/[^a-zA-Z0-9]/g, "_") + ".jpg";
    }

    // small frame for the picker, videos only
    function thumb(path: string): string {
        return isVideo(path) ? Paths.cache + "/thumbs/" + path.replace(/[^a-zA-Z0-9]/g, "_") + ".jpg" : path;
    }

    function refresh(): void {
        lister.running = true;
    }

    function set(path: string): void {
        Config.set("wallpaper.path", path);
        recolor(path);
        if (isVideo(path) && !videoSupport)
            Actions.say("movie", "Install qt6 multimedia to play video wallpapers.");
    }

    function random(): void {
        if (files.length > 0)
            set(files[Math.floor(Math.random() * files.length)]);
    }

    // write both palettes to the state file, then run user templates
    function recolor(path: string): void {
        const t = Config.options.theme;
        if (!t.fromWallpaper || !path)
            return;
        // matugen reads images only, so videos color from their still frame
        if (isVideo(path)) {
            if (stillFor === path)
                runMatugen(["image", poster(path)]);
            else
                stillMaker.recolorAfter = true;
            return;
        }
        runMatugen(["image", path]);
    }

    function makeStill(): void {
        if (!isVideo(current))
            return;
        const out = poster(current);
        stillMaker.forPath = current;
        stillMaker.command = ["sh", "-c", `mkdir -p ${Paths.quote(Paths.cache + "/posters")} && { [ -s ${Paths.quote(out)} ] || ffmpeg -loglevel error -y -ss 1 -i ${Paths.quote(current)} -frames:v 1 -vf scale=1920:-2 ${Paths.quote(out)}; }`];
        stillMaker.running = true;
    }

    onCurrentChanged: makeStill()

    function recolorFromAccent(): void {
        runMatugen(["color", "hex", Config.options.theme.accent]);
    }

    function runMatugen(source: list<string>): void {
        const t = Config.options.theme;
        const out = Paths.state + "/colors.json";
        const base = ["matugen", ...source, "-t", t.scheme, "-m", t.dark ? "dark" : "light", "--prefer", "saturation"];
        let cmd = `${base.map(Paths.quote).join(" ")} -j hex --dry-run > ${Paths.quote(out + ".tmp")} && mv ${Paths.quote(out + ".tmp")} ${Paths.quote(out)}`;
        if (t.matugenConfig)
            cmd += ` && ${base.map(Paths.quote).join(" ")} -c ${Paths.quote(Paths.expand(t.matugenConfig))} -q`;
        matugen.command = ["sh", "-c", cmd];
        generating = true;
        matugen.running = true;
    }

    Process {
        id: lister

        command: ["find", "-L", root.dir, "-maxdepth", "3", "-type", "f", "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", "-o", "-iname", "*.bmp", "-o", "-iname", "*.gif", "-o", "-iname", "*.mp4", "-o", "-iname", "*.webm", "-o", "-iname", "*.mkv", "-o", "-iname", "*.mov", ")"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.files = text.split("\n").filter(l => l !== "").sort();
                // a fresh install starts on a random wallpaper instead of a blank screen
                const stills = root.files.filter(f => !root.isLive(f));
                if (root.current === "" && stills.length > 0)
                    root.set(stills[Math.floor(Math.random() * stills.length)]);
                const videos = root.files.filter(f => root.isVideo(f));
                if (videos.length === 0)
                    return;
                // poster frames for picker thumbnails, made once and cached
                const jobs = videos.map(v => `[ -f ${Paths.quote(root.thumb(v))} ] || ffmpeg -loglevel error -y -ss 1 -i ${Paths.quote(v)} -frames:v 1 -vf scale=480:-2 ${Paths.quote(root.thumb(v))}`);
                posterMaker.command = ["sh", "-c", `mkdir -p ${Paths.quote(Paths.cache + "/thumbs")}; ${jobs.join("; ")}`];
                posterMaker.running = true;
            }
        }
    }

    Process {
        id: posterMaker

        onExited: root.posters++
    }

    Process {
        id: stillMaker

        property string forPath
        property bool recolorAfter: false

        onExited: code => {
            if (code !== 0) {
                Actions.say("hide_image", "Could not read that video.");
                return;
            }
            root.stillFor = forPath;
            if (recolorAfter && forPath === root.current) {
                recolorAfter = false;
                root.recolor(forPath);
            }
        }
    }

    Process {
        running: true
        command: ["sh", "-c", "for d in /usr/lib/qt6/qml /usr/lib64/qt6/qml /usr/lib/qt/qml $(echo \"$QML_IMPORT_PATH\" | tr ':' ' '); do [ -d \"$d/QtMultimedia\" ] && exit 0; done; exit 1"]
        onExited: code => root.videoSupport = code === 0
    }

    Process {
        id: matugen

        onExited: code => {
            root.generating = false;
            if (code !== 0)
                Actions.say("palette", "Could not recolor from this wallpaper.");
        }
    }

    // the folder may change while the shell runs
    onDirChanged: refresh()
    Component.onCompleted: {
        refresh();
        makeStill();
    }

    Connections {
        target: Config

        function onOptionsChanged(): void {
            const t = Config.options.theme;
            const sig = [t.dark, t.scheme, t.fromWallpaper, t.accent].join();
            if (sig === root.themeSig)
                return;
            const first = root.themeSig === "";
            root.themeSig = sig;
            if (first)
                return;
            if (t.fromWallpaper)
                root.recolor(root.current);
            else
                root.recolorFromAccent();
        }
    }

    property string themeSig: ""

    IpcHandler {
        target: "wallpapers"

        function set(path: string): void {
            root.set(path);
        }

        function random(): void {
            root.random();
        }

        function get(): string {
            return root.current;
        }

        function recolor(): void {
            root.recolor(root.current);
        }
    }
}
