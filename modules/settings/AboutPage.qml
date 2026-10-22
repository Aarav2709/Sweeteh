import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.theme
import qs.services
import qs.components

// version, files and shell actions
ColumnLayout {
    spacing: Theme.spacing.small

    FileView {
        id: version

        path: Quickshell.shellPath("VERSION")
        printErrors: false
    }

    Label {
        text: "Sweeteh"
        font.pixelSize: Theme.font.display
        font.weight: Font.DemiBold
        color: Theme.color.primary
    }

    Label {
        text: "Version " + (version.text().trim() || "unknown") + ", a shell built around one island."
        font.pixelSize: Theme.font.large
        color: Theme.color.inkMeta
    }

    Section {
        Layout.fillWidth: true
        title: "Updates"
        icon: "system_update"

        OptionRow {
            label: Updates.available !== "" ? "Version " + Updates.available.replace(/^v/, "") + " is available" : "You are on the newest release"
            hint: Updates.updating ? "Updating, the shell restarts by itself when it is done." : "Updates come from tagged releases of the repository."

            Button {
                visible: Updates.available === ""
                variant: "neutral"
                icon: "refresh"
                text: Updates.checking ? "Checking" : "Check now"
                disabled: Updates.checking
                onClicked: Updates.check()
            }

            Button {
                visible: Updates.available !== ""
                variant: "filled"
                icon: "download"
                text: "Update"
                disabled: Updates.updating
                onClicked: Updates.update()
            }
        }
    }

    Section {
        Layout.fillWidth: true
        title: "Files"
        icon: "folder"

        Repeater {
            model: [
                { label: "Config", path: Config.path },
                { label: "Shell", path: Quickshell.shellPath("") },
                { label: "State", path: Paths.state + "/" }
            ]

            OptionRow {
                required property var modelData

                label: modelData.label
                hint: modelData.path

                IconButton {
                    icon: "folder_open"
                    onClicked: Actions.run(["xdg-open", modelData.path.slice(0, modelData.path.lastIndexOf("/") + 1)])
                }
            }
        }
    }

    Section {
        Layout.fillWidth: true
        title: "Shell"
        icon: "terminal"

        OptionRow {
            label: "Reload the shell"
            hint: "Config changes apply live, this restarts every module."

            Button {
                icon: "refresh"
                text: "Reload"
                onClicked: Quickshell.reload(true)
            }
        }

        OptionRow {
            label: "Recolor from the wallpaper"

            Button {
                icon: "palette"
                text: "Recolor"
                onClicked: Wallpapers.recolor(Wallpapers.current)
            }
        }
    }
}
