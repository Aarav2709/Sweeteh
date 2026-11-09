pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// files opened lately and the hosts in the ssh config, read when the launcher asks for them
Singleton {
    id: root

    property list<string> files: []
    property list<string> hosts: []

    function refreshFiles(): void {
        fileLister.running = true;
    }

    function refreshHosts(): void {
        hostLister.running = true;
    }

    function connect(host: string): void {
        Quickshell.execDetached([Config.options.general.terminal, "-e", "ssh", host]);
    }

    // gtk keeps what every app opened in one list, the newest are taken and the ones since deleted dropped
    Process {
        id: fileLister

        command: ["sh", "-c", `f="\${XDG_DATA_HOME:-$HOME/.local/share}/recently-used.xbel"; [ -r "$f" ] || exit 0
grep -o '<bookmark href="file://[^"]*" added="[^"]*" modified="[^"]*"' "$f" | sed -E 's/.*href="file:\\/\\/([^"]*)".*modified="([^"]*)"/\\2\\t\\1/' | sort -r | head -n 60 | cut -f2`]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    if (line === "")
                        continue;
                    try {
                        out.push(decodeURIComponent(line.replace(/&amp;/g, "&").replace(/&apos;/g, "'").replace(/&quot;/g, "\"").replace(/&lt;/g, "<").replace(/&gt;/g, ">")));
                    } catch (e) {}
                }
                checker.paths = out;
                checker.command = ["sh", "-c", 'for p in "$@"; do [ -e "$p" ] && printf "%s\\n" "$p"; done; true', "sh"].concat(out);
                checker.running = true;
            }
        }
    }

    Process {
        id: checker

        property list<string> paths

        stdout: StdioCollector {
            onStreamFinished: root.files = text.split("\n").filter(l => l !== "").slice(0, 30)
        }
    }

    // named hosts only, patterns with a star or a question mark are rules and not places to go
    Process {
        id: hostLister

        command: ["sh", "-c", `[ -r "$HOME/.ssh/config" ] || exit 0
awk 'tolower($1) == "host" { for (i = 2; i <= NF; i++) if ($i !~ /[*?!]/) print $i }' "$HOME/.ssh/config" | sort -u`]
        stdout: StdioCollector {
            onStreamFinished: root.hosts = text.split("\n").filter(l => l !== "")
        }
    }
}
