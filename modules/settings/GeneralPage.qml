import QtQuick
import QtQuick.Layouts
import qs.config
import qs.theme
import qs.services
import qs.components

// every remaining option, generated from the defaults
ColumnLayout {
    id: root

    readonly property var sections: ["general", "clock", "notifications", "osd", "launcher", "island", "moments", "media", "desktop", "lock", "power", "nightLight", "performance", "clipboard", "overview"]
    readonly property var icons: ({ general: "tune", clock: "schedule", notifications: "notifications", osd: "volume_up", launcher: "search", island: "pill", moments: "auto_awesome", media: "music_note", desktop: "widgets", lock: "lock", power: "battery_charging_full", nightLight: "nightlight", performance: "speed", clipboard: "content_paste", overview: "overview" })

    spacing: Theme.spacing.small

    Label {
        text: "General"
        font.pixelSize: Theme.font.headline
        font.weight: Font.DemiBold
    }

    // first on the page, so trying a moment is one click away
    Section {
        Layout.fillWidth: true
        title: "Preview moments"
        icon: "play_circle"
        subtitle: "See each island moment without waiting for it to happen."

        Flow {
            Layout.fillWidth: true
            spacing: Theme.spacing.small

            Repeater {
                model: [["battery", "Charging"], ["unplugged", "Unplugged"], ["low", "Low"], ["critical", "Critical"], ["welcome", "Welcome"], ["bluetooth", "Bluetooth"], ["network", "Wi-Fi"], ["toggles", "Toggle"], ["privacy", "Privacy"], ["downloads", "Download"], ["clipboard", "Clipboard"], ["audio", "Audio output"]]

                Button {
                    required property var modelData

                    implicitHeight: 32
                    variant: "neutral"
                    text: modelData[1]
                    onClicked: Actions.momentPreview(modelData[0])
                }
            }
        }
    }

    Repeater {
        model: root.sections

        Section {
            id: section

            required property string modelData

            Layout.fillWidth: true
            title: Theme.humanize(modelData)
            icon: root.icons[modelData] ?? ""

            Repeater {
                model: Object.keys(Defaults.values[section.modelData]).filter(k => typeof Defaults.values[section.modelData][k] !== "object")

                AutoOption {
                    required property string modelData

                    key: section.modelData + "." + modelData
                }
            }
        }
    }

    Section {
        Layout.fillWidth: true
        title: "Arrange widgets"
        icon: "dashboard_customize"
        subtitle: "Place clock, dial, weather, calendar, media and tasks widgets on the desktop."

        OptionRow {
            label: "Edit the desktop"

            Button {
                icon: "widgets"
                text: "Edit"
                onClicked: Actions.editDesktop()
            }
        }
    }
}
