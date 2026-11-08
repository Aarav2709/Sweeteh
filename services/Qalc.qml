pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// unit, currency and anything else the built in sums cannot do, asked of qalc in the background when it is installed
Singleton {
    id: root

    property bool installed: false
    property string asked: ""
    property string answer: ""
    property string answerFor: ""

    // 10 km to mi or 20 usd in eur, worth offering qalc for when it is missing
    function looksLikeConversion(q: string): bool {
        return /\d\s*[a-z$€£¥]+\s+(to|in|into)\s+[a-z$€£¥]+$/i.test(q.trim());
    }

    // only questions that look like conversions or functions go out, plain sums stay in the shell
    function ask(query: string): void {
        const q = query.trim();
        if (!installed || q.length < 3 || !/\d/.test(q) && !/\b(to|in)\b/.test(q) || !/[a-z]/i.test(q)) {
            asked = "";
            return;
        }
        asked = q;
        wait.restart();
    }

    // looked for again after the shell installs a package
    Connections {
        target: Packages

        function onInstalled(): void {
            probe.running = true;
        }
    }

    Process {
        id: probe

        running: true
        command: ["sh", "-c", "command -v qalc"]
        onExited: code => root.installed = code === 0
    }

    Timer {
        id: wait

        interval: 180
        onTriggered: {
            if (root.asked === "")
                return;
            run.forQuery = root.asked;
            run.command = ["qalc", "-t", "-e", root.asked];
            run.running = true;
        }
    }

    Process {
        id: run

        property string forQuery

        stdout: StdioCollector {
            onStreamFinished: {
                const out = text.trim().split("\n").pop() ?? "";
                // qalc echoes what it could not read, that is not an answer
                const useful = out !== "" && out !== run.forQuery && !/error|warning/i.test(out);
                root.answerFor = run.forQuery;
                root.answer = useful ? out : "";
            }
        }
    }
}
