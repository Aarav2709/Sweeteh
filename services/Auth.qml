pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Polkit

// polkit agent, apps asking for admin rights get a password prompt in the island
Singleton {
    id: root

    readonly property var flow: agent.flow
    readonly property bool active: agent.isActive && flow !== null
    readonly property bool registered: agent.isRegistered

    function submit(password: string): void {
        flow?.submit(password);
    }

    function cancel(): void {
        flow?.cancelAuthenticationRequest();
    }

    PolkitAgent {
        id: agent
    }
}
