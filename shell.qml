//@ pragma UseQApplication
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma DefaultEnv QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.theme
import qs.services

ShellRoot {
    id: root

    settings.watchFiles: true

    // services that own ipc targets or must run from the start
    Component.onCompleted: {
        Modes.current;
        Actions.panel;
        Notifs.dnd;
        Media.active;
        Brightness.available;
        Keybinds.refresh();
        Wallpapers.current;
        Borders.enabled;
        Auth.registered;
        AppTheme.enabled;
        Updates.available;
    }

    // bundled fonts, loaded here so nothing has to be installed
    FontLoader {
        source: Quickshell.shellPath("assets/fonts/GoogleSansFlex.ttf")
    }

    FontLoader {
        source: Quickshell.shellPath("assets/fonts/MaterialSymbolsRounded.ttf")
    }

    ModuleHost {}

    // shell wide commands, modules add their own handlers
    IpcHandler {
        target: "shell"

        function reload(): void {
            Quickshell.reload(true);
        }

        function ping(): string {
            return "pong";
        }

        function theme(): string {
            return Theme.dark ? "dark" : "light";
        }

        function mode(): string {
            return Modes.current;
        }
    }
}
