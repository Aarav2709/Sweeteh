import QtQuick
import QtMultimedia

// looping muted video, kept in its own file so a missing multimedia module only disables video wallpapers
Video {
    property bool paused: false

    loops: MediaPlayer.Infinite
    muted: true
    fillMode: VideoOutput.PreserveAspectCrop
    // the source arrives after creation, where autoplay no longer kicks in on qt 6.12, so start it by hand
    onSourceChanged: {
        if (source != "" && !paused)
            play();
    }
    onPausedChanged: paused ? pause() : play()
    // a failed open says why in the shell log instead of leaving a still wallpaper with no clue
    onErrorOccurred: (error, text) => console.warn("live wallpaper:", text, source)
}
