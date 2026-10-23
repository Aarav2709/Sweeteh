import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.components

// a short colored moment, the island blushes with the accent and a shine sweeps across it
// battery moments draw a little battery, every other one pops its icon in
Item {
    id: root

    property bool shown: false
    // kind, and optionally icon, title, sub and accent
    property var moment: ({ kind: "plugged" })
    readonly property string kind: moment.kind ?? ""
    readonly property bool plugged: kind === "plugged"
    readonly property bool battery: ["plugged", "unplugged", "low", "critical"].includes(kind)
    readonly property bool warning: kind === "low" || kind === "critical"
    // every moment speaks in the shell accent, only alerts turn to the error color
    readonly property bool alert: kind === "critical" || (moment.alert ?? false)
    readonly property color accent: alert ? Theme.color.error : Theme.color.primary
    readonly property color blush: alert ? Theme.color.errorContainer : Theme.color.vivid
    readonly property string title: moment.title ?? (({ welcome: "Welcome back!", plugged: Battery.percent >= 100 ? "Fully charged" : "Charging", unplugged: "On battery", low: "Battery low", critical: "Battery critical" })[kind] ?? "")
    readonly property string icon: moment.icon ?? (kind === "welcome" ? "waving_hand" : "info")
    // the charger moments say how fast power flows and how long it lasts, live while they show
    readonly property string sub: moment.sub ?? (warning && Battery.autoSaver ? "Battery saver on" : battery ? [Battery.watts >= 0.5 ? Battery.watts.toFixed(Battery.watts < 10 ? 1 : 0) + " W" : "", Battery.percent < 100 && Battery.timeText ? Battery.timeText + (Battery.charging ? " to full" : " left") : ""].filter(t => t).join("  ·  ") : "")
    // moments that can do something on click show a pointer
    readonly property bool actionable: typeof moment.run === "function"
    // a stronger blush for moments that stand on their own
    readonly property real strength: moment.strength ?? (kind === "welcome" ? 0.6 : 0.4)
    // read by the surface, glow tints the notch and sweep moves the shine from 0 to 1
    property real glow: 0
    property real sweep: -1
    property real fill: Battery.level
    property real bolt: 0

    signal clicked

    implicitWidth: row.implicitWidth + Theme.spacing.small * 2
    implicitHeight: row.implicitHeight

    function play(): void {
        outro.stop();
        breathe.stop();
        fill = plugged ? 0 : Battery.level;
        bolt = 0;
        intro.restart();
    }

    onShownChanged: {
        if (shown) {
            play();
        } else {
            intro.stop();
            breathe.stop();
            sweep = -1;
            outro.restart();
        }
    }

    // one moment straight after another plays again from the start
    onMomentChanged: {
        if (shown)
            play();
    }

    // burst of color and the shine, then a calm breathing until the flash ends
    SequentialAnimation {
        id: intro

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "glow"
                to: 1
                duration: 320
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: root
                property: "sweep"
                from: root.kind === "unplugged" ? 1 : 0
                to: root.kind === "unplugged" ? 0 : 1
                duration: 1100
                easing.type: Easing.InOutCubic
            }

            NumberAnimation {
                target: root
                property: "fill"
                to: Battery.level
                duration: 1000
                easing.type: Easing.OutCubic
            }

            SequentialAnimation {
                PauseAnimation {
                    duration: 180
                }

                NumberAnimation {
                    target: root
                    property: "bolt"
                    to: 1
                    duration: 520
                    easing.type: Easing.OutBack
                    easing.overshoot: 3
                }
            }
        }

        ScriptAction {
            script: {
                root.sweep = -1;
                breathe.restart();
            }
        }
    }

    SequentialAnimation {
        id: breathe

        loops: Animation.Infinite

        NumberAnimation {
            target: root
            property: "glow"
            to: root.warning ? 0.35 : 0.55
            duration: root.kind === "critical" ? 380 : 900
            easing.type: Easing.InOutSine
        }

        NumberAnimation {
            target: root
            property: "glow"
            to: root.warning ? 1 : 0.8
            duration: root.kind === "critical" ? 380 : 900
            easing.type: Easing.InOutSine
        }
    }

    // back to the plain notch while the island shrinks to rest
    NumberAnimation {
        id: outro

        target: root
        property: "glow"
        to: 0
        duration: Theme.anim.slow
        easing.type: Easing.OutCubic
    }

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Theme.spacing.small

        Icon {
            visible: !root.battery
            name: root.icon
            fill: 1
            size: 22
            color: root.accent
            scale: root.bolt
            rotation: (1 - root.bolt) * -40
        }

        // a little battery that fills up on the charger, the bolt pops in over it
        Item {
            visible: root.battery
            implicitWidth: 30
            implicitHeight: 16

            Rectangle {
                id: cell

                width: 27
                height: 16
                radius: 5
                color: "transparent"
                border.width: 1.5
                border.color: root.accent

                Rectangle {
                    x: 2.5
                    y: 2.5
                    height: parent.height - 5
                    width: Math.max(height / 2, (parent.width - 5) * Math.min(1, Math.max(0, root.fill)))
                    radius: 2.5
                    color: root.accent
                    opacity: root.warning ? 0.5 + root.glow * 0.5 : 1
                }
            }

            Rectangle {
                anchors.left: cell.right
                anchors.leftMargin: 1
                anchors.verticalCenter: cell.verticalCenter
                width: 2
                height: 6
                radius: 1
                color: root.accent
            }

            Icon {
                anchors.centerIn: cell
                visible: root.plugged
                name: "bolt"
                fill: 1
                size: 18
                scale: root.bolt
                color: root.alert ? Theme.color.fgError : Theme.color.fgPrimary
            }
        }

        Label {
            text: root.title
            font.weight: Font.DemiBold
        }

        Label {
            visible: root.battery
            text: Battery.percent + "%"
            font.weight: Font.DemiBold
            font.features: ({
                    "tnum": 1
                })
            color: Theme.mix(Theme.color.ink, root.accent, 0.75)
        }

        Label {
            visible: text !== ""
            Layout.maximumWidth: 320
            text: root.sub
            font.pixelSize: Theme.font.small
            color: Theme.color.inkMeta
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -Theme.spacing.medium
        enabled: root.actionable
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
