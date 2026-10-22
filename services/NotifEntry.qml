import QtQuick
import Quickshell.Services.Notifications

// one notification, live or restored from history
QtObject {
    id: root

    property int key
    property string appName
    property string appIcon
    property string summary
    property string body
    property string image
    property int urgency: NotificationUrgency.Normal
    property real time: Date.now()
    property bool popup: false
    property var actions: []
    property Notification notification: null

    readonly property bool critical: urgency === NotificationUrgency.Critical

    function invoke(identifier: string): void {
        const action = notification?.actions.find(a => a.identifier === identifier);
        if (action)
            action.invoke();
    }

    function toJson(): var {
        return {
            key: key,
            appName: appName,
            appIcon: appIcon,
            summary: summary,
            body: body,
            image: image.startsWith("/") || image.startsWith("file:") ? image : "",
            urgency: urgency,
            time: time
        };
    }

    readonly property Connections tracker: Connections {
        target: root.notification

        function onClosed(): void {
            root.notification = null;
        }
    }
}
