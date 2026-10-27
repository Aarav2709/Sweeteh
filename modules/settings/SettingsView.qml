import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.theme
import qs.services
import qs.components

// settings in the island, pages are backlit keys down the side, the page in use is pressed in and lit
Item {
    id: root

    property string page: "Appearance"
    // the page on screen trails page so the old one can slide out first
    property string shownPage: page
    readonly property var pages: [
        { name: "Appearance", icon: "palette", hint: "Colors, type and motion" },
        { name: "Layout", icon: "view_quilt", hint: "Bar, island and widgets" },
        { name: "Wallpaper", icon: "wallpaper", hint: "Folder and transitions" },
        { name: "Keybinds", icon: "keyboard", hint: "Every shortcut" },
        { name: "General", icon: "tune", hint: "Apps, power and the rest" },
        { name: "About", icon: "info", hint: "Version and updates" }
    ]
    readonly property int index: pages.findIndex(p => p.name === page)

    function reset(): void {
        if (Actions.settingsPage !== "" && pages.some(p => p.name === Actions.settingsPage))
            page = Actions.settingsPage;
        Actions.settingsPage = "";
        rail.forceActiveFocus();
    }

    function step(delta: int): void {
        page = pages[(index + delta + pages.length) % pages.length].name;
    }

    onPageChanged: swap.restart()

    implicitWidth: 1000
    implicitHeight: 600

    RowLayout {
        anchors.fill: parent
        spacing: Theme.spacing.large

        ColumnLayout {
            id: rail

            // a fixed width, its keys fill it and would otherwise squeeze the page pane to nothing
            Layout.preferredWidth: 220
            Layout.maximumWidth: 220
            Layout.fillWidth: false
            Layout.fillHeight: true
            spacing: Theme.spacing.small
            focus: true
            Keys.onUpPressed: root.step(-1)
            Keys.onDownPressed: root.step(1)
            Keys.onTabPressed: root.step(1)
            Keys.onBacktabPressed: root.step(-1)
            Keys.onReturnPressed: pageLoader.item?.nextItemInFocusChain(true)?.forceActiveFocus()

            Label {
                Layout.leftMargin: Theme.spacing.xs
                Layout.bottomMargin: Theme.spacing.small
                text: "Settings"
                font.pixelSize: Theme.font.headline
                font.weight: Font.DemiBold
            }

            Repeater {
                model: root.pages

                // a page key, the chosen one sinks onto its light
                Rectangle {
                    id: key

                    required property var modelData
                    readonly property bool selected: root.page === modelData.name

                    Layout.fillWidth: true
                    Layout.bottomMargin: Theme.depth.offset
                    implicitHeight: 52
                    radius: Theme.radius.large
                    color: selected ? Theme.mix(Theme.color.layer2, Theme.color.backlight, 0.18) : Theme.color.layer1
                    border.width: Theme.depth.rim
                    border.color: selected ? Qt.alpha(Theme.color.backlight, 0.7) : Theme.color.depthRim
                    transform: Translate {
                        y: depth.shift
                    }

                    Behavior on color {
                        ColorAnim {
                            duration: Theme.anim.fast
                        }
                    }

                    Depth {
                        id: depth

                        sink: key.selected ? 0.6 : press.pressed ? 1 : 0
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacing.medium
                        anchors.rightMargin: Theme.spacing.medium
                        spacing: Theme.spacing.medium

                        Icon {
                            name: key.modelData.icon
                            fill: key.selected ? 1 : 0
                            color: key.selected ? Theme.color.backlight : Theme.color.inkMeta
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Label {
                                text: key.modelData.name
                                font.weight: key.selected ? Font.DemiBold : Font.Medium
                            }

                            Label {
                                Layout.fillWidth: true
                                text: key.modelData.hint
                                font.pixelSize: Theme.font.tiny
                                color: Theme.color.inkFaint
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        id: press

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.page = key.modelData.name
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            // the raw file for anything the pages do not cover, right click copies its path
            Button {
                Layout.fillWidth: true
                variant: "neutral"
                icon: "edit"
                text: "Config file"
                onClicked: Qt.openUrlExternally("file://" + Config.path)
            }
        }

        // the page pane, sunk into the island so the keys beside it stand up
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.radius.xl
            color: Qt.alpha(Theme.color.depthShadow, 0.35)
            border.width: 1
            border.color: Theme.color.hairline
            clip: true

            Flickable {
                id: flick

                anchors.fill: parent
                contentWidth: width
                contentHeight: pageLoader.implicitHeight + Theme.spacing.xl * 2
                boundsBehavior: Flickable.StopAtBounds

                Loader {
                    id: pageLoader

                    x: Theme.spacing.xl
                    y: Theme.spacing.xl
                    width: flick.width - Theme.spacing.xl * 2
                    source: root.shownPage + "Page.qml"
                    transform: Translate {
                        id: slide
                    }
                }
            }
        }
    }

    // the old page slides off the way the new one comes from, then springs in
    SequentialAnimation {
        id: swap

        readonly property int dir: root.pages.findIndex(p => p.name === root.page) > root.pages.findIndex(p => p.name === root.shownPage) ? 1 : -1

        ParallelAnimation {
            NumberAnimation {
                target: pageLoader
                property: "opacity"
                to: 0
                duration: Theme.anim.fast / 2
            }

            NumberAnimation {
                target: slide
                property: "y"
                to: -swap.dir * 24
                duration: Theme.anim.fast / 2
            }
        }

        ScriptAction {
            script: {
                root.shownPage = root.page;
                flick.contentY = 0;
                slide.y = swap.dir * 36;
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
                target: slide
                property: "y"
                to: 0
                duration: Theme.anim.slow
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.anim.spatial
            }
        }
    }
}
