import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.theme
import qs.services
import qs.components

// wallpaper grid in the island, picking one recolors the whole shell
Item {
    id: root

    property string filter: ""
    // browsing wallhaven instead of the local folder
    property bool online: false
    readonly property var matches: Wallpapers.files.filter(f => f.toLowerCase().includes(filter.toLowerCase()))

    implicitWidth: column.width
    implicitHeight: column.implicitHeight

    function reset(): void {
        Wallpapers.refresh();
        search.text = "";
        filter = "";
        search.focusInput();
        grid.currentIndex = Math.max(0, matches.indexOf(Wallpapers.current));
    }

    ColumnLayout {
        id: column

        width: 960
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
                placeholder: root.online ? "Search wallhaven, enter to look" : "Filter wallpapers"
                onEdited: {
                    if (!root.online)
                        root.filter = text;
                }
                onAccepted: {
                    if (root.online)
                        Wallhaven.search(text);
                    else if (root.matches[grid.currentIndex])
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
                variant: root.online ? "filled" : "neutral"
                icon: "travel_explore"
                text: root.online ? "Online" : "Local"
                onClicked: {
                    root.online = !root.online;
                    search.text = "";
                    root.filter = "";
                    if (root.online && Wallhaven.results.length === 0)
                        Wallhaven.search("");
                }
            }

            Button {
                visible: !root.online
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
            visible: count > 0 && !root.online
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

        // wallhaven results, a click downloads into the wallpaper folder and sets it
        GridView {
            id: web

            Layout.fillWidth: true
            Layout.preferredHeight: grid.cellHeight * 2.5
            visible: root.online && count > 0
            clip: true
            cellWidth: grid.cellWidth
            cellHeight: grid.cellHeight
            model: Wallhaven.results

            delegate: Item {
                id: shot

                required property var modelData

                width: web.cellWidth
                height: web.cellHeight

                ClippingRectangle {
                    anchors.fill: parent
                    anchors.margins: Theme.spacing.xs
                    radius: Theme.radius.large
                    color: Theme.color.layer2
                    scale: webHover.hovered ? 1.03 : 1

                    Behavior on scale {
                        Anim {
                            duration: Theme.anim.fast
                        }
                    }

                    Image {
                        anchors.fill: parent
                        source: shot.modelData.thumb
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize: Qt.size(400, 250)
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.margins: Theme.spacing.small
                        width: sizeLabel.implicitWidth + Theme.spacing.small * 2
                        height: 22
                        radius: height / 2
                        color: Theme.color.panel

                        Label {
                            id: sizeLabel

                            anchors.centerIn: parent
                            text: Wallhaven.fetching === shot.modelData.id ? "Downloading" : shot.modelData.size
                            font.pixelSize: Theme.font.tiny
                            font.weight: Font.DemiBold
                        }
                    }
                }

                HoverHandler {
                    id: webHover

                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: Wallhaven.pick(shot.modelData)
                }
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.margins: Theme.spacing.xl
            visible: root.online && web.count === 0
            text: Wallhaven.loading ? "Looking on wallhaven." : Wallhaven.failed ? "Could not reach wallhaven." : "Nothing found, try other words."
            color: Theme.color.inkMeta
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.spacing.xl
            visible: grid.count === 0 && !root.online
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
