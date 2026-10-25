pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.config
import qs.theme
import "Fuzzy.js" as Fuzzy
import "Calc.js" as Calc

// shell actions for the launcher and the > command palette
Singleton {
    id: root

    readonly property list<var> list: {
        const out = [];
        for (const name of Modes.names) {
            const m = Modes.modes[name];
            out.push({
                icon: m.icon,
                title: "Switch to " + m.name + " mode",
                keywords: "mode layout " + name,
                run: () => Modes.set(name)
            });
        }
        const pages = [["Appearance", "palette", "theme color dark light font round blur"], ["Layout", "view_quilt", "bar island layout islands"], ["Keybinds", "keyboard", "shortcuts keys"], ["Wallpaper", "wallpaper", "background"], ["General", "tune", "options apps"], ["About", "info", "version update"]];
        for (const p of pages)
            out.push({
                icon: p[1],
                title: p[0] + " settings",
                keywords: "settings preferences " + p[2],
                run: () => Actions.openSettings(p[0])
            });
        for (const s of Defaults.choices["theme.scheme"])
            out.push({
                icon: "format_paint",
                title: "Use the " + Theme.humanize(s).toLowerCase() + " scheme",
                keywords: "scheme palette colors matugen " + s,
                run: () => Config.set("theme.scheme", s)
            });
        const wifi = Network.wifiEnabled;
        const bt = BluetoothState.enabled;
        const playing = Media.active ? [
            { icon: Media.playing ? "pause" : "play_arrow", title: Media.playing ? "Pause" : "Play", keywords: "media music song play pause", run: () => Media.toggle() },
            { icon: "skip_next", title: "Next track", keywords: "media music song skip next", run: () => Media.next() },
            { icon: "skip_previous", title: "Previous track", keywords: "media music song back previous", run: () => Media.previous() }
        ] : [];
        return out.concat(playing, [
            { icon: wifi ? "wifi_off" : "wifi", title: wifi ? "Turn Wi-Fi off" : "Turn Wi-Fi on", keywords: "wifi wi-fi wireless network internet", run: () => Network.setWifi(!wifi) },
            { icon: "wifi_find", title: "Wi-Fi networks", keywords: "wifi wi-fi wireless network connect", run: () => Actions.openPage("network") },
            { icon: bt ? "bluetooth_disabled" : "bluetooth", title: bt ? "Turn Bluetooth off" : "Turn Bluetooth on", keywords: "bluetooth bt", run: () => BluetoothState.setEnabled(!bt) },
            { icon: "bluetooth_searching", title: "Bluetooth devices", keywords: "bluetooth bt pair headphones devices", run: () => Actions.openPage("bluetooth") },
            { icon: "tune", title: "Quick settings", keywords: "control center dashboard toggles island", run: () => Actions.open("island") },
            { icon: Audio.muted ? "volume_up" : "volume_off", title: Audio.muted ? "Unmute sound" : "Mute sound", keywords: "audio volume sound mute speaker", run: () => Audio.toggleMute() },
            { icon: Audio.micMuted ? "mic" : "mic_off", title: Audio.micMuted ? "Unmute microphone" : "Mute microphone", keywords: "mic microphone mute input", run: () => Audio.toggleMic() },
            { icon: "nightlight", title: NightLight.active ? "Turn night light off" : "Turn night light on", keywords: "night light warm blue filter eyes", run: () => NightLight.toggle() },
            { icon: "wallpaper", title: "Pick a wallpaper", keywords: "wallpaper background", run: () => Actions.open("wallpaper") },
            { icon: "shuffle", title: "Random wallpaper", keywords: "wallpaper background shuffle", run: () => Wallpapers.random() },
            { icon: "palette", title: "Recolor from wallpaper", keywords: "wallpaper colors matugen theme refresh", run: () => Wallpapers.recolor(Wallpapers.current) },
            { icon: "lock", title: "Lock screen", keywords: "lock", run: () => Actions.lock() },
            { icon: "screenshot_region", title: "Capture a region", keywords: "screenshot capture", run: () => Actions.screenshot("region") },
            { icon: "screenshot_monitor", title: "Capture the screen", keywords: "screenshot capture full", run: () => Actions.screenshot("screen") },
            Recorder.recording ? { icon: "stop_circle", title: "Stop recording", keywords: "record recording screen video stop", run: () => Recorder.stop() } : { icon: "screen_record", title: "Record the screen", keywords: "record recording screen video", run: () => Recorder.start("") },
            { icon: "content_paste", title: "Clipboard history", keywords: "clipboard paste copy", run: () => Actions.open("clipboard") },
            { icon: "overview", title: "Workspace overview", keywords: "overview windows", run: () => Actions.open("overview") },
            { icon: "keyboard", title: "Keybind cheat sheet", keywords: "keys shortcuts", run: () => Actions.open("cheatsheet") },
            { icon: "monitoring", title: "System monitor", keywords: "task manager cpu memory processes", run: () => Actions.open("monitor") },
            { icon: "widgets", title: "Edit desktop widgets", keywords: "desktop widgets", run: () => Actions.editDesktop() },
            { icon: "do_not_disturb_on", title: Notifs.dnd ? "Turn do not disturb off" : "Turn do not disturb on", keywords: "dnd notifications quiet focus", run: () => Notifs.setDnd(!Notifs.dnd) },
            { icon: "clear_all", title: "Clear notifications", keywords: "notifications clear dismiss", run: () => Notifs.clear() },
            { icon: "dark_mode", title: Config.options.theme.dark ? "Use the light theme" : "Use the dark theme", keywords: "dark light theme", run: () => Config.set("theme.dark", !Config.options.theme.dark) },
            { icon: "coffee", title: Session.caffeine ? "Turn caffeine off" : "Turn caffeine on", keywords: "idle awake caffeine", run: () => Session.caffeine = !Session.caffeine },
            { icon: "energy_savings_leaf", title: "Power saver", keywords: "power profile battery saver", run: () => Battery.setProfile(PowerProfile.PowerSaver) },
            { icon: "balance", title: "Balanced power", keywords: "power profile balanced", run: () => Battery.setProfile(PowerProfile.Balanced) },
            { icon: "bolt", title: "Performance power", keywords: "power profile performance fast", run: () => Battery.setProfile(PowerProfile.Performance) },
            { icon: "system_update", title: "Check for updates", keywords: "updates upgrade packages", run: () => Updates.check() },
            { icon: "refresh", title: "Reload the shell", keywords: "reload restart shell quickshell", run: () => Quickshell.reload(false) },
            { icon: "logout", title: "Log out", keywords: "exit logout session", run: () => Session.logout() },
            { icon: "bedtime", title: "Suspend", keywords: "sleep suspend", run: () => Session.suspend() },
            { icon: "restart_alt", title: "Reboot", keywords: "restart reboot", run: () => Session.reboot() },
            { icon: "power_settings_new", title: "Shut down", keywords: "poweroff shutdown", run: () => Session.poweroff() }
        ]);
    }

    // every wallpaper by name, only searched once something is typed
    readonly property list<var> wallpapers: Wallpapers.files.map(f => {
        const name = f.slice(f.lastIndexOf("/") + 1).replace(/\.[^.]+$/, "");
        return { icon: "image", title: "Wallpaper " + name, keywords: "wallpaper background " + name.replace(/[-_.]/g, " "), run: () => Wallpapers.set(f) };
    })

    // dates and times to copy, with offsets like 3d, -3d, +4h or 2w
    readonly property var units: ({ s: 1e3, sec: 1e3, m: 6e4, min: 6e4, h: 36e5, hr: 36e5, hour: 36e5, d: 864e5, day: 864e5, w: 6048e5, wk: 6048e5, week: 6048e5 })

    function shift(base: var, sign: int, n: real, unit: string): var {
        const out = new Date(base.getTime());
        if (unit === "mo" || unit === "month")
            out.setMonth(out.getMonth() + sign * n);
        else if (unit === "y" || unit === "yr" || unit === "year")
            out.setFullYear(out.getFullYear() + sign * n);
        else if (units[unit])
            out.setTime(out.getTime() + sign * n * units[unit]);
        else
            return null;
        return out;
    }

    function ago(ms: real, day: bool): string {
        const abs = Math.abs(ms);
        if (day ? abs < 432e5 : abs < 6e4)
            return day ? "Today" : "Now";
        const steps = [[31536e6, "year"], [2592e6, "month"], [6048e5, "week"], [864e5, "day"], [36e5, "hour"], [6e4, "minute"]];
        for (const s of steps)
            if (abs >= s[0]) {
                const n = Math.round(abs / s[0]);
                const text = n + " " + s[1] + (n === 1 ? "" : "s");
                return ms < 0 ? text + " ago" : "In " + text;
            }
        return "";
    }

    function moments(cmd: string): list<var> {
        const m = cmd.toLowerCase().match(/^(today|tomorrow|yesterday|date|time|now|unix|timestamp)\b\s*(.*)$/);
        if (!m)
            return [];
        const word = m[1];
        const day = word !== "time" && word !== "now" && word !== "unix" && word !== "timestamp";
        const now = new Date();
        let at = new Date(now.getTime() + (word === "tomorrow" ? 864e5 : word === "yesterday" ? -864e5 : 0));
        const rest = m[2].trim();
        if (rest !== "") {
            const re = /([+-]?)\s*(\d+(?:\.\d+)?)\s*([a-z]*)/g;
            let hit, eaten = "";
            while ((hit = re.exec(rest)) !== null) {
                if (hit[0] === "")
                    break;
                const unit = (hit[3] || (day ? "d" : "h")).replace(/s$/, "") || "s";
                at = shift(at, hit[1] === "-" ? -1 : 1, Number(hit[2]), unit);
                if (!at)
                    return [];
                eaten += hit[0];
            }
            // anything left over is not an offset, so this is not a date query after all
            if (eaten.replace(/\s/g, "") !== rest.replace(/\s/g, ""))
                return [];
        }
        const label = ago(at.getTime() - now.getTime(), day);
        const formats = word === "unix" || word === "timestamp" ? [String(Math.floor(at.getTime() / 1000))] : word === "now" ? [at.toISOString(), String(Math.floor(at.getTime() / 1000))] : day ? [Qt.formatDate(at, "dddd, d MMMM yyyy"), Qt.formatDate(at, "yyyy-MM-dd"), Qt.formatDate(at, "dd/MM/yyyy")] : [Qt.formatTime(at, "HH:mm"), Qt.formatTime(at, "h:mm AP"), Qt.formatDateTime(at, "yyyy-MM-dd HH:mm")];
        return formats.map(text => ({ kind: "copy", icon: day ? "calendar_today" : "schedule", title: text, subtitle: label, run: () => Actions.copy(text) }));
    }

    // commands that take something after them, volume 40, ws 3, timer 5m, close firefox, #ff8800
    function answers(cmd: string): list<var> {
        const out = moments(cmd);
        const lower = cmd.toLowerCase();
        const num = lower.match(/^(volume|vol|brightness|bright|ws|workspace|go)\s+(\d+)%?$/);
        if (num) {
            const n = Number(num[2]);
            if (num[1].startsWith("vol"))
                out.push({ kind: "action", icon: "volume_up", title: "Set volume to " + Math.min(150, n) + "%", run: () => Audio.setVolume(Math.min(150, n) / 100) });
            else if (num[1].startsWith("bright") && Brightness.available)
                out.push({ kind: "action", icon: "brightness_6", title: "Set brightness to " + Math.min(100, n) + "%", run: () => Brightness.set(Math.min(100, n) / 100) });
            else if (n > 0)
                out.push({ kind: "action", icon: "space_dashboard", title: "Go to workspace " + n, run: () => Hypr.focusWorkspace(n) });
        }
        const timer = lower.match(/^timer\s+(.+)$/);
        if (timer) {
            const ms = span(timer[1]);
            if (ms > 0)
                out.push({ kind: "action", icon: "timer", title: "Timer for " + ago(ms, false).replace(/^In /, ""), subtitle: countdown.running ? "Replaces the running timer" : "The island glows when it ends", run: () => startTimer(ms, timer[1]) });
        }
        if (/^timer\b/.test(lower) && countdown.running)
            out.push({ kind: "action", icon: "timer_off", title: "Cancel the timer", subtitle: ago(timerEnd - Date.now(), false).replace(/^In /, "") + " left", run: () => countdown.stop() });
        const win = lower.match(/^(close|kill|focus|win|window)\s+(.+)$/);
        if (win)
            for (const t of Hypr.toplevels.values) {
                const cls = t.wayland?.appId ?? t.lastIpcObject?.class ?? "";
                const s = Fuzzy.best(win[2], [cls, t.title]);
                if (s <= 0)
                    continue;
                const close = win[1] === "close" || win[1] === "kill";
                out.push({ kind: "action", image: Apps.icon(cls), title: (close ? "Close " : "Focus ") + (t.title || cls), subtitle: cls, score: s, run: close ? () => Hypr.closeWindow(t.address) : () => Hypr.focusWindow(t.address) });
            }
        // three digits only with the hash, so words like bad or fed stay words
        const hex = cmd.match(/^(?:#([0-9a-f]{3}|[0-9a-f]{6})|([0-9a-f]{6}))$/i);
        if (hex) {
            const c = Qt.color("#" + (hex[1] ?? hex[2]));
            const rgb = `rgb(${Math.round(c.r * 255)}, ${Math.round(c.g * 255)}, ${Math.round(c.b * 255)})`;
            const hsl = `hsl(${Math.round(Math.max(0, c.hslHue) * 360)}, ${Math.round(c.hslSaturation * 100)}%, ${Math.round(c.hslLightness * 100)}%)`;
            for (const text of [c.toString(), rgb, hsl])
                out.push({ kind: "copy", icon: "palette", swatch: c, title: text, run: () => Actions.copy(text) });
        }
        if (lower === "uuid") {
            const id = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, ch => ((ch === "x" ? 0 : 8) + Math.floor(Math.random() * (ch === "x" ? 16 : 4))).toString(16));
            out.push({ kind: "copy", icon: "fingerprint", title: id, subtitle: "New uuid", run: () => Actions.copy(id) });
        }
        const pass = lower.match(/^(pass|password)\s*(\d*)$/);
        if (pass) {
            const len = Math.max(8, Math.min(64, Number(pass[2]) || 20));
            const set = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$%&*-_";
            let pw = "";
            for (let i = 0; i < len; i++)
                pw += set[Math.floor(Math.random() * set.length)];
            out.push({ kind: "copy", icon: "password", title: pw, subtitle: len + " characters", run: () => Actions.copy(pw) });
        }
        const sum = Calc.evaluate(cmd);
        if (sum !== null)
            out.push({ kind: "sum", icon: "calculate", title: String(sum), subtitle: "Press enter to copy", run: () => Actions.copy(String(sum)) });
        return out;
    }

    // 5m, 1h30m, 90s, a bare number is minutes
    function span(text: string): real {
        const re = /(\d+(?:\.\d+)?)\s*([a-z]*)/g;
        let hit, total = 0;
        while ((hit = re.exec(text.toLowerCase())) !== null)
            total += Number(hit[1]) * (units[(hit[2] || "m").replace(/s$/, "") || "s"] ?? 0);
        return total;
    }

    property real timerEnd: 0
    property string timerLabel: ""

    function startTimer(ms: real, label: string): void {
        timerEnd = Date.now() + ms;
        timerLabel = label.trim();
        countdown.interval = ms;
        countdown.restart();
        Actions.say("timer", "Timer set for " + timerLabel);
    }

    Timer {
        id: countdown

        onTriggered: {
            Actions.say("timer", "Timer done, " + root.timerLabel);
            Quickshell.execDetached(["notify-send", "-a", "Sweeteh", "-i", "alarm", "Timer done", root.timerLabel]);
        }
    }

    // the palette remembers what ran lately so it comes back first
    property list<string> recent: []

    function used(title: string): void {
        recent = [title].concat(recent.filter(t => t !== title)).slice(0, 8);
        recentStore.setText(JSON.stringify(recent));
    }

    // a small lift for what ran lately, the newest the most
    function boost(title: string): int {
        const i = recent.indexOf(title);
        return i < 0 ? 0 : 120 - i * 12;
    }

    FileView {
        id: recentStore

        path: Paths.state + "/palette.json"
        printErrors: false
        onLoaded: {
            try {
                root.recent = JSON.parse(text());
            } catch (e) {}
        }
    }
}
