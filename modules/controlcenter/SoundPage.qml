import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.components

// where sound goes and comes from, and how loud each app plays
DevicePage {
    id: root

    title: "Sound"
    icon: "graphic_eq"
    on: !Audio.muted
    empty: "No sound devices found."
    onSwitched: on => {
        if (on === Audio.muted)
            Audio.toggleMute();
    }
    Component.onCompleted: Audio.watching = true
    Component.onDestruction: Audio.watching = false

    // one flat list with headings, so the page scrolls as a whole
    model: {
        const rows = [];
        const outs = Audio.sinks.filter(n => root.matches(Audio.label(n)));
        const ins = Audio.sources.filter(n => root.matches(Audio.label(n)));
        const apps = Audio.streams.filter(n => root.matches(Audio.label(n)));
        if (apps.length > 0)
            rows.push({ kind: "head", text: "Apps" }, ...apps.map(n => ({ kind: "app", node: n })));
        if (outs.length > 0)
            rows.push({ kind: "head", text: "Output" }, ...outs.map(n => ({ kind: "out", node: n })));
        if (ins.length > 0)
            rows.push({ kind: "head", text: "Input" }, ...ins.map(n => ({ kind: "in", node: n })));
        return rows;
    }

    delegate: Loader {
        id: row

        required property var modelData

        width: ListView.view.width
        sourceComponent: modelData.kind === "head" ? head : modelData.kind === "app" ? app : device

        Component {
            id: head

            Label {
                leftPadding: Theme.spacing.small
                topPadding: Theme.spacing.small
                bottomPadding: Theme.spacing.xxs
                text: row.modelData.text
                font.pixelSize: Theme.font.small
                font.weight: Font.DemiBold
                color: Theme.color.inkMeta
            }
        }

        Component {
            id: device

            ListRow {
                readonly property bool isDefault: row.modelData.kind === "out" ? Audio.sink === row.modelData.node : Audio.source === row.modelData.node

                icon: row.modelData.kind === "in" ? "mic" : (row.modelData.node.name ?? "").includes("bluez") ? "headphones" : (row.modelData.node.name ?? "").includes("hdmi") ? "tv" : "speaker"
                title: Audio.label(row.modelData.node)
                subtitle: isDefault ? "In use" : ""
                selected: isDefault
                onClicked: row.modelData.kind === "out" ? Audio.setDefault(row.modelData.node) : Audio.setDefaultSource(row.modelData.node)
            }
        }

        Component {
            id: app

            ColumnLayout {
                spacing: Theme.spacing.xxs

                Label {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.spacing.small
                    text: Audio.label(row.modelData.node)
                    elide: Text.ElideRight
                    font.weight: Font.Medium
                }

                Slider {
                    Layout.fillWidth: true
                    icon: row.modelData.node.audio?.muted ? "volume_off" : "volume_up"
                    value: row.modelData.node.audio?.volume ?? 0
                    onMoved: v => {
                        const a = row.modelData.node.audio;
                        if (a) {
                            a.muted = false;
                            a.volume = Math.max(0, Math.min(1.5, v));
                        }
                    }
                }
            }
        }
    }
}
