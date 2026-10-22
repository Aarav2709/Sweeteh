import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.theme
import qs.components

// tray app menu drawn by the shell, submenus open in place with a way back
PopupWindow {
    id: root

    property var anchorItem: null
    property var rootMenu: null
    // submenus walked into, the last one is on screen
    property var trail: []
    readonly property var current: trail.length > 0 ? trail[trail.length - 1] : rootMenu
    property int highlighted: -1
    // drives the open and close animation, the window hides once it has played out
    property bool shown: false

    function open(item: var, menu: var): void {
        anchorItem = item;
        rootMenu = menu;
        trail = [];
        highlighted = -1;
        visible = true;
        shown = true;
    }

    function close(): void {
        shown = false;
        hideTimer.restart();
    }

    onTrailChanged: pageIn.restart()

    Timer {
        id: hideTimer

        interval: Theme.anim.fast
        onTriggered: {
            if (!root.shown) {
                root.visible = false;
                root.trail = [];
            }
        }
    }

    // a submenu slides in from the side it was entered from
    ParallelAnimation {
        id: pageIn

        Anim {
            target: column
            property: "opacity"
            from: 0
            to: 1
            duration: Theme.anim.fast
        }

        Anim {
            target: columnSlide
            property: "x"
            from: 16
            to: 0
            easing.bezierCurve: Theme.anim.decel
        }
    }

    function activate(entry: var): void {
        if (!entry || entry.isSeparator || !entry.enabled)
            return;
        if (entry.hasChildren) {
            trail = [...trail, entry];
            highlighted = -1;
            return;
        }
        entry.triggered();
        close();
    }

    anchor.item: anchorItem
    anchor.rect.y: anchorItem ? anchorItem.height + Theme.spacing.small : 0
    anchor.rect.x: anchorItem ? anchorItem.width / 2 - implicitWidth / 2 : 0
    implicitWidth: 250
    implicitHeight: card.height + Theme.depth.offset + 2
    color: "transparent"

    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: root.close()
    }

    QsMenuOpener {
        id: opener

        menu: root.current
    }

    Rectangle {
        id: card

        width: parent.width
        height: column.implicitHeight + Theme.spacing.small * 2
        radius: Theme.radius.large
        color: Theme.color.panel
        border.width: Theme.depth.rim
        border.color: Theme.color.depthRim
        focus: true
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.92
        transformOrigin: Item.Top
        transform: Translate {
            y: root.shown ? 0 : -8

            Behavior on y {
                Anim {
                    duration: Theme.anim.fast
                    easing.bezierCurve: Theme.anim.decel
                }
            }
        }

        Behavior on opacity {
            Anim {
                duration: Theme.anim.fast
            }
        }

        Behavior on scale {
            Anim {
                duration: Theme.anim.normal
                easing.bezierCurve: root.shown ? Theme.anim.spatial : Theme.anim.accel
            }
        }
        Keys.onEscapePressed: root.trail.length > 0 ? root.trail = root.trail.slice(0, -1) : root.close()
        Keys.onLeftPressed: {
            if (root.trail.length > 0)
                root.trail = root.trail.slice(0, -1);
        }
        Keys.onDownPressed: root.highlighted = Math.min(opener.children.values.length - 1, root.highlighted + 1)
        Keys.onUpPressed: root.highlighted = Math.max(0, root.highlighted - 1)
        Keys.onReturnPressed: root.activate(opener.children.values[root.highlighted])
        Keys.onRightPressed: root.activate(opener.children.values[root.highlighted])

        Depth {}

        ColumnLayout {
            id: column

            anchors.fill: parent
            anchors.margins: Theme.spacing.small
            spacing: Theme.spacing.xxs
            transform: Translate {
                id: columnSlide
            }

            Row {
                id: back

                Layout.fillWidth: true
                visible: root.trail.length > 0

                Item {
                    width: column.width
                    height: 34

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radius.small
                        color: backArea.containsMouse ? Theme.color.layer2 : "transparent"
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacing.small
                        spacing: Theme.spacing.small

                        Icon {
                            name: "arrow_back"
                            size: Theme.font.large + 2
                            color: Theme.color.inkMeta
                        }

                        Label {
                            Layout.fillWidth: true
                            text: root.current?.text ?? ""
                            font.weight: Font.DemiBold
                        }
                    }

                    MouseArea {
                        id: backArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.trail = root.trail.slice(0, -1)
                    }
                }
            }

            Repeater {
                model: opener.children

                Item {
                    id: row

                    required property var modelData
                    required property int index
                    readonly property bool lit: root.highlighted === index

                    Layout.fillWidth: true
                    implicitHeight: modelData.isSeparator ? 9 : 34
                    opacity: modelData.enabled || modelData.isSeparator ? 1 : 0.45

                    Rectangle {
                        visible: row.modelData.isSeparator
                        anchors.centerIn: parent
                        width: parent.width - Theme.spacing.medium * 2
                        height: 1
                        color: Theme.color.hairline
                    }

                    Rectangle {
                        visible: !row.modelData.isSeparator
                        anchors.fill: parent
                        radius: Theme.radius.small
                        color: row.lit ? Theme.color.layer2 : "transparent"

                        Behavior on color {
                            ColorAnim {
                                duration: Theme.anim.fast
                            }
                        }
                    }

                    RowLayout {
                        visible: !row.modelData.isSeparator
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacing.small
                        anchors.rightMargin: Theme.spacing.small
                        spacing: Theme.spacing.small

                        // checkboxes and radio items show their state, plain items their icon
                        Icon {
                            visible: row.modelData.buttonType !== QsMenuButtonType.None
                            name: row.modelData.buttonType === QsMenuButtonType.RadioButton ? (row.modelData.checkState === Qt.Checked ? "radio_button_checked" : "radio_button_unchecked") : (row.modelData.checkState === Qt.Checked ? "check_box" : "check_box_outline_blank")
                            size: Theme.font.large + 2
                            fill: row.modelData.checkState === Qt.Checked ? 1 : 0
                            color: row.modelData.checkState === Qt.Checked ? Theme.color.primary : Theme.color.inkMeta
                        }

                        IconImage {
                            visible: row.modelData.buttonType === QsMenuButtonType.None && row.modelData.icon !== ""
                            implicitSize: 18
                            source: row.modelData.icon
                        }

                        Label {
                            Layout.fillWidth: true
                            text: row.modelData.text.replace(/_(?!_)/g, "")
                        }

                        Icon {
                            visible: row.modelData.hasChildren
                            name: "chevron_right"
                            size: Theme.font.large + 2
                            color: Theme.color.inkMeta
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !row.modelData.isSeparator
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.highlighted = row.index
                        onClicked: root.activate(row.modelData)
                    }
                }
            }
        }
    }
}
