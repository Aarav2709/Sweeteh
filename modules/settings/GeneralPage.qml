import QtQuick
import QtQuick.Layouts
import qs.config
import qs.theme
import qs.services
import qs.components

// every remaining option, generated from the defaults
ColumnLayout {
    id: root

    readonly property var sections: ["general", "clock", "notifications", "osd", "launcher", "island", "media", "desktop", "lock", "power", "nightLight", "clipboard", "overview"]
    readonly property var icons: ({ general: "tune", clock: "schedule", notifications: "notifications", osd: "volume_up", launcher: "search", island: "pill", media: "music_note", desktop: "widgets", lock: "lock", power: "battery_charging_full", nightLight: "nightlight", clipboard: "content_paste", overview: "overview" })

    spacing: Theme.spacing.small

    Label {
        text: "General"
        font.pixelSize: Theme.font.headline
        font.weight: Font.DemiBold
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
