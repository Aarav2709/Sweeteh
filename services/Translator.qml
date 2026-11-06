pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// >tr text, or >tr text in spanish, through translate-shell in the background
Singleton {
    id: root

    property bool installed: false
    property string asked: ""
    property string answer: ""
    property string answerFor: ""
    property bool loading: false

    // a trailing "in <language>" or "to <language>" picks the target, english otherwise
    function ask(input: string): void {
        const q = input.trim();
        // the launcher rebuilds when the answer lands, asking the same again must not start another run
        if (q === asked)
            return;
        if (!installed || q === "") {
            asked = "";
            return;
        }
        asked = q;
        wait.restart();
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v trans"]
        onExited: code => root.installed = code === 0
    }

    Timer {
        id: wait

        interval: 400
        onTriggered: {
            const m = root.asked.match(/^(.*\S)\s+(?:in|to|into)\s+([a-zA-Z-]+)$/);
            const text = m ? m[1] : root.asked;
            const lang = m ? m[2].toLowerCase() : "en";
            run.forQuery = root.asked;
            run.command = ["trans", "-b", "-no-ansi", ":" + lang, text];
            root.loading = true;
            run.running = true;
        }
    }

    Process {
        id: run

        property string forQuery

        stdout: StdioCollector {
            onStreamFinished: {
                root.answerFor = run.forQuery;
                root.answer = text.trim();
                root.loading = false;
            }
        }
    }
}
