import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.components

// the line being sung, the one before it faded above and the next one waiting below
DeskCard {
    id: root

    span: "wide"

    readonly property bool synced: Lyrics.lines.length > 0 && Media.active && !Media.video
    readonly property int at: Lyrics.index

    function line(i: int): string {
        return i >= 0 && i < Lyrics.lines.length ? Lyrics.lines[i].text : "";
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.large
        spacing: Theme.spacing.xs

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.xs

            Icon {
                name: "lyrics"
                size: 18
                fill: Media.playing ? 1 : 0
                color: Theme.wall.primary
            }

            Label {
                Layout.fillWidth: true
                text: Media.active ? Media.title : "Lyrics"
                font.pixelSize: Theme.font.small
                font.weight: Font.DemiBold
                color: Theme.wall.inkMeta
            }
        }

        Item {
            Layout.fillHeight: true
        }

        Label {
            Layout.fillWidth: true
            visible: root.synced
            text: root.line(root.at - 1)
            font.pixelSize: Theme.font.small
            color: Theme.wall.inkFaint
        }

        // the sung line glides in as it changes
        Label {
            id: sung

            Layout.fillWidth: true
            text: root.synced ? (root.line(root.at) || "♪") : !Media.active ? "Play a song for its words to show here." : Media.video ? "Videos have no lyrics." : Lyrics.loading ? "Looking for lyrics." : "No synced lyrics for this one."
            wrapMode: Text.Wrap
            maximumLineCount: 2
            font.pixelSize: root.synced ? Theme.font.large : Theme.font.body
            font.weight: root.synced ? Font.DemiBold : Font.Medium
            color: root.synced ? Theme.wall.ink : Theme.wall.inkMeta

            onTextChanged: {
                if (root.synced && Theme.anim.speed > 0)
                    glide.restart();
            }

            transform: Translate {
                id: shift
            }

            ParallelAnimation {
                id: glide

                NumberAnimation {
                    target: shift
                    property: "y"
                    from: 10
                    to: 0
                    duration: Theme.anim.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.anim.decel
                }

                NumberAnimation {
                    target: sung
                    property: "opacity"
                    from: 0.3
                    to: 1
                    duration: Theme.anim.normal
                }
            }
        }

        Label {
            Layout.fillWidth: true
            visible: root.synced
            text: root.line(root.at + 1)
            font.pixelSize: Theme.font.small
            color: Theme.wall.inkMeta
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
