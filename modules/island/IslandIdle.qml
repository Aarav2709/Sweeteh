import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.theme
import qs.services
import qs.components

// resting island, the time with the track playing beside it
// without a bar around it the island also shows the workspace and status
Item {
    id: root

    property bool shown: true
    readonly property bool hovered: hover.hovered
    readonly property bool alone: !Modes.islands

    implicitWidth: row.implicitWidth + Theme.spacing.medium * 2
    implicitHeight: Config.options.island.height
    opacity: shown ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        Anim {}
    }

    HoverHandler {
        id: hover
    }

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Theme.spacing.small

        // a recording in progress, click to stop it
        Rectangle {
            visible: Recorder.recording
            implicitWidth: recRow.implicitWidth + Theme.spacing.small * 2
            implicitHeight: 22
            radius: height / 2
            color: Theme.color.error

            Row {
                id: recRow

                anchors.centerIn: parent
                spacing: Theme.spacing.xs

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8
                    height: 8
                    radius: 4
                    color: Theme.color.fgError

                    SequentialAnimation on opacity {
                        running: Recorder.recording
                        loops: Animation.Infinite

                        NumberAnimation {
                            to: 0.25
                            duration: 700
                        }

                        NumberAnimation {
                            to: 1
                            duration: 700
                        }
                    }
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Recorder.elapsed
                    font.pixelSize: Theme.font.small
                    font.weight: Font.DemiBold
                    font.features: ({
                            "tnum": 1
                        })
                    color: Theme.color.fgError
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Recorder.stop()
            }
        }

        Rectangle {
            visible: root.alone
            implicitWidth: Math.max(implicitHeight, wsLabel.implicitWidth + Theme.spacing.small * 2)
            implicitHeight: 22
            radius: height / 2
            color: Theme.color.primary

            Label {
                id: wsLabel

                anchors.centerIn: parent
                text: Hypr.activeWorkspace
                font.pixelSize: Theme.font.small
                font.weight: Font.DemiBold
                color: Theme.color.fgPrimary
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Actions.toggle("overview")
            }
        }

        ClippingRectangle {
            visible: Media.active && Media.art !== ""
            implicitWidth: 22
            implicitHeight: 22
            radius: Theme.radius.xs
            color: Theme.color.layer2

            Image {
                anchors.fill: parent
                source: Media.art
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(44, 44)
            }
        }

        // hovering swaps the time for what is playing, or the date when nothing is
        Label {
            Layout.leftMargin: Theme.spacing.xs
            Layout.rightMargin: Theme.spacing.xs
            Layout.maximumWidth: 300
            text: !root.hovered ? Time.time : Media.active ? Media.title + (Media.artist ? ", " + Media.artist : "") : Time.shortDate + "   " + Time.time
            font.weight: Font.DemiBold
            font.features: ({
                    "tnum": 1
                })
        }

        // a small level meter that dances while music plays
        Row {
            visible: Media.active
            spacing: 2

            Repeater {
                model: 4

                Rectangle {
                    id: bar

                    required property int index
                    property real level: 0.3

                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: 4 + 10 * level
                    radius: 1.5
                    color: Theme.color.primary

                    SequentialAnimation on level {
                        running: Media.playing && root.visible
                        loops: Animation.Infinite

                        NumberAnimation {
                            to: 1
                            duration: 260 + bar.index * 70
                            easing.type: Easing.InOutSine
                        }

                        NumberAnimation {
                            to: 0.2
                            duration: 300 + bar.index * 50
                            easing.type: Easing.InOutSine
                        }
                    }
                }
            }
        }

        Rectangle {
            visible: Notifs.list.length > 0 && !Notifs.dnd
            implicitWidth: 6
            implicitHeight: 6
            radius: 3
            color: Theme.color.primary
        }

        Icon {
            visible: Notifs.dnd
            name: "do_not_disturb_on"
            size: Theme.font.large
            color: Theme.color.inkMeta
        }

        Row {
            visible: root.alone
            spacing: Theme.spacing.xxs

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: Battery.available ? Battery.icon : Network.icon
                size: Theme.font.large
                color: Battery.available && Battery.percent <= 15 && !Battery.charging ? Theme.color.error : Theme.color.ink
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                visible: Battery.available
                text: Battery.percent + "%"
                font.pixelSize: Theme.font.bar
                font.weight: Font.DemiBold
                font.features: ({
                        "tnum": 1
                    })
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: e => e.button === Qt.RightButton ? Actions.open("modeswitcher") : e.button === Qt.MiddleButton ? Media.toggle() : Actions.toggle("island")
        onWheel: e => Audio.setVolume(Audio.volume + (e.angleDelta.y > 0 ? 0.05 : -0.05))
    }
}
