pragma Singleton

import QtQuick
import Quickshell
import qs.config

// one shared clock
Singleton {
    id: root

    property date now: new Date()
    readonly property bool use24h: Config.options.clock.use24h
    readonly property string time: Qt.formatTime(now, use24h ? (Config.options.clock.showSeconds ? "HH:mm:ss" : "HH:mm") : (Config.options.clock.showSeconds ? "h:mm:ss AP" : "h:mm AP"))
    readonly property string hours: Qt.formatTime(now, use24h ? "HH" : "hh")
    readonly property string minutes: Qt.formatTime(now, "mm")
    readonly property string date: Qt.formatDate(now, "dddd, d MMMM")
    readonly property string shortDate: Qt.formatDate(now, "ddd d MMM")

    SystemClock {
        id: clock

        precision: Config.options.clock.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
        // copied over by hand so a clock that is being torn down never feeds an empty date
        onDateChanged: {
            if (date)
                root.now = date;
        }
    }
}
