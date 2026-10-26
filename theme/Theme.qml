pragma Singleton

import QtQuick
import Quickshell
import qs.config

// design tokens shared by every module
Singleton {
    id: root

    readonly property var opts: Config.options.theme
    readonly property real panelOpacity: Math.max(0.3, Math.min(1, opts.panelOpacity))
    readonly property bool dark: opts.dark
    // the cover of the playing song takes over the accent roles, both fade so nothing jumps
    property color song: "#7c9cff"
    property bool songOn: false
    property real songMix: songOn ? 1 : 0

    Behavior on songMix {
        NumberAnimation {
            duration: 900
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on song {
        ColorAnimation {
            duration: 900
        }
    }

    // the wallpaper's real color, red stays red and black stays black, kept dark or light enough for text
    property color wallpaper: "#000000"
    readonly property color wallpaperSurface: Qt.hsla(Math.max(0, wallpaper.hslHue), Math.min(1, wallpaper.hslSaturation * 1.25), dark ? Math.max(0.05, Math.min(0.26, wallpaper.hslLightness)) : Math.max(0.82, Math.min(0.94, wallpaper.hslLightness)), panelOpacity)

    Behavior on wallpaper {
        ColorAnimation {
            duration: 900
        }
    }

    // a color at a fixed lightness, so text on it keeps its contrast whatever cover it came from
    function tone(c: color, light: real, sat: real): color {
        return Qt.hsla(Math.max(0, c.hslHue), Math.max(0, Math.min(1, Math.max(0.3, Math.min(0.9, c.hslSaturation)) * sat)), light, 1);
    }

    readonly property ColorSet color: ColorSet {}
    readonly property ColorSet wall: ColorSet {
        follow: false
    }
    readonly property real islandTint: Math.max(0, Math.min(1, Config.options.island.wallpaperTint))

    // readable label from a camel case or dashed key
    function humanize(key: string): string {
        const words = String(key).replace(/^scheme-/, "").replace(/[-_]/g, " ").replace(/([a-z])([A-Z0-9])/g, "$1 $2").toLowerCase();
        return words.charAt(0).toUpperCase() + words.slice(1);
    }

    // blend two colors, amount is how much of b is used
    function mix(a: color, b: color, amount: real): color {
        return Qt.rgba(a.r + (b.r - a.r) * amount, a.g + (b.g - a.g) * amount, a.b + (b.b - a.b) * amount, a.a + (b.a - a.a) * amount);
    }

    readonly property QtObject radius: QtObject {
        readonly property real scale: Math.max(0, root.opts.roundness)
        readonly property int xs: Math.round(6 * scale)
        readonly property int small: Math.round(10 * scale)
        readonly property int medium: Math.round(14 * scale)
        readonly property int large: Math.round(20 * scale)
        readonly property int xl: Math.round(26 * scale)
        readonly property int full: scale > 0 ? 999 : 0
        // concave join between a drawer and the edge it grows from
        readonly property int flare: Math.round(18 * scale)
    }

    readonly property QtObject spacing: QtObject {
        readonly property real scale: Math.max(0.5, root.opts.spacing)
        readonly property int xxs: Math.round(2 * scale)
        readonly property int xs: Math.round(4 * scale)
        readonly property int small: Math.round(8 * scale)
        readonly property int medium: Math.round(12 * scale)
        readonly property int large: Math.round(16 * scale)
        readonly property int xl: Math.round(20 * scale)
        readonly property int xxl: Math.round(28 * scale)
    }

    readonly property QtObject font: QtObject {
        readonly property real scale: Math.max(0.6, root.opts.fontScale)
        readonly property string family: root.opts.fontFamily
        readonly property string mono: root.opts.monoFamily
        readonly property string icon: "Material Symbols Rounded"
        // softness of letter ends on fonts that have a round axis
        readonly property int round: Math.max(0, Math.min(100, root.opts.fontRound))
        readonly property int tiny: Math.round(11 * scale)
        readonly property int small: Math.round(12 * scale)
        // one size for every bar label so pills read evenly
        readonly property int bar: Math.round(13 * scale)
        readonly property int body: Math.round(14 * scale)
        readonly property int large: Math.round(16 * scale)
        readonly property int title: Math.round(20 * scale)
        readonly property int headline: Math.round(26 * scale)
        readonly property int display: Math.round(46 * scale)
        readonly property int hero: Math.round(88 * scale)
    }

    readonly property QtObject size: QtObject {
        readonly property int icon: Math.round(18 * root.font.scale)
        readonly property int iconLarge: Math.round(24 * root.font.scale)
        readonly property int button: 34
        readonly property int buttonLarge: 44
        readonly property int toggle: 56
        readonly property int slider: 36
        readonly property int barWidget: Math.max(22, Config.options.bar.size - 12)
        readonly property int panelWidth: 380
        readonly property int launcherWidth: 600
        readonly property int border: 1
        readonly property int shadow: 20
    }

    readonly property QtObject anim: QtObject {
        readonly property real speed: Math.max(0, root.opts.animationSpeed)
        readonly property int fast: speed > 0 ? Math.round(180 / speed) : 0
        readonly property int normal: speed > 0 ? Math.round(320 / speed) : 0
        readonly property int slow: speed > 0 ? Math.round(450 / speed) : 0
        readonly property int extraSlow: speed > 0 ? Math.round(650 / speed) : 0

        // material 3 expressive motion curves
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> emphasized: [0.05, 0, 0.133, 0.06, 0.166, 0.4, 0.208, 0.82, 0.25, 1, 1, 1]
        readonly property list<real> decel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property list<real> accel: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property list<real> spatial: [0.34, 1.56, 0.4, 1, 1, 1]
        readonly property list<real> spatialFast: [0.3, 1.8, 0.4, 0.95, 1, 1]
        // physics for things that should land with a bounce, stiffer as the speed setting rises
        readonly property real spring: 3.4 * speed * speed
        readonly property real damping: 0.24
        // content blurs while it fades so moves read as motion, off in perf mode
        readonly property bool blur: speed > 0 && root.opts.motionBlur
    }

    // raised 2.5d look, a crisp rim and a hard shadow that pressed surfaces sink into
    readonly property QtObject depth: QtObject {
        readonly property bool on: root.opts.depth
        readonly property int offset: on ? 4 : 0
        readonly property int rim: on ? 1 : 0
        // keys lit from below, the light spills out under each one and blooms under the island
        readonly property bool backlit: on && root.opts.style !== "classic"
    }

    // state layer opacities for hover and press feedback
    readonly property QtObject state: QtObject {
        readonly property real hover: 0.08
        readonly property real press: 0.14
        readonly property real disabled: 0.38
    }
}
