import QtQuick
import QtQuick.Layouts
import qs.config
import qs.theme
import qs.services
import qs.components
import "../../services/Fuzzy.js" as Fuzzy

// clipboard history with search, enter copies, delete removes, shown inside the island
ColumnLayout {
    id: root

    property string filter: ""
    readonly property var matches: filter === "" ? Clipboard.entries : Clipboard.entries.filter(e => !e.image && Fuzzy.score(filter, e.text) > 0)

    signal done

    function reset(): void {
        Clipboard.refresh();
        field.text = "";
        filter = "";
        list.currentIndex = 0;
        field.focusInput();
    }

    function pick(index: int): void {
        const e = matches[index];
        if (!e)
            return;
        Clipboard.copy(e);
        done();
    }

    width: 560
    spacing: Theme.spacing.medium

    RowLayout {
        Layout.fillWidth: true

        Field {
            id: field

            Layout.fillWidth: true
            color: Theme.color.layer1
            outlineOnFocus: false
            icon: "content_paste_search"
            placeholder: "Search clipboard"
            onEdited: {
                root.filter = text;
                list.currentIndex = 0;
            }
            onAccepted: root.pick(list.currentIndex)
            input.Keys.onPressed: e => {
                if (e.key === Qt.Key_Down) {
                    list.incrementCurrentIndex();
                    e.accepted = true;
                } else if (e.key === Qt.Key_Up) {
                    list.decrementCurrentIndex();
                    e.accepted = true;
                } else if (e.key === Qt.Key_Escape) {
                    root.done();
                    e.accepted = true;
                } else if (e.key === Qt.Key_Delete && root.matches[list.currentIndex]) {
                    Clipboard.remove(root.matches[list.currentIndex]);
                    e.accepted = true;
                }
            }
        }

        IconButton {
            icon: "delete_sweep"
            filled: true
            onClicked: Clipboard.wipe()
        }
    }

    ListView {
        id: list

        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(64, Math.min(contentHeight, 380))
        clip: true
        spacing: Theme.spacing.xxs
        model: root.matches
        highlightMoveDuration: Theme.anim.fast
        highlight: Rectangle {
            radius: Theme.radius.medium
            color: Theme.color.secondaryContainer
        }

        delegate: Item {
            id: row

            required property var modelData
            required property int index

            width: list.width
            height: modelData.image ? 120 : 48

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacing.medium
                anchors.rightMargin: Theme.spacing.xs
                spacing: Theme.spacing.medium

                Icon {
                    name: row.modelData.image ? "image" : "notes"
                    color: Theme.color.inkMeta
                }

                Label {
                    Layout.fillWidth: true
                    visible: !row.modelData.image
                    text: row.modelData.text
                    maximumLineCount: 1
                }

                Image {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: Theme.spacing.xs
                    visible: row.modelData.image
                    source: row.modelData.image && Clipboard.decoded[row.modelData.id] ? Paths.url(Clipboard.imagePath(row.modelData)) + "?v=" + Clipboard.imageVersion : ""
                    fillMode: Image.PreserveAspectFit
                    horizontalAlignment: Image.AlignLeft
                    asynchronous: true
                    cache: false
                    sourceSize.height: 220
                }

                IconButton {
                    size: 32
                    icon: "close"
                    onClicked: Clipboard.remove(row.modelData)
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: 40
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: list.currentIndex = row.index
                onClicked: root.pick(row.index)
            }
        }

        Label {
            anchors.centerIn: parent
            visible: list.count === 0
            text: Clipboard.available ? "Clipboard history is empty." : "Install cliphist and wl clipboard to keep history."
            color: Theme.color.inkMeta
        }
    }
}
