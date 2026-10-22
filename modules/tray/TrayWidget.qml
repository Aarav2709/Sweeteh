import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.theme
import qs.components

// status notifier items, right click opens the app menu in shell style
BarItem {
    id: root

    interactive: false
    shown: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items

        Item {
            id: entry

            required property SystemTrayItem modelData

            implicitWidth: Theme.size.icon + 4
            implicitHeight: Theme.size.icon + 4
            // icons pop in when an app shows up in the tray
            scale: 0
            Component.onCompleted: scale = 1

            Behavior on scale {
                Anim {
                    duration: Theme.anim.normal
                    easing.bezierCurve: Theme.anim.spatial
                }
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: Theme.size.icon
                source: {
                    const icon = entry.modelData.icon;
                    // some apps pass a path in the icon name
                    if (icon.includes("?path=")) {
                        const [name, path] = icon.split("?path=");
                        return "file://" + path + "/" + name.slice(name.lastIndexOf("/") + 1);
                    }
                    return icon;
                }
                asynchronous: true
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: e => {
                    if (e.button === Qt.MiddleButton)
                        entry.modelData.secondaryActivate();
                    else if ((e.button === Qt.RightButton || entry.modelData.onlyMenu) && entry.modelData.hasMenu)
                        menu.open(entry, entry.modelData.menu);
                    else
                        entry.modelData.activate();
                }
                onWheel: e => entry.modelData.scroll(e.angleDelta.y, false)
            }
        }
    }

    TrayMenu {
        id: menu
    }
}
