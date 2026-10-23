import QtQuick
import qs.theme
import qs.components

// one positioned widget, draggable in edit mode
Item {
    id: root

    required property var spec
    property bool editing: false
    // the desktop layer it sits on, set once the repeater parents it
    property Item area: null

    signal moved(real fx, real fy)
    signal removed

    onParentChanged: area = parent ?? null
    x: spec.x * (area?.width ?? 0)
    y: spec.y * (area?.height ?? 0)
    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    Loader {
        id: loader

        source: ({ clock: "ClockWidget.qml", analog: "AnalogWidget.qml", weather: "WeatherWidget.qml", media: "MediaWidget.qml", system: "SystemWidget.qml", calendar: "CalendarWidget.qml" })[root.spec.type] ?? ""
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -Theme.spacing.small
        visible: root.editing
        radius: Theme.radius.xl + Theme.spacing.small
        color: dragArea.active ? Qt.alpha(Theme.wall.primary, 0.08) : "transparent"
        border.width: 2
        border.color: dragArea.active ? Theme.wall.primary : Qt.alpha(Theme.wall.ink, 0.35)
    }

    MouseArea {
        id: dragArea

        readonly property bool active: drag.active

        anchors.fill: parent
        enabled: root.editing
        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        drag.target: root
        drag.minimumX: 0
        drag.minimumY: 0
        drag.maximumX: (root.area?.width ?? 0) - root.width
        drag.maximumY: (root.area?.height ?? 0) - root.height
        onReleased: root.moved(root.x / root.area.width, root.y / root.area.height)
    }

    IconButton {
        visible: root.editing
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: -Theme.spacing.large
        size: 28
        icon: "close"
        filled: true
        onClicked: root.removed()
    }
}
