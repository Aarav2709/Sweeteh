pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.theme
import "ColorMath.js" as ColorMath

// repaints kitty and gtk apps such as nautilus from the shell palette whenever it changes
Singleton {
    id: root

    readonly property bool enabled: Config.options.theme.appTheming
    readonly property var c: Theme.color
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || Paths.home + "/.config"
    readonly property string signature: [c.surface, c.primary, c.tertiary, c.fgSurface, Theme.dark].join()

    function hex(col: color): string {
        const h = v => Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16).padStart(2, "0");
        return "#" + h(col.r) + h(col.g) + h(col.b);
    }

    // end 4 terminal palette, its base colors harmonized toward the accent with the foreground pushed away from the background
    readonly property var termBase: ({
            dark: ["#282828", "#CC241D", "#98971A", "#D79921", "#458588", "#B16286", "#689D6A", "#A89984", "#928374", "#FB4934", "#B8BB26", "#FABD2F", "#83A598", "#D3869B", "#8EC07C", "#EBDBB2"],
            light: ["#FDF9F3", "#FF6188", "#A9DC76", "#FC9867", "#FFD866", "#F47FD4", "#78DCE8", "#333034", "#121212", "#FF6188", "#A9DC76", "#FC9867", "#FFD866", "#F47FD4", "#78DCE8", "#333034"]
        })

    function terminal(): var {
        const base = termBase[Theme.dark ? "dark" : "light"];
        // the monochrome scheme keeps the plain base colors
        if (Config.options.theme.scheme === "scheme-monochrome")
            return base;
        const source = hex(c.primary);
        return base.map((col, i) => {
            if (i === 0)
                return ColorMath.boost(hex(c.surfaceContainerLow), 1.2, 0.95);
            if (i === 15)
                return ColorMath.boost(hex(c.fgSurface), 3, 1);
            return ColorMath.boost(ColorMath.harmonize(col, source, 100, 0.8), 1, 1 + 0.35 * (Theme.dark ? 1 : -1));
        });
    }

    function kitty(): string {
        const t = terminal();
        const lines = ["# written by sweeteh, changes when the wallpaper does", "background " + t[0]];
        t.forEach((col, i) => lines.push("color" + i + " " + col));
        lines.push("cursor " + t[7], "foreground " + t[7], "selection_background " + hex(c.fgSecondaryContainer), "selection_foreground " + hex(c.secondaryContainer));
        // prompts such as starship read these high slots for the palette roles
        const roles = [[255, c.primary], [254, c.primaryContainer], [253, c.secondary], [252, c.secondaryContainer], [251, c.tertiary], [250, c.tertiaryContainer], [249, c.error], [248, c.errorContainer], [232, c.fgPrimary], [233, c.fgPrimaryContainer], [234, c.fgSecondary], [235, c.fgSecondaryContainer], [236, c.fgTertiary], [237, c.fgTertiaryContainer], [238, c.fgError], [239, c.fgErrorContainer], [240, c.fgPrimary], [243, c.primary], [244, c.error], [245, c.outlineVariant]];
        for (const r of roles)
            lines.push("color" + r[0] + " " + hex(r[1]));
        return lines.join("\n") + "\n";
    }

    // libadwaita and gtk3 both read these named colors
    function gtk(): string {
        const pairs = [
            ["accent_color", c.primary], ["accent_bg_color", c.primary], ["accent_fg_color", c.fgPrimary],
            ["window_bg_color", c.surface], ["window_fg_color", c.fgSurface],
            ["view_bg_color", c.surfaceContainerLow], ["view_fg_color", c.fgSurface],
            ["headerbar_bg_color", c.surfaceContainer], ["headerbar_fg_color", c.fgSurface],
            ["headerbar_backdrop_color", c.surface], ["headerbar_shade_color", c.shadow],
            ["sidebar_bg_color", c.surfaceContainer], ["sidebar_fg_color", c.fgSurface],
            ["sidebar_backdrop_color", c.surfaceContainerLow], ["secondary_sidebar_bg_color", c.surfaceContainerLow],
            ["card_bg_color", c.surfaceContainerHigh], ["card_fg_color", c.fgSurface],
            ["dialog_bg_color", c.surfaceContainerHigh], ["dialog_fg_color", c.fgSurface],
            ["popover_bg_color", c.surfaceContainerHigh], ["popover_fg_color", c.fgSurface],
            ["thumbnail_bg_color", c.surfaceContainerHigh], ["thumbnail_fg_color", c.fgSurface],
            ["destructive_color", c.error], ["destructive_bg_color", c.error], ["destructive_fg_color", c.fgError],
            ["theme_bg_color", c.surface], ["theme_fg_color", c.fgSurface], ["theme_base_color", c.surfaceContainerLow],
            ["theme_text_color", c.fgSurface], ["theme_selected_bg_color", c.primary], ["theme_selected_fg_color", c.fgPrimary]
        ];
        return "/* written by sweeteh, changes when the wallpaper does */\n" + pairs.map(p => `@define-color ${p[0]} ${hex(p[1])};`).join("\n") + "\n";
    }

    // osc escape codes that recolor any terminal, fish prints them when it starts
    function sequences(): string {
        const t = terminal();
        const osc = (code, value) => "\u001b]" + code + ";" + value + "\u001b\\";
        const out = t.map((col, i) => osc("4;" + i, col));
        out.push(osc(10, t[7]), osc(11, t[0]), osc(12, t[7]), osc(17, t[7]), osc(19, t[0]));
        return out.join("");
    }

    // folder icon blues swapped for the wallpaper's hue at matching tones, even on the monochrome scheme
    // only a grey wallpaper gives grey folders
    function folderColors(): var {
        const p = ColorMath.toLch(hex(c.hueSource));
        const chroma = c.hueSource.hslSaturation < 0.06 ? 0 : Math.max(20, Math.min(55, p.c));
        const at = tone => ColorMath.fromLch(tone, chroma, p.h);
        return [["#62a0ea", at(64)], ["#438de6", at(57)], ["#a4caee", at(80)], ["#afd4ff", at(84)], ["#c0d5ea", at(85)]];
    }

    // vesktop runs on devilbro's discord recolor theme, which takes its colors as rgb triplets
    function vesktop(): string {
        const rgb = col => [col.r, col.g, col.b].map(v => Math.round(v * 255)).join(", ");
        const v = [
            ["--accentcolor", c.primary], ["--accentcolor2", c.tertiary], ["--linkcolor", c.primary], ["--mentioncolor", c.tertiary],
            ["--textbrightest", c.fgSurface], ["--textbrighter", c.fgSurface], ["--textbright", c.fgSurfaceVariant],
            ["--textdark", c.outline], ["--textdarker", c.outline], ["--textdarkest", c.outlineVariant],
            ["--backgroundcode", c.surfaceContainerLowest], ["--backgroundaccent", c.surfaceContainerHigh], ["--backgroundprimary", c.surface],
            ["--backgroundsecondary", c.surfaceContainerLow], ["--backgroundsecondaryalt", c.surfaceContainer],
            ["--backgroundtertiary", c.surfaceContainerLowest], ["--backgroundfloating", c.surfaceContainerHigh]
        ];
        return "/**\n * @name Sweeteh\n * @description Follows the sweeteh wallpaper colors.\n * @author sweeteh\n */\n@import url('https://mwittrien.github.io/BetterDiscordAddons/Themes/DiscordRecolor/DiscordRecolor.css');\n\n:root {\n    --settingsicons: 1;\n    --font: \"" + Theme.font.family + "\", \"gg sans\", \"Noto Sans\";\n" + v.map(x => `    ${x[0]}: ${rgb(x[1])};`).join("\n") + "\n}\n";
    }

    // a zed theme that tracks the palette, pick sweeteh in zed to use it
    function zed(): string {
        const t = terminal();
        const style = {
            "background": hex(c.surface), "surface.background": hex(c.surfaceContainerLow), "elevated_surface.background": hex(c.surfaceContainerHigh),
            "panel.background": hex(c.surfaceContainerLow), "editor.background": hex(c.surface), "editor.gutter.background": hex(c.surface),
            "editor.active_line.background": hex(c.surfaceContainerLow), "editor.line_number": hex(c.outline), "editor.active_line_number": hex(c.primary),
            "editor.foreground": hex(c.fgSurface), "text": hex(c.fgSurface), "text.muted": hex(c.fgSurfaceVariant), "text.placeholder": hex(c.outline), "text.accent": hex(c.primary),
            "border": hex(c.outlineVariant), "border.variant": hex(c.surfaceContainerHigh), "border.focused": hex(c.primary), "border.selected": hex(c.primary),
            "element.background": hex(c.surfaceContainerHigh), "element.hover": hex(c.surfaceContainerHighest), "element.selected": hex(c.secondaryContainer),
            "ghost_element.hover": hex(c.surfaceContainer), "ghost_element.selected": hex(c.secondaryContainer),
            "tab_bar.background": hex(c.surfaceContainerLow), "tab.active_background": hex(c.surface), "tab.inactive_background": hex(c.surfaceContainerLow),
            "title_bar.background": hex(c.surfaceContainerLow), "status_bar.background": hex(c.surfaceContainerLow), "toolbar.background": hex(c.surface),
            "scrollbar.thumb.background": hex(c.surfaceContainerHighest) + "99", "icon": hex(c.fgSurfaceVariant), "icon.accent": hex(c.primary),
            "terminal.background": t[0], "terminal.foreground": t[7], "accents": [hex(c.primary), hex(c.tertiary), hex(c.secondary)],
            "players": [{ "cursor": hex(c.primary), "selection": hex(c.primaryContainer) + "80", "background": hex(c.primary) }],
            "syntax": {
                "keyword": { "color": hex(c.primary) }, "function": { "color": hex(c.tertiary) }, "string": { "color": t[10] }, "comment": { "color": hex(c.outline), "font_style": "italic" },
                "type": { "color": hex(c.secondary) }, "number": { "color": t[11] }, "constant": { "color": t[11] }, "property": { "color": t[12] }, "variable": { "color": hex(c.fgSurface) },
                "operator": { "color": hex(c.fgSurfaceVariant) }, "punctuation": { "color": hex(c.fgSurfaceVariant) }, "tag": { "color": hex(c.primary) }, "attribute": { "color": t[13] }
            }
        };
        ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"].forEach((n, i) => {
            style["terminal.ansi." + n] = t[i];
            style["terminal.ansi.bright_" + n] = t[i + 8];
        });
        return JSON.stringify({
            "$schema": "https://zed.dev/schema/themes/v0.2.0.json",
            "name": "Sweeteh",
            "author": "sweeteh",
            "themes": [{ "name": "Sweeteh", "appearance": Theme.dark ? "dark" : "light", "style": style }]
        }, null, 2) + "\n";
    }

    function apply(): void {
        if (!enabled || c.surface.a === 0)
            return;
        kittyFile.setText(kitty());
        gtk4File.setText(gtk());
        gtk3File.setText(gtk());
        vesktopFile.setText(vesktop());
        sequencesFile.setText(sequences());
        zedFile.setText(zed());
        const recolor = folderColors().map(p => `-e 's/${p[0]}/${p[1]}/gI'`).join(" ");
        // hook our files into the app configs once, then nudge running apps to reload
        writer.command = ["sh", "-c", `
cfg=${Paths.quote(configHome)}
icons=${Paths.quote(dataHome + "/icons/Sweeteh")}
src=/usr/share/icons/Adwaita/scalable/places
if [ -d "$src" ]; then
  mkdir -p "$icons/scalable/places"
  printf '[Icon Theme]\nName=Sweeteh\nComment=Adwaita with folders in the wallpaper colors\nInherits=Adwaita,hicolor\nDirectories=scalable/places\n\n[scalable/places]\nSize=128\nMinSize=8\nMaxSize=512\nType=Scalable\nContext=Places\n' > "$icons/index.theme"
  for f in "$src"/folder*.svg "$src"/user-*.svg "$src"/network-*.svg; do sed ${recolor} "$f" > "$icons/scalable/places/$(basename "$f")"; done
  touch "$icons"
  command -v gsettings >/dev/null && gsettings set org.gnome.desktop.interface icon-theme Sweeteh
fi
ves="$cfg/vesktop/settings/settings.json"
if [ -f "$ves" ] && ! grep -q 'sweeteh.css' "$ves"; then
  if grep -q '"enabledThemes": *\\[ *\\]' "$ves"; then
    sed -i 's/"enabledThemes": *\\[ *\\]/"enabledThemes": ["sweeteh.css"]/' "$ves"
  else
    sed -i 's/"enabledThemes": *\\[/"enabledThemes": ["sweeteh.css",/' "$ves"
  fi
fi
hook() { [ -f "$1" ] && grep -qF "$2" "$1" || { mkdir -p "$(dirname "$1")"; printf '\\n%s\\n' "$2" >> "$1"; }; }
hook "$cfg/kitty/kitty.conf" "include sweeteh.conf"
hook "$cfg/gtk-4.0/gtk.css" "@import url('sweeteh.css');"
hook "$cfg/gtk-3.0/gtk.css" "@import url('sweeteh.css');"
pkill -USR1 -x kitty
command -v gsettings >/dev/null && gsettings set org.gnome.desktop.interface color-scheme ${Theme.dark ? "prefer-dark" : "prefer-light"}
true`];
        writer.running = true;
    }

    onSignatureChanged: debounce.restart()
    onEnabledChanged: debounce.restart()

    Timer {
        id: debounce

        interval: 600
        onTriggered: root.apply()
    }

    readonly property string dataHome: Quickshell.env("XDG_DATA_HOME") || Paths.home + "/.local/share"

    FileView {
        id: sequencesFile

        path: Paths.state + "/terminal-sequences.txt"
        printErrors: false
    }

    FileView {
        id: vesktopFile

        path: root.configHome + "/vesktop/themes/sweeteh.css"
        printErrors: false
    }

    FileView {
        id: zedFile

        path: root.configHome + "/zed/themes/sweeteh.json"
        printErrors: false
    }

    FileView {
        id: kittyFile

        path: root.configHome + "/kitty/sweeteh.conf"
        printErrors: false
    }

    FileView {
        id: gtk4File

        path: root.configHome + "/gtk-4.0/sweeteh.css"
        printErrors: false
    }

    FileView {
        id: gtk3File

        path: root.configHome + "/gtk-3.0/sweeteh.css"
        printErrors: false
    }

    Process {
        id: writer
    }
}
