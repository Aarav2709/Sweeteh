import QtQuick

// an animated gif wallpaper, its own file so the live layer loads by source alone
AnimatedImage {
    property bool paused: false

    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
    playing: !paused
}
