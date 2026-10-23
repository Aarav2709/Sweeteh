import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.theme
import qs.services
import qs.components

// one notification with actions, swipe or click the close button to dismiss
Item {
    id: root

    property NotifEntry entry
    property bool popup: false
    property bool expanded: false
    // set by the history list to sweep the card away before a clear
    property bool leaving: false
    property int leaveDelay: 0
    readonly property bool hovered: hover.hovered
    readonly property bool critical: entry?.critical ?? false
    readonly property string iconSource: String(entry?.appIcon ? Quickshell.iconPath(entry.appIcon, true) || (entry.appIcon.startsWith("/") ? "file://" + entry.appIcon : "") : "")

    implicitHeight: card.implicitHeight
    onLeavingChanged: {
        if (leaving)
            leaveTimer.restart();
    }

    Timer {
        id: leaveTimer

        interval: root.leaveDelay
        onTriggered: card.x = card.width + Theme.spacing.large
    }

    Timer {
        running: root.popup && !root.hovered && !root.critical
        interval: root.entry?.notification?.expireTimeout > 0 ? root.entry.notification.expireTimeout : Config.options.notifications.timeout
        onTriggered: Notifs.hide(root.entry)
    }

    HoverHandler {
        id: hover
    }

    Rectangle {
        id: card

        width: parent.width
        implicitHeight: content.implicitHeight + Theme.spacing.medium * 2
        radius: Theme.radius.large
        color: root.critical ? Theme.mix(Theme.color.layer1, Theme.color.errorContainer, 0.45) : Theme.color.layer1
        opacity: width > 0 ? 1 - Math.min(1, Math.abs(x) / width) : 1

        Behavior on x {
            enabled: !drag.active

            Anim {
                easing.bezierCurve: root.leaving ? Theme.anim.accel : Theme.anim.standard
            }
        }

        DragHandler {
            id: drag

            yAxis.enabled: false
            onActiveChanged: {
                if (active)
                    return;
                if (Math.abs(card.x) > card.width * 0.35)
                    root.popup ? Notifs.hide(root.entry) : Notifs.dismiss(root.entry);
                else
                    card.x = 0;
            }
        }

        RowLayout {
            id: content

            anchors.fill: parent
            anchors.margins: Theme.spacing.medium
            spacing: Theme.spacing.medium

            Item {
                Layout.alignment: Qt.AlignTop
                implicitWidth: 40
                implicitHeight: 40

                ClippingRectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: root.critical ? Theme.color.error : Theme.color.secondaryContainer

                    Image {
                        id: picture

                        anchors.fill: parent
                        visible: status === Image.Ready
                        source: root.entry?.image ?? ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    IconImage {
                        anchors.centerIn: parent
                        visible: !picture.visible && root.iconSource !== ""
                        implicitSize: 24
                        source: root.iconSource
                    }

                    Icon {
                        anchors.centerIn: parent
                        visible: !picture.visible && root.iconSource === ""
                        name: root.critical ? "priority_high" : "notifications"
                        fill: 1
                        color: root.critical ? Theme.color.fgError : Theme.color.fgSecondaryContainer
                    }
                }

                // app badge over a contact picture
                Rectangle {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: -3
                    visible: picture.visible && root.iconSource !== ""
                    width: 20
                    height: 20
                    radius: width / 2
                    color: card.color

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 14
                        source: root.iconSource
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacing.xxs

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing.xs

                    Label {
                        Layout.maximumWidth: implicitWidth
                        Layout.fillWidth: true
                        text: root.entry?.appName || "Notification"
                        font.pixelSize: Theme.font.small
                        font.weight: Font.Medium
                        color: Theme.color.inkMeta
                    }

                    Label {
                        Layout.fillWidth: true
                        text: root.entry ? Notifs.ago(root.entry.time) : ""
                        font.pixelSize: Theme.font.small
                        color: Theme.color.inkFaint
                    }

                    IconButton {
                        Layout.topMargin: -Theme.spacing.xs
                        Layout.rightMargin: -Theme.spacing.xs
                        size: 24
                        icon: "close"
                        opacity: root.hovered ? 1 : 0
                        onClicked: Notifs.dismiss(root.entry)

                        Behavior on opacity {
                            Anim {
                                duration: Theme.anim.fast
                            }
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    Layout.topMargin: -Theme.spacing.xs
                    visible: text !== ""
                    text: root.entry?.summary ?? ""
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                }

                Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.entry?.body ?? ""
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: root.expanded ? 12 : 3
                    color: Theme.color.inkSoft
                    linkColor: Theme.color.primary
                    onLinkActivated: link => Qt.openUrlExternally(link)

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }

                    TapHandler {
                        onTapped: root.expanded = !root.expanded
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacing.small
                    visible: (root.entry?.actions.length ?? 0) > 0 && root.entry?.notification !== null
                    spacing: Theme.spacing.small

                    Repeater {
                        model: root.entry?.actions ?? []

                        Button {
                            required property var modelData

                            implicitHeight: 30
                            variant: "neutral"
                            text: modelData.text
                            onClicked: {
                                root.entry.invoke(modelData.identifier);
                                Notifs.dismiss(root.entry);
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacing.small
                    visible: (root.entry?.progress ?? -1) >= 0
                    implicitHeight: 6
                    radius: 3
                    color: Theme.color.layer2

                    Rectangle {
                        width: parent.width * (root.entry?.progress ?? 0) / 100
                        height: parent.height
                        radius: 3
                        color: Theme.color.primary

                        Behavior on width {
                            Anim {}
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacing.small
                    visible: root.entry?.canReply ?? false
                    spacing: Theme.spacing.small

                    Field {
                        id: reply

                        Layout.fillWidth: true
                        implicitHeight: 36
                        icon: "reply"
                        placeholder: root.entry?.notification?.inlineReplyPlaceholder || "Reply"
                        onAccepted: send.clicked()
                        input.onActiveFocusChanged: Notifs.replying = input.activeFocus || text !== ""
                    }

                    IconButton {
                        id: send

                        icon: "send"
                        size: 36
                        enabled: reply.text !== ""
                        onClicked: {
                            if (reply.text === "")
                                return;
                            root.entry.reply(reply.text);
                            reply.text = "";
                            Notifs.replying = false;
                            Notifs.dismiss(root.entry);
                        }
                    }
                }
            }
        }
    }
}
