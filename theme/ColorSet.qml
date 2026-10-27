import QtQuick

// material color roles, filled from the active palette
QtObject {
    id: root

    // a palette role at its own lightness in the wallpaper's hue, so nothing is plain white or grey
    // sat is the least color it carries, a grey wallpaper leaves the palette as it is
    function wash(role: string, sat: real): color {
        const base = Colors.pick(role);
        if (hueSource.hslSaturation < 0.06)
            return base;
        return Qt.hsla(Math.max(0, hueSource.hslHue), Math.max(base.hslSaturation, sat), base.hslLightness, base.a);
    }

    // the secondary roles are lighter and darker shades of the accent, so they never fall back to grey
    function shade(light: real, dark: real, sat: real): color {
        return Theme.tone(primary, Theme.dark ? dark : light, sat);
    }

    // container surfaces keep their lightness and take a faint hue of the wallpaper
    function hued(role: string): color {
        return wash(role, 0.22);
    }

    readonly property color background: wash("background", 0.22)
    readonly property color error: Colors.pick("error")
    readonly property color errorContainer: Colors.pick("error_container")
    readonly property color inverseOnSurface: wash("inverse_on_surface", 0.25)
    readonly property color inversePrimary: wash("inverse_primary", 0.5)
    readonly property color inverseSurface: wash("inverse_surface", 0.25)
    readonly property color fgBackground: wash("on_background", 0.3)
    readonly property color fgError: Colors.pick("on_error")
    readonly property color fgErrorContainer: Colors.pick("on_error_container")
    readonly property color fgPrimary: wash("on_primary", 0.35)
    readonly property color fgPrimaryContainer: wash("on_primary_container", 0.4)
    readonly property color fgPrimaryFixed: Colors.pick("on_primary_fixed")
    readonly property color fgPrimaryFixedVariant: Colors.pick("on_primary_fixed_variant")
    readonly property color fgSecondary: shade(1.0, 0.15, 0.5)
    readonly property color fgSecondaryContainer: shade(0.15, 0.9, 0.5)
    readonly property color fgSecondaryFixed: Colors.pick("on_secondary_fixed")
    readonly property color fgSecondaryFixedVariant: Colors.pick("on_secondary_fixed_variant")
    readonly property color fgSurface: wash("on_surface", 0.3)
    readonly property color fgSurfaceVariant: wash("on_surface_variant", 0.22)
    readonly property color fgTertiary: Colors.pick("on_tertiary")
    readonly property color fgTertiaryContainer: Colors.pick("on_tertiary_container")
    readonly property color fgTertiaryFixed: Colors.pick("on_tertiary_fixed")
    readonly property color fgTertiaryFixedVariant: Colors.pick("on_tertiary_fixed_variant")
    readonly property color outline: wash("outline", 0.2)
    readonly property color outlineVariant: wash("outline_variant", 0.2)
    readonly property color primary: wash("primary", 0.6)
    readonly property color primaryContainer: wash("primary_container", 0.45)
    readonly property color primaryFixed: Colors.pick("primary_fixed")
    readonly property color primaryFixedDim: Colors.pick("primary_fixed_dim")
    readonly property color scrim: Colors.pick("scrim")
    readonly property color secondary: shade(0.45, 0.72, 0.6)
    readonly property color secondaryContainer: shade(0.85, 0.32, 0.7)
    readonly property color secondaryFixed: Colors.pick("secondary_fixed")
    readonly property color secondaryFixedDim: Colors.pick("secondary_fixed_dim")
    readonly property color shadow: Colors.pick("shadow")
    readonly property color surface: wash("surface", 0.22)
    readonly property color surfaceBright: wash("surface_bright", 0.22)
    readonly property color surfaceContainer: hued("surface_container")
    readonly property color surfaceContainerHigh: hued("surface_container_high")
    readonly property color surfaceContainerHighest: hued("surface_container_highest")
    readonly property color surfaceContainerLow: hued("surface_container_low")
    readonly property color surfaceContainerLowest: hued("surface_container_lowest")
    readonly property color surfaceDim: wash("surface_dim", 0.22)
    readonly property color surfaceTint: wash("surface_tint", 0.6)
    readonly property color surfaceVariant: wash("surface_variant", 0.22)
    readonly property color tertiary: Colors.pick("tertiary")
    readonly property color tertiaryContainer: Colors.pick("tertiary_container")
    readonly property color tertiaryFixed: Colors.pick("tertiary_fixed")
    readonly property color tertiaryFixedDim: Colors.pick("tertiary_fixed_dim")

    // the wallpaper's real color, never the song's, so the island tints even on the monochrome scheme
    readonly property color source: Theme.wallpaper
    // the wallpaper's hue colors everything, a grey wallpaper falls back to the raw palette
    readonly property color hueSource: source.hslSaturation >= 0.06 ? source : Colors.pick("primary")
    // the lightest and darkest shades of the wallpaper, used where white and black would look flat
    readonly property color glint: hueSource.hslSaturation < 0.06 ? Qt.hsla(0, 0, 0.94, 1) : Qt.hsla(Math.max(0, hueSource.hslHue), 0.7, 0.9, 1)
    readonly property color abyss: hueSource.hslSaturation < 0.06 ? Qt.hsla(0, 0, 0.04, 1) : Qt.hsla(Math.max(0, hueSource.hslHue), 0.5, 0.05, 1)
    // a vivid version of the accent for moments to blush the island with
    readonly property color vivid: hueSource.hslSaturation < 0.06 ? Theme.tone(primary, Theme.dark ? 0.4 : 0.7, 0) : Theme.tone(hueSource, Theme.dark ? 0.4 : 0.7, 1.1)
    // ground of the bar, drawers and island, follows the opacity setting
    readonly property color panel: Qt.alpha(surface, Theme.panelOpacity)
    // raised layers that sit on the panel ground
    readonly property color layer1: surfaceContainer
    readonly property color layer2: surfaceContainerHigh
    readonly property color layer3: surfaceContainerHighest
    // text inks from loud to quiet
    readonly property color ink: fgSurface
    readonly property color inkSoft: Theme.mix(fgSurface, fgSurfaceVariant, 0.55)
    readonly property color inkMeta: fgSurfaceVariant
    readonly property color inkFaint: Theme.mix(fgSurfaceVariant, surface, 0.4)
    readonly property color hairline: Qt.alpha(outlineVariant, 0.7)
    readonly property color scrimSoft: Qt.alpha(scrim, 0.4)
    // the light under every key, the wallpaper's hue at full color, a grey wallpaper gives a white light
    readonly property color backlight: hueSource.hslSaturation < 0.06 ? Qt.hsla(0, 0, Theme.dark ? 0.78 : 0.6, 1) : Qt.hsla(Math.max(0, hueSource.hslHue), Math.min(1, Math.max(0.65, hueSource.hslSaturation * 1.3)), Theme.dark ? 0.6 : 0.55, 1)
    // the lit ledge fades from a deep shade of the wallpaper at the top to the light at the bottom
    readonly property color depthLit: backlight
    readonly property color depthShadow: Theme.dark ? Qt.alpha(abyss, 0.9) : Theme.tone(hueSource, 0.28, 0.9)
    // a glossy candy edge on every key
    readonly property color depthRim: Qt.alpha(glint, Theme.dark ? 0.22 : 0.7)
    readonly property color sourceTone: Qt.hsla(Math.max(0, source.hslHue), Math.min(1, source.hslSaturation * 1.35), Theme.dark ? Math.max(0.08, Math.min(0.24, source.hslLightness)) : Math.max(0.8, Math.min(0.92, source.hslLightness)), panel.a)
    // the island and the bar pills, the plain panel with the wallpaper seeping in
    readonly property color island: Theme.mix(panel, sourceTone, Theme.islandTint)
}
