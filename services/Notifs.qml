pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.config

// notification server, popups and persisted history
Singleton {
    id: root

    property list<NotifEntry> list: []
    // a reply field has the keyboard, the island holds the card open meanwhile
    property bool replying: false
    readonly property list<NotifEntry> popups: list.filter(n => n.popup)
    readonly property bool dnd: Config.options.notifications.dnd
    property int nextKey: 1

    signal arrived(NotifEntry entry)

    function add(n: Notification): void {
        n.tracked = true;
        const entry = entryComponent.createObject(root, {
            key: nextKey++,
            appName: n.appName,
            appIcon: n.appIcon,
            summary: n.summary,
            body: n.body,
            image: n.image,
            urgency: n.urgency,
            actions: n.actions.map(a => ({
                        identifier: a.identifier,
                        text: a.text
                    })),
            notification: n,
            popup: true
        });
        if (dnd && n.urgency !== NotificationUrgency.Critical)
            entry.popup = false;
        const limit = Config.options.notifications.historyLimit;
        const next = [entry, ...list];
        for (const old of next.slice(limit))
            old.destroy();
        list = next.slice(0, limit);
        arrived(entry);
        save.restart();
    }

    // cards that are still animating out may call back after their entry is gone
    function hide(entry: NotifEntry): void {
        if (!entry)
            return;
        entry.popup = false;
        list = list.slice();
    }

    function dismiss(entry: NotifEntry): void {
        if (!entry)
            return;
        entry.notification?.dismiss();
        list = list.filter(n => n !== entry);
        entry.destroy();
        save.restart();
    }

    function clear(): void {
        for (const n of list) {
            n.notification?.dismiss();
            n.destroy();
        }
        list = [];
        save.restart();
    }

    function setDnd(on: bool): void {
        Config.set("notifications.dnd", on);
    }

    // short relative time for cards
    function ago(time: real): string {
        const s = Math.floor((Date.now() - time) / 1000);
        if (s < 60)
            return "Now";
        if (s < 3600)
            return Math.floor(s / 60) + " min";
        if (s < 86400)
            return Math.floor(s / 3600) + " h";
        return Qt.formatDate(new Date(time), "d MMM");
    }

    NotificationServer {
        keepOnReload: false
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        inlineReplySupported: true
        imageSupported: true
        persistenceSupported: true
        onNotification: n => root.add(n)
    }

    Component {
        id: entryComponent

        NotifEntry {}
    }

    Timer {
        id: save

        interval: 1000
        onTriggered: store.setText(JSON.stringify(root.list.map(n => n.toJson())))
    }

    FileView {
        id: store

        path: Paths.state + "/notifications.json"
        printErrors: false
        onLoaded: {
            try {
                const saved = JSON.parse(text());
                root.list = saved.map(o => entryComponent.createObject(root, o)).concat(root.list);
                root.nextKey = Math.max(0, ...saved.map(o => o.key)) + 1;
            } catch (e) {}
        }
    }

    IpcHandler {
        target: "notifs"

        function clear(): void {
            root.clear();
        }

        function dnd(): void {
            root.setDnd(!Config.options.notifications.dnd);
        }

        function count(): int {
            return root.list.length;
        }
    }
}
