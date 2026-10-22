import QtQuick
import QtQuick.Layouts
import qs.config
import qs.theme
import qs.components

// pick islands or island, each drawn as a tiny screen
ColumnLayout {
    id: root

    spacing: Theme.spacing.small

    Label {
        text: "Layout"
        font.pixelSize: Theme.font.headline
        font.weight: Font.DemiBold
    }

    Label {
        Layout.fillWidth: true
        text: "How the shell sits on screen. Switch any time from the mode switcher too."
        wrapMode: Text.Wrap
        color: Theme.color.inkMeta
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacing.medium
        spacing: Theme.spacing.medium

        Repeater {
            model: Modes.names

            Rectangle {
                id: card

                required property string modelData
                readonly property var mode: Modes.modes[modelData]
                readonly property bool selected: Modes.current === modelData

                Layout.fillWidth: true
                implicitHeight: 230
                radius: Theme.radius.xl
                color: selected ? Theme.color.secondaryContainer : Theme.color.layer1
                border.width: selected ? 2 : 0
                border.color: Theme.color.primary

                Behavior on color {
                    ColorAnim {}
                }

                // the little screen
                Rectangle {
                    id: screen

                    readonly property color ink: card.selected ? Theme.color.primary : Theme.color.inkMeta

                    x: Theme.spacing.medium
                    y: Theme.spacing.medium
                    width: parent.width - Theme.spacing.medium * 2
                    height: 150
                    radius: Theme.radius.medium
                    color: Theme.color.layer3
                    clip: true

                    Repeater {
                        model: card.mode.bar ? [[6, 46], [screen.width - 52, 46]] : []

                        Rectangle {
                            required property var modelData

                            x: modelData[0]
                            y: 5
                            width: modelData[1]
                            height: 9
                            radius: 4.5
                            color: screen.ink
                            opacity: 0.85
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: -8
                        width: 64
                        height: 22
                        radius: 8
                        color: screen.ink
                    }

                    Rectangle {
                        x: parent.width * 0.18
                        y: parent.height * 0.32
                        width: parent.width * 0.64
                        height: parent.height * 0.52
                        radius: 4
                        color: "transparent"
                        border.width: 1
                        border.color: Theme.color.inkFaint
                    }
                }

                ColumnLayout {
                    x: Theme.spacing.medium
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.spacing.medium
                    spacing: 0

                    Label {
                        text: card.mode.name
                        font.weight: Font.DemiBold
                        color: card.selected ? Theme.color.fgSecondaryContainer : Theme.color.ink
                    }

                    Label {
                        text: card.mode.bar ? "Bar pills around the island." : "Just the island."
                        font.pixelSize: Theme.font.small
                        color: card.selected ? Theme.color.fgSecondaryContainer : Theme.color.inkMeta
                    }
                }

                StateLayer {
                    onClicked: Modes.set(card.modelData)
                }
            }
        }
    }

    Section {
        Layout.fillWidth: true
        visible: Modes.islands
        title: "Bar"
        icon: "toolbar"

        Repeater {
            model: Object.keys(Defaults.values.bar)

            AutoOption {
                required property string modelData

                key: "bar." + modelData
            }
        }
    }
}
