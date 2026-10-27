import QtQuick
import QtMultimedia

// looping muted video, kept in its own file so a missing multimedia module only disables video wallpapers
Video {
    // resting rather than paused, qt 6.12's video already has a paused member and the clash threw on every load
    property bool resting: false
    // the output is black until the first frame decodes, so the layer stays hidden until then
    readonly property bool ready: position > 0 || mediaStatus === MediaPlayer.BufferedMedia

    loops: MediaPlayer.Infinite
    muted: true
    fillMode: VideoOutput.PreserveAspectCrop
    // the source arrives after creation, where autoplay no longer kicks in on qt 6.12, so start it by hand
    onSourceChanged: {
        if (source != "" && !resting)
            play();
    }
    onRestingChanged: resting ? pause() : play()
    // a failed open says why in the shell log instead of leaving a still wallpaper with no clue
    onErrorOccurred: (error, text) => console.warn("live wallpaper:", text, source)
}
