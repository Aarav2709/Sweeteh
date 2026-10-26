import QtQuick
import QtQuick.Layouts
import qs.config
import qs.theme
import qs.services
import qs.components

// cards for each mode in the island, arrows and enter switch live
Item {
    id: root

    property int current: Modes.names.indexOf(Modes.current)

    function pick(i: int): void {
        const name = Modes.names[i];
        if (name !== Modes.current) {
            Modes.set(name);
            Actions.say(Modes.modes[name].icon, Modes.modes[name].name + " mode is on.");
        }
        Actions.close("modeswitcher");
    }

    function reset(): void {
        current = Modes.names.indexOf(Modes.current);
        keys.forceActiveFocus();
    }

    implicitWidth: keys.implicitWidth
    implicitHeight: keys.implicitHeight

    ColumnLayout {
        id: keys

        focus: true
        spacing: Theme.spacing.large
        Keys.onLeftPressed: root.current = (root.current + Modes.names.length - 1) % Modes.names.length
        Keys.onRightPressed: root.current = (root.current + 1) % Modes.names.length
        Keys.onTabPressed: root.current = (root.current + 1) % Modes.names.length
        Keys.onReturnPressed: root.pick(root.current)
        Keys.onEnterPressed: root.pick(root.current)

        ColumnLayout {
            spacing: 0

            Label {
                text: "Switch mode"
                font.pixelSize: Theme.font.headline
                font.weight: Font.DemiBold
            }

            Label {
                text: "Pick how the shell sits on screen."
                color: Theme.color.inkMeta
            }
        }

        RowLayout {
            spacing: Theme.spacing.medium

            Repeater {
                model: Modes.names

                Rectangle {
                    id: card

                    required property string modelData
                    required property int index
                    readonly property var mode: Modes.modes[modelData]
                    readonly property bool selected: root.current === index
                    readonly property bool active: Modes.current === modelData
                    readonly property color ink: selected ? Theme.color.fgPrimaryContainer : Theme.color.ink

                    implicitWidth: 200
                    implicitHeight: 176
                    radius: Theme.radius.xl
                    color: selected ? Theme.color.primaryContainer : Theme.color.layer1

                    Behavior on color {
                        ColorAnim {}
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spacing.large
                        spacing: Theme.spacing.xxs

                        RowLayout {
                            Layout.fillWidth: true

                            Rectangle {
                                implicitWidth: 44
                                implicitHeight: 44
                                radius: card.selected ? Theme.radius.medium : width / 2
                                color: card.selected ? Theme.color.primary : Theme.color.layer2

                                Behavior on radius {
                                    Anim {}
                                }

                                Icon {
                                    anchors.centerIn: parent
                                    name: card.mode.icon
                                    size: 22
                                    fill: card.selected ? 1 : 0
                                    color: card.selected ? Theme.color.fgPrimary : Theme.color.ink
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Icon {
                                Layout.alignment: Qt.AlignTop
                                visible: card.active
                                name: "check_circle"
                                fill: 1
                                color: card.selected ? Theme.color.fgPrimaryContainer : Theme.color.primary
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        Label {
                            text: card.mode.name
                            font.pixelSize: Theme.font.title
                            font.weight: Font.DemiBold
                            color: card.ink
                        }

                        Label {
                            Layout.fillWidth: true
                            text: card.mode.bar ? "Bar pills around the island." : "Just the island."
                            font.pixelSize: Theme.font.small
                            color: card.selected ? Qt.alpha(Theme.color.fgPrimaryContainer, 0.8) : Theme.color.inkMeta
                        }
                    }

                    StateLayer {
                        tint: card.ink
                        onEntered: root.current = card.index
                        onClicked: root.pick(card.index)
                    }
                }
            }
        }
    }
}
