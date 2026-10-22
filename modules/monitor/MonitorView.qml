import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.components

// a small task manager shown inside the island, it samples only while visible
Item {
    id: root

    property int armed: -1
    // set while the island shows this view, sampling runs only then
    property bool active: false

    implicitWidth: 760
    implicitHeight: 360
    width: implicitWidth
    height: implicitHeight
    onActiveChanged: {
        System.watchers += active ? 1 : -1;
        System.wantProcesses = active;
        armed = -1;
    }
    Component.onDestruction: {
        if (active)
            System.watchers--;
    }

    RowLayout {
        anchors.fill: parent
        spacing: Theme.spacing.large

        ColumnLayout {
            Layout.preferredWidth: 360
            Layout.maximumWidth: 360
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignTop
            spacing: Theme.spacing.small

            RowLayout {
                Layout.leftMargin: Theme.spacing.xs
                Layout.bottomMargin: Theme.spacing.xs

                Label {
                    text: "System"
                    font.pixelSize: Theme.font.headline
                    font.weight: Font.DemiBold
                }

                Label {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: 4
                    horizontalAlignment: Text.AlignRight
                    text: "Up for " + System.duration(System.uptime)
                    font.pixelSize: Theme.font.small
                    color: Theme.color.inkMeta
                }
            }

            StatCard {
                Layout.fillWidth: true
                icon: "memory"
                title: "Processor"
                value: Math.round(System.cpu * 100) + "%"
                badge: System.temp > 0 ? Math.round(System.temp) + "°" : ""
                history: System.cpuHistory
            }

            StatCard {
                Layout.fillWidth: true
                icon: "memory_alt"
                title: "Memory"
                value: System.bytes(System.memUsed) + " of " + System.bytes(System.memTotal)
                note: System.swapTotal > 0 ? "Swap " + System.bytes(System.swapUsed) + " of " + System.bytes(System.swapTotal) : ""
                history: System.memHistory
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.spacing.small

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacing.small

                Tile {
                    icon: "hard_drive"
                    title: "Disk"
                    value: Math.round(System.diskRatio * 100) + "%"
                    note: System.bytes(System.diskUsed) + " of " + System.bytes(System.diskTotal)
                    ratio: System.diskRatio
                }

                Tile {
                    icon: "swap_vert"
                    title: "Network"
                    value: System.bytes(System.down) + "/s"
                    note: "Up " + System.bytes(System.up) + "/s"
                    ratio: -1
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radius.large
                color: Theme.color.layer1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacing.medium
                    spacing: Theme.spacing.xxs

                    Label {
                        Layout.bottomMargin: Theme.spacing.xs
                        text: root.armed > 0 ? "Press the check to end it." : "Busiest processes"
                        font.weight: Font.DemiBold
                        color: root.armed > 0 ? Theme.color.error : Theme.color.ink
                    }

                    Repeater {
                        model: System.processes.slice(0, 5)

                        RowLayout {
                            id: proc

                            required property var modelData

                            Layout.fillWidth: true
                            spacing: Theme.spacing.small

                            Label {
                                Layout.fillWidth: true
                                text: proc.modelData.name
                            }

                            Label {
                                Layout.preferredWidth: 48
                                horizontalAlignment: Text.AlignRight
                                text: proc.modelData.cpu.toFixed(1) + "%"
                                font.pixelSize: Theme.font.small
                                font.features: ({
                                        "tnum": 1
                                    })
                                color: Theme.color.inkMeta
                            }

                            IconButton {
                                size: 26
                                icon: root.armed === proc.modelData.pid ? "check" : "close"
                                checked: root.armed === proc.modelData.pid
                                onClicked: {
                                    if (root.armed === proc.modelData.pid) {
                                        System.kill(proc.modelData.name);
                                        root.armed = -1;
                                    } else
                                        root.armed = proc.modelData.pid;
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }

    component StatCard: Rectangle {
        id: card

        property string icon
        property string title
        property string value
        property string note
        property string badge
        property var history: []

        implicitHeight: column.implicitHeight + Theme.spacing.medium * 2
        radius: Theme.radius.large
        color: Theme.color.layer1

        ColumnLayout {
            id: column

            anchors.fill: parent
            anchors.margins: Theme.spacing.medium
            spacing: Theme.spacing.xs

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacing.small

                Icon {
                    name: card.icon
                    color: Theme.color.primary
                }

                Label {
                    Layout.fillWidth: true
                    text: card.title
                    font.pixelSize: Theme.font.small
                    color: Theme.color.inkMeta
                }

                Rectangle {
                    visible: card.badge !== ""
                    implicitWidth: badgeLabel.implicitWidth + Theme.spacing.small * 2
                    implicitHeight: 22
                    radius: height / 2
                    color: Theme.color.layer2

                    Label {
                        id: badgeLabel

                        anchors.centerIn: parent
                        text: card.badge
                        font.pixelSize: Theme.font.small
                        font.weight: Font.DemiBold
                    }
                }
            }

            Label {
                text: card.value
                font.pixelSize: Theme.font.title
                font.weight: Font.DemiBold
            }

            Sparkline {
                Layout.fillWidth: true
                implicitHeight: 44
                values: card.history
                capacity: System.historySize
            }

            Label {
                Layout.fillWidth: true
                visible: card.note !== ""
                text: card.note
                font.pixelSize: Theme.font.small
                color: Theme.color.inkMeta
            }
        }
    }

    component Tile: Rectangle {
        id: tile

        property string icon
        property string title
        property string value
        property string note
        property real ratio: -1

        Layout.fillWidth: true
        implicitHeight: 104
        radius: Theme.radius.large
        color: Theme.color.layer1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacing.medium
            spacing: Theme.spacing.xxs

            RowLayout {
                spacing: Theme.spacing.small

                Icon {
                    name: tile.icon
                    color: Theme.color.primary
                }

                Label {
                    text: tile.title
                    font.pixelSize: Theme.font.small
                    color: Theme.color.inkMeta
                }
            }

            Item {
                Layout.fillHeight: true
            }

            Label {
                text: tile.value
                font.pixelSize: Theme.font.large
                font.weight: Font.DemiBold
            }

            Label {
                Layout.fillWidth: true
                text: tile.note
                font.pixelSize: Theme.font.tiny
                color: Theme.color.inkMeta
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: Theme.spacing.xxs
                visible: tile.ratio >= 0
                implicitHeight: 6
                radius: 3
                color: Theme.color.layer3

                Rectangle {
                    width: parent.width * Math.max(0, tile.ratio)
                    height: parent.height
                    radius: 3
                    color: Theme.color.primary
                }
            }
        }
    }
}
