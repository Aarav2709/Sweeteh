import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.components

// month grid starting on monday, scroll or arrows change the month
ColumnLayout {
    id: root

    property int month: Time.now.getMonth()
    property int year: Time.now.getFullYear()
    readonly property date first: new Date(year, month, 1)
    readonly property int offset: (first.getDay() + 6) % 7
    readonly property int days: new Date(year, month + 1, 0).getDate()
    readonly property bool current: month === Time.now.getMonth() && year === Time.now.getFullYear()

    property int direction: 1

    function reset(): void {
        const now = Time.now;
        if (month === now.getMonth() && year === now.getFullYear())
            return;
        direction = now > first ? 1 : -1;
        swap.target = new Date(now.getFullYear(), now.getMonth(), 1);
        swap.restart();
    }

    function shift(delta: int): void {
        direction = delta;
        swap.target = new Date(year, month + delta, 1);
        swap.restart();
    }

    // the old month slides out and the new one slides in from the side it came from
    SequentialAnimation {
        id: swap

        property date target

        ParallelAnimation {
            Anim {
                target: grid
                property: "opacity"
                to: 0
                duration: Theme.anim.fast
                easing.bezierCurve: Theme.anim.accel
            }

            Anim {
                target: slide
                property: "x"
                to: -root.direction * 24
                duration: Theme.anim.fast
                easing.bezierCurve: Theme.anim.accel
            }
        }

        ScriptAction {
            script: {
                root.month = swap.target.getMonth();
                root.year = swap.target.getFullYear();
                slide.x = root.direction * 24;
            }
        }

        ParallelAnimation {
            Anim {
                target: grid
                property: "opacity"
                to: 1
                easing.bezierCurve: Theme.anim.decel
            }

            Anim {
                target: slide
                property: "x"
                to: 0
                easing.bezierCurve: Theme.anim.spatial
            }
        }
    }

    spacing: Theme.spacing.small

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.spacing.small
        spacing: Theme.spacing.xs

        Label {
            Layout.fillWidth: true
            text: Qt.formatDate(root.first, root.year === Time.now.getFullYear() ? "MMMM" : "MMMM yyyy")
            font.pixelSize: Theme.font.large
            font.weight: Font.DemiBold
        }

        Button {
            visible: !root.current
            variant: "text"
            text: "Today"
            implicitHeight: 30
            onClicked: root.reset()
        }

        IconButton {
            size: 30
            icon: "chevron_left"
            onClicked: root.shift(-1)
        }

        IconButton {
            size: 30
            icon: "chevron_right"
            onClicked: root.shift(1)
        }
    }

    GridLayout {
        id: grid

        Layout.fillWidth: true
        columns: 7
        transform: Translate {
            id: slide
        }
        rowSpacing: Theme.spacing.xxs
        columnSpacing: Theme.spacing.xxs

        Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

            Label {
                required property string modelData
                required property int index

                Layout.fillWidth: true
                Layout.bottomMargin: Theme.spacing.xs
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                font.pixelSize: Theme.font.tiny
                font.weight: Font.DemiBold
                color: index >= 5 ? Theme.color.primary : Theme.color.inkMeta
            }
        }

        Repeater {
            model: Math.ceil((root.offset + root.days) / 7) * 7

            Rectangle {
                id: day

                required property int index
                readonly property int number: index - root.offset + 1
                readonly property bool inMonth: number >= 1 && number <= root.days
                readonly property bool today: inMonth && number === Time.now.getDate() && root.month === Time.now.getMonth() && root.year === Time.now.getFullYear()

                Layout.fillWidth: true
                implicitHeight: 34
                radius: Theme.radius.full
                color: today ? Theme.color.primary : "transparent"

                Label {
                    anchors.centerIn: parent
                    text: day.inMonth ? day.number : new Date(root.year, root.month, day.number).getDate()
                    font.pixelSize: Theme.font.small
                    font.features: ({
                            "tnum": 1
                        })
                    color: day.today ? Theme.color.fgPrimary : day.inMonth ? Theme.color.ink : Theme.color.inkFaint
                    font.weight: day.today ? Font.DemiBold : Font.Medium
                }
            }
        }
    }

    WheelHandler {
        onWheel: e => root.shift(e.angleDelta.y > 0 ? -1 : 1)
    }
}
