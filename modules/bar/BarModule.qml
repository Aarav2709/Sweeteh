import QtQuick
import Quickshell

// one bar per screen
Scope {
    Variants {
        model: Quickshell.screens

        BarWindow {}

    }
}
