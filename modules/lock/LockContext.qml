import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

// password state shared by every lock surface
Scope {
    id: root

    property string password: ""
    property bool busy: false
    property string error: ""
    // set once the password is accepted, the surfaces play their exit before the lock goes
    property bool leaving: false
    // fingerprint runs beside the password once fprintd has a finger enrolled
    property bool fingerprint: false
    property string fingerMessage: ""
    property int fingerTries: 0
    // notifications that arrive after this are counted on the lockscreen
    property real lockedAt: Date.now()

    signal unlocked

    function reset(): void {
        leaving = false;
        password = "";
        error = "";
        busy = false;
        fingerMessage = "";
        fingerTries = 0;
        lockedAt = Date.now();
        if (fingerprint)
            fingerRetry.restart();
    }

    function accept(): void {
        watchdog.stop();
        fingerRetry.stop();
        if (pam.active)
            pam.abort();
        if (finger.active)
            finger.abort();
        busy = false;
        password = "";
        leaving = true;
        exitDelay.restart();
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

    Process {
        running: true
        command: ["sh", "-c", "command -v fprintd-list >/dev/null && fprintd-list \"$USER\" 2>/dev/null | grep -q ' - #'"]
        onExited: code => root.fingerprint = code === 0
    }

    // a missed or timed out scan starts listening again while the lock is up
    Timer {
        id: fingerRetry

        interval: 600
        onTriggered: {
            if (!root.leaving && !finger.active)
                finger.start();
        }
    }

    PamContext {
        id: finger

        configDirectory: Quickshell.shellPath("assets/pam")
        config: "fprint"
        onMessageChanged: root.fingerMessage = message
        onCompleted: result => {
            if (result === PamResult.Success && !root.leaving)
                root.accept();
            else if (!root.leaving && ++root.fingerTries < 10)
                fingerRetry.restart();
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
                root.accept();
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
