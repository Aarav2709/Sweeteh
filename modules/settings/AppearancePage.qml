import QtQuick
import QtQuick.Layouts
import qs.config
import qs.theme
import qs.components

// colors, shape, type and motion
ColumnLayout {
    id: root

    readonly property var t: Config.options.theme
    readonly property list<string> swatches: Defaults.choices["theme.accent"]
    readonly property var schemeNotes: ({
            "scheme-tonal-spot": "Calm, a muted take on the main wallpaper color.",
            "scheme-content": "Stays close to the colors actually in the wallpaper.",
            "scheme-expressive": "Playful, shifts hues away from the source.",
            "scheme-fidelity": "Matches the source color as closely as it can.",
            "scheme-fruit-salad": "Bold and colorful with rotated hues.",
            "scheme-monochrome": "Greys only, no color at all.",
            "scheme-neutral": "Nearly grey with a hint of color.",
            "scheme-rainbow": "Colorful accents on a neutral ground.",
            "scheme-vibrant": "Saturated, the loudest palette."
        })

    spacing: Theme.spacing.small

    Label {
        text: "Appearance"
        font.pixelSize: Theme.font.headline
        font.weight: Font.DemiBold
    }

    Section {
        Layout.fillWidth: true
        title: "Color"
        icon: "palette"

        OptionRow {
            label: "Dark theme"

            Toggle {
                checked: root.t.dark
                onToggled: v => Config.set("theme.dark", v)
            }
        }

        OptionRow {
            label: "Colors from wallpaper"
            hint: "Matugen builds the palette from the current wallpaper."

            Toggle {
                checked: root.t.fromWallpaper
                onToggled: v => Config.set("theme.fromWallpaper", v)
            }
        }

        OptionRow {
            label: "Accent color"
            hint: "Used when colors do not come from the wallpaper."
            opacity: root.t.fromWallpaper ? Theme.state.disabled : 1

            Repeater {
                model: root.swatches

                Rectangle {
                    required property string modelData

                    implicitWidth: 30
                    implicitHeight: 30
                    radius: 15
                    color: modelData
                    border.width: root.t.accent === modelData ? 3 : 0
                    border.color: Theme.color.ink

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Config.set("theme.fromWallpaper", false);
                            Config.set("theme.accent", parent.modelData);
                        }
                    }
                }
            }

            Field {
                implicitWidth: 120
                implicitHeight: 36
                text: root.t.accent
                onAccepted: {
                    if (/^#[0-9a-fA-F]{6}$/.test(text))
                        Config.set("theme.accent", text);
                }
            }
        }

        Label {
            Layout.leftMargin: Theme.spacing.small
            Layout.topMargin: Theme.spacing.small
            text: "Scheme"
            font.weight: Font.Medium
        }

        Repeater {
            model: Defaults.choices["theme.scheme"]

            Rectangle {
                id: scheme

                required property string modelData
                readonly property bool selected: root.t.scheme === modelData

                Layout.fillWidth: true
                implicitHeight: 52
                radius: Theme.radius.medium
                color: selected ? Theme.color.secondaryContainer : "transparent"

                Behavior on color {
                    ColorAnim {
                        duration: Theme.anim.fast
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacing.small
                    anchors.rightMargin: Theme.spacing.medium
                    spacing: Theme.spacing.medium

                    Icon {
                        name: scheme.selected ? "radio_button_checked" : "radio_button_unchecked"
                        fill: scheme.selected ? 1 : 0
                        color: scheme.selected ? Theme.color.primary : Theme.color.inkMeta
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Label {
                            text: Theme.humanize(scheme.modelData)
                            font.weight: Font.DemiBold
                            color: scheme.selected ? Theme.color.fgSecondaryContainer : Theme.color.ink
                        }

                        Label {
                            Layout.fillWidth: true
                            text: root.schemeNotes[scheme.modelData] ?? ""
                            font.pixelSize: Theme.font.small
                            color: scheme.selected ? Theme.color.fgSecondaryContainer : Theme.color.inkMeta
                        }
                    }
                }

                StateLayer {
                    onClicked: Config.set("theme.scheme", scheme.modelData)
                }
            }
        }

        OptionRow {
            label: "Panel opacity"

            Slider {
                implicitWidth: 260
                from: 0.3
                to: 1
                value: root.t.panelOpacity
                onMoved: v => Config.set("theme.panelOpacity", Math.round(v * 100) / 100)
            }
        }

        OptionRow {
            label: "Matugen config"
            hint: "Optional matugen config with your own templates, to recolor other apps too."

            Field {
                implicitWidth: 300
                implicitHeight: 40
                placeholder: "~/.config/matugen/config.toml"
                text: root.t.matugenConfig
                onAccepted: Config.set("theme.matugenConfig", text)
            }
        }
    }

    Section {
        Layout.fillWidth: true
        title: "Shape and type"
        icon: "format_shapes"

        Repeater {
            model: [
                { key: "roundness", label: "Roundness", from: 0, to: 2 },
                { key: "spacing", label: "Spacing", from: 0.5, to: 1.6 },
                { key: "fontScale", label: "Text size", from: 0.7, to: 1.5 },
                { key: "animationSpeed", label: "Animation speed", from: 0, to: 2.5 }
            ]

            OptionRow {
                required property var modelData

                label: modelData.label
                hint: modelData.key === "animationSpeed" ? "Zero turns animations off." : ""

                Slider {
                    implicitWidth: 260
                    showValue: false
                    from: modelData.from
                    to: modelData.to
                    value: root.t[modelData.key]
                    onMoved: v => Config.set("theme." + modelData.key, Math.round(v * 20) / 20)
                }

                Label {
                    Layout.preferredWidth: 40
                    text: root.t[modelData.key].toFixed(2)
                    color: Theme.color.inkMeta
                }
            }
        }

        AutoOption {
            key: "theme.fontFamily"
        }

        AutoOption {
            key: "theme.monoFamily"
        }
    }

    Section {
        Layout.fillWidth: true
        title: "Style"
        icon: "layers"

        OptionRow {
            label: "Raised look"
            hint: "Pills, cards and the island sit on a crisp edge and a hard shadow, and sink when pressed."

            Toggle {
                checked: root.t.depth
                onToggled: v => Config.set("theme.depth", v)
            }
        }

        OptionRow {
            label: "Motion blur"
            hint: "Island content blurs while it fades in and out. Skipped in performance mode."

            Toggle {
                checked: root.t.motionBlur
                onToggled: v => Config.set("theme.motionBlur", v)
            }
        }

        OptionRow {
            label: "Window borders from wallpaper"
            hint: "Window borders take their colors from the palette. Turning this off hands them back to your Hyprland config."

            Toggle {
                checked: root.t.windowBorders
                onToggled: v => Config.set("theme.windowBorders", v)
            }
        }

        OptionRow {
            label: "Rounded screen corners"

            Toggle {
                checked: root.t.screenCorners
                onToggled: v => Config.set("theme.screenCorners", v)
            }
        }

        OptionRow {
            label: "Theme apps"
            hint: "Kitty, Nautilus, Vesktop, Zed and other gtk apps follow the wallpaper colors, folder icons included."

            Toggle {
                checked: root.t.appTheming
                onToggled: v => Config.set("theme.appTheming", v)
            }
        }

        OptionRow {
            label: "Letter roundness"
            hint: "Softens letter ends on fonts that support it."

            Slider {
                implicitWidth: 260
                showValue: false
                from: 0
                to: 100
                value: root.t.fontRound
                onMoved: v => Config.set("theme.fontRound", Math.round(v))
            }

            Label {
                Layout.preferredWidth: 40
                text: root.t.fontRound
                color: Theme.color.inkMeta
            }
        }
    }

    Section {
        Layout.fillWidth: true
        title: "Preview"
        icon: "visibility"

        RowLayout {
            Layout.margins: Theme.spacing.small
            spacing: Theme.spacing.medium

            Button {
                variant: "filled"
                icon: "check"
                text: "Filled"
            }

            Button {
                icon: "palette"
                text: "Tonal"
            }

            Toggle {
                checked: true
            }

            Slider {
                implicitWidth: 180
                icon: "volume_up"
                value: 0.6
            }
        }
    }
}
