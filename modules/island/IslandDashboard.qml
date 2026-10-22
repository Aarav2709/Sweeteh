import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.components
import qs.modules.clock
import qs.modules.controlcenter

// the island opened wide, calendar, quick settings and notifications side by side
// a plain box with a fixed size, so the island does not jump as notifications come and go
Item {
    id: root

    property string page: ""
    // the page on screen trails page so the old one can slide out first
    property string shownPage: ""

    onPageChanged: pageSwap.restart()

    SequentialAnimation {
        id: pageSwap

        readonly property int dir: root.page === "" ? -1 : 1

        ParallelAnimation {
            Anim {
                target: pageLoader
                property: "opacity"
                to: 0
                duration: Theme.anim.fast
                easing.bezierCurve: Theme.anim.accel
            }

            Anim {
                target: pageSlide
                property: "x"
                to: -pageSwap.dir * 28
                duration: Theme.anim.fast
                easing.bezierCurve: Theme.anim.accel
            }
        }

        ScriptAction {
            script: {
                root.shownPage = root.page;
                pageSlide.x = pageSwap.dir * 28;
            }
        }

        ParallelAnimation {
            Anim {
                target: pageLoader
                property: "opacity"
                to: 1
                easing.bezierCurve: Theme.anim.decel
            }

            Anim {
                target: pageSlide
                property: "x"
                to: 0
                easing.bezierCurve: Theme.anim.spatial
            }
        }
    }

    implicitWidth: 290 + 340 + 320 + Theme.spacing.large * 2
    implicitHeight: 372

    RowLayout {
        anchors.fill: parent
        spacing: Theme.spacing.large

        ColumnLayout {
            Layout.preferredWidth: 290
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            spacing: Theme.spacing.medium

            ColumnLayout {
                Layout.leftMargin: Theme.spacing.small
                spacing: 0

                Label {
                    text: Qt.formatDate(Time.now, "dddd")
                    font.pixelSize: Theme.font.headline
                    font.weight: Font.DemiBold
                }

                Label {
                    text: Qt.formatDate(Time.now, "d MMMM yyyy")
                    color: Theme.color.inkMeta
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: calendar.implicitHeight + Theme.spacing.medium * 2
                radius: Theme.radius.large
                color: Theme.color.layer1

                Calendar {
                    id: calendar

                    anchors.fill: parent
                    anchors.margins: Theme.spacing.medium
                }
            }
        }

        ColumnLayout {
            Layout.preferredWidth: 340
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            spacing: Theme.spacing.medium

            Loader {
                id: pageLoader

                Layout.fillWidth: true
                Layout.fillHeight: root.shownPage !== ""
                sourceComponent: root.shownPage === "network" ? networkPage : root.shownPage === "bluetooth" ? bluetoothPage : togglesPage
                transform: Translate {
                    id: pageSlide
                }
            }

            Slider {
                Layout.fillWidth: true
                visible: root.shownPage === ""
                icon: Audio.icon
                value: Audio.volume
                onMoved: v => Audio.setVolume(v)
            }

            Slider {
                Layout.fillWidth: true
                visible: Brightness.available && root.shownPage === ""
                icon: Brightness.icon
                value: Brightness.value
                onMoved: v => Brightness.set(v)
            }

        }

        ColumnLayout {
            Layout.preferredWidth: 320
            Layout.fillHeight: true
            spacing: Theme.spacing.medium

            MediaCard {
                Layout.fillWidth: true
                visible: Media.active
            }

            NotificationList {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    Component {
        id: togglesPage

        Toggles {
            onPage: name => root.page = name
        }
    }

    Component {
        id: networkPage

        NetworkPage {
            onBack: root.page = ""
        }
    }

    Component {
        id: bluetoothPage

        BluetoothPage {
            onBack: root.page = ""
        }
    }
}
