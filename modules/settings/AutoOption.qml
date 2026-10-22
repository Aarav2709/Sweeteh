import QtQuick
import QtQuick.Layouts
import qs.config
import qs.theme
import qs.components

// control picked from the type of the default value
OptionRow {
    id: root

    required property string key
    readonly property var fallback: key.split(".").reduce((o, k) => o?.[k], Defaults.values)
    readonly property var value: Config.get(key)
    readonly property var choices: Defaults.choices[key] ?? null
    readonly property string kind: choices ? "choice" : typeof fallback

    label: Theme.humanize(key.slice(key.lastIndexOf(".") + 1))

    Toggle {
        visible: root.kind === "boolean"
        checked: root.value === true
        onToggled: v => Config.set(root.key, v)
    }

    NumberControl {
        visible: root.kind === "number"
        value: root.kind === "number" ? root.value : 0
        step: !Number.isInteger(root.fallback) ? 0.05 : root.fallback >= 1000 ? 100 : root.fallback >= 100 ? 10 : 1
        maximum: Number.isInteger(root.fallback) ? 100000 : 4
        onChanged: v => Config.set(root.key, v)
    }

    Field {
        visible: root.kind === "string"
        implicitWidth: 320
        implicitHeight: 40
        text: root.kind === "string" ? root.value : ""
        onAccepted: Config.set(root.key, text)
        input.onActiveFocusChanged: {
            if (!input.activeFocus && text !== root.value)
                Config.set(root.key, text);
        }
    }

    ChipGroup {
        visible: root.kind === "choice"
        Layout.maximumWidth: 420
        options: root.choices ?? []
        current: root.kind === "choice" ? root.value : ""
        onPicked: v => Config.set(root.key, v)
    }

    IconButton {
        icon: "restart_alt"
        size: 32
        visible: JSON.stringify(root.value) !== JSON.stringify(root.fallback)
        onClicked: Config.reset(root.key)
    }
}
