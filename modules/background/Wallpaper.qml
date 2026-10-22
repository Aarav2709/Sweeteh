import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.theme
import qs.services
import qs.components

// wallpaper layer with fade, circle, wipe and zoom transitions
// live wallpapers play on top of their still frame once the transition is done
PanelWindow {
    id: root

    required property var modelData
    readonly property string path: Wallpapers.still
    readonly property string live: Wallpapers.isAnimated(Wallpapers.current) || (Wallpapers.isVideo(Wallpapers.current) && Wallpapers.videoSupport) ? Wallpapers.current : ""
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    // nobody sees the wallpaper under a fullscreen window, so playback rests
    readonly property bool covered: monitor?.activeWorkspace?.toplevels.values.some(t => (t.lastIpcObject?.fullscreen ?? 0) > 0) ?? false
    readonly property string transition: Config.options.wallpaper.transition
    property real progress: 1

    screen: modelData
    color: Theme.color.surface
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "sweeteh-wallpaper"
    WlrLayershell.layer: WlrLayer.Background
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    onPathChanged: {
        if (path === "")
            return;
        if (current.source.toString() === "") {
            current.source = Paths.url(path);
            return;
        }
        incoming.source = Paths.url(path);
    }

    Component.onCompleted: {
        if (path !== "")
            current.source = Paths.url(path);
    }

    Image {
        id: current

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize: Qt.size(root.width * (root.screen?.devicePixelRatio ?? 1), root.height * (root.screen?.devicePixelRatio ?? 1))
    }

    Image {
        id: incoming

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        visible: false
        sourceSize: current.sourceSize
        onStatusChanged: {
            if (status === Image.Ready) {
                root.progress = 0;
                reveal.restart();
            }
        }
    }

    // circle and wipe use a mask, fade and zoom draw the image directly
    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            visible: root.transition === "circle"
            readonly property real r: Math.hypot(root.width, root.height) * root.progress
            width: r * 2
            height: r * 2
            radius: r
            x: root.width / 2 - r
            y: root.height / 2 - r
        }

        Rectangle {
            visible: root.transition === "wipe"
            width: root.width * root.progress
            height: root.height
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: incoming
        visible: root.progress < 1 && (root.transition === "circle" || root.transition === "wipe")
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }

    Image {
        anchors.fill: parent
        visible: root.progress < 1 && (root.transition === "fade" || root.transition === "zoom")
        source: incoming.source
        fillMode: Image.PreserveAspectCrop
        sourceSize: current.sourceSize
        opacity: root.progress
        scale: root.transition === "zoom" ? 1.08 - 0.08 * root.progress : 1
    }

    Loader {
        id: liveLayer

        anchors.fill: parent
        active: root.live !== "" && root.progress >= 1
        opacity: status === Loader.Ready ? 1 : 0
        source: Wallpapers.isVideo(root.live) ? "LiveVideo.qml" : ""
        sourceComponent: Wallpapers.isAnimated(root.live) ? gif : undefined
        onLoaded: {
            item.source = Paths.url(root.live);
            item.paused = Qt.binding(() => root.covered);
        }

        Behavior on opacity {
            Anim {
                duration: Theme.anim.slow
            }
        }
    }

    Component {
        id: gif

        AnimatedImage {
            property bool paused: false

            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            playing: !paused
        }
    }

    NumberAnimation {
        id: reveal

        target: root
        property: "progress"
        from: 0
        to: 1
        duration: Theme.anim.speed > 0 ? Config.options.wallpaper.duration / Theme.anim.speed : 0
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Theme.anim.emphasized
        onFinished: {
            current.source = incoming.source;
            incoming.source = "";
        }
    }
}
