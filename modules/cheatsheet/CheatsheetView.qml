import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.components
import "../../services/Fuzzy.js" as Fuzzy

// every hyprland bind that has a description, searchable in the island
Item {
    id: root

    property string filter: ""
    readonly property var matches: Keybinds.live.filter(b => filter === "" || Fuzzy.best(filter, [b.description, b.mods + " " + b.key]) > 0)

    // readable names for keys that hyprland spells in lowercase
    function keyName(key: string): string {
        const names = { escape: "Esc", return: "Enter", tab: "Tab", space: "Space", slash: "Slash", comma: "Comma", period: "Period", print: "Print", backspace: "Backspace", delete: "Delete" };
        const k = String(key);
        return names[k.toLowerCase()] ?? (k.length === 1 ? k.toUpperCase() : k.charAt(0).toUpperCase() + k.slice(1).toLowerCase());
    }

    implicitWidth: 780
    implicitHeight: 470

    function reset(): void {
        Keybinds.refresh();
        field.text = "";
        filter = "";
        field.focusInput();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.medium

            Label {
                text: "Keybinds"
                font.pixelSize: Theme.font.headline
                font.weight: Font.DemiBold
            }

            Field {
                id: field

                Layout.fillWidth: true
                icon: "search"
                placeholder: "Search keybinds"
                onEdited: root.filter = text
            }

            Button {
                icon: "edit"
                text: "Edit"
                onClicked: Actions.openSettings("Keybinds")
            }
        }

        GridView {
            id: grid

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: width / 2
            cellHeight: 52
            model: root.matches

            delegate: Item {
                required property var modelData

                width: grid.cellWidth
                height: grid.cellHeight

                RowLayout {
                    anchors.fill: parent
                    anchors.rightMargin: Theme.spacing.large
                    spacing: Theme.spacing.medium

                    Row {
                        spacing: Theme.spacing.xs

                        Repeater {
                            model: [...modelData.mods.split(" "), modelData.key].filter(k => k !== "")

                            Rectangle {
                                required property string modelData

                                width: Math.max(30, keyLabel.implicitWidth + Theme.spacing.medium * 2)
                                height: 28
                                radius: Theme.radius.small
                                color: Theme.color.layer2
                                border.width: Theme.depth.rim
                                border.color: Theme.color.depthRim

                                Depth {}

                                Label {
                                    id: keyLabel

                                    anchors.centerIn: parent
                                    text: root.keyName(modelData)
                                    font.pixelSize: Theme.font.small
                                    font.weight: Font.DemiBold
                                }
                            }
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: modelData.description
                        color: Theme.color.inkMeta
                    }
                }
            }

            Label {
                anchors.centerIn: parent
                width: parent.width * 0.7
                visible: grid.count === 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: Keybinds.live.length === 0 ? "No binds with a description yet. Add a description option to your hyprland binds, or install sweeteh to get its binds." : "Nothing matches that search."
                color: Theme.color.inkMeta
            }
        }
    }
}
