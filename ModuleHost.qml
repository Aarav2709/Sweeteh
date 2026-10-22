import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
// module folders are imported so quickshell indexes them for url loading
import qs.modules.bar
import qs.modules.island
import qs.modules.background
import qs.modules.workspaces
import qs.modules.clock
import qs.modules.tray
import qs.modules.indicators
import qs.modules.media
import qs.modules.notifications
import qs.modules.osd
import qs.modules.launcher
import qs.modules.controlcenter
import qs.modules.power
import qs.modules.lock
import qs.modules.wallpaper
import qs.modules.clipboard
import qs.modules.overview
import qs.modules.screenshot
import qs.modules.cheatsheet
import qs.modules.modeswitcher
import qs.modules.desktop
import qs.modules.monitor
import qs.modules.settings

// loads only modules enabled in the current mode, and gives each one ipc
Scope {
    Variants {
        model: Registry.modules

        Scope {
            id: slot

            required property var modelData
            readonly property string moduleId: modelData.id
            readonly property bool on: Modes.enabled(moduleId)
            // true while a loaded module may still own the ipc target
            property bool held: false

            // own handlers register only after the generic one has stepped aside
            LazyLoader {
                id: loader

                active: slot.modelData.entry && slot.on && (!slot.modelData.own || !generic.enabled)
                onItemChanged: {
                    if (item)
                        slot.held = true;
                    else
                        release.restart();
                }
                source: slot.modelData.entry ? Qt.resolvedUrl(`modules/${slot.moduleId}/${Registry.stem(slot.moduleId)}Module.qml`) : ""
            }

            // destroyed modules are deleted later, so wait before taking the target back
            Timer {
                id: release

                interval: 100
                onTriggered: slot.held = loader.item !== null
            }

            // modules with their own handler take over this target while loaded
            IpcHandler {
                id: generic

                target: slot.moduleId
                enabled: !(slot.modelData.own && (slot.on || slot.held))

                function toggle(): string {
                    if (!slot.modelData.panel) {
                        Modes.setModule(slot.moduleId, !slot.on);
                        return "";
                    }
                    if (!slot.on)
                        return "Module is off in this mode.";
                    Actions.toggle(slot.moduleId);
                    return "";
                }

                function open(): string {
                    if (!slot.modelData.panel) {
                        Modes.setModule(slot.moduleId, true);
                        return "";
                    }
                    if (!slot.on)
                        return "Module is off in this mode.";
                    Actions.open(slot.moduleId);
                    return "";
                }

                function close(): void {
                    if (slot.modelData.panel)
                        Actions.close(slot.moduleId);
                    else
                        Modes.setModule(slot.moduleId, false);
                }
            }
        }
    }
}
