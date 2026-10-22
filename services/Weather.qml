pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// current weather from wttr.in, located by ip unless a place is set, refreshed every half hour
Singleton {
    id: root

    property bool ready: false
    property int tempC: 0
    property int feelsC: 0
    property int code: 113
    property string condition: ""
    property string place: ""
    property int humidity: 0
    readonly property bool fahrenheit: Config.options.desktop.fahrenheit
    readonly property string temp: Math.round(fahrenheit ? tempC * 9 / 5 + 32 : tempC) + "°"
    readonly property bool night: {
        const h = Time.now.getHours();
        return h < 6 || h >= 19;
    }
    readonly property string icon: {
        if (code === 113)
            return night ? "clear_night" : "sunny";
        if (code === 116)
            return night ? "nights_stay" : "partly_cloudy_day";
        if ([119, 122].includes(code))
            return "cloud";
        if ([143, 248, 260].includes(code))
            return "foggy";
        if ([200, 386, 389, 392, 395].includes(code))
            return "thunderstorm";
        if ([179, 182, 185, 227, 230, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377].includes(code))
            return "weather_snowy";
        return "rainy";
    }

    function refresh(): void {
        fetch.running = true;
    }

    Process {
        id: fetch

        command: ["curl", "-sf", "-m", "15", "https://wttr.in/" + encodeURIComponent(Config.options.desktop.weatherPlace) + "?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    const c = d.current_condition[0];
                    root.tempC = parseInt(c.temp_C);
                    root.feelsC = parseInt(c.FeelsLikeC);
                    root.code = parseInt(c.weatherCode);
                    root.condition = c.weatherDesc[0].value;
                    root.humidity = parseInt(c.humidity);
                    root.place = Config.options.desktop.weatherPlace || d.nearest_area[0].areaName[0].value;
                    root.ready = true;
                } catch (e) {}
            }
        }
    }

    Timer {
        running: true
        repeat: true
        triggeredOnStart: true
        interval: 30 * 60 * 1000
        onTriggered: root.refresh()
    }
}
