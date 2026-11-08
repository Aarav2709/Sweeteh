pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// upcoming events from a calendar link, the ics address google, proton, outlook or nextcloud give out
// fetched every half hour, recurring events are worked out for the next few weeks
Singleton {
    id: root

    readonly property string url: (Config.options.clock.calendarUrl ?? "").trim().replace(/^webcal:\/\//i, "https://")
    // every occurrence in the coming weeks, soonest first, as { title, start, end, allDay }
    property var upcoming: []
    // yyyy-m-d of each day that has something, for the dots in the calendar
    readonly property var days: {
        const out = {};
        for (const e of upcoming)
            out[root.key(e.start)] = true;
        return out;
    }
    // what is still ahead, today and later
    readonly property var next: upcoming.filter(e => (e.allDay ? new Date(e.start.getFullYear(), e.start.getMonth(), e.start.getDate() + 1) : e.end) > Time.now).slice(0, 3)

    function key(d: date): string {
        return d.getFullYear() + "-" + d.getMonth() + "-" + d.getDate();
    }

    function refresh(): void {
        if (url === "") {
            upcoming = [];
            return;
        }
        fetch.running = true;
    }

    onUrlChanged: refresh()

    // 20261108, 20261108T093000 or 20261108T093000Z, a trailing z is utc and the rest is read as local time
    function parseDate(v: string): var {
        const m = v.match(/^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z)?)?/);
        if (!m)
            return null;
        if (!m[4])
            return new Date(+m[1], +m[2] - 1, +m[3]);
        if (m[7])
            return new Date(Date.UTC(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +m[6]));
        return new Date(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +m[6]);
    }

    function parse(text: string): void {
        // folded lines continue on the next one after a space
        const lines = text.replace(/\r?\n[ \t]/g, "").split(/\r?\n/);
        const from = new Date(Time.now.getFullYear(), Time.now.getMonth(), Time.now.getDate() - 1);
        const until = new Date(from.getTime() + 45 * 86400000);
        const out = [];
        let ev = null;
        for (const line of lines) {
            if (line === "BEGIN:VEVENT") {
                ev = {
                    exdates: []
                };
                continue;
            }
            if (line === "END:VEVENT") {
                if (ev && ev.start && !ev.cancelled)
                    expand(ev, from, until, out);
                ev = null;
                continue;
            }
            if (!ev)
                continue;
            const colon = line.indexOf(":");
            if (colon < 0)
                continue;
            const name = line.slice(0, colon).split(";")[0];
            const value = line.slice(colon + 1);
            if (name === "SUMMARY")
                ev.title = value.replace(/\\,/g, ",").replace(/\;/g, ";").replace(/\\n/gi, " ");
            else if (name === "DTSTART") {
                ev.start = parseDate(value);
                ev.allDay = !/T\d/.test(value);
            } else if (name === "DTEND")
                ev.end = parseDate(value);
            else if (name === "RRULE")
                ev.rule = Object.fromEntries(value.split(";").map(p => p.split("=")));
            else if (name === "EXDATE")
                ev.exdates.push(...value.split(",").map(v => parseDate(v)?.getTime()));
            else if (name === "STATUS" && value === "CANCELLED")
                ev.cancelled = true;
        }
        upcoming = out.sort((a, b) => a.start - b.start);
    }

    // a single event, or the repeats of one, daily, weekly, monthly or yearly with an interval, count, end and weekdays
    function expand(ev: var, from: date, until: date, out: var): void {
        const length = ev.end ? ev.end - ev.start : (ev.allDay ? 86400000 : 3600000);
        const push = start => {
            if (ev.exdates.includes(start.getTime()))
                return;
            const end = new Date(start.getTime() + length);
            if (end > from && start < until)
                out.push({
                    title: ev.title || "Event",
                    start: start,
                    end: end,
                    allDay: ev.allDay
                });
        };
        const r = ev.rule;
        if (!r) {
            push(ev.start);
            return;
        }
        const step = Math.max(1, +(r.INTERVAL ?? 1));
        const last = r.UNTIL ? parseDate(r.UNTIL) : null;
        const count = r.COUNT ? +r.COUNT : Infinity;
        const weekdays = r.BYDAY && r.FREQ === "WEEKLY" ? r.BYDAY.split(",").map(d => ["SU", "MO", "TU", "WE", "TH", "FR", "SA"].indexOf(d.slice(-2))) : null;
        let made = 0;
        for (let i = 0; i < 1500 && made < count; i++) {
            const s = new Date(ev.start);
            if (r.FREQ === "DAILY")
                s.setDate(s.getDate() + i * step);
            else if (r.FREQ === "WEEKLY")
                s.setDate(s.getDate() + i * 7 * step);
            else if (r.FREQ === "MONTHLY")
                s.setMonth(s.getMonth() + i * step);
            else if (r.FREQ === "YEARLY")
                s.setFullYear(s.getFullYear() + i * step);
            else {
                push(ev.start);
                return;
            }
            if ((last && s > last) || s > until)
                return;
            if (weekdays) {
                // every listed weekday in this week of the rule
                const monday = new Date(s);
                monday.setDate(s.getDate() - ((s.getDay() + 6) % 7));
                for (const wd of weekdays) {
                    const d = new Date(monday);
                    d.setDate(monday.getDate() + ((wd + 6) % 7));
                    if (d < ev.start || (last && d > last) || made >= count)
                        continue;
                    made++;
                    push(d);
                }
            } else {
                made++;
                push(s);
            }
        }
    }

    Process {
        id: fetch

        command: ["curl", "-sfL", "--max-time", "20", root.url]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.includes("BEGIN:VCALENDAR"))
                    root.parse(text);
            }
        }
    }

    Timer {
        running: root.url !== ""
        repeat: true
        triggeredOnStart: true
        interval: 30 * 60 * 1000
        onTriggered: root.refresh()
    }
}
