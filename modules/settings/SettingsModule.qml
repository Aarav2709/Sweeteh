import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// settings live in the island, this only answers the settings ipc and page requests
Scope {
    id: root

    function show(name: string): void {
        Actions.settingsPage = name;
        Actions.open("settings");
    }

    Connections {
        target: Actions

        function onSettingsRequested(page: string): void {
            root.show(page);
        }
    }

    IpcHandler {
        target: "settings"

        function toggle(): void {
            Actions.toggle("settings");
        }

        function open(): void {
            Actions.open("settings");
        }

        function close(): void {
            Actions.close("settings");
        }

        function page(name: string): void {
            root.show(name);
        }
    }
}
