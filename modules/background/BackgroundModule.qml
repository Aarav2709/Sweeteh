import QtQuick
import Quickshell

// wallpaper and rounded corners on every screen
Scope {
    Variants {
        model: Quickshell.screens

        Wallpaper {}
    }

    Variants {
        model: Quickshell.screens

        ScreenCorners {}
    }
}
