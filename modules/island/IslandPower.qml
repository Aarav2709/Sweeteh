import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.components

// charger and battery flash, the island blushes with the state color and a shine sweeps across it
Item {
    id: root

    property bool shown: false
    property string kind: "plugged"
    readonly property bool plugged: kind === "plugged"
    readonly property bool warning: kind === "low" || kind === "critical"
    readonly property color accent: plugged ? "#30d158" : kind === "unplugged" ? "#ff9f0a" : "#ff453a"
    readonly property string title: ({ plugged: Battery.percent >= 100 ? "Fully charged" : "Charging", unplugged: "On battery", low: "Battery low", critical: "Battery critical" })[kind] ?? ""
    // read by the surface, glow tints the notch and sweep moves the shine from 0 to 1
    property real glow: 0
    property real sweep: -1
    property real fill: Battery.level
    property real bolt: 0

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

    // one power flash straight after another plays again from the start
    onKindChanged: {
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

        // a little battery that fills up on the charger, the bolt pops in over it
        Item {
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
                color: "#ffffff"
            }
        }

        Label {
            text: root.title
            font.weight: Font.DemiBold
        }

        Label {
            text: Battery.percent + "%"
            font.weight: Font.DemiBold
            font.features: ({
                    "tnum": 1
                })
            color: Theme.mix(Theme.color.ink, root.accent, 0.75)
        }

        Label {
            visible: text !== "" && Battery.percent < 100
            text: Battery.timeText ? Battery.timeText + (Battery.charging ? " to full" : " left") : ""
            font.pixelSize: Theme.font.small
            color: Theme.color.inkMeta
        }
    }
}
