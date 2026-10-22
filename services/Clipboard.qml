pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// clipboard history through cliphist, the shell runs the watcher itself
Singleton {
    id: root

    property var entries: []
    property bool available: false
    property bool watching: false

    function refresh(): void {
        if (available)
            lister.running = true;
    }

    function copy(entry: var): void {
        Quickshell.execDetached(["sh", "-c", `printf '%s' ${Paths.quote(entry.id + "\t")} | cliphist decode | wl-copy`]);
    }

    function remove(entry: var): void {
        Quickshell.execDetached(["sh", "-c", `printf '%s' ${Paths.quote(entry.raw)} | cliphist delete`]);
        entries = entries.filter(e => e.id !== entry.id);
    }

    function wipe(): void {
        Quickshell.execDetached(["cliphist", "wipe"]);
        entries = [];
    }

    property int imageVersion: 0
    // ids whose image decoded to a real file
    property var decoded: ({})

    function imagePath(entry: var): string {
        return Paths.cache + "/clip/" + entry.id + "." + entry.format;
    }

    // decode image entries that are not cached yet, in one pass
    function decodeImages(): void {
        const todo = entries.filter(e => e.image);
        if (todo.length === 0)
            return;
        const dir = Paths.quote(Paths.cache + "/clip");
        const steps = todo.map(e => `{ [ -s ${Paths.quote(imagePath(e))} ] || printf '%s' ${Paths.quote(e.id + "\t")} | cliphist decode > ${Paths.quote(imagePath(e))}; }; if [ -s ${Paths.quote(imagePath(e))} ]; then echo ${e.id}; else rm -f ${Paths.quote(imagePath(e))}; fi`);
        decoder.command = ["sh", "-c", `mkdir -p ${dir}; ${steps.join("; ")}`];
        decoder.running = true;
    }

    Process {
        id: decoder

        stdout: StdioCollector {
            onStreamFinished: {
                const next = {};
                for (const id of text.split("\n"))
                    if (id !== "")
                        next[id] = true;
                root.decoded = next;
                root.imageVersion++;
            }
        }
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v cliphist && command -v wl-paste"]
        onExited: code => {
            root.available = code === 0;
            root.watching = root.available;
            root.refresh();
        }
    }

    // store text and images as they are copied
    Process {
        running: root.watching
        command: ["wl-paste", "--watch", "sh", "-c", `cliphist -max-items ${Config.options.clipboard.maxItems} store`]
    }

    Process {
        running: root.watching
        command: ["wl-paste", "--type", "image", "--watch", "sh", "-c", `cliphist -max-items ${Config.options.clipboard.maxItems} store`]
    }

    Process {
        id: lister

        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 0)
                        continue;
                    const id = line.slice(0, tab);
                    const preview = line.slice(tab + 1);
                    const img = preview.match(/^\[\[ binary data .* (png|jpe?g|webp|gif|bmp) /i);
                    out.push({
                        id: id,
                        raw: line,
                        text: preview,
                        image: img !== null,
                        format: img ? img[1].toLowerCase() : ""
                    });
                }
                root.entries = out;
                root.decodeImages();
            }
        }
    }
}
