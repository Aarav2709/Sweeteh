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
    readonly property var notes: [
        ["visibility_off", "Out of the way in fullscreen", "The island tucks away over games and videos, the small stuff waits until you are back."],
        ["search", "A smarter launcher", "Type : for emoji, >tr to translate, 10 km to mi to convert and ? for everything else."],
        ["colorize", "New tools", "A color picker, text from the screen and system updates, all from >."],
        ["volume_up", "Sound page", "Pick devices and set each app's volume in quick settings."],
        ["wallpaper", "Wallhaven in the picker", "Search and set wallpapers without leaving the island."],
        ["lock", "A calmer lock", "Your password typed as shapes in your wallpaper's colors."]
    ]

    signal done

    implicitWidth: 520
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

        Repeater {
            model: root.notes

            RowLayout {
                required property var modelData

                Layout.fillWidth: true
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

        Button {
            Layout.alignment: Qt.AlignRight
            variant: "filled"
            text: "Got it"
            onClicked: root.done()
        }
    }
}
