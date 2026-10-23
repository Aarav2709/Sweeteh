import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
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
    property var moment: ({ kind: "plugged" })
    // bluetooth devices seen connected, so a change can tell who came and who left
    property var btSeen: []
    property var btWarned: []
    // moments waiting for the island, one per kind so a flipped switch only shows its last state
    property var queue: []
    // moments held back while something is fullscreen
    property var held: []
    // hovering the resting island while music plays opens a small player
    property bool peeking: false
    property NotifEntry notif: null
    // panels that live in the island, first match wins
    readonly property string hosted: ["launcher", "clipboard", "monitor", "island", "media"].find(id => Actions.isOpen(id) && (id === "island" || Modes.enabled(id))) ?? ""
    readonly property bool typing: hosted === "launcher" || hosted === "clipboard" || Auth.active || (Notifs.replying && flashing === "notification")
    readonly property bool expanded: hosted !== "" || Auth.active
    readonly property string state: Auth.active ? "auth" : hosted === "island" ? "dashboard" : hosted !== "" ? hosted : flashing !== "" ? flashing : peeking ? "peek" : "idle"

    function flash(kind: string, ms: int): void {
        flashing = kind;
        flashTimer.interval = ms;
        flashTimer.restart();
    }

    // a colored moment, a notification on screen keeps its turn and a newer moment replaces an older one
    // which moments switch a kind belongs to
    function category(kind: string): string {
        return ["plugged", "unplugged", "low", "critical", "profile"].includes(kind) ? "battery" : kind.startsWith("bluetooth") ? "bluetooth" : kind === "network" ? "network" : kind.startsWith("privacy") ? "privacy" : kind === "download" ? "downloads" : kind === "welcome" ? "welcome" : "toggles";
    }

    function glow(m: var, ms: int): void {
        const alert = m.kind === "critical" || (m.alert ?? false);
        // only a critical battery ignores the switches, it is the one that can cost work
        if (m.kind !== "critical" && Config.options.moments[category(m.kind)] === false)
            return;
        // over a fullscreen game or video the small stuff waits until it is gone
        if (!alert && Perf.fullscreen && Config.options.performance.quietMoments) {
            held = held.filter(q => q.moment.kind !== m.kind).concat([{ moment: m, ms: ms }]);
            return;
        }
        // the same kind again updates the moment on screen instead of waiting behind it
        if (flashing === "notification" || (flashing === "glow" && moment.kind !== m.kind)) {
            queue = queue.filter(q => q.moment.kind !== m.kind).concat([{ moment: m, ms: ms }]);
            return;
        }
        moment = m;
        flash("glow", ms);
    }

    // after a flash, waiting notifications go first and then queued moments
    function advance(): void {
        if (flashing !== "")
            return;
        showNext();
        if (flashing !== "" || queue.length === 0)
            return;
        const next = queue[0];
        queue = queue.slice(1);
        moment = next.moment;
        flash("glow", next.ms);
    }

    // switches flipped by keybinds or toggles, ignored while the shell is still loading
    function toggled(on: bool, icon: string, title: string): void {
        if (armed.ready)
            glow({ kind: "toggle " + title, icon: icon, title: title, sub: on ? "On" : "Off" }, 2200);
    }

    function btIcon(icon: string): string {
        return icon.includes("audio") || icon.includes("headset") || icon.includes("headphone") ? "headphones" : icon.includes("keyboard") ? "keyboard" : icon.includes("mouse") || icon.includes("input") ? "mouse" : icon.includes("phone") ? "smartphone" : icon.includes("watch") ? "watch" : "bluetooth";
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
            Notifs.replying = false;
            root.flashing = "";
            root.notif = null;
            Qt.callLater(root.advance);
        }
    }

    Connections {
        target: Notifs

        function onReplyingChanged(): void {
            if (Notifs.replying)
                flashTimer.stop();
            else if (root.flashing === "notification")
                flashTimer.restart();
        }

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

    // the charger going in or out and the battery running low each get a colored moment
    Connections {
        target: Battery

        function onPluggedChanged(): void {
            if (Battery.available && armed.ready)
                root.glow({ kind: Battery.plugged ? "plugged" : "unplugged", run: () => Actions.open("island") }, 3600);
        }

        function onDropped(critical: bool): void {
            root.glow({ kind: critical ? "critical" : "low", run: () => Battery.setProfile(PowerProfile.PowerSaver) }, 4500);
        }

        // a battery moment already says when the saver kicked in
        function onProfileChanged(): void {
            if (!armed.ready || (root.flashing === "glow" && ["plugged", "low", "critical"].includes(root.moment.kind)))
                return;
            const p = Battery.profile;
            root.glow(p === PowerProfile.PowerSaver ? { kind: "profile", icon: "energy_savings_leaf", title: "Battery saver", sub: "On" } : p === PowerProfile.Performance ? { kind: "profile", icon: "speed", title: "Performance", sub: "Power mode" } : { kind: "profile", icon: "balance", title: "Balanced", sub: "Power mode" }, 2400);
        }
    }

    // coming back from the lockscreen gets a greeting
    Connections {
        target: Actions

        function onUnlocked(): void {
            root.glow({ kind: "welcome" }, 3500);
        }
    }

    Connections {
        target: BluetoothState

        function onConnectedDevicesChanged(): void {
            const now = BluetoothState.connectedDevices;
            const ids = now.map(d => d.address);
            if (armed.ready) {
                const came = now.find(d => !root.btSeen.includes(d.address));
                const left = root.btSeen.filter(a => !ids.includes(a));
                if (came)
                    root.glow({ kind: "bluetooth", icon: root.btIcon(came.icon ?? ""), title: came.name || came.deviceName || "Device", sub: "Connected" + (came.batteryAvailable ? "  ·  " + Math.round(came.battery * 100) + "%" : ""), run: () => Actions.open("island") }, 3000);
                else if (left.length > 0)
                    root.glow({ kind: "bluetooth", icon: "bluetooth_disabled", title: "Bluetooth device", sub: "Disconnected" }, 2400);
            }
            root.btSeen = ids;
        }

        function onEnabledChanged(): void {
            root.toggled(BluetoothState.enabled, "bluetooth", "Bluetooth");
        }
    }

    Connections {
        target: Network

        function onConnectedChanged(): void {
            if (!armed.ready || !Network.wifiEnabled)
                return;
            nameWait.restart();
        }

        function onWifiEnabledChanged(): void {
            root.toggled(Network.wifiEnabled, Network.wifiEnabled ? "wifi" : "wifi_off", "Wi-Fi");
        }
    }

    // the network name lands a moment after the connection itself
    Timer {
        id: nameWait

        interval: 600
        onTriggered: root.glow(Network.connected ? { kind: "network", icon: Network.wired ? "lan" : "wifi", title: Network.name || "Connected", sub: "Connected" } : { kind: "network", icon: "wifi_off", title: "Wi-Fi dropped", sub: "Offline", run: () => Actions.open("island") }, 2800)
    }

    Connections {
        target: Privacy

        function onMicChanged(): void {
            if (Privacy.mic && armed.ready)
                root.glow({ kind: "privacy mic", icon: "mic", title: "Microphone in use", sub: Privacy.micApp }, 2600);
        }

        function onCameraChanged(): void {
            if (Privacy.camera && armed.ready)
                root.glow({ kind: "privacy camera", icon: "videocam", title: "Camera in use", sub: Privacy.cameraApp }, 2600);
        }

        function onScreenChanged(): void {
            if (Privacy.screen && armed.ready)
                root.glow({ kind: "privacy screen", icon: "screen_share", title: "Screen shared" }, 2600);
        }
    }

    // headphones and the like warn once when they run low, and again after a charge
    Timer {
        running: BluetoothState.connectedDevices.length > 0
        repeat: true
        triggeredOnStart: true
        interval: 60000
        onTriggered: {
            for (const d of BluetoothState.connectedDevices) {
                if (!d.batteryAvailable)
                    continue;
                const warned = root.btWarned.includes(d.address);
                if (d.battery <= 0.15 && !warned) {
                    root.btWarned = root.btWarned.concat([d.address]);
                    root.glow({ kind: "bluetooth low " + d.address, icon: root.btIcon(d.icon ?? ""), title: (d.name || "Device") + " battery low", sub: Math.round(d.battery * 100) + "%", alert: true }, 3500);
                } else if (d.battery > 0.25 && warned) {
                    root.btWarned = root.btWarned.filter(a => a !== d.address);
                }
            }
        }
    }

    Connections {
        target: Audio

        function onMicMutedChanged(): void {
            if (armed.ready)
                root.glow({ kind: "mic", icon: Audio.micMuted ? "mic_off" : "mic", title: Audio.micMuted ? "Microphone muted" : "Microphone on" }, 2000);
        }
    }

    Connections {
        target: Session

        function onCaffeineChanged(): void {
            root.toggled(Session.caffeine, "coffee", "Caffeine");
        }
    }

    Connections {
        target: Notifs

        function onDndChanged(): void {
            root.toggled(Notifs.dnd, "do_not_disturb_on", "Do not disturb");
        }
    }

    Connections {
        target: NightLight

        function onActiveChanged(): void {
            root.toggled(NightLight.active, "nightlight", "Night light");
        }
    }

    Connections {
        target: Recorder

        function onRecordingChanged(): void {
            if (armed.ready)
                root.glow({ kind: "record", icon: Recorder.recording ? "radio_button_checked" : "check_circle", title: Recorder.recording ? "Recording" : "Recording saved" }, 2200);
        }
    }

    Connections {
        target: Keyboard

        function onCapsChanged(): void {
            root.toggled(Keyboard.caps, "keyboard_capslock", "Caps Lock");
        }

        function onLayoutChanged(): void {
            if (armed.ready && Keyboard.layout)
                root.glow({ kind: "layout", icon: "keyboard", title: Keyboard.layout, sub: "Layout" }, 1800);
        }
    }

    Connections {
        target: Downloads

        function onActiveChanged(): void {
            if (Downloads.active && armed.ready)
                root.glow({ kind: "download", icon: "download", title: "Downloading", sub: Downloads.name, run: () => Quickshell.execDetached(["xdg-open", Downloads.folder]) }, 2400);
        }

        function onFinished(name: string): void {
            root.glow({ kind: "download", icon: "download_done", title: "Downloaded", sub: name, run: () => Quickshell.execDetached(["xdg-open", Downloads.folder + "/" + name]) }, 3600);
        }

        function onCancelled(name: string): void {
            root.glow({ kind: "download", icon: "cancel", title: "Download cancelled", sub: name }, 2400);
        }
    }

    Connections {
        target: Modes

        function onCurrentChanged(): void {
            if (armed.ready)
                root.glow({ kind: "mode", icon: Modes.mode.icon, title: Modes.mode.name, sub: "Mode" }, 2000);
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
        target: Perf

        function onFullscreenChanged(): void {
            if (Perf.fullscreen || root.held.length === 0)
                return;
            // only the latest few, a long game should not end in a parade
            root.queue = root.queue.concat(root.held.slice(-3));
            root.held = [];
            root.advance();
        }
    }

    // scrolling the island while music plays moves that player's own volume
    Connections {
        target: Media

        function onVolumeNudged(): void {
            if (!Modes.enabled("osd"))
                return;
            root.osdKind = "player";
            root.flash("osd", Config.options.osd.timeout);
        }
    }

    // the peek opens after a short hover and folds a moment after the pointer leaves
    Timer {
        interval: island.hovered ? 450 : 350
        running: island.hovered !== root.peeking && (root.peeking || (Media.active && Config.options.island.peek && root.flashing === "" && root.hosted === ""))
        onTriggered: root.peeking = island.hovered && Media.active
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
        moment: root.moment
        notif: root.notif
        onDismissNotification: flashTimer.triggered()
        // a moment with somewhere to go runs it and folds away
        onMomentClicked: {
            const run = root.moment.run;
            flashTimer.stop();
            flashTimer.triggered();
            if (typeof run === "function")
                run();
        }
        // a hovered moment or notification stays until the pointer leaves
        onHoveredChanged: {
            if (root.flashing !== "glow" && root.flashing !== "notification")
                return;
            if (hovered)
                flashTimer.stop();
            else if (!Notifs.replying) {
                flashTimer.interval = 1500;
                flashTimer.restart();
            }
        }
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

        // preview a moment, plugged, unplugged, low, critical or welcome
        function moment(kind: string): void {
            root.glow({ kind: kind }, 3200);
        }
    }
}
