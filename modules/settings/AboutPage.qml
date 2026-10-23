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

    // every changed option in one file, to carry to another machine or keep before a reinstall
    Section {
        id: sync

        property string status: ""

        Layout.fillWidth: true
        title: "Sync settings"
        icon: "sync"
        subtitle: "Export your options to a file, or load them from one."

        OptionRow {
            label: "File"

            Field {
                id: syncPath

                implicitWidth: 320
                implicitHeight: 40
                text: Quickshell.env("HOME") + "/sweeteh-settings.json"
            }
        }

        OptionRow {
            label: sync.status || "Your keybinds, layout and theme travel with it."

            Button {
                icon: "upload"
                text: "Export"
                onClicked: {
                    exportFile.setText(JSON.stringify(Config.user, null, 2) + "\n");
                    sync.status = "Saved to " + syncPath.text;
                }
            }

            Button {
                icon: "download"
                text: "Import"
                onClicked: {
                    if (importFile.path === syncPath.text)
                        importFile.reload();
                    else
                        importFile.path = syncPath.text;
                }
            }
        }

        FileView {
            id: exportFile

            path: syncPath.text
            blockLoading: true
            printErrors: false
        }

        // only given a path on import, a file view loads as soon as it has one
        FileView {
            id: importFile

            printErrors: false
            onLoaded: {
                try {
                    const parsed = JSON.parse(text());
                    if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed))
                        throw "not an object";
                    Config.save(parsed);
                    sync.status = "Loaded from " + syncPath.text;
                } catch (e) {
                    sync.status = "That file is not a sweeteh settings file.";
                }
            }
            onLoadFailed: sync.status = "Could not read " + syncPath.text
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
