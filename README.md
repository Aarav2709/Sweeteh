# Sweeteh

A desktop shell for Hyprland, built with Quickshell.

Everything lives in one island at the top of the screen. It morphs into the launcher, quick settings, media controls, notifications, the clipboard, a system monitor and password prompts, then shrinks back to the time. Colors come from your wallpaper and carry over to window borders, kitty and GTK apps like Nautilus.

## Install

On Arch or any Arch based distro:

```sh
curl -fsSL https://raw.githubusercontent.com/Aarav2709/Sweeteh/main/install.sh | bash
```

You do not need Hyprland first. The installer:

- installs Hyprland, Quickshell and everything else Sweeteh needs with pacman, after asking
- turns on NetworkManager, Bluetooth and power profiles
- installs the newest release in `~/.local/share/sweeteh` and adds a `sweeteh` command to `~/.local/bin`
- sets up Hyprland, kitty, fish and the starship prompt with the Sweeteh configs
- starts Hyprland when you log into tty1 if you have no login screen, otherwise pick Hyprland on your login screen
- adds a few wallpapers to `~/Pictures/Wallpapers` if it is empty

Every file it replaces is moved to `~/.local/state/sweeteh/backups/` first, and uninstalling puts them back.

| Option | What it does |
| --- | --- |
| `--keep-configs` | Keep your own Hyprland, kitty, fish and starship configs. Add `hl.on("hyprland.start", function() hl.exec_cmd("sweeteh run") end)` to your `hyprland.lua` so the shell starts on login |
| `--no-deps` | Skip installing packages |
| `--dry-run` | Show what would change without changing anything |
| `--uninstall` | Remove Sweeteh and put your previous configs back |
| `--purge` | With `--uninstall`, also delete Sweeteh settings, backups and cache |
| `-y` | Do not ask before installing packages |

Pass options through curl like this: `curl -fsSL ... | bash -s -- --keep-configs`.

To install from a clone instead, run `./install.sh` inside it. The shell then runs straight from that folder, so your edits show up live.

On other distros, install these yourself and then run the installer with `--no-deps`:

`hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk qt5-wayland qt6-wayland polkit quickshell matugen qt6-multimedia ffmpeg pipewire wireplumber playerctl brightnessctl upower power-profiles-daemon networkmanager bluez cliphist wl-clipboard wf-recorder libnotify curl git kitty nautilus fish starship eza` and a Nerd Font such as JetBrains Mono Nerd Font.

## Use

| Keys | Does |
| --- | --- |
| Super | Launcher for apps, files, actions, sums and web search |
| Super A | The island with quick settings, calendar, media and notifications |
| Super Period | Every keybind |
| Super T, E, W | Terminal, files, browser |
| Super Q | Close the window |
| Super V, F, D | Float, fullscreen, maximize |
| Super Arrows | Move focus |
| Super 1 to 0 | Go to a workspace, add Shift to move the window there |
| Super Tab | Workspace overview, arrows pick and Enter goes |
| Super Shift V | Clipboard history |
| Ctrl Shift Esc | System monitor |
| Super Comma | Settings |
| Super Escape | Power menu |
| Super L | Lock the screen |
| Super Shift W | Wallpapers |
| Super Shift M | Switch between the Islands and Island layouts |
| Print | Screenshot of a region, a window or the screen |
| Super Shift R | Start or stop a screen recording |
| Super Shift E | Arrange desktop widgets |

Change any of them in Settings, Keybinds. They are saved to `~/.config/hypr/sweeteh/binds.lua`, which the Sweeteh `hyprland.lua` loads, so they keep working even if the shell is not running.

Everything works from the keyboard. Tab moves between controls, Enter or Space presses them and Escape closes whatever is open.

The `sweeteh` command:

```sh
sweeteh run        # start the shell
sweeteh stop       # stop it
sweeteh restart    # stop and start again
sweeteh check      # print the newest release if there is one
sweeteh update     # move to the newest release and restart
sweeteh ipc launcher toggle   # call anything in the shell
```

## Updates

Sweeteh follows tagged releases. It checks for a new one a minute after login and every six hours after, says so in the island, and Settings, About has an Update button. `sweeteh update` does the same from a terminal.

## Features

- **Two layouts.** Islands splits the bar into raised pills around the island. Island shows only the island.
- **The island.** Launcher, quick settings with Wifi and Bluetooth pages, media with synced lyrics, notifications, volume and brightness, clipboard, system monitor, a polkit password prompt and a recording indicator, all in one surface.
- **Wallpapers.** Images, GIFs and videos, with circle, wipe, fade and zoom transitions. Video wallpapers pause under fullscreen windows.
- **A themed terminal.** Kitty runs fish with a starship prompt, both colored from the wallpaper.
- **Tray menus** drawn by the shell instead of plain app menus.
- **Colors from the wallpaper.** Matugen builds the palette. The shell, window borders, kitty, Nautilus and other GTK apps, folder icons, Vesktop and Zed all follow it. Pick the Sweeteh theme in Zed to use it.
- **Desktop widgets.** Analog clock, weather, calendar, media and system load, arranged with Super Shift E.
- **Lockscreen** with a blurred wallpaper, clock and media controls.
- **Password prompts** from apps that need admin rights appear in the island.
- **Screenshots and recordings** of a region, a window or the whole screen.
- **Settings** for every option, including a keybind editor. Everything is also in `~/.config/sweeteh/config.json`, which reloads as you save it.

## Credits

Sweeteh was designed by studying these shells. Their ideas were recreated from scratch and reworked to fit Sweeteh's island design. The one exception is end-4's terminal color scheme, kitty, fish and starship settings, which Sweeteh reuses under the same GPL 3.0 license.

- [end-4's dots-hyprland, illogical impulse](https://github.com/end-4/dots-hyprland) for the settings app layout, wallpaper based Material theming, the one line installer, and the kitty, fish and starship setup with its terminal palette, which Sweeteh reuses
- [end4-pC](https://github.com/pctrade/end4-pC) for desktop widgets and how far customization can go
- [Ambxst](https://github.com/Axenide/Ambxst) for the dynamic island and its dashboard, and the idea of theming Vesktop through DevilBro's DiscordRecolor
- [Caelestia](https://github.com/caelestia-dots/shell) for panel motion, the wavy media progress bar and workspace indicators
- [SekaiPop](https://github.com/Blapples/SekaiPop) for the raised 2.5D look
- [impasto](https://github.com/andreumassanet/impasto) for the top bar, desk widgets and its notch
- [Tacit](https://github.com/ciscobugger/tacit) for the quiet type scale, inks and overall feel

Sweeteh also bundles [Google Sans Flex](https://fonts.google.com/specimen/Google+Sans+Flex) under the SIL Open Font License and [Material Symbols](https://github.com/google/material-design-icons) under the Apache 2.0 license. Lyrics come from [LRCLIB](https://lrclib.net) and weather from [wttr.in](https://wttr.in).

## License

GPL 3.0, see [LICENSE](LICENSE).
