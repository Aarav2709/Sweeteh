import QtQuick
import QtQuick.Layouts
import qs.config
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
    implicitHeight: Math.max(372, dateColumn.implicitHeight)

    RowLayout {
        anchors.fill: parent
        spacing: Theme.spacing.large

        ColumnLayout {
            id: dateColumn

            Layout.preferredWidth: 290
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            spacing: Theme.spacing.medium

            // the date lines up with the calendar card's content below it
            ColumnLayout {
                Layout.leftMargin: Theme.spacing.medium
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

            // what is coming up from the linked calendar, on the same left edge as the date
            Repeater {
                model: Events.next

                RowLayout {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.spacing.medium
                    Layout.rightMargin: Theme.spacing.medium
                    spacing: Theme.spacing.small

                    Rectangle {
                        implicitWidth: 4
                        implicitHeight: 28
                        radius: 2
                        color: Theme.color.primary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Label {
                            Layout.fillWidth: true
                            text: modelData.title
                            elide: Text.ElideRight
                            font.weight: Font.Medium
                        }

                        Label {
                            text: {
                                const s = modelData.start;
                                const today = new Date(Time.now.getFullYear(), Time.now.getMonth(), Time.now.getDate());
                                const d = Math.round((new Date(s.getFullYear(), s.getMonth(), s.getDate()) - today) / 86400000);
                                const day = d <= 0 ? "Today" : d === 1 ? "Tomorrow" : Qt.formatDate(s, "ddd d MMM");
                                return modelData.allDay ? day + ", all day" : day + ", " + Qt.formatTime(s, Config.options.clock.use24h ? "HH:mm" : "h:mm ap");
                            }
                            font.pixelSize: Theme.font.small
                            color: Theme.color.inkMeta
                        }
                    }
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
                sourceComponent: root.shownPage === "network" ? networkPage : root.shownPage === "bluetooth" ? bluetoothPage : root.shownPage === "sound" ? soundPage : togglesPage
                transform: Translate {
                    id: pageSlide
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.shownPage === ""
                spacing: Theme.spacing.small

                Slider {
                    Layout.fillWidth: true
                    icon: Audio.icon
                    value: Audio.volume
                    onMoved: v => Audio.setVolume(v)
                }

                // devices and per app volume
                IconButton {
                    icon: "tune"
                    filled: true
                    onClicked: root.page = "sound"
                }
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
        id: soundPage

        SoundPage {
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
