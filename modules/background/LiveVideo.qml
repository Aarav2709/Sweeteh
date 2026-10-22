import QtQuick
import QtMultimedia

// looping muted video, kept in its own file so a missing multimedia module only disables video wallpapers
Video {
    property bool paused: false

    loops: MediaPlayer.Infinite
    muted: true
    autoPlay: true
    fillMode: VideoOutput.PreserveAspectCrop
    onPausedChanged: paused ? pause() : play()
}
