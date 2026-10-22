import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.theme
import qs.services
import qs.components

// wallpaper grid, picking one recolors the whole shell
Panel {
    id: root

    property string filter: ""
    readonly property var matches: Wallpapers.files.filter(f => f.toLowerCase().includes(filter.toLowerCase()))

    panelId: "wallpaper"
    edge: "bottom"
    exclusiveKeyboard: true
    onOpened: {
        Wallpapers.refresh();
        search.text = "";
        filter = "";
        search.focusInput();
        grid.currentIndex = Math.max(0, matches.indexOf(Wallpapers.current));
    }

    ColumnLayout {
        id: column

        width: Math.min((root.screen?.width ?? 1200) - Theme.spacing.xxl * 4, 1000)
        height: implicitHeight
        spacing: Theme.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.small

            Field {
                id: search

                Layout.fillWidth: true
                color: Theme.color.layer1
                outlineOnFocus: false
                icon: "search"
                placeholder: "Filter wallpapers"
                onEdited: root.filter = text
                onAccepted: {
                    if (root.matches[grid.currentIndex])
                        Wallpapers.set(root.matches[grid.currentIndex]);
                }
                input.Keys.onPressed: e => {
                    if (e.key === Qt.Key_Right) {
                        grid.moveCurrentIndexRight();
                        e.accepted = true;
                    } else if (e.key === Qt.Key_Left) {
                        grid.moveCurrentIndexLeft();
                        e.accepted = true;
                    } else if (e.key === Qt.Key_Down) {
                        grid.moveCurrentIndexDown();
                        e.accepted = true;
                    } else if (e.key === Qt.Key_Up) {
                        grid.moveCurrentIndexUp();
                        e.accepted = true;
                    }
                }
            }

            Button {
                variant: "neutral"
                icon: "shuffle"
                text: "Random"
                onClicked: Wallpapers.random()
            }

            Button {
                variant: "neutral"
                icon: Theme.dark ? "light_mode" : "dark_mode"
                text: Theme.dark ? "Light" : "Dark"
                onClicked: Config.set("theme.dark", !Theme.dark)
            }
        }

        GridView {
            id: grid

            readonly property int columns: Math.max(2, Math.floor(width / 260))

            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(cellHeight * 2.5, Math.max(cellHeight, contentHeight))
            visible: count > 0
            clip: true
            cellWidth: width / columns
            cellHeight: cellWidth * 0.62
            model: root.matches
            highlightFollowsCurrentItem: true
            keyNavigationEnabled: true

            delegate: Item {
                id: tile

                required property string modelData
                required property int index
                readonly property bool current: Wallpapers.current === modelData
                readonly property bool selected: GridView.isCurrentItem

                width: grid.cellWidth
                height: grid.cellHeight

                ClippingRectangle {
                    anchors.fill: parent
                    anchors.margins: Theme.spacing.xs
                    radius: Theme.radius.large
                    color: Theme.color.layer2
                    border.width: tile.current ? 3 : tile.selected ? 2 : 0
                    border.color: tile.current ? Theme.color.primary : Theme.color.ink
                    scale: hover.hovered ? 1.03 : 1

                    Behavior on scale {
                        Anim {
                            duration: Theme.anim.fast
                        }
                    }

                    Image {
                        anchors.fill: parent
                        source: !Wallpapers.isVideo(tile.modelData) ? Paths.url(tile.modelData) : Wallpapers.posters > 0 ? Paths.url(Wallpapers.thumb(tile.modelData)) + "?v=" + Wallpapers.posters : ""
                        cache: !Wallpapers.isVideo(tile.modelData)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize: Qt.size(400, 250)
                    }

                    Rectangle {
                        visible: Wallpapers.isLive(tile.modelData)
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.margins: Theme.spacing.small
                        width: liveRow.implicitWidth + Theme.spacing.small * 2
                        height: 24
                        radius: height / 2
                        color: Theme.color.panel

                        Row {
                            id: liveRow

                            anchors.centerIn: parent
                            spacing: Theme.spacing.xxs

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: Wallpapers.isVideo(tile.modelData) ? "play_circle" : "gif_box"
                                size: 14
                                fill: 1
                                color: Theme.color.primary
                            }

                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Live"
                                font.pixelSize: Theme.font.tiny
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    Rectangle {
                        visible: tile.current
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Theme.spacing.small
                        width: 28
                        height: 28
                        radius: 14
                        color: Theme.color.primary

                        Icon {
                            anchors.centerIn: parent
                            name: "check"
                            color: Theme.color.fgPrimary
                            size: 18
                        }
                    }
                }

                HoverHandler {
                    id: hover

                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: {
                        grid.currentIndex = tile.index;
                        Wallpapers.set(tile.modelData);
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.spacing.xl
            visible: grid.count === 0
            spacing: Theme.spacing.medium

            Icon {
                Layout.alignment: Qt.AlignHCenter
                name: "hide_image"
                size: 48
                color: Theme.color.outline
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: Wallpapers.files.length === 0 ? "No images in " + Config.options.general.wallpaperDir + ", add some or pick another folder in settings." : "Nothing matches that filter."
                color: Theme.color.inkMeta
            }
        }
    }
}
