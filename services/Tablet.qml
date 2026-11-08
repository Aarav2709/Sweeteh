pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// tablet mode from the hinge's switch, folded back the shell offers the on screen keyboard
Singleton {
    id: root

    property bool tablet: false
    // the on screen keyboard, open by hand or from the handle in tablet mode
    property bool keyboard: false

    function setTablet(on: bool): void {
        if (tablet === on)
            return;
        tablet = on;
        if (!on)
            keyboard = false;
        Actions.offered({
            kind: "tablet",
            icon: on ? "tablet" : "laptop",
            title: on ? "Tablet mode" : "Laptop mode",
            ms: 1800
        });
    }

    // the switch has a different name on every machine, so it is looked up and bound to the ipc below
    Process {
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let name = "";
                try {
                    name = (JSON.parse(text).switches ?? []).map(s => s.name).find(n => /tablet/i.test(n)) ?? "";
                } catch (e) {}
                if (name === "")
                    return;
                const lua = [];
                for (const state of ["on", "off"]) {
                    const key = Keybinds.luaString(`switch:${state}:${name}`);
                    lua.push(`hl.unbind(${key})`);
                    lua.push(`hl.bind(${key}, hl.dsp.exec_cmd(${Keybinds.luaString(Keybinds.ipcPrefix + "tablet " + state)}), { locked = true, description = "Tablet mode ${state}" })`);
                }
                Quickshell.execDetached(["hyprctl", "eval", lua.join("\n")]);
            }
        }
    }

    IpcHandler {
        target: "tablet"

        function on(): void {
            root.setTablet(true);
        }

        function off(): void {
            root.setTablet(false);
        }

        function keyboard(): void {
            root.keyboard = !root.keyboard;
        }
    }
}
