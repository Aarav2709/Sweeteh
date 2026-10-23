import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
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

// the notch fused to the top edge, its size follows whichever content is showing
Item {
    id: root

    property string mode: "idle"
    property string messageIcon
    property string messageText
    property string osdKind
    property var moment: ({ kind: "plugged" })
    property NotifEntry notif
    readonly property Item content: ({ idle: idle, message: message, glow: glow, osd: osd, track: track, notification: notification, media: media, launcher: launcher, clipboard: clipboard, monitor: monitor, dashboard: dashboard, auth: auth })[mode] ?? idle
    readonly property bool compact: mode === "idle" || mode === "message" || mode === "glow" || mode === "osd" || mode === "track"
    readonly property int pad: mode === "idle" ? 0 : compact ? Theme.spacing.medium : Theme.spacing.large
    readonly property int idleHeight: Config.options.island.height
    // the cover of the playing track tints the island and lights its rim
    property real music: Media.playing && Media.hasAccent && ["idle", "track", "media", "osd", "message"].includes(mode) ? 1 : 0

    Behavior on music {
        Anim {
            duration: Theme.anim.extraSlow
        }
    }

    signal dismissNotification

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

    implicitWidth: content.implicitWidth + pad * 2
    implicitHeight: Math.max(idleHeight, content.implicitHeight + pad * 2)
    width: implicitWidth
    height: implicitHeight

    Behavior on width {
        Anim {
            duration: Theme.anim.slow
            easing.bezierCurve: Theme.anim.spatial
        }
    }

    Behavior on height {
        Anim {
            duration: Theme.anim.slow
            easing.bezierCurve: Theme.anim.spatial
        }
    }

    // hard shadow under the notch for the raised look
    NotchShape {
        anchors.fill: parent
        anchors.topMargin: Theme.depth.offset
        anchors.bottomMargin: -Theme.depth.offset
        visible: Theme.depth.on
        color: Theme.color.depthShadow
        radius: shape.radius
        flare: shape.flare
    }

    NotchShape {
        id: shape

        anchors.fill: parent
        // a hint that the resting island opens the dashboard
        // a moment blushes the notch with its state color
        color: Theme.mix(Theme.mix(root.mode === "idle" && idle.hovered ? Theme.mix(Theme.color.panel, Theme.color.ink, 0.07) : Theme.color.panel, Qt.alpha(Media.accent, 1), root.music * 0.3), Qt.alpha(glowView.accent, 1), glowView.glow * glowView.strength)
        rimWidth: Math.max(Theme.depth.rim, root.music * 1.5)
        rim: Theme.mix(Theme.color.depthRim, Media.accent, root.music * 0.8)
        radius: root.compact ? Math.min(height / 2, Theme.radius.medium) : Theme.radius.xl
        flare: root.compact ? Theme.radius.flare / 2 : Theme.radius.flare

        Behavior on color {
            ColorAnim {
                duration: Theme.anim.fast
            }
        }

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

    // the shine that sweeps across on a moment, drawn in the notch outline so it keeps the corners
    NotchShape {
        anchors.fill: parent
        visible: glowView.sweep >= 0
        radius: shape.radius
        flare: shape.flare
        gradient: LinearGradient {
            readonly property real band: 90
            readonly property real at: -band + glowView.sweep * (root.width + band * 2)

            x1: at - band
            x2: at + band
            y1: 0
            y2: 0

            GradientStop {
                position: 0
                color: "transparent"
            }

            GradientStop {
                position: 0.5
                color: Qt.alpha(glowView.accent, 0.55)
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
                onEntryChanged: expanded = false
            }
        }

        IslandSlot {
            id: media

            shown: root.mode === "media"

            MediaView {}
        }

        IslandSlot {
            id: dashboard

            shown: root.mode === "dashboard"

            IslandDashboard {
                id: dashboardView
            }

            onShownChanged: dashboardView.page = ""
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

                onDone: Actions.close("launcher")
            }

            onShownChanged: {
                if (shown)
                    launcherView.reset();
            }
        }
    }
}
