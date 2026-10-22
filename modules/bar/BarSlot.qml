import QtQuick
import qs.config
import qs.theme

// one slot of widgets, a widget only loads when its module is on
Row {
    id: root

    property list<string> ids: []

    spacing: Theme.spacing.small

    Repeater {
        model: root.ids

        Loader {
            required property string modelData
            readonly property var entry: Registry.byId(modelData)

            anchors.verticalCenter: parent.verticalCenter
            active: entry !== null && entry.widget && Modes.enabled(modelData)
            visible: active && (item?.shown ?? true)
            source: active ? Qt.resolvedUrl(`../${modelData}/${Registry.stem(modelData)}Widget.qml`) : ""
        }
    }
}
