import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.theme
import qs.services
import qs.components

// one surface that morphs between its resting state, quick flashes and the panels it hosts
PanelWindow {
    id: root

    property string flashing: ""
    property string messageIcon: ""
    property string messageText: ""
    property string osdKind: "volume"
    property NotifEntry notif: null
    // panels that live in the island, first match wins
    readonly property string hosted: ["launcher", "clipboard", "monitor", "island", "media"].find(id => Actions.isOpen(id) && (id === "island" || Modes.enabled(id))) ?? ""
    readonly property bool typing: hosted === "launcher" || hosted === "clipboard" || Auth.active
    readonly property bool expanded: hosted !== "" || Auth.active
    readonly property string state: Auth.active ? "auth" : hosted === "island" ? "dashboard" : hosted !== "" ? hosted : flashing !== "" ? flashing : "idle"

    function flash(kind: string, ms: int): void {
        flashing = kind;
        flashTimer.interval = ms;
        flashTimer.restart();
    }

    function showNext(): void {
        const next = Notifs.popups[Notifs.popups.length - 1];
        if (!next || Notifs.dnd || !Modes.enabled("notifications"))
            return;
        notif = next;
        flash("notification", Config.options.notifications.timeout);
    }

    screen: Hypr.screenFor(Hypr.focusedScreenName)
    color: "transparent"
    // beside a split bar the bar already holds the space
    exclusionMode: Modes.islands ? ExclusionMode.Ignore : ExclusionMode.Normal
    WlrLayershell.namespace: "sweeteh-island"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: typing ? WlrKeyboardFocus.Exclusive : expanded ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    anchors.top: true
    implicitWidth: 1120
    implicitHeight: 680
    mask: Region {
        item: island
    }

    // setting a zone forces normal exclusion, so it is only bound while the island stands alone
    Binding {
        target: root
        property: "exclusiveZone"
        value: Config.options.island.height
        when: !Modes.islands
        restoreMode: Binding.RestoreNone
    }

    // sinks report their volume once on load, ignore that
    Timer {
        id: armed

        property bool ready: false

        running: true
        interval: 1500
        onTriggered: ready = true
    }

    Timer {
        id: flashTimer

        onTriggered: {
            if (root.flashing === "notification" && root.notif)
                Notifs.hide(root.notif);
            root.flashing = "";
            root.notif = null;
            Qt.callLater(root.showNext);
        }
    }

    Connections {
        target: Notifs

        function onArrived(entry: NotifEntry): void {
            if (root.flashing !== "notification")
                root.showNext();
        }
    }

    Connections {
        target: Actions

        function onMessage(icon: string, text: string): void {
            root.messageIcon = icon;
            root.messageText = text;
            if (root.flashing !== "notification")
                root.flash("message", Config.options.island.messageTime);
        }
    }

    Connections {
        target: Audio

        function onChanged(): void {
            if (!Modes.enabled("osd") || !armed.ready)
                return;
            root.osdKind = "volume";
            root.flash("osd", Config.options.osd.timeout);
        }
    }

    // a new track peeks out of the island for a moment
    Connections {
        target: Media

        function onTitleChanged(): void {
            if (!Media.playing || !armed.ready || root.flashing === "notification")
                return;
            root.flash("track", 3500);
        }
    }

    Connections {
        target: Brightness

        function onChanged(): void {
            if (!Modes.enabled("osd") || !armed.ready)
                return;
            root.osdKind = "brightness";
            root.flash("osd", Config.options.osd.timeout);
        }
    }

    // grab after the keyboard focus change lands, or hyprland clears it at once
    Timer {
        id: grabDelay

        interval: 80
        onTriggered: grab.active = root.expanded
    }

    onExpandedChanged: {
        if (expanded) {
            grabDelay.restart();
            if (!typing)
                island.forceActiveFocus();
        } else {
            grab.active = false;
        }
    }

    HyprlandFocusGrab {
        id: grab

        windows: [root]
        onCleared: Actions.close(root.hosted)
    }

    IslandSurface {
        id: island

        anchors.horizontalCenter: parent.horizontalCenter
        mode: root.state
        messageIcon: root.messageIcon
        messageText: root.messageText
        osdKind: root.osdKind
        notif: root.notif
        onDismissNotification: flashTimer.triggered()
    }

    IpcHandler {
        target: "island"

        function toggle(): void {
            Actions.toggle("island");
        }

        function open(): void {
            Actions.open("island");
        }

        function close(): void {
            Actions.close("island");
        }

        function message(text: string): void {
            Actions.say("info", text);
        }
    }
}
