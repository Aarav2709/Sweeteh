pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config

// power actions, idle sleep and the caffeine idle inhibitor
Singleton {
    id: root

    property bool caffeine: false
    readonly property var opts: Config.options.power
    // a shorter wait on battery, the charger gets the longer one
    readonly property int sleepMinutes: Battery.available && !Battery.plugged ? opts.sleepMinutes : opts.sleepMinutesPlugged
    readonly property string sleepAction: Defaults.choices["power.sleepAction"].includes(opts.sleepAction) ? opts.sleepAction : "suspend"

    function lock(): void {
        Actions.lock();
    }

    function logout(): void {
        Hypr.exit();
    }

    function suspend(): void {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    // the configured sleep, falling back to suspend when hibernation is not set up
    function sleep(): void {
        Quickshell.execDetached(["sh", "-c", `systemctl ${root.sleepAction} || systemctl suspend`]);
    }

    function reboot(): void {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function poweroff(): void {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    // an inhibitor needs a surface, so keep a tiny invisible one while active
    LazyLoader {
        active: root.caffeine

        PanelWindow {
            id: holder

            implicitWidth: 1
            implicitHeight: 1
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            anchors.top: true
            anchors.left: true
            mask: Region {}
            WlrLayershell.namespace: "sweeteh-caffeine"
            WlrLayershell.layer: WlrLayer.Background

            IdleInhibitor {
                window: holder
                enabled: true
            }
        }
    }

    // nobody at the keyboard and nothing playing, video players and caffeine hold it off through inhibitors
    IdleMonitor {
        enabled: root.sleepMinutes > 0 && !root.caffeine && !Media.playing
        timeout: root.sleepMinutes * 60
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle)
                root.sleep();
        }
    }

    // the screens fade out over the last half minute before idle sleep, any input brings them back
    IdleMonitor {
        id: dimIdle

        enabled: root.sleepMinutes > 0 && !root.caffeine && !Media.playing
        timeout: Math.max(30, root.sleepMinutes * 60 - 30)
        respectInhibitors: true
    }

    LazyLoader {
        active: dimIdle.enabled && dimIdle.isIdle

        Variants {
            model: Quickshell.screens

            PanelWindow {
                required property var modelData

                screen: modelData
                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                mask: Region {}
                WlrLayershell.namespace: "sweeteh-dim"
                WlrLayershell.layer: WlrLayer.Overlay

                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: 0

                    NumberAnimation on opacity {
                        to: 0.85
                        duration: 30000
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }

    // logind announces every sleep, lid or idle or menu, so the lock goes up before the screen comes back
    Process {
        id: sleepWatch

        running: root.opts.lockOnSleep
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1", "--object-path", "/org/freedesktop/login1"]
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("PrepareForSleep (true"))
                    Actions.lock();
            }
        }
        onExited: {
            if (root.opts.lockOnSleep)
                rewatch.restart();
        }
    }

    Timer {
        id: rewatch

        interval: 5000
        onTriggered: sleepWatch.running = Qt.binding(() => root.opts.lockOnSleep)
    }
}
