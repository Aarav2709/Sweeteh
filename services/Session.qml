pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland

// power actions and the caffeine idle inhibitor
Singleton {
    id: root

    property bool caffeine: false

    function lock(): void {
        Actions.lock();
    }

    function logout(): void {
        Hypr.exit();
    }

    function suspend(): void {
        Quickshell.execDetached(["systemctl", "suspend"]);
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
}
