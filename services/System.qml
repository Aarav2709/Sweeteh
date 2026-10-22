pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// processor, memory, disk, network and heat, sampled only while something shows them
Singleton {
    id: root

    // panels and widgets that show these numbers count themselves in and out
    property int watchers: 0
    property bool wantProcesses: false
    readonly property int historySize: 40

    property real cpu: 0
    property var cpuHistory: []
    property real memUsed: 0
    property real memTotal: 1
    property var memHistory: []
    property real swapUsed: 0
    property real swapTotal: 0
    property real diskUsed: 0
    property real diskTotal: 1
    property real down: 0
    property real up: 0
    property real temp: 0
    property real uptime: 0
    property var processes: []

    property var lastCpu: null
    property var lastNet: null
    property string tempPath: ""

    readonly property real memRatio: memUsed / Math.max(1, memTotal)
    readonly property real diskRatio: diskUsed / Math.max(1, diskTotal)

    function bytes(n: real): string {
        const units = ["B", "KB", "MB", "GB", "TB"];
        let i = 0;
        while (n >= 1024 && i < units.length - 1) {
            n /= 1024;
            i++;
        }
        return (i >= 3 ? n.toFixed(1) : Math.round(n)) + " " + units[i];
    }

    function duration(seconds: real): string {
        const d = Math.floor(seconds / 86400), h = Math.floor(seconds % 86400 / 3600), m = Math.floor(seconds % 3600 / 60);
        return (d > 0 ? d + " d " : "") + (d > 0 || h > 0 ? h + " h " : "") + m + " min";
    }

    function push(list: var, value: real): var {
        const next = list.concat([value]);
        return next.length > historySize ? next.slice(next.length - historySize) : next;
    }

    // ends every process of that name, since grouped rows stand for all of them
    function kill(name: string): void {
        Quickshell.execDetached(["pkill", "-x", name]);
        procs.running = true;
    }

    function sample(): void {
        stat.reload();
        const f = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        const idle = f[3] + f[4];
        const total = f.reduce((a, b) => a + b, 0);
        if (lastCpu) {
            const dt = total - lastCpu.total;
            cpu = dt > 0 ? 1 - (idle - lastCpu.idle) / dt : 0;
            cpuHistory = push(cpuHistory, cpu);
        }
        lastCpu = {
            idle: idle,
            total: total
        };

        meminfo.reload();
        const mem = {};
        for (const line of meminfo.text().split("\n")) {
            const m = line.match(/^(\w+):\s+(\d+)/);
            if (m)
                mem[m[1]] = Number(m[2]) * 1024;
        }
        memTotal = mem.MemTotal ?? 1;
        memUsed = memTotal - (mem.MemAvailable ?? 0);
        swapTotal = mem.SwapTotal ?? 0;
        swapUsed = swapTotal - (mem.SwapFree ?? 0);
        memHistory = push(memHistory, memRatio);

        net.reload();
        let rx = 0, tx = 0;
        for (const line of net.text().split("\n").slice(2)) {
            const parts = line.trim().split(/[:\s]+/);
            if (parts.length < 10 || parts[0] === "lo")
                continue;
            rx += Number(parts[1]);
            tx += Number(parts[9]);
        }
        const now = Date.now();
        if (lastNet) {
            const dt = (now - lastNet.time) / 1000;
            down = Math.max(0, (rx - lastNet.rx) / dt);
            up = Math.max(0, (tx - lastNet.tx) / dt);
        }
        lastNet = {
            rx: rx,
            tx: tx,
            time: now
        };

        uptimeFile.reload();
        uptime = Number(uptimeFile.text().split(" ")[0]);

        if (tempPath !== "") {
            tempFile.reload();
            temp = Number(tempFile.text()) / 1000;
        }
    }

    FileView {
        id: stat

        path: "/proc/stat"
        blockLoading: true
    }

    FileView {
        id: meminfo

        path: "/proc/meminfo"
        blockLoading: true
    }

    FileView {
        id: net

        path: "/proc/net/dev"
        blockLoading: true
    }

    FileView {
        id: uptimeFile

        path: "/proc/uptime"
        blockLoading: true
    }

    FileView {
        id: tempFile

        path: root.tempPath
        blockLoading: true
        printErrors: false
    }

    // the package sensor is the most honest cpu temperature, fall back to the first zone
    Process {
        running: true
        command: ["sh", "-c", "for z in /sys/class/thermal/thermal_zone*; do [ \"$(cat $z/type)\" = x86_pkg_temp ] && echo $z/temp && exit; done; echo /sys/class/thermal/thermal_zone0/temp"]
        stdout: StdioCollector {
            onStreamFinished: root.tempPath = text.trim()
        }
    }

    Process {
        id: disk

        command: ["df", "-B1", "--output=size,used", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("\n").pop().trim().split(/\s+/);
                root.diskTotal = Number(parts[0]);
                root.diskUsed = Number(parts[1]);
            }
        }
    }

    Process {
        id: procs

        command: ["ps", "-eo", "pid,comm,%cpu,%mem", "--sort=-%cpu", "--no-headers"]
        stdout: StdioCollector {
            // apps with many processes show once, with their load added up
            onStreamFinished: {
                const byName = {};
                for (const l of text.trim().split("\n")) {
                    const p = l.trim().split(/\s+/);
                    const e = byName[p[1]] ?? (byName[p[1]] = {
                            pid: Number(p[0]),
                            name: p[1],
                            cpu: 0,
                            mem: 0
                        });
                    e.cpu += Number(p[2]);
                    e.mem += Number(p[3]);
                }
                root.processes = Object.values(byName).sort((a, b) => b.cpu - a.cpu).slice(0, 6);
            }
        }
    }

    Timer {
        running: root.watchers > 0
        repeat: true
        triggeredOnStart: true
        interval: 2000
        onTriggered: {
            root.sample();
            if (root.wantProcesses)
                procs.running = true;
        }
    }

    Timer {
        running: root.watchers > 0
        repeat: true
        triggeredOnStart: true
        interval: 60000
        onTriggered: disk.running = true
    }
}
