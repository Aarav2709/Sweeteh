# Sweeteh

A desktop shell for Hyprland, built with Quickshell.

https://github.com/user-attachments/assets/47775564-aa10-4187-a838-3ff012cb136e

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
- **The island.** Launcher, quick settings with Wifi and Bluetooth pages, media with synced lyrics, notifications, volume and brightness, clipboard, system monitor, wallpaper picker, workspace overview, keybind cheat sheet, power menu, settings, a polkit password prompt and a recording indicator, all in one surface. It flares as you type, breathes with the bass of your music and glows for moments like charging, downloads and copies.
- **Backlit look.** Pills, keys and cards sit on a ledge lit from below in the wallpaper's hue, and springs carry every move.
- **Command palette.** Type `>` in the launcher for every shell action, then things like `>wifi`, `>date -3d`, `>time +4h`, `>timer 5m`, `>vol 40`, `>ws 3`, `>close firefox`, `>#ff8800` or `>uuid`. Enter runs or copies, Ctrl and a number picks a row, Tab completes a word, and what you use most comes first.
- **A welcome tour** on first start, and again any time with `>welcome`.
- **Wallpapers.** Images, GIFs and videos, with circle, wipe, fade and zoom transitions. Video wallpapers pause under fullscreen windows, and can also pause behind tiled ones.
- **A themed terminal.** Kitty runs fish with a starship prompt, both colored from the wallpaper.
- **Tray menus** drawn by the shell instead of plain app menus.
- **Colors from the wallpaper.** Matugen builds the palette. The shell, window borders, kitty, Nautilus and other GTK apps, folder icons, Vesktop and Zed all follow it. Pick the Sweeteh theme in Zed to use it.
- **Desktop widgets.** Analog clock, weather, calendar, media and system load, arranged with Super Shift E.
- **Lockscreen** with a blurred wallpaper, clock and media controls.
- **Password prompts** from apps that need admin rights appear in the island.
- **Screenshots and recordings** of a region, a window or the whole screen, driven by mouse or arrows, Tab and Enter. Recordings encode on the GPU when it can and can carry the system sound.
- **Settings** for every option, in the island, including a keybind editor and previews of every island moment. Everything is also in `~/.config/sweeteh/config.json`, which reloads as you save it.

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

> I credit my friends, [@Antinity](https://github.com/Antinity) and [@Saturn](https://github.com/SleeperOfSaturn) too, who gave me valuable feedback upon asking and shaped a major portion on how this shell IS.

## License

GPL 3.0, see [LICENSE](LICENSE).
