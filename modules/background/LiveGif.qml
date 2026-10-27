import QtQuick

// an animated gif wallpaper, its own file so the live layer loads by source alone
AnimatedImage {
    property bool resting: false
    readonly property bool ready: status === Image.Ready

    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
    playing: !resting
}
