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
    // everything since 1.0.0, the same story as the release notes
    readonly property var notes: [["visibility_off", "Out of the way in fullscreen", "The island tucks away over games and videos, the small stuff waits."], ["search", "A smarter launcher", ": for emoji, >tr to translate, 10 km to mi, app actions and ? for help."], ["colorize", "New tools", "A color picker, text from the screen and system updates, all from >."], ["volume_up", "Sound page", "Pick devices and set each app's volume in quick settings."], ["music_note", "Better media", "Shuffle, repeat, every player and cleaner YouTube titles."], ["timer", "More in the island", "VPN toggles, a running timer and quiet hours for notifications."], ["wallpaper", "Wallhaven in the picker", "Search and set wallpapers without leaving the island."], ["widgets", "New desktop widgets", "Synced lyrics, a live spectrum and a right click menu."], ["push_pin", "Pins and search", "Pin clipboard entries and search every setting."], ["lock", "A nicer lock", "A rolling clock and your password typed as shapes."], ["interests", "Crisper icons", "Sharper glyphs, and moments set in material shapes."], ["download", "Tools that ask", "A missing package says so and installs with a click."], ["speed", "Calmer and lighter", "Motion with no bounces, less drawing and no more freezes."]]

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
