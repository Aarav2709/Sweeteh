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

    Process {
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
