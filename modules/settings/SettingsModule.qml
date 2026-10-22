import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.theme
import qs.services
import qs.components

// settings app in a normal window
Scope {
    id: root

    property bool open: false
    property string page: "Appearance"
    readonly property var pages: [
        { name: "Appearance", icon: "palette" },
        { name: "Layout", icon: "view_quilt" },
        { name: "Wallpaper", icon: "wallpaper" },
        { name: "Keybinds", icon: "keyboard" },
        { name: "General", icon: "tune" },
        { name: "About", icon: "info" }
    ]

    function show(name: string): void {
        if (pages.some(p => p.name === name))
            page = name;
        open = true;
    }

    Connections {
        target: Actions

        function onSettingsRequested(page: string): void {
            root.show(page);
        }
    }

    LazyLoader {
        active: root.open

        FloatingWindow {
            id: win

            readonly property bool wide: width >= 860

            title: "Sweeteh settings"
            implicitWidth: 980
            implicitHeight: 640
            minimumSize: Qt.size(720, 480)
            color: Theme.color.surface
            visible: true
            onVisibleChanged: {
                if (!visible)
                    root.open = false;
            }

            // escape closes, ctrl tab and ctrl page keys walk the pages
            Shortcut {
                sequence: "Escape"
                onActivated: root.open = false
            }

            Shortcut {
                sequences: ["Ctrl+Tab", "Ctrl+PgDown"]
                onActivated: root.page = root.pages[(root.pages.findIndex(p => p.name === root.page) + 1) % root.pages.length].name
            }

            Shortcut {
                sequences: ["Ctrl+Shift+Tab", "Ctrl+PgUp"]
                onActivated: root.page = root.pages[(root.pages.findIndex(p => p.name === root.page) + root.pages.length - 1) % root.pages.length].name
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacing.small
                spacing: Theme.spacing.small

                // navigation rail, labels sit beside the icons when there is room
                ColumnLayout {
                    Layout.fillHeight: true
                    Layout.fillWidth: false
                    Layout.preferredWidth: win.wide ? 196 : 64
                    Layout.margins: Theme.spacing.xs
                    spacing: Theme.spacing.xs

                    Behavior on Layout.preferredWidth {
                        Anim {}
                    }

                    Label {
                        Layout.leftMargin: Theme.spacing.medium
                        Layout.topMargin: Theme.spacing.small
                        Layout.bottomMargin: Theme.spacing.small
                        visible: win.wide
                        text: "Settings"
                        font.pixelSize: Theme.font.headline
                        font.weight: Font.DemiBold
                    }

                    // opens the config file, right click copies its path
                    Rectangle {
                        Layout.fillWidth: !win.wide
                        Layout.preferredWidth: win.wide ? fab.implicitWidth + Theme.spacing.large * 2 : 56
                        Layout.bottomMargin: Theme.spacing.medium
                        implicitHeight: 52
                        radius: Theme.radius.large
                        color: Theme.color.primaryContainer

                        Row {
                            id: fab

                            anchors.centerIn: parent
                            spacing: Theme.spacing.small

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: "edit"
                                color: Theme.color.fgPrimaryContainer
                            }

                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: win.wide
                                text: "Config file"
                                font.weight: Font.DemiBold
                                color: Theme.color.fgPrimaryContainer
                            }
                        }

                        StateLayer {
                            tint: Theme.color.fgPrimaryContainer
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: e => e.button === Qt.RightButton ? Quickshell.clipboardText = Config.path : Qt.openUrlExternally("file://" + Config.path)
                        }
                    }

                    Repeater {
                        model: root.pages

                        Item {
                            id: item

                            required property var modelData
                            readonly property bool selected: root.page === modelData.name

                            Layout.fillWidth: true
                            implicitHeight: win.wide ? 44 : 56
                            // tab lands here, up and down walk the pages, enter moves into the page
                            activeFocusOnTab: true
                            readonly property bool rail: true

                            Keys.onUpPressed: {
                                const prev = nextItemInFocusChain(false);
                                if (prev?.rail)
                                    prev.forceActiveFocus();
                            }
                            Keys.onDownPressed: {
                                const next = nextItemInFocusChain(true);
                                if (next?.rail)
                                    next.forceActiveFocus();
                            }
                            Keys.onReturnPressed: {
                                root.page = item.modelData.name;
                                pageLoader.item?.nextItemInFocusChain(true)?.forceActiveFocus();
                            }
                            onActiveFocusChanged: {
                                if (activeFocus)
                                    root.page = item.modelData.name;
                            }

                            Rectangle {
                                id: indicator

                                width: win.wide ? parent.width : 56
                                height: win.wide ? parent.height : 32
                                radius: height / 2
                                color: item.selected ? Theme.color.secondaryContainer : "transparent"

                                Behavior on color {
                                    ColorAnim {}
                                }

                                StateLayer {
                                    tint: Theme.color.ink
                                    onClicked: root.page = item.modelData.name
                                }
                            }

                            FocusRing {
                                target: indicator
                                shown: item.activeFocus
                            }

                            Icon {
                                x: win.wide ? Theme.spacing.large : (56 - width) / 2
                                y: (indicator.height - height) / 2
                                name: item.modelData.icon
                                fill: item.selected ? 1 : 0
                                color: item.selected ? Theme.color.fgSecondaryContainer : Theme.color.inkMeta
                            }

                            Label {
                                x: win.wide ? Theme.spacing.large + Theme.size.icon + Theme.spacing.medium : (56 - width) / 2
                                y: win.wide ? (indicator.height - height) / 2 : indicator.height + 2
                                text: item.modelData.name
                                font.pixelSize: win.wide ? Theme.font.body : Theme.font.tiny
                                font.weight: item.selected ? Font.DemiBold : Font.Medium
                                color: item.selected ? (win.wide ? Theme.color.fgSecondaryContainer : Theme.color.ink) : Theme.color.inkMeta
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                }

                // content pane, pages fade and rise in when switching
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radius.xl
                    color: Theme.color.surfaceContainerLow
                    clip: true

                    Flickable {
                        id: flick

                        anchors.fill: parent
                        contentWidth: width
                        contentHeight: pageLoader.implicitHeight + Theme.spacing.xxl * 2
                        boundsBehavior: Flickable.StopAtBounds

                        Loader {
                            id: pageLoader

                            property string shown: root.page

                            x: Theme.spacing.xxl
                            y: Theme.spacing.xxl
                            width: flick.width - Theme.spacing.xxl * 2
                            source: shown + "Page.qml"
                        }
                    }

                    Connections {
                        target: root

                        function onPageChanged(): void {
                            swap.restart();
                        }
                    }

                    SequentialAnimation {
                        id: swap

                        NumberAnimation {
                            target: pageLoader
                            property: "opacity"
                            to: 0
                            duration: Theme.anim.fast / 2
                        }

                        ScriptAction {
                            script: {
                                pageLoader.shown = root.page;
                                flick.contentY = 0;
                                pageLoader.y = Theme.spacing.xxl + Theme.spacing.xl;
                            }
                        }

                        ParallelAnimation {
                            NumberAnimation {
                                target: pageLoader
                                property: "opacity"
                                to: 1
                                duration: Theme.anim.normal
                            }

                            NumberAnimation {
                                target: pageLoader
                                property: "y"
                                to: Theme.spacing.xxl
                                duration: Theme.anim.normal
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Theme.anim.decel
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "settings"

        function toggle(): void {
            root.open = !root.open;
        }

        function open(): void {
            root.show(root.page);
        }

        function close(): void {
            root.open = false;
        }

        function page(name: string): void {
            root.show(name);
        }
    }
}
