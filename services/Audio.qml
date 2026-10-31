pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// default sink and source from pipewire
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool ready: sink?.ready ?? false
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? false
    readonly property string icon: muted || volume <= 0 ? "volume_off" : volume < 0.34 ? "volume_mute" : volume < 0.67 ? "volume_down" : "volume_up"
    readonly property string micIcon: micMuted ? "mic_off" : "mic"
    readonly property list<PwNode> sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property list<PwNode> sources: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio && !(n.name ?? "").endsWith(".monitor"))
    // apps playing sound right now, the shell's own meter is left out
    readonly property list<PwNode> streams: Pipewire.nodes.values.filter(n => n.isStream && n.isSink === false && n.audio && !["cava", "Quickshell", "quickshell"].includes(n.properties?.["application.name"] ?? ""))

    // emitted when volume or mute changes, used by the osd
    signal changed

    function setVolume(v: real): void {
        if (sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1.5, v));
        }
    }

    function setMicVolume(v: real): void {
        if (source?.audio)
            source.audio.volume = Math.max(0, Math.min(1.5, v));
    }

    function toggleMute(): void {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function toggleMic(): void {
        if (source?.audio)
            source.audio.muted = !source.audio.muted;
    }

    function setDefault(node: PwNode): void {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultSource(node: PwNode): void {
        Pipewire.preferredDefaultAudioSource = node;
    }

    // a readable name for a device or an app stream
    function label(node: PwNode): string {
        if (!node)
            return "";
        const p = node.properties ?? {};
        return node.isStream ? (p["application.name"] || node.description || node.name) : (node.nickname || node.description || node.name);
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    // device and app volumes are only live while a page shows them
    property bool watching: false

    PwObjectTracker {
        objects: root.watching ? root.sinks.concat(root.sources, root.streams) : []
    }

    Connections {
        target: root.sink?.audio ?? null

        function onVolumeChanged(): void {
            root.changed();
        }

        function onMutedChanged(): void {
            root.changed();
        }
    }
}
