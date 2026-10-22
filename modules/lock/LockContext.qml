import QtQuick
import Quickshell
import Quickshell.Services.Pam

// password state shared by every lock surface
Scope {
    id: root

    property string password: ""
    property bool busy: false
    property string error: ""
    // set once the password is accepted, the surfaces play their exit before the lock goes
    property bool leaving: false

    signal unlocked

    function reset(): void {
        leaving = false;
        password = "";
        error = "";
        busy = false;
    }

    function submit(): void {
        if (password === "" || busy)
            return;
        busy = true;
        error = "";
        watchdog.restart();
        if (!pam.start()) {
            busy = false;
            error = "Authentication is not available.";
        }
    }

    Timer {
        id: exitDelay

        interval: 420
        onTriggered: root.unlocked()
    }

    // a stuck pam conversation never leaves the user locked out
    Timer {
        id: watchdog

        interval: 15000
        onTriggered: {
            if (!root.busy)
                return;
            pam.abort();
            root.busy = false;
            root.password = "";
            root.error = "That took too long, try again.";
        }
    }

    PamContext {
        id: pam

        onResponseRequiredChanged: {
            if (responseRequired) {
                respond(root.password);
            }
        }
        onCompleted: result => {
            watchdog.stop();
            root.busy = false;
            if (result === PamResult.Success) {
                root.password = "";
                root.leaving = true;
                exitDelay.restart();
            } else {
                root.password = "";
                root.error = result === PamResult.MaxTries ? "Too many attempts, wait a moment." : "Wrong password, try again.";
            }
        }
        onError: {
            watchdog.stop();
            root.busy = false;
            root.error = "Authentication is not available.";
        }
    }
}
