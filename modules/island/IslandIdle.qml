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
    readonly property color tint: Media.hasAccent ? Media.accent : Theme.color.primary
    // while a song plays the whole resting island takes the cover color, not only the meter
    readonly property bool themed: Media.playing && Media.hasAccent
    readonly property color accent: themed ? Media.accent : Theme.color.primary
    readonly property color onAccent: themed ? "#111111" : Theme.color.fgPrimary
    readonly property color ink: themed ? Theme.mix(Theme.color.ink, Qt.lighter(Media.accent, 1.35), 0.55) : Theme.color.ink
    readonly property color batteryColor: Battery.charging ? "#30d158" : Battery.low ? "#ff453a" : Battery.saver ? "#ffd60a" : ink
    // a sideways swipe skips the track, the row follows the finger a little
    property real drag: 0
    property bool swiped: false

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
        anchors.horizontalCenterOffset: root.drag

        Behavior on anchors.horizontalCenterOffset {
            enabled: !mouse.pressed

            Anim {
                duration: Theme.anim.slow
                easing.bezierCurve: Theme.anim.spatialFast
            }
        }
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
            color: root.accent

            Behavior on color {
                ColorAnim {
                    duration: Theme.anim.slow
                }
            }

            Label {
                id: wsLabel

                anchors.centerIn: parent
                text: Hypr.activeWorkspace
                font.pixelSize: Theme.font.small
                font.weight: Font.DemiBold
                color: root.onAccent
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
            color: root.ink
            text: !root.hovered ? Time.time : Media.active ? Media.title + (Media.artist ? ", " + Media.artist : "") : Time.shortDate + "   " + Time.time
            font.weight: Font.DemiBold
            font.features: ({
                    "tnum": 1
                })
        }

        // the microphone, camera or screen in use by an app
        Row {
            visible: Privacy.mic || Privacy.camera || Privacy.screen
            spacing: 3

            Repeater {
                model: [Privacy.camera ? "#30d158" : "", Privacy.mic ? "#ff9f0a" : "", Privacy.screen ? "#bf5af2" : ""].filter(c => c !== "")

                Rectangle {
                    required property string modelData

                    anchors.verticalCenter: parent.verticalCenter
                    width: 7
                    height: 7
                    radius: 3.5
                    color: modelData
                }
            }
        }

        // a browser download in progress
        Row {
            visible: Downloads.active
            spacing: Theme.spacing.xxs

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: "downloading"
                size: Theme.font.large
                color: "#64d2ff"
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: Downloads.format(Downloads.bytes)
                font.pixelSize: Theme.font.small
                font.weight: Font.DemiBold
                font.features: ({
                        "tnum": 1
                    })
            }
        }

        // the level meter follows the real audio through cava, or dances without it, in the cover color
        Row {
            visible: Media.active
            spacing: 2

            Repeater {
                model: 5

                Rectangle {
                    id: bar

                    required property int index
                    property real level: 0.3

                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: 4 + 12 * (Cava.active ? Cava.values[index] ?? 0 : Media.playing ? level : 0.1)
                    radius: 1.5
                    color: root.tint

                    Behavior on height {
                        enabled: Cava.active

                        NumberAnimation {
                            duration: 60
                        }
                    }

                    SequentialAnimation on level {
                        running: Media.playing && root.visible && !Cava.active
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

        // a little battery that fills to the level, green on the charger, red when low, yellow on the saver
        Row {
            visible: root.alone
            spacing: Theme.spacing.xs

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                visible: !Battery.available
                name: Network.icon
                size: Theme.font.large
                color: root.ink
            }

            Item {
                anchors.verticalCenter: parent.verticalCenter
                visible: Battery.available
                implicitWidth: 25
                implicitHeight: 13

                Rectangle {
                    id: cell

                    width: 22
                    height: 13
                    radius: 4
                    color: "transparent"
                    border.width: 1.5
                    border.color: Qt.alpha(root.batteryColor, 0.55)

                    Rectangle {
                        x: 2.5
                        y: 2.5
                        height: parent.height - 5
                        width: Math.max(2, (parent.width - 5) * Battery.level)
                        radius: 1.5
                        color: root.batteryColor

                        Behavior on width {
                            Anim {}
                        }

                        Behavior on color {
                            ColorAnim {}
                        }
                    }
                }

                Rectangle {
                    anchors.left: cell.right
                    anchors.leftMargin: 1
                    anchors.verticalCenter: cell.verticalCenter
                    width: 2
                    height: 5
                    radius: 1
                    color: Qt.alpha(root.batteryColor, 0.55)
                }

                Icon {
                    anchors.centerIn: cell
                    visible: Battery.charging
                    name: "bolt"
                    fill: 1
                    size: 14
                    color: "#ffffff"
                }
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
                color: Battery.low || Battery.charging ? root.batteryColor : root.ink
            }
        }
    }

    // how far the track has played, a thin line along the flat part of the bottom
    Rectangle {
        readonly property int inset: Theme.radius.medium

        visible: Media.active && Media.length > 0
        x: inset
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        width: (root.width - inset * 2) * Math.min(1, Media.position / Math.max(1, Media.length))
        height: 1
        radius: 0.5
        color: root.tint
        opacity: 0.85

        Behavior on width {
            Anim {
                duration: 1000
                easing.bezierCurve: Theme.anim.standard
            }
        }
    }

    Timer {
        id: single

        interval: 220
        onTriggered: Actions.toggle("island")
    }

    MouseArea {
        id: mouse

        property real pressX: 0
        property real pressY: 0

        anchors.fill: parent
        z: -1
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: e => {
            pressX = e.x;
            pressY = e.y;
            root.swiped = false;
        }
        onPositionChanged: e => {
            if (pressed && Media.active)
                root.drag = Math.max(-28, Math.min(28, (e.x - pressX) / 2));
        }
        onReleased: e => {
            const dx = e.x - pressX, dy = e.y - pressY;
            // pulling the island down opens the dashboard, a sideways swipe skips the track
            if (dy > 24 && dy > Math.abs(dx)) {
                root.swiped = true;
                Actions.open("island");
            } else if (Media.active && Math.abs(dx) > 40) {
                root.swiped = true;
                dx < 0 ? Media.next() : Media.previous();
            }
            root.drag = 0;
        }
        // with music loaded a double click plays or pauses, so a single click waits a beat to be sure
        onClicked: e => {
            if (root.swiped)
                return;
            if (e.button === Qt.RightButton)
                Actions.open("modeswitcher");
            else if (e.button === Qt.MiddleButton)
                Media.toggle();
            else if (Media.active)
                single.restart();
            else
                Actions.toggle("island");
        }
        onDoubleClicked: e => {
            if (e.button !== Qt.LeftButton || !Media.active)
                return;
            single.stop();
            Media.toggle();
        }
        onWheel: e => {
            const step = e.angleDelta.y > 0 ? 0.05 : -0.05;
            if (Media.playing && Media.volumeSupported)
                Media.setVolume(Media.volume + step);
            else
                Audio.setVolume(Audio.volume + step);
        }
    }
}
