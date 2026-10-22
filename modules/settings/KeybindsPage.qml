import QtQuick
import QtQuick.Layouts
import qs.config
import qs.theme
import qs.services
import qs.components

// every bind the shell owns, grouped, saved to the sweeteh config and to a file hyprland loads
ColumnLayout {
    id: root

    property var draft: JSON.parse(JSON.stringify(Keybinds.binds))
    property string filter: ""
    readonly property bool dirty: JSON.stringify(draft) !== JSON.stringify(Keybinds.binds)
    readonly property var groups: [...new Set(draft.map(b => b.group || "Custom"))]

    function update(i: int, field: string, value: string): void {
        const next = draft.slice();
        next[i] = Object.assign({}, next[i], { [field]: value });
        draft = next;
    }

    function matches(b: var): bool {
        const q = filter.trim().toLowerCase();
        return q === "" || [b.keys, b.action, b.description].some(t => String(t ?? "").toLowerCase().includes(q));
    }

    spacing: Theme.spacing.small

    RowLayout {
        Layout.fillWidth: true

        Label {
            Layout.fillWidth: true
            text: "Keybinds"
            font.pixelSize: Theme.font.headline
            font.weight: Font.DemiBold
        }

        Button {
            variant: "neutral"
            text: "Revert"
            visible: root.dirty
            onClicked: root.draft = JSON.parse(JSON.stringify(Keybinds.binds))
        }

        Button {
            variant: "filled"
            icon: "save"
            text: "Save"
            disabled: !root.dirty
            onClicked: {
                Keybinds.save(root.draft.filter(b => b.keys && b.action));
                Actions.say("keyboard", "Keybinds saved.");
            }
        }
    }

    Label {
        Layout.fillWidth: true
        text: "Click a shortcut and press the new keys. Binds keep working even when the shell is not running."
        wrapMode: Text.Wrap
        color: Theme.color.inkMeta
    }

    Field {
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacing.small
        color: Theme.color.layer1
        outlineOnFocus: false
        icon: "search"
        placeholder: "Search keybinds"
        onEdited: root.filter = text
    }

    Repeater {
        model: root.groups

        Section {
            id: section

            required property string modelData
            readonly property var entries: root.draft.map((b, i) => ({
                        bind: b,
                        index: i
                    })).filter(r => (r.bind.group || "Custom") === modelData && root.matches(r.bind))

            Layout.fillWidth: true
            visible: entries.length > 0
            title: modelData
            icon: ({ Apps: "apps", Windows: "select_window", Shell: "pill", Session: "power_settings_new", Capture: "screenshot_region" })[modelData] ?? "keyboard"

            Repeater {
                model: section.entries

                RowLayout {
                    id: row

                    required property var modelData
                    readonly property bool conflict: Keybinds.conflicts.includes(modelData.bind.keys)

                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacing.xxs
                    Layout.bottomMargin: Theme.spacing.xxs
                    spacing: Theme.spacing.small

                    Field {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        implicitHeight: 36
                        implicitWidth: 0
                        color: "transparent"
                        placeholder: "Description"
                        text: row.modelData.bind.description ?? ""
                        onEdited: root.update(row.modelData.index, "description", text)
                    }

                    KeyCapture {
                        Layout.alignment: Qt.AlignTop
                        Layout.preferredWidth: 190
                        keys: row.modelData.bind.keys
                        conflict: row.conflict
                        onCaptured: k => root.update(row.modelData.index, "keys", k)
                    }

                    ActionField {
                        Layout.fillWidth: false
                        Layout.preferredWidth: 200
                        Layout.alignment: Qt.AlignTop
                        text: row.modelData.bind.action
                        onCommitted: v => root.update(row.modelData.index, "action", v)
                    }

                    IconButton {
                        Layout.alignment: Qt.AlignTop
                        icon: "delete"
                        size: 36
                        onClicked: root.draft = root.draft.filter((b, i) => i !== row.modelData.index)
                    }
                }
            }
        }
    }

    Label {
        Layout.fillWidth: true
        visible: Keybinds.conflicts.length > 0
        text: "Shortcuts in red are already taken by your Hyprland config, so they are skipped."
        wrapMode: Text.Wrap
        font.pixelSize: Theme.font.small
        color: Theme.color.error
    }

    Button {
        Layout.topMargin: Theme.spacing.small
        icon: "add"
        text: "Add keybind"
        onClicked: root.draft = [...root.draft, { group: "Custom", keys: "", action: "", description: "" }]
    }
}
