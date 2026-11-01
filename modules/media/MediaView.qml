import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.config
import qs.theme
import qs.services
import qs.components

// cover, controls, progress and synced lyrics, shared with the island
ColumnLayout {
    id: root

    property bool showLyrics: Config.options.media.lyrics

    implicitWidth: 380
    width: 380
    spacing: Theme.spacing.medium

    ClippingRectangle {
        Layout.fillWidth: true
        implicitHeight: 128
        radius: Theme.radius.xl
        color: Theme.color.layer1

        // tiny cover scaled up and blurred for a tinted backdrop
        Image {
            anchors.fill: parent
            visible: Media.art !== ""
            source: Media.art
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize: Qt.size(48, 48)
            opacity: 0.55
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1
                blurMax: 48
                saturation: 0.2
            }
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: Qt.alpha(Theme.color.layer1, 0.2)
                }

                GradientStop {
                    position: 1
                    color: Qt.alpha(Theme.color.layer1, 0.75)
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacing.medium
            spacing: Theme.spacing.large

            // a video keeps its wide thumbnail, a song its square cover
            ClippingRectangle {
                implicitWidth: Media.video ? 160 : 104
                implicitHeight: Media.video ? 90 : 104
                radius: Theme.radius.large
                color: Theme.color.secondaryContainer

                Image {
                    anchors.fill: parent
                    source: Media.art
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Media.video ? Qt.size(320, 180) : Qt.size(208, 208)
                }

                Icon {
                    anchors.centerIn: parent
                    visible: Media.art === ""
                    name: Media.video ? "smart_display" : "music_note"
                    size: 40
                    color: Theme.color.fgSecondaryContainer
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacing.xxs

                Rectangle {
                    visible: Media.active
                    implicitWidth: source.implicitWidth + Theme.spacing.small * 2
                    implicitHeight: 22
                    radius: height / 2
                    color: Qt.alpha(Theme.color.ink, 0.1)

                    Row {
                        id: source

                        anchors.centerIn: parent
                        spacing: Theme.spacing.xs

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: Media.players.length > 1 ? "swap_horiz" : Media.video ? "smart_display" : "graphic_eq"
                            size: 14
                            color: Theme.color.inkSoft
                        }

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Media.source
                            font.pixelSize: Theme.font.tiny
                            font.weight: Font.DemiBold
                            color: Theme.color.inkSoft
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: Media.players.length > 1
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Media.cycle()
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: Media.title
                    font.pixelSize: Theme.font.large
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                }

                Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    // a song names its album too, a video only its channel
                    text: Media.video ? Media.artist : [Media.artist, Media.album].filter(t => t !== "" && t !== Media.title).join("  ·  ")
                    elide: Text.ElideRight
                    color: Theme.color.inkSoft
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.spacing.xs
        Layout.rightMargin: Theme.spacing.xs
        visible: Media.length > 0
        spacing: 0

        WavyProgress {
            Layout.fillWidth: true
            moving: Media.playing
            from: 0
            to: Math.max(1, Media.length)
            value: Media.position
            onMoved: v => Media.seek(v)
        }

        RowLayout {
            Layout.fillWidth: true

            Label {
                Layout.fillWidth: true
                text: Media.format(Media.position)
                font.pixelSize: Theme.font.tiny
                font.features: ({
                        "tnum": 1
                    })
                color: Theme.color.inkMeta
            }

            Label {
                text: Media.format(Media.length)
                font.pixelSize: Theme.font.tiny
                font.features: ({
                        "tnum": 1
                    })
                color: Theme.color.inkMeta
            }
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Theme.spacing.medium

        IconButton {
            visible: Media.player?.shuffleSupported ?? false
            icon: "shuffle"
            size: 36
            checked: Media.player?.shuffle ?? false
            onClicked: Media.shuffle()
        }

        IconButton {
            icon: "skip_previous"
            size: 44
            filled: true
            disabled: !(Media.player?.canGoPrevious ?? false)
            onClicked: Media.previous()
        }

        Rectangle {
            implicitWidth: 76
            implicitHeight: 52
            radius: play.pressed ? Theme.radius.medium : Media.playing ? Theme.radius.large : height / 2
            color: Theme.color.primary

            Behavior on radius {
                Anim {
                    easing.bezierCurve: Theme.anim.spatial
                }
            }

            Icon {
                anchors.centerIn: parent
                name: Media.playing ? "pause" : "play_arrow"
                fill: 1
                size: 28
                color: Theme.color.fgPrimary
            }

            StateLayer {
                id: play

                tint: Theme.color.fgPrimary
                onClicked: Media.toggle()
            }
        }

        IconButton {
            icon: "skip_next"
            size: 44
            filled: true
            disabled: !(Media.player?.canGoNext ?? false)
            onClicked: Media.next()
        }

        IconButton {
            visible: Media.player?.loopSupported ?? false
            icon: Media.player?.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
            size: 36
            checked: (Media.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
            onClicked: Media.loop()
        }
    }

    ListView {
        id: lyrics

        Layout.fillWidth: true
        Layout.preferredHeight: 180
        visible: root.showLyrics && Lyrics.lines.length > 0
        clip: true
        interactive: false
        model: Lyrics.lines
        currentIndex: Math.max(0, Lyrics.index)
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: height / 2 - 18
        preferredHighlightEnd: height / 2 + 18
        highlightMoveDuration: Theme.anim.slow
        spacing: Theme.spacing.xs

        delegate: Label {
            required property var modelData
            required property int index
            readonly property bool active: index === Lyrics.index

            width: lyrics.width
            height: implicitHeight
            text: modelData.text || "..."
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: active ? Theme.font.large : Theme.font.body
            font.weight: active ? Font.DemiBold : Font.Normal
            color: active ? Theme.color.primary : Theme.color.inkMeta
            opacity: active ? 1 : 0.6

            Behavior on opacity {
                Anim {}
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: fade
            maskThresholdMin: 0.1
            maskSpreadAtMin: 1
        }
    }

    // soft fade at the top and bottom of the lyrics
    Rectangle {
        id: fade

        width: lyrics.width
        height: lyrics.height
        visible: false
        layer.enabled: true
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "transparent"
            }
            GradientStop {
                position: 0.25
                color: Theme.color.surface
            }
            GradientStop {
                position: 0.75
                color: Theme.color.surface
            }
            GradientStop {
                position: 1
                color: "transparent"
            }
        }
    }

    Label {
        Layout.fillWidth: true
        visible: root.showLyrics && Lyrics.lines.length === 0 && Media.active && !Media.video
        text: Lyrics.loading ? "Looking for lyrics." : Lyrics.plain !== "" ? "Only unsynced lyrics are available." : "No lyrics found."
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Theme.font.small
        color: Theme.color.inkMeta
    }

    // every app playing something, a click brings it to the front
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacing.small
        visible: Media.players.length > 1
        spacing: Theme.spacing.xxs

        Label {
            text: "Playing now"
            font.pixelSize: Theme.font.small
            font.weight: Font.DemiBold
            color: Theme.color.inkMeta
        }

        Repeater {
            model: Media.players

            ListRow {
                required property var modelData

                Layout.fillWidth: true
                selected: modelData === Media.player
                title: (modelData.trackTitle || modelData.identity || "Unknown").replace(/^\(\d+\)\s*/, "").replace(/\s+[-–]\s+YouTube$/, "")
                subtitle: (modelData.isPlaying ? "Playing" : "Paused") + "  ·  " + (modelData.identity ?? "")
                icon: modelData.isPlaying ? "graphic_eq" : "pause"
                onClicked: Media.manual = modelData
            }
        }
    }

    // what played lately, a click picks the player back up or opens the app again
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacing.small
        visible: Config.options.media.history && recent.count > 0
        spacing: Theme.spacing.xxs

        Label {
            text: "Recently played"
            font.pixelSize: Theme.font.small
            font.weight: Font.DemiBold
            color: Theme.color.inkMeta
        }

        Repeater {
            id: recent

            model: Media.history.filter(h => h.title !== Media.title).slice(0, 3)

            ListRow {
                required property var modelData

                Layout.fillWidth: true
                title: modelData.title
                subtitle: modelData.artist
                icon: "history"
                onClicked: Media.resume(modelData)
            }
        }
    }
}
