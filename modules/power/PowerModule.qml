import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.components

// power menu, arrows move, enter runs, a second press confirms risky actions
Panel {
    id: root

    property int current: 0
    property int armed: -1
    readonly property var items: [
        { icon: "lock", label: "Lock", risky: false, run: () => Session.lock() },
        { icon: "bedtime", label: "Suspend", risky: false, run: () => Session.suspend() },
        { icon: "logout", label: "Log out", risky: true, run: () => Session.logout() },
        { icon: "restart_alt", label: "Reboot", risky: true, run: () => Session.reboot() },
        { icon: "power_settings_new", label: "Shut down", risky: true, run: () => Session.poweroff() }
    ]

    function activate(i: int): void {
        const item = items[i];
        if (item.risky && armed !== i) {
            armed = i;
            return;
        }
        Actions.close("power");
        item.run();
    }

    panelId: "power"
    edge: "center"
    exclusiveKeyboard: true
    padding: Theme.spacing.xl
    onOpened: {
        current = 0;
        armed = -1;
    }

    ColumnLayout {
        focus: true
        spacing: Theme.spacing.xl
        Keys.onLeftPressed: root.current = (root.current + root.items.length - 1) % root.items.length
        Keys.onRightPressed: root.current = (root.current + 1) % root.items.length
        Keys.onTabPressed: root.current = (root.current + 1) % root.items.length
        Keys.onReturnPressed: root.activate(root.current)
        Keys.onEnterPressed: root.activate(root.current)

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: Time.time
                font.pixelSize: Theme.font.display
                font.weight: Font.DemiBold
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: root.armed >= 0 ? "Press again to " + root.items[root.armed].label.toLowerCase() + "." : Time.date
                color: root.armed >= 0 ? Theme.color.error : Theme.color.inkMeta
            }
        }

        RowLayout {
            spacing: Theme.spacing.medium

            Repeater {
                model: root.items

                ColumnLayout {
                    id: cell

                    required property var modelData
                    required property int index
                    readonly property bool selected: root.current === index
                    readonly property bool armed: root.armed === index

                    spacing: Theme.spacing.small

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 80
                        implicitHeight: 80
                        radius: layer.pressed ? Theme.radius.medium : cell.selected ? Theme.radius.xl : width / 2
                        color: cell.armed ? Theme.color.error : cell.selected ? Theme.color.primary : Theme.color.layer1

                        Behavior on radius {
                            Anim {
                                easing.bezierCurve: Theme.anim.spatial
                            }
                        }

                        Behavior on color {
                            ColorAnim {}
                        }

                        Icon {
                            anchors.centerIn: parent
                            name: cell.modelData.icon
                            size: 30
                            fill: cell.selected ? 1 : 0
                            color: cell.armed ? Theme.color.fgError : cell.selected ? Theme.color.fgPrimary : Theme.color.ink
                        }

                        StateLayer {
                            id: layer

                            tint: cell.selected ? Theme.color.fgPrimary : Theme.color.ink
                            onEntered: root.current = cell.index
                            onClicked: root.activate(cell.index)
                        }
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: cell.modelData.label
                        font.weight: cell.selected ? Font.DemiBold : Font.Normal
                        color: cell.selected ? Theme.color.ink : Theme.color.inkMeta
                    }
                }
            }
        }
    }
}
