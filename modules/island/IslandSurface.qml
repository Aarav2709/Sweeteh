import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell.Io
import Quickshell.Widgets
import qs.config
import qs.theme
import qs.services
import qs.components
import qs.modules.launcher
import qs.modules.clipboard
import qs.modules.monitor
import qs.modules.media
import qs.modules.osd
import qs.modules.notifications
import qs.modules.power
import qs.modules.wallpaper
import qs.modules.overview
import qs.modules.cheatsheet
import qs.modules.modeswitcher

// the notch fused to the top edge, its size follows whichever content is showing
Item {
    id: root

    property string mode: "idle"
    property string messageIcon
    property string messageText
    property string osdKind
    property var moment: ({ kind: "plugged" })
    property NotifEntry notif
    property int notifGroup: 0
    readonly property bool hovered: hover.hovered
    // the workspace number, or the workspace peek itself, under the pointer
    readonly property bool wsHovered: idle.wsHovered || (mode === "workspaces" && hover.hovered)
    readonly property color base: Theme.color.island
    readonly property Item content: ({ idle: idle, peek: peek, workspaces: workspaces, message: message, glow: glow, osd: osd, track: track, notification: notification, media: media, launcher: launcher, clipboard: clipboard, monitor: monitor, dashboard: dashboard, auth: auth, welcome: welcome })[mode] ?? hostedSlot(mode) ?? idle

    function hostedSlot(id: string): Item {
        for (let i = 0; i < hostedViews.count; i++) {
            const slot = hostedViews.itemAt(i);
            if (slot?.modelData.id === id)
                return slot;
        }
        return null;
    }
    readonly property bool compact: mode === "idle" || mode === "message" || mode === "glow" || mode === "osd" || mode === "track"
    readonly property int pad: mode === "idle" ? 0 : compact ? Theme.spacing.medium : Theme.spacing.large
    readonly property int idleHeight: Config.options.island.height
    // the hover hint eases by itself, the color as a whole has no behavior so a fading moment
    // follows the shrinking island frame by frame instead of trailing behind it
    property real hoverMix: mode === "idle" && idle.hovered ? 1 : 0

    Behavior on hoverMix {
        Anim {
            duration: Theme.anim.fast
        }
    }

    // a download fills the resting island from the left, or a band runs across while its size is unknown
    property real downloadFill: Downloads.progress >= 0 ? Downloads.progress : 0
    property real downloadBand: 0

    Behavior on downloadFill {
        Anim {
            duration: Theme.anim.slow
        }
    }

    NumberAnimation on downloadBand {
        running: Downloads.active && Downloads.progress < 0 && root.mode === "idle"
        loops: Animation.Infinite
        from: -0.3
        to: 1.3
        duration: 1600
        easing.type: Easing.InOutSine
    }

    HoverHandler {
        id: hover
    }

    signal dismissNotification
    signal momentClicked
    signal workspacePicked

    focus: true
    // escape folds whatever the island is showing back to rest, the player answers to space and arrows
    Keys.onEscapePressed: Actions.close("")
    Keys.onPressed: e => {
        if (mode !== "media" && mode !== "dashboard")
            return;
        if (e.key === Qt.Key_Space && mode === "media")
            Media.toggle();
        else if (e.key === Qt.Key_Left && mode === "media")
            Media.previous();
        else if (e.key === Qt.Key_Right && mode === "media")
            Media.next();
        else if (e.key === Qt.Key_Down || e.key === Qt.Key_Tab)
            nextItemInFocusChain(true).forceActiveFocus();
        else
            return;
        e.accepted = true;
    }

    // squash and stretch, the island leans into growing and settles with a little spring
    transform: [
        Scale {
            id: squash

            origin.x: root.width / 2
            origin.y: 0
        },
        // at start the island slides out of the top edge
        // never below zero, a bounce past the edge would leave a gap above the island
        Translate {
            y: Math.min(0, -(1 - root.intro) * (root.height + Theme.depth.offset + 4))
        }
    ]

    // a plain value, not a binding, so a config change can never send the island back off screen
    property real intro: 1

    // started once and left to finish, the bounce overshoots 1 on its way
    SequentialAnimation on intro {
        id: introAnim

        running: false

        PauseAnimation {
            duration: 250
        }

        NumberAnimation {
            to: 1
            duration: 650
            easing.type: Easing.OutBack
            easing.overshoot: 1.4
        }
    }

    property real lastWidth: 0

    onModeChanged: {
        const next = content.implicitWidth + pad * 2;
        if (Config.options.island.squash && Theme.anim.speed > 0 && Math.abs(next - lastWidth) > 8) {
            wobble.grow = next > lastWidth;
            wobble.restart();
        }
        lastWidth = next;
    }

    SequentialAnimation {
        id: wobble

        property bool grow: true

        ParallelAnimation {
            NumberAnimation {
                target: squash
                property: "xScale"
                to: wobble.grow ? 1.035 : 0.97
                duration: 150
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                target: squash
                property: "yScale"
                to: wobble.grow ? 0.95 : 1.04
                duration: 150
                easing.type: Easing.OutQuad
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: squash
                property: "xScale"
                to: 1
                duration: 380
                easing.type: Easing.OutBack
                easing.overshoot: 2.2
            }

            NumberAnimation {
                target: squash
                property: "yScale"
                to: 1
                duration: 380
                easing.type: Easing.OutBack
                easing.overshoot: 2.2
            }
        }
    }

    Component.onCompleted: {
        lastWidth = implicitWidth;
        if (Config.options.island.intro && Theme.anim.speed > 0) {
            intro = 0;
            introAnim.start();
        }
    }

    implicitWidth: content.implicitWidth + pad * 2
    implicitHeight: Math.max(idleHeight, content.implicitHeight + pad * 2)
    width: implicitWidth
    height: implicitHeight

    Behavior on width {
        enabled: Theme.anim.speed > 0

        Spring {}
    }

    Behavior on height {
        enabled: Theme.anim.speed > 0

        Spring {}
    }

    // how bright the light under the island burns, it breathes with the bass and flares on a moment
    readonly property real backlight: Math.min(1, 0.45 + (Cava.active ? Cava.bass * 0.55 : Media.playing ? 0.1 : 0) + glowView.glow * 0.4 + glowView.shine * 0.3 + keyFlare * 0.5)

    // every key typed into the island flashes the light under it, the signature of the shell
    property real keyFlare: 0

    NumberAnimation on keyFlare {
        id: flare

        running: false
        from: 1
        to: 0
        duration: 520
        easing.type: Easing.OutCubic
    }

    Connections {
        target: Actions

        function onKeystroke(): void {
            if (Theme.anim.speed > 0)
                flare.restart();
        }
    }

    // the bloom, the island's own light spilling onto the desktop below it
    NotchShape {
        anchors.fill: parent
        anchors.topMargin: Theme.depth.offset * 2
        anchors.bottomMargin: -Theme.depth.offset * 2 - root.keyFlare * 10
        visible: Theme.depth.backlit && !Perf.active
        opacity: root.backlight * 0.8
        color: Theme.color.backlight
        radius: shape.radius
        flare: 0
        layer.enabled: visible
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 40
            blur: 1
            autoPaddingEnabled: true
        }

        Behavior on opacity {
            Anim {
                duration: Theme.anim.fast
            }
        }
    }

    // the ledge under the notch for the raised look, lit at its lower edge when backlit
    NotchShape {
        anchors.fill: parent
        anchors.topMargin: Theme.depth.offset
        anchors.bottomMargin: -Theme.depth.offset
        visible: Theme.depth.on
        radius: shape.radius
        flare: shape.flare
        gradient: LinearGradient {
            y1: 0
            y2: root.height
            x1: 0
            x2: 0

            GradientStop {
                position: 0
                color: Theme.color.depthShadow
            }

            GradientStop {
                position: 0.75
                color: Theme.color.depthShadow
            }

            GradientStop {
                position: 1
                color: Theme.mix(Theme.color.depthShadow, Theme.color.depthLit, 0.5 + root.backlight * 0.5)
            }
        }
    }

    NotchShape {
        id: shape

        anchors.fill: parent
        // a hint that the resting island opens the dashboard
        // a moment blushes the notch with its state color
        color: Theme.mix(Theme.mix(root.base, Theme.color.ink, 0.07 * root.hoverMix), Qt.alpha(glowView.blush, 1), glowView.glow * glowView.strength)
        rimWidth: Theme.depth.rim
        radius: root.compact ? Math.min(height / 2, Theme.radius.medium) : Theme.radius.xl
        flare: root.compact ? Theme.radius.flare / 2 : Theme.radius.flare

        Behavior on radius {
            Anim {
                duration: Theme.anim.slow
            }
        }

        Behavior on flare {
            Anim {
                duration: Theme.anim.slow
            }
        }
    }

    NotchShape {
        anchors.fill: parent
        visible: opacity > 0
        opacity: Downloads.active && root.mode === "idle" ? 1 : 0
        radius: shape.radius
        flare: shape.flare
        gradient: LinearGradient {
            id: dl

            readonly property bool known: Downloads.progress >= 0
            readonly property color blue: Qt.alpha(Theme.color.primary, 0.4)

            x1: known ? 0 : (root.downloadBand - 0.3) * root.width
            x2: known ? root.width : (root.downloadBand + 0.3) * root.width
            y1: 0
            y2: 0

            GradientStop {
                position: 0
                color: dl.known ? dl.blue : "transparent"
            }

            GradientStop {
                position: dl.known ? root.downloadFill : 0.5
                color: dl.blue
            }

            GradientStop {
                position: dl.known ? Math.min(1, root.downloadFill + 0.004) : 1
                color: "transparent"
            }
        }

        Behavior on opacity {
            Anim {}
        }
    }

    // the light that swells from inside on a moment, drawn in the notch outline so it keeps the corners
    NotchShape {
        anchors.fill: parent
        visible: glowView.shine > 0
        opacity: glowView.shine
        radius: shape.radius
        flare: shape.flare
        rimWidth: 1.5
        rim: Qt.alpha(Qt.lighter(glowView.accent, 1.3), 0.8)
        gradient: RadialGradient {
            centerX: root.width / 2
            centerY: root.height / 2
            centerRadius: root.width * 0.6
            focalX: centerX
            focalY: centerY

            GradientStop {
                position: 0
                color: Qt.alpha(glowView.accent, 0.5)
            }

            GradientStop {
                position: 1
                color: "transparent"
            }
        }
    }

    Item {
        anchors.fill: parent
        clip: true

        IslandIdle {
            id: idle

            anchors.centerIn: parent
            shown: root.mode === "idle"
        }

        IslandSlot {
            id: workspaces

            shown: root.mode === "workspaces"

            Loader {
                active: workspaces.shown

                sourceComponent: IslandWorkspaces {
                    onPicked: root.workspacePicked()
                }
            }
        }

        IslandSlot {
            id: peek

            shown: root.mode === "peek"

            IslandPeek {}
        }

        IslandSlot {
            id: message

            shown: root.mode === "message"

            RowLayout {
                spacing: Theme.spacing.small

                Icon {
                    name: root.messageIcon || "info"
                    fill: 1
                    color: Theme.color.primary
                }

                Label {
                    Layout.maximumWidth: 520
                    text: root.messageText
                    font.weight: Font.Medium
                }
            }
        }

        IslandSlot {
            id: glow

            shown: root.mode === "glow"

            IslandGlow {
                id: glowView

                shown: glow.shown
                moment: root.moment
                onClicked: root.momentClicked()
            }
        }

        IslandSlot {
            id: track

            shown: root.mode === "track"

            RowLayout {
                spacing: Theme.spacing.medium

                ClippingRectangle {
                    implicitWidth: 40
                    implicitHeight: 40
                    radius: Theme.radius.small
                    color: Theme.color.secondaryContainer

                    Image {
                        anchors.fill: parent
                        source: Media.art
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize: Qt.size(80, 80)
                    }
                }

                ColumnLayout {
                    spacing: 0

                    Label {
                        Layout.maximumWidth: 340
                        text: Media.title
                        font.weight: Font.DemiBold
                    }

                    Label {
                        Layout.maximumWidth: 340
                        visible: text !== ""
                        text: Media.artist
                        font.pixelSize: Theme.font.small
                        color: Theme.color.inkMeta
                    }
                }

                Icon {
                    name: "graphic_eq"
                    color: Theme.color.primary
                }
            }
        }

        IslandSlot {
            id: osd

            shown: root.mode === "osd"

            OsdView {
                kind: root.osdKind
            }
        }

        IslandSlot {
            id: notification

            shown: root.mode === "notification"

            NotificationCard {
                implicitWidth: Theme.size.panelWidth
                width: Theme.size.panelWidth
                entry: root.notif
                groupCount: root.notifGroup
                onExpandGroup: Actions.open("island")
                onEntryChanged: expanded = false
            }
        }

        IslandSlot {
            id: media

            shown: root.mode === "media"

            // heavy views load on first open and unload a while after closing
            Loader {
                active: media.shown || media.visible || mediaKeep.running

                sourceComponent: MediaView {}
            }

            Timer {
                id: mediaKeep

                interval: 20000
            }

            onShownChanged: {
                if (!shown)
                    mediaKeep.restart();
            }
        }

        IslandSlot {
            id: dashboard

            shown: root.mode === "dashboard"

            Loader {
                id: dashboardView

                active: dashboard.shown || dashboard.visible || dashboardKeep.running
                sourceComponent: IslandDashboard {}
                onLoaded: openPage()

                // a page asked for by the palette, taken once
                function openPage(): void {
                    if (item && Actions.dashboardPage !== "") {
                        item.page = Actions.dashboardPage;
                        Actions.dashboardPage = "";
                    }
                }
            }

            Timer {
                id: dashboardKeep

                interval: 20000
            }

            onShownChanged: {
                if (shown) {
                    dashboardView.openPage();
                } else {
                    dashboardKeep.restart();
                    if (dashboardView.item)
                        dashboardView.item.page = "";
                }
            }
        }

        IslandSlot {
            id: auth

            shown: root.mode === "auth"

            IslandAuth {
                id: authView
            }

            onShownChanged: {
                if (shown)
                    authView.reset();
            }
        }

        IslandSlot {
            id: clipboard

            shown: root.mode === "clipboard"

            ClipboardView {
                id: clipboardView

                onDone: Actions.close("clipboard")
            }

            onShownChanged: {
                if (shown)
                    clipboardView.reset();
            }
        }

        IslandSlot {
            id: monitor

            shown: root.mode === "monitor"

            MonitorView {
                active: monitor.shown
            }
        }

        IslandSlot {
            id: launcher

            shown: root.mode === "launcher"

            LauncherView {
                id: launcherView

                active: launcher.visible

                onDone: Actions.close("launcher")
            }

            onShownChanged: {
                if (shown)
                    launcherView.reset();
            }
        }

        IslandSlot {
            id: welcome

            shown: root.mode === "welcome"

            Loader {
                active: welcome.shown || welcome.visible

                sourceComponent: IslandWelcome {
                    onDone: {
                        welcomed.setText("1");
                        Actions.close("welcome");
                    }
                }
                onLoaded: item.reset()
            }

            FileView {
                id: welcomed

                path: Paths.state + "/welcomed"
                printErrors: false
            }
        }

        // the old panels, each loads when it opens and resets itself as it shows
        Repeater {
            id: hostedViews

            model: [
                { id: "power", view: powerView },
                { id: "wallpaper", view: wallpaperView },
                { id: "overview", view: overviewView },
                { id: "cheatsheet", view: cheatsheetView },
                { id: "modeswitcher", view: modeSwitcherView }
            ]

            IslandSlot {
                id: hostedSlot

                required property var modelData

                shown: root.mode === modelData.id

                Loader {
                    id: hostedLoader

                    active: hostedSlot.shown || hostedSlot.visible
                    sourceComponent: hostedSlot.modelData.view
                    onLoaded: {
                        if (hostedSlot.shown)
                            item.reset();
                    }
                }

                onShownChanged: {
                    if (shown && hostedLoader.item)
                        hostedLoader.item.reset();
                }
            }
        }

        Component {
            id: powerView

            PowerView {}
        }

        Component {
            id: wallpaperView

            WallpaperView {}
        }

        Component {
            id: overviewView

            OverviewView {}
        }

        Component {
            id: cheatsheetView

            CheatsheetView {}
        }

        Component {
            id: modeSwitcherView

            ModeSwitcherView {}
        }
    }
}
