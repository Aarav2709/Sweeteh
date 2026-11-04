import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.theme
import qs.services
import qs.components

// widget layer under windows, raised above them while editing
PanelWindow {
    id: root

    required property var modelData
    property bool editing: false
    property var draft: []
    readonly property var widgets: editing ? draft : Config.options.desktop.widgets
    readonly property var types: [
        { type: "clock", icon: "schedule", name: "Clock" },
        { type: "analog", icon: "nest_clock_farsight_analog", name: "Dial" },
        { type: "weather", icon: "partly_cloudy_day", name: "Weather" },
        { type: "calendar", icon: "calendar_month", name: "Calendar" },
        { type: "media", icon: "music_note", name: "Media" },
        { type: "system", icon: "monitoring", name: "System" },
        { type: "lyrics", icon: "lyrics", name: "Lyrics" },
        { type: "spectrum", icon: "graphic_eq", name: "Spectrum" }
    ]

    signal done

    function save(): void {
        Config.set("desktop.widgets", draft);
        done();
    }

    onEditingChanged: {
        if (editing)
            draft = JSON.parse(JSON.stringify(Config.options.desktop.widgets));
    }

    screen: modelData
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "sweeteh-desktop"
    WlrLayershell.layer: editing ? WlrLayer.Overlay : WlrLayer.Bottom
    WlrLayershell.keyboardFocus: editing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    Rectangle {
        id: scrim

        anchors.fill: parent
        color: Theme.wall.scrim
        opacity: root.editing ? 0.35 : 0
        focus: root.editing
        Keys.onEscapePressed: root.done()
        Keys.onReturnPressed: root.save()

        Behavior on opacity {
            Anim {}
        }
    }

    Repeater {
        model: root.widgets

        DesktopWidget {
            required property var modelData
            required property int index

            spec: modelData
            editing: root.editing
            onMoved: (fx, fy) => {
                const next = root.draft.slice();
                next[index] = Object.assign({}, next[index], { x: fx, y: fy });
                root.draft = next;
            }
            onRemoved: root.draft = root.draft.filter((w, i) => i !== index)
        }
    }

    Rectangle {
        visible: root.editing
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.spacing.xxl
        implicitWidth: toolbar.implicitWidth + Theme.spacing.small * 2
        implicitHeight: toolbar.implicitHeight + Theme.spacing.small * 2
        radius: height / 2
        color: Theme.wallpaperSurface
        border.width: Theme.depth.rim
        border.color: Theme.wall.depthRim

        Depth {
            color: Theme.wall.depthShadow
        }

        RowLayout {
            id: toolbar

            property string hovering: ""

            anchors.centerIn: parent
            spacing: Theme.spacing.small

            // a plain hint, or the name of the widget under the pointer
            Label {
                Layout.leftMargin: Theme.spacing.small
                Layout.rightMargin: Theme.spacing.xs
                Layout.preferredWidth: 150
                text: toolbar.hovering !== "" ? "Add " + toolbar.hovering.toLowerCase() : "Drag to move"
                color: Theme.wall.inkMeta
            }

            Repeater {
                model: root.types

                IconButton {
                    id: add

                    required property var modelData

                    icon: modelData.icon
                    filled: true
                    onClicked: root.draft = [...root.draft, { type: modelData.type, x: 0.4, y: 0.4 }]

                    HoverHandler {
                        onHoveredChanged: toolbar.hovering = hovered ? add.modelData.name : (toolbar.hovering === add.modelData.name ? "" : toolbar.hovering)
                    }
                }
            }

            Button {
                variant: "text"
                text: "Cancel"
                onClicked: root.done()
            }

            Button {
                variant: "filled"
                icon: "check"
                text: "Done"
                onClicked: root.save()
            }
        }
    }
}
