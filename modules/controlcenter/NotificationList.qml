import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.theme
import qs.services
import qs.components
import qs.modules.notifications

// notification history with a clear button
ColumnLayout {
    id: root

    // one card per app, the rest fold behind it until opened
    readonly property bool grouping: Config.options.notifications.group
    property var openApps: []

    property bool clearing: false
    readonly property int stagger: 45

    // sweep the visible cards out one after another, then drop them all
    function clearAll(): void {
        if (clearing)
            return;
        clearing = true;
        clearTimer.interval = Math.min(list.count, 8) * stagger + Theme.anim.normal;
        clearTimer.restart();
    }

    spacing: Theme.spacing.small

    Timer {
        id: clearTimer

        onTriggered: {
            Notifs.clear();
            root.clearing = false;
        }
    }

    RowLayout {
        Layout.fillWidth: true

        Layout.leftMargin: Theme.spacing.xs

        Label {
            text: "Notifications"
            font.pixelSize: Theme.font.large
            font.weight: Font.DemiBold
        }

        Rectangle {
            visible: Notifs.list.length > 0
            implicitWidth: Math.max(implicitHeight, count.implicitWidth + Theme.spacing.small * 2)
            implicitHeight: 20
            radius: height / 2
            color: Theme.color.primary

            Label {
                id: count

                anchors.centerIn: parent
                text: Notifs.list.length
                font.pixelSize: Theme.font.tiny
                font.weight: Font.DemiBold
                color: Theme.color.fgPrimary
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Button {
            visible: Notifs.list.length > 0
            variant: "neutral"
            icon: "clear_all"
            text: "Clear"
            implicitHeight: 30
            onClicked: root.clearAll()
        }
    }

    ListView {
        id: list

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 80
        clip: true
        spacing: Theme.spacing.small
        model: ScriptModel {
            values: Array.from(Notifs.list).filter((n, i, all) => !root.grouping || root.openApps.includes(n.appName) || all.findIndex(m => m.appName === n.appName) === i)
        }

        delegate: NotificationCard {
            required property var modelData
            required property int index

            width: list.width
            entry: modelData
            groupCount: root.grouping && !root.openApps.includes(modelData.appName) ? Notifs.list.filter(n => n.appName === modelData.appName).length - 1 : 0
            onExpandGroup: root.openApps = root.openApps.concat([modelData.appName])
            leaving: root.clearing
            leaveDelay: Math.min(index, 8) * root.stagger
        }

        add: Transition {
            ParallelAnimation {
                Anim {
                    property: "opacity"
                    from: 0
                    to: 1
                }

                Anim {
                    property: "scale"
                    from: 0.92
                    to: 1
                    easing.bezierCurve: Theme.anim.spatial
                }
            }
        }

        remove: Transition {
            ParallelAnimation {
                Anim {
                    property: "x"
                    to: list.width
                    easing.bezierCurve: Theme.anim.accel
                }

                Anim {
                    property: "opacity"
                    to: 0
                    easing.bezierCurve: Theme.anim.accel
                }
            }
        }

        removeDisplaced: Transition {
            Anim {
                property: "y"
            }
        }

        Column {
            anchors.centerIn: parent
            visible: list.count === 0
            spacing: Theme.spacing.small

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 64
                height: 64
                radius: Theme.radius.large
                color: Theme.color.layer1

                Icon {
                    anchors.centerIn: parent
                    name: Notifs.dnd ? "notifications_paused" : "notifications"
                    size: Theme.size.iconLarge
                    color: Theme.color.inkMeta
                }
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Notifs.dnd ? "Do not disturb is on." : "You are all caught up."
                color: Theme.color.inkMeta
            }
        }
    }
}
