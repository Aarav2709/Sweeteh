import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// desktop widgets on every screen, with a shared edit mode
Scope {
    id: root

    property bool editing: false

    Connections {
        target: Actions

        function onDesktopEditRequested(): void {
            root.editing = !root.editing;
        }
    }

    Variants {
        model: Quickshell.screens

        DesktopLayer {
            editing: root.editing
            onDone: root.editing = false
        }
    }

    IpcHandler {
        target: "desktop"

        function edit(): void {
            root.editing = !root.editing;
        }

        function toggle(): void {
            root.editing = !root.editing;
        }

        function open(): void {
            root.editing = true;
        }

        function close(): void {
            root.editing = false;
        }
    }
}
