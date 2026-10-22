import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services
import qs.theme

// session lock with pam, idle lock when configured
Scope {
    id: root

    function lock(): void {
        if (!session.locked) {
            lockContext.reset();
            session.locked = true;
        }
    }

    LockContext {
        id: lockContext

        onUnlocked: session.locked = false
    }

    WlSessionLock {
        id: session

        WlSessionLockSurface {
            color: Theme.color.surface

            LockSurface {
                anchors.fill: parent
                context: lockContext
            }
        }
    }

    Connections {
        target: Actions

        function onLockRequested(): void {
            root.lock();
        }
    }

    IdleMonitor {
        enabled: Config.options.lock.idleMinutes > 0 && !Session.caffeine
        timeout: Config.options.lock.idleMinutes * 60
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle)
                root.lock();
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock();
        }

        function toggle(): void {
            root.lock();
        }

        function open(): void {
            root.lock();
        }

        function close(): string {
            return "Unlock with your password.";
        }

        function isLocked(): bool {
            return session.locked;
        }
    }
}
