import QtQuick
import qs.theme
import qs.services
import qs.components

// click then press a key combination to record it in hyprland syntax
Rectangle {
    id: root

    property string keys
    property bool recording: false
    property bool conflict: false

    signal captured(string keys)

    onRecordingChanged: {
        Keybinds.capture(recording);
        if (recording)
            giveUp.restart();
    }
    Component.onDestruction: {
        if (recording)
            Keybinds.capture(false);
    }

    // never leave hyprland stuck in the capture submap
    Timer {
        id: giveUp

        interval: 8000
        onTriggered: root.recording = false
    }

    // hyprland key text written the way people say it
    function pretty(keys: string): string {
        const names = { super: "Super", super_l: "Super", ctrl: "Ctrl", control: "Ctrl", shift: "Shift", alt: "Alt", escape: "Esc", return: "Enter", tab: "Tab", space: "Space", period: "Period", comma: "Comma", slash: "Slash", print: "Print", "code:642": "Print" };
        const parts = keys.split("+").map(p => p.trim()).filter(p => p !== "");
        const out = [...new Set(parts.map(p => names[p.toLowerCase()] ?? (p.length === 1 ? p.toUpperCase() : p.charAt(0).toUpperCase() + p.slice(1))))];
        return out.join(" + ");
    }

    function keyName(e): string {
        const named = {
            [Qt.Key_Space]: "space", [Qt.Key_Return]: "Return", [Qt.Key_Enter]: "Return", [Qt.Key_Escape]: "escape",
            [Qt.Key_Tab]: "TAB", [Qt.Key_Backspace]: "BackSpace", [Qt.Key_Delete]: "Delete", [Qt.Key_Print]: "Print",
            [Qt.Key_Left]: "left", [Qt.Key_Right]: "right", [Qt.Key_Up]: "up", [Qt.Key_Down]: "down",
            [Qt.Key_Comma]: "comma", [Qt.Key_Period]: "period", [Qt.Key_Slash]: "slash", [Qt.Key_Semicolon]: "semicolon",
            [Qt.Key_Minus]: "minus", [Qt.Key_Equal]: "equal", [Qt.Key_BracketLeft]: "bracketleft", [Qt.Key_BracketRight]: "bracketright",
            [Qt.Key_Home]: "Home", [Qt.Key_End]: "End", [Qt.Key_PageUp]: "Prior", [Qt.Key_PageDown]: "Next", [Qt.Key_Insert]: "Insert"
        };
        if (named[e.key])
            return named[e.key];
        if (e.key >= Qt.Key_F1 && e.key <= Qt.Key_F24)
            return "F" + (e.key - Qt.Key_F1 + 1);
        if ((e.key >= Qt.Key_A && e.key <= Qt.Key_Z) || (e.key >= Qt.Key_0 && e.key <= Qt.Key_9))
            return String.fromCharCode(e.key);
        // modifiers alone are not a shortcut
        if ([Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_AltGr].includes(e.key))
            return "";
        // anything else is bound by its raw keycode, which hyprland understands
        return e.nativeScanCode > 0 ? "code:" + e.nativeScanCode : "";
    }

    implicitWidth: 160
    implicitHeight: 36
    radius: Theme.radius.small
    color: recording ? Theme.color.primaryContainer : Theme.color.layer2
    border.width: activeFocus || conflict ? 2 : 0
    border.color: conflict && !activeFocus ? Theme.color.error : Theme.color.primary

    Label {
        anchors.centerIn: parent
        text: root.recording ? "Press keys" : root.keys ? root.pretty(root.keys) : "Not set"
        font.pixelSize: Theme.font.small
        color: root.recording ? Theme.color.fgPrimaryContainer : Theme.color.ink
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.recording = true;
            root.forceActiveFocus();
        }
    }

    onActiveFocusChanged: {
        if (!activeFocus)
            recording = false;
    }

    activeFocusOnTab: true
    Keys.onPressed: e => {
        if (!recording) {
            if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) {
                recording = true;
                e.accepted = true;
            }
            return;
        }
        e.accepted = true;
        const key = keyName(e);
        if (key === "")
            return;
        const mods = [];
        if (e.modifiers & Qt.MetaModifier)
            mods.push("SUPER");
        if (e.modifiers & Qt.ControlModifier)
            mods.push("CTRL");
        if (e.modifiers & Qt.AltModifier)
            mods.push("ALT");
        if (e.modifiers & Qt.ShiftModifier)
            mods.push("SHIFT");
        recording = false;
        captured([...mods, key].join(" + "));
    }
}
