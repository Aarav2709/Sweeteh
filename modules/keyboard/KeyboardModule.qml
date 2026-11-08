import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.theme
import qs.services
import qs.components

// on screen keyboard for tablet mode, keys go out through wtype so the app in front keeps its focus
Scope {
    id: root

    // one shot shift, and modifiers that stay down until the next key
    property bool shift: false
    property var held: []

    // label, what it types or the keysym it sends, and how wide it is in units
    readonly property var rows: [[["`", "~"], ["1", "!"], ["2", "@"], ["3", "#"], ["4", "$"], ["5", "%"], ["6", "^"], ["7", "&"], ["8", "*"], ["9", "("], ["0", ")"], ["-", "_"], ["=", "+"],
            {
                label: "backspace",
                sym: "BackSpace",
                w: 1.6,
                icon: true,
                repeat: true
            }
        ], [
            {
                label: "Tab",
                sym: "Tab",
                w: 1.4
            },
            "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", ["[", "{"], ["]", "}"], ["\\", "|"]], [
            {
                label: "Esc",
                sym: "Escape",
                w: 1.7
            },
            "a", "s", "d", "f", "g", "h", "j", "k", "l", [";", ":"], ["'", "\""],
            {
                label: "keyboard_return",
                sym: "Return",
                w: 1.9,
                icon: true
            }
        ], [
            {
                label: "shift",
                mod: "shift",
                w: 2.2,
                icon: true
            },
            "z", "x", "c", "v", "b", "n", "m", [",", "<"], [".", ">"], ["/", "?"],
            {
                label: "keyboard_arrow_up",
                sym: "Up",
                icon: true,
                repeat: true
            },
            {
                label: "shift",
                mod: "shift",
                w: 1.4,
                icon: true
            }
        ], [
            {
                label: "Ctrl",
                mod: "ctrl",
                w: 1.4
            },
            {
                label: "Super",
                mod: "logo",
                w: 1.4
            },
            {
                label: "Alt",
                mod: "alt",
                w: 1.4
            },
            {
                label: "",
                sym: "space",
                w: 6.6
            },
            {
                label: "keyboard_arrow_left",
                sym: "Left",
                icon: true,
                repeat: true
            },
            {
                label: "keyboard_arrow_down",
                sym: "Down",
                icon: true,
                repeat: true
            },
            {
                label: "keyboard_arrow_right",
                sym: "Right",
                icon: true,
                repeat: true
            },
            {
                label: "keyboard_hide",
                hide: true,
                w: 1.4,
                icon: true
            }
        ]]
    // keysym names for characters typed while a modifier is held
    readonly property var names: ({
            "-": "minus",
            "=": "equal",
            "[": "bracketleft",
            "]": "bracketright",
            "\\": "backslash",
            ";": "semicolon",
            "'": "apostrophe",
            ",": "comma",
            ".": "period",
            "/": "slash",
            "`": "grave"
        })

    function spec(k: var): var {
        if (k === undefined || k === null)
            return {
                label: "",
                w: 1
            };
        if (typeof k === "string")
            return {
                label: k,
                text: k,
                shifted: k.toUpperCase(),
                w: 1
            };
        if (Array.isArray(k))
            return {
                label: k[0],
                text: k[0],
                shifted: k[1],
                w: 1
            };
        return Object.assign({
            w: 1
        }, k);
    }

    function press(k: var): void {
        if (k.hide) {
            Tablet.keyboard = false;
            return;
        }
        if (k.mod) {
            if (k.mod === "shift")
                shift = !shift;
            else
                held = held.includes(k.mod) ? held.filter(m => m !== k.mod) : held.concat([k.mod]);
            return;
        }
        const down = held.flatMap(m => ["-M", m]);
        const up = held.flatMap(m => ["-m", m]);
        let send;
        if (k.sym)
            send = ["-k", k.sym];
        else if (held.length > 0)
            send = (names[k.text] ? ["-k", names[k.text]] : [k.text]);
        else {
            const t = shift ? k.shifted : k.text;
            send = t === "-" ? ["-k", "minus"] : [t];
        }
        // shift with another modifier is held down for real, alone it already picked the character
        const withShift = held.length > 0 && shift ? ["-M", "shift"] : [];
        const releaseShift = held.length > 0 && shift ? ["-m", "shift"] : [];
        Quickshell.execDetached(["wtype"].concat(withShift, down, send, up, releaseShift));
        shift = false;
        held = [];
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

    Connections {
        target: Tablet

        function onKeyboardChanged(): void {
            if (Tablet.keyboard)
                probe.running = true;
        }
    }

    // the keyboard itself, along the bottom of the focused screen, windows move up to make room
    LazyLoader {
        active: Tablet.keyboard

        PanelWindow {
            id: board

            screen: Hypr.screenFor(Hypr.focusedScreenName)
            color: "transparent"
            WlrLayershell.namespace: "sweeteh-keyboard"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            implicitHeight: Math.round(Math.min(340, (screen?.height ?? 1080) * 0.36))
            exclusiveZone: implicitHeight

            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 0
                topLeftRadius: Theme.radius.large
                topRightRadius: Theme.radius.large
                color: Theme.color.panel

                ColumnLayout {
                    id: keys

                    // one unit is the width of a letter key, the widest row sets it
                    readonly property real unit: (width - Theme.spacing.xs * 14) / 15

                    anchors.fill: parent
                    anchors.margins: Theme.spacing.medium
                    anchors.bottomMargin: Theme.spacing.medium + Theme.depth.offset
                    spacing: Theme.spacing.xs

                    Repeater {
                        model: root.rows

                        RowLayout {
                            id: row

                            required property var modelData

                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillHeight: true
                            spacing: Theme.spacing.xs

                            Repeater {
                                model: row.modelData

                                Rectangle {
                                    id: key

                                    required property var modelData
                                    readonly property var k: root.spec(modelData)
                                    readonly property bool on: (k.mod === "shift" && root.shift) || (k.mod !== undefined && root.held.includes(k.mod))
                                    readonly property bool down: touch.pressed

                                    Layout.fillHeight: true
                                    Layout.preferredWidth: keys.unit * k.w + Theme.spacing.xs * (k.w - 1)
                                    radius: Theme.radius.medium
                                    color: on ? Theme.color.primary : k.text !== undefined || k.sym === "space" ? Theme.color.layer2 : Theme.color.layer1
                                    transform: Translate {
                                        y: ledge.shift
                                    }

                                    Depth {
                                        id: ledge

                                        sink: key.down ? 1 : 0
                                    }

                                    Label {
                                        anchors.centerIn: parent
                                        visible: !key.k.icon
                                        text: (key.k.text !== undefined ? (root.shift ? key.k.shifted : key.k.text) : key.k.label) ?? ""
                                        font.pixelSize: key.k.text !== undefined ? Theme.font.large : Theme.font.small
                                        font.weight: Font.Medium
                                        color: key.on ? Theme.color.fgPrimary : Theme.color.ink
                                    }

                                    Icon {
                                        anchors.centerIn: parent
                                        visible: key.k.icon === true
                                        name: key.k.label ?? ""
                                        fill: key.on ? 1 : 0
                                        color: key.on ? Theme.color.fgPrimary : Theme.color.ink
                                    }

                                    MouseArea {
                                        id: touch

                                        anchors.fill: parent
                                        onPressed: {
                                            root.press(key.k);
                                            if (key.k.repeat)
                                                again.start();
                                        }
                                        onReleased: again.stop()
                                        onCanceled: again.stop()
                                    }

                                    // held arrows and backspace keep going
                                    Timer {
                                        id: again

                                        interval: 380
                                        repeat: true
                                        onTriggered: {
                                            interval = 60;
                                            root.press(key.k);
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

    // in tablet mode a small handle at the bottom edge brings the keyboard up
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
            margins.bottom: Theme.spacing.small
            implicitWidth: 76
            implicitHeight: 34

            Rectangle {
                anchors.fill: parent
                anchors.bottomMargin: Theme.depth.offset
                radius: height / 2
                color: Theme.color.panel

                Depth {}

                Icon {
                    anchors.centerIn: parent
                    name: "keyboard"
                    color: Theme.color.ink
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Tablet.keyboard = true
                }
            }
        }
    }
}
