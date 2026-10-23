import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.theme
import qs.services
import qs.components

// blurred wallpaper, big clock, password field and media
Item {
    id: root

    required property LockContext context
    property bool ready: false
    // blurred while locked, it clears as the lock lets go
    readonly property bool shown: ready && !context.leaving

    focus: true
    Component.onCompleted: {
        ready = true;
        forceActiveFocus();
    }
    Keys.onPressed: e => {
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
            context.submit();
        else if (e.key === Qt.Key_Backspace)
            context.password = e.modifiers & Qt.ControlModifier ? "" : context.password.slice(0, -1);
        else if (e.key === Qt.Key_Escape)
            context.password = "";
        else if (e.text !== "" && e.text.charCodeAt(0) >= 32)
            context.password += e.text;
        else
            return;
        e.accepted = true;
    }

    // any click brings the keyboard back here
    MouseArea {
        anchors.fill: parent
        onPressed: e => {
            root.forceActiveFocus();
            e.accepted = false;
        }
    }

    Image {
        id: wall

        anchors.fill: parent
        source: Wallpapers.still ? Paths.url(Wallpapers.still) : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
        sourceSize: Qt.size(root.width / 2, root.height / 2)
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.color.surface
    }

    MultiEffect {
        anchors.fill: parent
        source: wall
        blurEnabled: true
        blur: root.shown ? 1 : 0
        blurMax: 64
        brightness: root.shown ? -0.08 : 0

        Behavior on blur {
            Anim {
                duration: Theme.anim.slow
                easing.bezierCurve: Theme.anim.standard
            }
        }

        Behavior on brightness {
            Anim {
                duration: Theme.anim.slow
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.color.scrim
        opacity: root.shown ? 0.25 : 0

        Behavior on opacity {
            Anim {
                duration: Theme.anim.slow
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.shown ? -root.height * 0.08 : 0
        spacing: Theme.spacing.small
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.92

        Behavior on opacity {
            Anim {
                duration: Theme.anim.slow
            }
        }

        Behavior on scale {
            Anim {
                duration: Theme.anim.slow
                easing.bezierCurve: Theme.anim.decel
            }
        }

        Behavior on anchors.verticalCenterOffset {
            Anim {
                duration: Theme.anim.slow
                easing.bezierCurve: Theme.anim.decel
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: Time.hours + ":" + Time.minutes
            font.pixelSize: Theme.font.hero * 1.4
            font.weight: Font.DemiBold
            color: Theme.color.ink
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: -Theme.spacing.large
            text: Time.date
            font.pixelSize: Theme.font.title
            font.weight: Font.Medium
            color: Theme.color.primary
        }

        // keys go straight into the context, no text field, so input methods cannot swallow them
        Rectangle {
            id: field

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Theme.spacing.xxl
            implicitWidth: 340
            implicitHeight: Theme.size.buttonLarge
            radius: height / 2
            color: Theme.color.panel
            border.width: Theme.depth.rim
            border.color: Theme.color.depthRim
            transform: Translate {
                id: nudge
            }

            Depth {}

            Icon {
                id: lead

                anchors.left: parent.left
                anchors.leftMargin: Theme.spacing.large
                anchors.verticalCenter: parent.verticalCenter
                name: root.context.busy ? "hourglass_top" : "lock"
                color: Theme.color.inkMeta
            }

            Label {
                anchors.left: lead.right
                anchors.right: parent.right
                anchors.leftMargin: Theme.spacing.medium
                anchors.rightMargin: Theme.spacing.large
                anchors.verticalCenter: parent.verticalCenter
                text: root.context.password === "" ? (root.context.busy ? "Checking" : "Type your password") : "•".repeat(Math.min(root.context.password.length, 24))
                color: root.context.password === "" ? Theme.color.inkFaint : Theme.color.ink
                font.pixelSize: root.context.password === "" ? Theme.font.body : Theme.font.large
                font.letterSpacing: root.context.password === "" ? 0 : 2
            }

            Connections {
                target: root.context

                function onErrorChanged(): void {
                    if (root.context.error !== "")
                        shake.restart();
                }
            }

            SequentialAnimation {
                id: shake

                loops: 2

                Anim {
                    target: nudge
                    property: "x"
                    to: 12
                    duration: 50
                }

                Anim {
                    target: nudge
                    property: "x"
                    to: -12
                    duration: 50
                }

                Anim {
                    target: nudge
                    property: "x"
                    to: 0
                    duration: 50
                }
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: Theme.font.body * 2
            text: root.context.error || (root.context.fingerprint ? root.context.fingerMessage || "Or touch the fingerprint sensor" : "")
            color: root.context.error ? Theme.color.error : Theme.color.inkMeta
        }
    }

    // what came in while away, app icons and a count only so nothing private shows
    Rectangle {
        id: away

        readonly property var fresh: Notifs.list.filter(n => n.time > root.context.lockedAt)
        readonly property var apps: fresh.map(n => n.appIcon).filter((a, i, all) => a && all.indexOf(a) === i).slice(0, 5)

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.spacing.xxl + (Config.options.lock.showMedia && Media.active ? 72 + Theme.spacing.medium : 0)
        visible: fresh.length > 0 && Config.options.lock.showNotifications
        implicitWidth: freshRow.implicitWidth + Theme.spacing.large * 2
        implicitHeight: 40
        radius: height / 2
        color: Theme.color.panel
        border.width: Theme.depth.rim
        border.color: Theme.color.depthRim

        Row {
            id: freshRow

            anchors.centerIn: parent
            spacing: Theme.spacing.small

            Repeater {
                model: away.apps

                IconImage {
                    required property string modelData

                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 20
                    source: Quickshell.iconPath(modelData, true) || (modelData.startsWith("/") ? "file://" + modelData : "")
                }
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: away.fresh.length + (away.fresh.length === 1 ? " notification" : " notifications")
                font.weight: Font.DemiBold
            }
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.spacing.xxl
        visible: Config.options.lock.showMedia && Media.active
        implicitWidth: 420
        implicitHeight: 72
        radius: height / 2
        color: Theme.mix(Theme.color.panel, Qt.alpha(Theme.color.primaryContainer, Theme.color.panel.a), 0.5)
        border.width: Theme.depth.rim
        border.color: Theme.color.depthRim

        Depth {}

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacing.small
            spacing: Theme.spacing.medium

            ClippingRectangle {
                implicitWidth: 56
                implicitHeight: 56
                radius: Theme.radius.full
                color: Theme.color.secondaryContainer

                Image {
                    anchors.fill: parent
                    source: Media.art
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(112, 112)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Label {
                    Layout.fillWidth: true
                    text: Media.title
                    font.weight: Font.DemiBold
                }

                Label {
                    Layout.fillWidth: true
                    text: Media.artist
                    color: Theme.color.inkMeta
                }
            }

            IconButton {
                icon: "skip_previous"
                onClicked: Media.previous()
            }

            IconButton {
                icon: Media.playing ? "pause" : "play_arrow"
                checked: true
                onClicked: Media.toggle()
            }

            IconButton {
                icon: "skip_next"
                onClicked: Media.next()
            }
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacing.xl
        implicitWidth: status.implicitWidth + Theme.spacing.medium * 2
        implicitHeight: 34
        radius: height / 2
        color: Theme.color.panel
        border.width: Theme.depth.rim
        border.color: Theme.color.depthRim

        Depth {}

        RowLayout {
            id: status

            anchors.centerIn: parent
            spacing: Theme.spacing.small

            Icon {
                name: Network.icon
            }

            Icon {
                visible: Battery.available
                name: Battery.icon
            }

            Label {
                visible: Battery.available
                text: Battery.percent + "%"
                font.pixelSize: Theme.font.bar
                font.weight: Font.DemiBold
            }
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacing.xl
        spacing: Theme.spacing.small

        IconButton {
            icon: "bedtime"
            filled: true
            onClicked: Session.suspend()
        }

        IconButton {
            icon: "power_settings_new"
            filled: true
            onClicked: Session.poweroff()
        }
    }
}
