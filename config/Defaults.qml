pragma Singleton

import QtQuick
import Quickshell

// every option and its default value, user config is merged over this
Singleton {
    // allowed values for options that are a fixed set
    readonly property var choices: ({
            "theme.scheme": ["scheme-tonal-spot", "scheme-content", "scheme-expressive", "scheme-fidelity", "scheme-fruit-salad", "scheme-monochrome", "scheme-neutral", "scheme-rainbow", "scheme-vibrant"],
            "wallpaper.transition": ["circle", "wipe", "fade", "zoom"],
            "power.sleepAction": ["suspend", "hibernate", "suspend-then-hibernate", "hybrid-sleep"],
            "theme.accent": ["#7c9cff", "#ff8a80", "#ffb74d", "#81c784", "#4dd0e1", "#ba68c8", "#f06292", "#a1887f"]
        })

    readonly property var values: ({
            mode: "islands",
            // the two ways the shell sits on screen, the bar splits into pills around the island or the island stands alone
            modes: {
                islands: {
                    name: "Islands",
                    icon: "view_agenda",
                    bar: true,
                    modules: ["bar", "island", "background", "workspaces", "tray", "indicators", "media", "notifications", "osd", "launcher", "controlcenter", "power", "lock", "wallpaper", "clipboard", "overview", "screenshot", "cheatsheet", "modeswitcher", "desktop", "monitor", "settings"],
                    slots: {
                        start: ["workspaces"],
                        end: ["tray", "indicators", "power"]
                    }
                },
                island: {
                    name: "Island",
                    icon: "pill",
                    bar: false,
                    modules: ["island", "background", "media", "notifications", "osd", "launcher", "controlcenter", "power", "lock", "wallpaper", "clipboard", "overview", "screenshot", "cheatsheet", "modeswitcher", "desktop", "monitor", "settings"],
                    slots: {
                        start: [],
                        end: []
                    }
                }
            },
            general: {
                terminal: "kitty",
                fileManager: "nautilus",
                webSearch: "https://duckduckgo.com/?q=",
                screenshotDir: "~/Pictures/Screenshots",
                wallpaperDir: "~/Pictures/Wallpapers"
            },
            theme: {
                dark: true,
                fromWallpaper: true,
                accent: "#7c9cff",
                scheme: "scheme-tonal-spot",
                matugenConfig: "",
                roundness: 1.0,
                spacing: 1.0,
                fontFamily: "Google Sans Flex",
                monoFamily: "monospace",
                fontScale: 1.0,
                fontRound: 40,
                animationSpeed: 1.0,
                motionBlur: true,
                panelOpacity: 1.0,
                windowBorders: true,
                appTheming: true,
                screenCorners: true
            },
            bar: {
                size: 40,
                workspaceCount: 10,
                showAppIcons: true
            },
            recording: {
                dir: "~/Videos/Recordings",
                audio: false
            },
            clock: {
                use24h: true,
                showSeconds: false
            },
            wallpaper: {
                path: "",
                transition: "circle",
                duration: 900,
                // live wallpapers also rest while tiled windows cover the workspace, not only under fullscreen
                pauseWithWindows: false
            },
            notifications: {
                // notifications from one app stack in the dashboard
                group: true,
                timeout: 6000,
                historyLimit: 100,
                dnd: false
            },
            osd: {
                timeout: 1500
            },
            launcher: {
                // apps you open at this hour and lately rise to the top
                smartRanking: true,
                // a copied link or sum is offered first on an empty search
                clipboardActions: true,
                maxResults: 8,
                files: true,
                web: true
            },
            island: {
                height: 34,
                // hover the workspace number for previews of your workspaces
                workspacePeek: true,
                // the island grows out of the edge and the pills drop in at start
                intro: true,
                // hover the island during music for a small player, with the sung line in it
                peek: true,
                peekLyrics: true,
                // swipe to skip, pull down for the dashboard, double click to play or pause
                gestures: true,
                // a little squash and stretch as the island changes shape
                squash: true,
                // camera, microphone and screen share dots
                privacyDots: true,
                // browser downloads, their progress across the island
                downloads: true,
                // how much the wallpaper color shows through the island, 0 keeps it plain
                wallpaperTint: 0.35,
                messageTime: 3000
            },
            media: {
                // pause when headphones go away, offer to resume when they come back
                pauseOnDisconnect: true,
                // live level meter through cava instead of the dance, livelier but jumpier
                visualizer: false,
                // recently played tracks in the player
                history: true,
                lyrics: true
            },
            lock: {
                // fingerprint beside the password when fprintd has a finger
                fingerprint: true,
                // a count and app icons of what came in while locked
                showNotifications: true,
                idleMinutes: 0,
                showMedia: true
            },
            // idle sleep, 0 turns it off, the lid itself is handled by logind
            power: {
                // fade the screens over the last half minute before idle sleep
                dimBeforeSleep: true,
                // time left from the average draw of the last ten minutes
                smartTime: true,
                sleepMinutes: 15,
                sleepMinutesPlugged: 30,
                sleepAction: "suspend",
                lockOnSleep: true,
                // switch to battery saver at the low step and back on the charger
                autoSaver: true,
                lowBattery: 20,
                criticalBattery: 10
            },
            // pause the level meter, the camera check and other busy work while something is fullscreen
            performance: {
                // hold minor moments while something is fullscreen, they show after
                quietMoments: true,
                auto: true
            },
            // colored moments in the island, one switch per kind
            moments: {
                battery: true,
                bluetooth: true,
                network: true,
                toggles: true,
                privacy: true,
                downloads: true,
                welcome: true,
                clipboard: true,
                audio: true
            },
            // warmer colors through hyprsunset between the two times
            nightLight: {
                // lower the screen to this percent while night light is on, 0 leaves it alone
                brightness: 0,
                auto: true,
                from: "19:00",
                to: "06:30",
                temperature: 4000
            },
            clipboard: {
                maxItems: 200
            },
            overview: {
                rows: 2,
                columns: 5,
                scale: 0.16
            },
            desktop: {
                fahrenheit: false,
                weatherPlace: "",
                widgets: [
                    {
                        type: "analog",
                        x: 0.73,
                        y: 0.09
                    },
                    {
                        type: "weather",
                        x: 0.86,
                        y: 0.09
                    },
                    {
                        type: "calendar",
                        x: 0.73,
                        y: 0.32
                    }
                ]
            },
            keybinds: [
                {
                    group: "Apps",
                    keys: "SUPER + SUPER_L",
                    action: "launcher toggle",
                    description: "Open the launcher",
                    release: true
                },
                {
                    group: "Apps",
                    keys: "SUPER + T",
                    action: "app terminal",
                    description: "Open the terminal"
                },
                {
                    group: "Apps",
                    keys: "SUPER + E",
                    action: "app files",
                    description: "Open the file manager"
                },
                {
                    group: "Apps",
                    keys: "SUPER + W",
                    action: "app browser",
                    description: "Open the browser"
                },
                {
                    group: "Windows",
                    keys: "SUPER + Q",
                    action: "window close",
                    description: "Close the window"
                },
                {
                    group: "Windows",
                    keys: "SUPER + V",
                    action: "window float",
                    description: "Float or tile the window"
                },
                {
                    group: "Windows",
                    keys: "SUPER + F",
                    action: "window fullscreen",
                    description: "Make the window fullscreen"
                },
                {
                    group: "Windows",
                    keys: "SUPER + D",
                    action: "window maximize",
                    description: "Maximize the window"
                },
                {
                    group: "Windows",
                    keys: "SUPER + J",
                    action: "window split",
                    description: "Flip the split direction"
                },
                {
                    group: "Windows",
                    keys: "SUPER + left",
                    action: "focus left",
                    description: "Focus the window on the left"
                },
                {
                    group: "Windows",
                    keys: "SUPER + right",
                    action: "focus right",
                    description: "Focus the window on the right"
                },
                {
                    group: "Windows",
                    keys: "SUPER + up",
                    action: "focus up",
                    description: "Focus the window above"
                },
                {
                    group: "Windows",
                    keys: "SUPER + down",
                    action: "focus down",
                    description: "Focus the window below"
                },
                {
                    group: "Windows",
                    keys: "SUPER + S",
                    action: "scratchpad toggle",
                    description: "Show the scratchpad"
                },
                {
                    group: "Windows",
                    keys: "SUPER + SHIFT + S",
                    action: "scratchpad send",
                    description: "Send the window to the scratchpad"
                },
                {
                    group: "Shell",
                    keys: "SUPER + A",
                    action: "island toggle",
                    description: "Open the island"
                },
                {
                    group: "Shell",
                    keys: "SUPER + TAB",
                    action: "overview toggle",
                    description: "Open the workspace overview"
                },
                {
                    group: "Shell",
                    keys: "SUPER + SHIFT + V",
                    action: "clipboard toggle",
                    description: "Open clipboard history"
                },
                {
                    group: "Shell",
                    keys: "CTRL + SHIFT + Escape",
                    action: "monitor toggle",
                    description: "Open the system monitor"
                },
                {
                    group: "Shell",
                    keys: "SUPER + period",
                    action: "cheatsheet toggle",
                    description: "Show keybinds"
                },
                {
                    group: "Shell",
                    keys: "SUPER + comma",
                    action: "settings toggle",
                    description: "Open settings"
                },
                {
                    group: "Shell",
                    keys: "SUPER + SHIFT + W",
                    action: "wallpaper toggle",
                    description: "Pick a wallpaper"
                },
                {
                    group: "Shell",
                    keys: "SUPER + SHIFT + M",
                    action: "modeswitcher toggle",
                    description: "Switch the layout"
                },
                {
                    group: "Shell",
                    keys: "SUPER + SHIFT + E",
                    action: "desktop edit",
                    description: "Edit desktop widgets"
                },
                {
                    group: "Session",
                    keys: "SUPER + escape",
                    action: "power toggle",
                    description: "Open the power menu"
                },
                {
                    group: "Session",
                    keys: "SUPER + L",
                    action: "lock lock",
                    description: "Lock the screen"
                },
                {
                    group: "Session",
                    keys: "SUPER + M",
                    action: "session logout",
                    description: "Log out of Hyprland"
                },
                {
                    group: "Capture",
                    keys: "code:642",
                    action: "screenshot region",
                    description: "Capture a region"
                },
                {
                    group: "Capture",
                    keys: "Print",
                    action: "screenshot region",
                    description: "Capture a region"
                },
                {
                    group: "Capture",
                    keys: "SUPER + code:642",
                    action: "screenshot screen",
                    description: "Capture the whole screen"
                },
                {
                    group: "Capture",
                    keys: "SUPER + SHIFT + R",
                    action: "screenshot record",
                    description: "Start or stop a screen recording"
                }
            ]
        })
}
