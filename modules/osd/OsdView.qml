import QtQuick
import qs.theme
import qs.services
import qs.components

// thick level bar with its icon riding inside the fill, upright or lying down
Item {
    id: root

    property string kind: "volume"
    property bool vertical: false
    readonly property real level: Math.min(1, kind === "volume" ? Audio.volume : Brightness.value)
    readonly property string icon: kind === "volume" ? Audio.icon : Brightness.icon
    readonly property bool muted: kind === "volume" && Audio.muted
    readonly property int thickness: 40
    readonly property int length: vertical ? 168 : 240

    implicitWidth: vertical ? thickness : length + value.implicitWidth + Theme.spacing.medium * 2
    implicitHeight: vertical ? length + value.implicitHeight + Theme.spacing.medium : thickness

    Label {
        id: value

        x: root.vertical ? (root.width - width) / 2 : root.width - width - Theme.spacing.xs
        y: root.vertical ? 0 : (root.height - height) / 2
        text: root.muted ? "Off" : Math.round(root.level * 100)
        font.pixelSize: root.vertical ? Theme.font.small : Theme.font.body
        font.weight: Font.DemiBold
        font.features: ({
                "tnum": 1
            })
        color: Theme.color.inkSoft
    }

    Rectangle {
        id: track

        x: 0
        y: root.vertical ? root.height - height : 0
        width: root.vertical ? root.thickness : root.length
        height: root.vertical ? root.length : root.thickness
        radius: root.thickness / 2
        color: Theme.color.layer2

        Rectangle {
            property real span: Math.max(root.thickness, (root.vertical ? track.height : track.width) * root.level)

            x: 0
            y: root.vertical ? track.height - height : 0
            width: root.vertical ? track.width : span
            height: root.vertical ? span : track.height
            radius: root.thickness / 2
            color: root.muted ? Theme.color.outline : Theme.color.primary

            Behavior on span {
                Anim {
                    duration: Theme.anim.fast
                }
            }
        }

        Icon {
            x: (root.thickness - width) / 2
            y: root.vertical ? track.height - root.thickness + (root.thickness - height) / 2 : (root.thickness - height) / 2
            name: root.icon
            fill: 1
            color: Theme.color.fgPrimary
        }
    }
}
