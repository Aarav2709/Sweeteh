import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.theme
import qs.services
import qs.components

// what the release brought, offered once after an update and kept in the launcher
Item {
    id: root

    readonly property string version: versionFile.text().trim()
    // what 1.1.1 brought, the same story as the release notes
    readonly property var notes: [["healing", "No more sudden exits", "The crash while typing in the launcher is gone, : included."], ["restart_alt", "Back by itself", "If the shell ever does crash, it restarts without a dialog in the way."], ["select_window", "Windows in the launcher", "@ switches to an open window, Ctrl Enter closes it."], ["content_paste", "Clipboard, files and ssh", "\" searches what you copied, / lists recent files, $ connects to a host."], ["terminal", "Your own commands", "Add rows to launcher.commands in the config, they show in > too."], ["palette", "Fixed themes", "Catppuccin, Gruvbox, Rosé Pine, Nord, Tokyo Night and Everforest."]]

    signal done

    implicitWidth: 760
    implicitHeight: column.implicitHeight

    focus: true
    Keys.onReturnPressed: done()
    Keys.onEnterPressed: done()
    Keys.onEscapePressed: done()

    FileView {
        id: versionFile

        path: Quickshell.shellPath("VERSION")
    }

    ColumnLayout {
        id: column

        width: parent.width
        spacing: Theme.spacing.large

        ColumnLayout {
            spacing: 0

            Label {
                text: "What's new in " + root.version
                font.pixelSize: Theme.font.headline
                font.weight: Font.DemiBold
            }

            Label {
                text: "Sweeteh just updated, here is what came with it."
                color: Theme.color.inkMeta
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Theme.spacing.xl
            rowSpacing: Theme.spacing.medium

            Repeater {
                model: root.notes

                RowLayout {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: Theme.spacing.medium

                    // centered on the title and its line together
                    IconBadge {
                        Layout.alignment: Qt.AlignVCenter
                        name: modelData[0]
                        shape: "cookie9"
                        size: 30
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Label {
                            text: modelData[1]
                            font.weight: Font.DemiBold
                        }

                        Label {
                            Layout.fillWidth: true
                            text: modelData[2]
                            wrapMode: Text.Wrap
                            font.pixelSize: Theme.font.small
                            color: Theme.color.inkMeta
                        }
                    }
                }
            }
        }

        Button {
            Layout.alignment: Qt.AlignRight
            variant: "filled"
            text: "Got it"
            onClicked: root.done()
        }
    }
}
