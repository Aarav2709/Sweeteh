import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config
import qs.theme
import qs.services
import qs.components

// the first run tour, a few pages in the island, arrows and enter walk it, escape skips it
Item {
    id: root

    property int page: 0
    readonly property int pages: 4
    readonly property var picks: Wallpapers.files.filter(f => !Wallpapers.isVideo(f)).slice(0, 5)
    readonly property var keys: [
        { action: "launcher toggle", text: "Search apps, files and sums" },
        { action: "", combo: [">"], text: "Every command, in the launcher" },
        { action: "island toggle", text: "Quick settings and notifications" },
        { action: "wallpaper toggle", text: "Pick a wallpaper" },
        { action: "cheatsheet toggle", text: "Every keybind" }
    ]

    signal done

    function reset(): void {
        page = 0;
        Wallpapers.refresh();
        forceActiveFocus();
    }

    function next(): void {
        if (page < pages - 1)
            page++;
        else
            done();
    }

    // the bind's keys as caps, a lone super tap reads as just super
    function combo(action: string): list<string> {
        const bind = Config.options.keybinds.find(b => b.action === action);
        if (!bind)
            return [];
        const parts = bind.keys.split("+").map(k => k.trim()).filter(k => k !== "");
        return [...new Set(parts.map(k => /^SUPER/i.test(k) ? "Super" : k.length === 1 ? k.toUpperCase() : k.charAt(0) + k.slice(1).toLowerCase()))];
    }

    implicitWidth: 560
    implicitHeight: column.implicitHeight

    focus: true
    Keys.onRightPressed: next()
    Keys.onReturnPressed: next()
    Keys.onEnterPressed: next()
    Keys.onLeftPressed: page = Math.max(0, page - 1)
    // skipping counts as seen, so it does not come back next start
    Keys.onEscapePressed: done()

    ColumnLayout {
        id: column

        width: parent.width
        spacing: Theme.spacing.large

        // the pages slide past each other, only the one in view is shown
        Item {
            Layout.fillWidth: true
            // tall enough for the fullest page, a squeezed layout would stack the buttons onto the text
            Layout.preferredHeight: Math.max(280, tallest)
            clip: true

            property real tallest: 0

            Repeater {
                model: root.pages

                Item {
                    id: pageItem

                    required property int index

                    width: parent.width
                    height: parent.height
                    x: (index - root.page) * (width + Theme.spacing.xl)
                    opacity: index === root.page ? 1 : 0
                    visible: opacity > 0

                    Behavior on x {
                        enabled: Theme.anim.speed > 0

                        Spring {}
                    }

                    Behavior on opacity {
                        Anim {}
                    }

                    Loader {
                        width: parent.width
                        height: Math.max(parent.height, implicitHeight)
                        sourceComponent: [hello, look, keysPage, ready][pageItem.index]
                        onImplicitHeightChanged: parent.parent.tallest = Math.max(parent.parent.tallest, implicitHeight)
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.small

            // where you are in the tour, the current dot stretches
            Row {
                spacing: Theme.spacing.xs

                Repeater {
                    model: root.pages

                    Rectangle {
                        required property int index

                        width: index === root.page ? 22 : 8
                        height: 8
                        radius: 4
                        color: index === root.page ? Theme.color.backlight : Theme.color.layer3

                        Behavior on width {
                            Anim {
                                easing.bezierCurve: Theme.anim.spatial
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                visible: root.page > 0
                variant: "neutral"
                text: "Back"
                onClicked: root.page--
            }

            Button {
                variant: "filled"
                icon: root.page === root.pages - 1 ? "check" : "arrow_forward"
                text: root.page === 0 ? "Show me" : root.page === root.pages - 1 ? "Let's go" : "Next"
                onClicked: root.next()
            }
        }
    }

    Component {
        id: hello

        ColumnLayout {
            spacing: Theme.spacing.small

            Item {
                Layout.fillHeight: true
            }

            Label {
                text: "Hi, this is Sweeteh."
                font.pixelSize: Theme.font.display
                font.weight: Font.DemiBold
            }

            Label {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: "Everything happens in this island. It glows with your wallpaper, breathes with your music and lights up when something happens."
                color: Theme.color.inkMeta
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }

    Component {
        id: look

        ColumnLayout {
            spacing: Theme.spacing.medium

            Label {
                text: "Make it yours"
                font.pixelSize: Theme.font.headline
                font.weight: Font.DemiBold
            }

            Label {
                text: "The whole shell takes its color from the wallpaper."
                color: Theme.color.inkMeta
            }

            RowLayout {
                spacing: Theme.spacing.small

                Repeater {
                    model: root.picks

                    ClippingRectangle {
                        id: pick

                        required property string modelData
                        readonly property bool current: Wallpapers.current === modelData

                        implicitWidth: 96
                        implicitHeight: 64
                        radius: Theme.radius.medium
                        color: Theme.color.layer2
                        border.width: current ? 3 : 0
                        border.color: Theme.color.backlight
                        scale: tap.pressed ? 0.94 : hover.hovered ? 1.05 : 1

                        Behavior on scale {
                            Anim {
                                duration: Theme.anim.fast
                                easing.bezierCurve: Theme.anim.spatialFast
                            }
                        }

                        Image {
                            anchors.fill: parent
                            source: Paths.url(pick.modelData)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize: Qt.size(192, 128)
                        }

                        HoverHandler {
                            id: hover

                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            id: tap

                            onTapped: Wallpapers.set(pick.modelData)
                        }
                    }
                }
            }

            RowLayout {
                spacing: Theme.spacing.small

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
        }
    }

    Component {
        id: keysPage

        ColumnLayout {
            spacing: Theme.spacing.small

            Label {
                text: "Keys worth knowing"
                font.pixelSize: Theme.font.headline
                font.weight: Font.DemiBold
            }

            Repeater {
                model: root.keys

                RowLayout {
                    id: keyRow

                    required property var modelData
                    readonly property list<string> caps: modelData.combo ?? root.combo(modelData.action)

                    visible: caps.length > 0
                    spacing: Theme.spacing.medium

                    Row {
                        Layout.preferredWidth: 120
                        spacing: Theme.spacing.xs

                        Repeater {
                            model: keyRow.caps

                            // a little backlit keycap
                            Rectangle {
                                required property string modelData

                                width: Math.max(30, capLabel.implicitWidth + Theme.spacing.medium * 2)
                                height: 28
                                radius: Theme.radius.small
                                color: Theme.color.layer2
                                border.width: Theme.depth.rim
                                border.color: Theme.color.depthRim

                                Depth {}

                                Label {
                                    id: capLabel

                                    anchors.centerIn: parent
                                    text: modelData
                                    font.pixelSize: Theme.font.small
                                    font.weight: Font.DemiBold
                                }
                            }
                        }
                    }

                    Label {
                        text: keyRow.modelData.text
                        color: Theme.color.inkMeta
                    }
                }
            }
        }
    }

    Component {
        id: ready

        ColumnLayout {
            spacing: Theme.spacing.small

            Item {
                Layout.fillHeight: true
            }

            Label {
                text: "You're set."
                font.pixelSize: Theme.font.display
                font.weight: Font.DemiBold
            }

            Label {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: "Tap Super and type > to see everything Sweeteh can do. Settings live there too, and this tour is one command away if you ever want it back."
                color: Theme.color.inkMeta
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
