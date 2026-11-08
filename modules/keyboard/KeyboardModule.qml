import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.theme
import qs.services
import qs.components

// on screen keyboard laid out like end-4's, a floating card of tonal keys along the bottom edge
// keys go out through wtype, so the app in front keeps its focus
Scope {
    id: root

    // 0 off, 1 for the next key, 2 locked like caps lock, a second tap on shift within 300 ms locks it
    property int shiftMode: 0
    property real shiftTapped: 0
    property bool ctrl: false
    property bool alt: false
    // pinned, windows make room for the keyboard instead of sliding under it
    property bool pinned: false

    readonly property real unit: 45
    readonly property var widths: ({
            normal: 1,
            fn: 1,
            tab: 1.6,
            caps: 1.9,
            shift: 2.5,
            control: 1.3
        })
    readonly property var heights: ({
            normal: 1,
            fn: 0.7,
            tab: 1,
            caps: 1,
            shift: 1,
            control: 1
        })

    // label, its shifted label, the keysym it sends, and its shape
    function k(label: string, shifted: string, sym: string, shape: string): var {
        return {
            label: label,
            shifted: shifted || label,
            sym: sym,
            shape: shape || "normal"
        };
    }

    function letters(s: string): var {
        return s.split("").map(c => k(c, c.toUpperCase(), c, "normal"));
    }

    readonly property var rows: [[k("Esc", "", "Escape", "fn"), k("F1", "", "F1", "fn"), k("F2", "", "F2", "fn"), k("F3", "", "F3", "fn"), k("F4", "", "F4", "fn"), k("F5", "", "F5", "fn"), k("F6", "", "F6", "fn"), k("F7", "", "F7", "fn"), k("F8", "", "F8", "fn"), k("F9", "", "F9", "fn"), k("F10", "", "F10", "fn"), k("F11", "", "F11", "fn"), k("F12", "", "F12", "fn"), k("PrtSc", "", "Print", "fn"), k("Del", "", "Delete", "fn")], [k("`", "~", "grave"), k("1", "!", "1"), k("2", "@", "2"), k("3", "#", "3"), k("4", "$", "4"), k("5", "%", "5"), k("6", "^", "6"), k("7", "&", "7"), k("8", "*", "8"), k("9", "(", "9"), k("0", ")", "0"), k("-", "_", "minus"), k("=", "+", "equal"), Object.assign(k("Backspace", "", "BackSpace", "expand"), {
                icon: "backspace",
                repeat: true
            })], [k("Tab", "", "Tab", "tab")].concat(letters("qwertyuiop"), [k("[", "{", "bracketleft"), k("]", "}", "bracketright"), k("\\", "|", "backslash", "expand")]), [
            {
                shape: "empty"
            },
            {
                shape: "empty"
            }
        ].concat(letters("asdfghjkl"), [k(";", ":", "semicolon"), k("'", "\"", "apostrophe"), Object.assign(k("Enter", "", "Return", "expand"), {
                icon: "subdirectory_arrow_left"
            })]), [Object.assign(k("Shift", "Shift", "", "shift"), {
                mod: "shift"
            })].concat(letters("zxcvbnm"), [k(",", "<", "comma"), k(".", ">", "period"), k("/", "?", "slash"), Object.assign(k("Shift", "Shift", "", "expand"), {
                mod: "shift"
            })]), [Object.assign(k("Ctrl", "", "", "control"), {
                mod: "ctrl"
            }), Object.assign(k("Alt", "", "", "normal"), {
                mod: "alt"
            }), k("Space", "", "space", "space"), Object.assign(k("Left", "", "Left"), {
                icon: "keyboard_arrow_left",
                repeat: true
            }), Object.assign(k("Down", "", "Down"), {
                icon: "keyboard_arrow_down",
                repeat: true
            }), Object.assign(k("Up", "", "Up"), {
                icon: "keyboard_arrow_up",
                repeat: true
            }), Object.assign(k("Right", "", "Right"), {
                icon: "keyboard_arrow_right",
                repeat: true
            }), Object.assign(k("Alt", "", "", "normal"), {
                mod: "alt"
            }), Object.assign(k("Ctrl", "", "", "control"), {
                mod: "ctrl"
            })]]

    function tapShift(): void {
        const now = Date.now();
        if (shiftMode === 0)
            shiftMode = 1;
        else if (shiftMode === 1 && now - shiftTapped < 300)
            shiftMode = 2;
        else
            shiftMode = 0;
        shiftTapped = now;
    }

    function send(key: var): void {
        if (key.mod === "shift") {
            tapShift();
            return;
        }
        if (key.mod === "ctrl") {
            ctrl = !ctrl;
            return;
        }
        if (key.mod === "alt") {
            alt = !alt;
            return;
        }
        const mods = [];
        if (ctrl)
            mods.push("ctrl");
        if (alt)
            mods.push("alt");
        const printable = key.label.length === 1;
        const args = ["wtype"];
        if (printable && mods.length === 0) {
            // a plain character is typed as text, so the app gets the right symbol whatever the layout
            const text = shiftMode > 0 ? key.shifted : key.label;
            if (text === "-")
                args.push("-k", "minus");
            else
                args.push(text);
        } else {
            // named keys and shortcuts press the keysym with the held modifiers around it
            if (shiftMode > 0)
                mods.push("shift");
            for (const m of mods)
                args.push("-M", m);
            args.push("-k", key.sym);
            for (const m of mods)
                args.push("-m", m);
        }
        Quickshell.execDetached(args);
        if (shiftMode === 1)
            shiftMode = 0;
    }

    function close(): void {
        Tablet.keyboard = false;
    }

    // how far the keyboard has slid up out of the edge, and how far a finger is pulling it back down
    property real reveal: Tablet.keyboard ? 1 : 0
    property real pull: 0

    Behavior on reveal {
        enabled: Theme.anim.speed > 0

        NumberAnimation {
            duration: Theme.anim.slow
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.anim.decel
        }
    }

    onRevealChanged: {
        if (reveal === 0)
            pull = 0;
    }

    Connections {
        target: Tablet

        function onKeyboardChanged(): void {
            if (Tablet.keyboard) {
                probe.running = true;
            } else {
                root.shiftMode = 0;
                root.ctrl = false;
                root.alt = false;
            }
        }
    }

    // missing wtype is offered once when the keyboard opens
    Process {
        id: probe

        command: ["sh", "-c", "command -v wtype"]
        onExited: code => {
            if (code !== 0) {
                Tablet.keyboard = false;
                Actions.needs(["wtype"], "keyboard", "The on screen keyboard");
            }
        }
    }

    // stays loaded while it slides away
    LazyLoader {
        active: Tablet.keyboard || root.reveal > 0

        PanelWindow {
            screen: Hypr.screenFor(Hypr.focusedScreenName)
            color: "transparent"
            WlrLayershell.namespace: "sweeteh-keyboard"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            implicitHeight: card.height + Theme.spacing.medium * 2
            exclusiveZone: root.pinned ? implicitHeight : 0
            mask: Region {
                item: card
            }

            Rectangle {
                id: card

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.spacing.medium
                width: content.implicitWidth + 20
                height: content.implicitHeight + 34
                radius: Theme.radius.large
                // slides in from below the edge, and follows a finger dragging it down
                transform: Translate {
                    y: (1 - root.reveal) * (card.height + Theme.spacing.medium * 2) + root.pull
                }

                // the grabber, drag it down to put the keyboard away
                Item {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 24

                    Rectangle {
                        anchors.centerIn: parent
                        width: 40
                        height: 4
                        radius: 2
                        color: Theme.color.inkFaint
                    }

                    DragHandler {
                        target: null
                        yAxis.enabled: true
                        xAxis.enabled: false
                        onTranslationChanged: root.pull = Math.max(0, translation.y)
                        onActiveChanged: {
                            if (active)
                                return;
                            if (root.pull > 60)
                                root.close();
                            else
                                root.pull = 0;
                        }
                    }
                }
                color: Theme.color.panel
                border.width: Theme.depth.rim
                border.color: Theme.color.depthRim

                RowLayout {
                    id: content

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 10
                    spacing: 5

                    ColumnLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 5

                        Rectangle {
                            implicitWidth: 40
                            implicitHeight: 40
                            radius: Theme.radius.medium
                            color: root.pinned ? Theme.color.primary : Theme.color.layer1

                            Icon {
                                anchors.centerIn: parent
                                name: "keep"
                                fill: root.pinned ? 1 : 0
                                color: root.pinned ? Theme.color.fgPrimary : Theme.color.ink
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.pinned = !root.pinned
                            }
                        }

                        Rectangle {
                            implicitWidth: 40
                            implicitHeight: 40
                            radius: Theme.radius.medium
                            color: false ? Theme.color.primary : Theme.color.layer1

                            Icon {
                                anchors.centerIn: parent
                                name: "keyboard_hide"
                                fill: false ? 1 : 0
                                color: false ? Theme.color.fgPrimary : Theme.color.ink
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.close()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillHeight: true
                        Layout.topMargin: 20
                        Layout.bottomMargin: 20
                        implicitWidth: 1
                        color: Theme.color.inkFaint
                        opacity: 0.4
                    }

                    ColumnLayout {
                        spacing: 5

                        Repeater {
                            model: root.rows

                            RowLayout {
                                id: row

                                required property var modelData

                                Layout.fillWidth: true
                                spacing: 5

                                Repeater {
                                    model: row.modelData

                                    Rectangle {
                                        id: button

                                        required property var modelData
                                        readonly property var key: modelData
                                        readonly property bool toggled: (key.mod === "shift" && root.shiftMode > 0) || (key.mod === "ctrl" && root.ctrl) || (key.mod === "alt" && root.alt)
                                        readonly property bool empty: key.shape === "empty"

                                        implicitWidth: root.unit * (root.widths[key.shape] ?? 1)
                                        implicitHeight: root.unit * (root.heights[key.shape] ?? 1)
                                        Layout.fillWidth: key.shape === "space" || key.shape === "expand"
                                        radius: Theme.radius.small
                                        color: empty ? "transparent" : toggled ? Theme.color.primary : Theme.color.layer1

                                        // the press darkens or lightens the key like a ripple settling
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: parent.radius
                                            visible: !button.empty
                                            color: button.toggled ? Theme.color.fgPrimary : Theme.color.ink
                                            opacity: touch.pressed ? 0.16 : touch.containsMouse ? 0.06 : 0

                                            Behavior on opacity {
                                                Anim {
                                                    duration: Theme.anim.fast
                                                }
                                            }
                                        }

                                        Label {
                                            anchors.centerIn: parent
                                            visible: !button.empty && !button.key.icon
                                            text: button.key.label === undefined ? "" : root.shiftMode === 2 && button.key.mod === "shift" ? "Caps" : root.shiftMode > 0 ? button.key.shifted : button.key.label
                                            font.pixelSize: button.key.shape === "fn" ? Theme.font.small : Theme.font.large
                                            color: button.toggled ? Theme.color.fgPrimary : Theme.color.ink
                                        }

                                        Icon {
                                            anchors.centerIn: parent
                                            visible: !button.empty && button.key.icon !== undefined
                                            name: button.key.icon ?? ""
                                            size: Theme.font.large + 6
                                            color: button.toggled ? Theme.color.fgPrimary : Theme.color.ink
                                        }

                                        MouseArea {
                                            id: touch

                                            anchors.fill: parent
                                            enabled: !button.empty
                                            hoverEnabled: true
                                            onPressed: {
                                                root.send(button.key);
                                                if (button.key.repeat)
                                                    again.start();
                                            }
                                            onReleased: again.stop()
                                            onCanceled: again.stop()
                                        }

                                        // held backspace and arrows keep going
                                        Timer {
                                            id: again

                                            interval: 380
                                            repeat: true
                                            onTriggered: {
                                                interval = 60;
                                                root.send(button.key);
                                            }
                                            onRunningChanged: {
                                                if (!running)
                                                    interval = 380;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // in tablet mode a tab joined to the bottom edge, swipe or scroll up on it, or tap it, for the keyboard
    LazyLoader {
        active: Tablet.tablet && !Tablet.keyboard

        PanelWindow {
            screen: Hypr.screenFor(Hypr.focusedScreenName)
            color: "transparent"
            WlrLayershell.namespace: "sweeteh-keyboard-handle"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            anchors.bottom: true
            implicitWidth: 84
            implicitHeight: 26

            Rectangle {
                id: tab

                property real lift: 0

                anchors.fill: parent
                topLeftRadius: height / 2
                topRightRadius: height / 2
                color: Theme.color.panel
                border.width: Theme.depth.rim
                border.color: Theme.color.depthRim

                Icon {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -tab.lift * 0.2
                    name: "keyboard_arrow_up"
                    color: Theme.color.ink
                }

                TapHandler {
                    onTapped: Tablet.keyboard = true
                }

                DragHandler {
                    target: null
                    xAxis.enabled: false
                    onTranslationChanged: {
                        tab.lift = Math.max(0, -translation.y);
                        if (tab.lift > 24)
                            Tablet.keyboard = true;
                    }
                    onActiveChanged: tab.lift = 0
                }

                WheelHandler {
                    onWheel: e => {
                        if (e.angleDelta.y > 0)
                            Tablet.keyboard = true;
                    }
                }
            }
        }
    }
}
