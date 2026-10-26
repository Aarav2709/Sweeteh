import QtQuick

// material color roles, filled from the active palette
QtObject {
    id: root

    // the desktop widgets keep to the wallpaper, everything else follows the song
    property bool follow: true

    // a palette role, blended toward the song tone at the lightness the role has in this theme
    function song(role: string, light: real, dark: real, sat: real): color {
        const base = Colors.pick(role);
        return !follow || Theme.songMix <= 0 ? base : Theme.mix(base, Theme.tone(Theme.song, Theme.dark ? dark : light, sat), Theme.songMix);
    }

    // the secondary roles are lighter and darker shades of the accent, so they never fall back to grey
    function shade(light: real, dark: real, sat: real): color {
        return Theme.tone(primary, Theme.dark ? dark : light, sat);
    }

    // container surfaces keep their lightness and take a faint hue of the accent
    function hued(role: string): color {
        const base = Colors.pick(role);
        return Qt.hsla(Math.max(0, primary.hslHue), Math.max(base.hslSaturation, primary.hslSaturation * 0.3), base.hslLightness, base.a);
    }

    readonly property color background: Colors.pick("background")
    readonly property color error: Colors.pick("error")
    readonly property color errorContainer: Colors.pick("error_container")
    readonly property color inverseOnSurface: Colors.pick("inverse_on_surface")
    readonly property color inversePrimary: Colors.pick("inverse_primary")
    readonly property color inverseSurface: Colors.pick("inverse_surface")
    readonly property color fgBackground: Colors.pick("on_background")
    readonly property color fgError: Colors.pick("on_error")
    readonly property color fgErrorContainer: Colors.pick("on_error_container")
    readonly property color fgPrimary: song("on_primary", 1.0, 0.18, 0.6)
    readonly property color fgPrimaryContainer: song("on_primary_container", 0.12, 0.9, 0.6)
    readonly property color fgPrimaryFixed: Colors.pick("on_primary_fixed")
    readonly property color fgPrimaryFixedVariant: Colors.pick("on_primary_fixed_variant")
    readonly property color fgSecondary: shade(1.0, 0.15, 0.5)
    readonly property color fgSecondaryContainer: shade(0.15, 0.9, 0.5)
    readonly property color fgSecondaryFixed: Colors.pick("on_secondary_fixed")
    readonly property color fgSecondaryFixedVariant: Colors.pick("on_secondary_fixed_variant")
    readonly property color fgSurface: Colors.pick("on_surface")
    readonly property color fgSurfaceVariant: Colors.pick("on_surface_variant")
    readonly property color fgTertiary: Colors.pick("on_tertiary")
    readonly property color fgTertiaryContainer: Colors.pick("on_tertiary_container")
    readonly property color fgTertiaryFixed: Colors.pick("on_tertiary_fixed")
    readonly property color fgTertiaryFixedVariant: Colors.pick("on_tertiary_fixed_variant")
    readonly property color outline: Colors.pick("outline")
    readonly property color outlineVariant: Colors.pick("outline_variant")
    readonly property color primary: song("primary", 0.4, 0.78, 1.0)
    readonly property color primaryContainer: song("primary_container", 0.88, 0.3, 0.8)
    readonly property color primaryFixed: Colors.pick("primary_fixed")
    readonly property color primaryFixedDim: Colors.pick("primary_fixed_dim")
    readonly property color scrim: Colors.pick("scrim")
    readonly property color secondary: shade(0.45, 0.72, 0.6)
    readonly property color secondaryContainer: shade(0.85, 0.32, 0.7)
    readonly property color secondaryFixed: Colors.pick("secondary_fixed")
    readonly property color secondaryFixedDim: Colors.pick("secondary_fixed_dim")
    readonly property color shadow: Colors.pick("shadow")
    readonly property color surface: Colors.pick("surface")
    readonly property color surfaceBright: Colors.pick("surface_bright")
    readonly property color surfaceContainer: hued("surface_container")
    readonly property color surfaceContainerHigh: hued("surface_container_high")
    readonly property color surfaceContainerHighest: hued("surface_container_highest")
    readonly property color surfaceContainerLow: hued("surface_container_low")
    readonly property color surfaceContainerLowest: hued("surface_container_lowest")
    readonly property color surfaceDim: Colors.pick("surface_dim")
    readonly property color surfaceTint: song("surface_tint", 0.4, 0.78, 1.0)
    readonly property color surfaceVariant: Colors.pick("surface_variant")
    readonly property color tertiary: Colors.pick("tertiary")
    readonly property color tertiaryContainer: Colors.pick("tertiary_container")
    readonly property color tertiaryFixed: Colors.pick("tertiary_fixed")
    readonly property color tertiaryFixedDim: Colors.pick("tertiary_fixed_dim")

    // ground of the bar, drawers and island, follows the opacity setting
    // a vivid version of the accent for moments to blush the island with
    // grey schemes borrow the wallpaper's hue so moments still have a color, a grey wallpaper stays grey
    readonly property color hueSource: primary.hslSaturation >= 0.12 || source.hslSaturation < 0.06 ? primary : source
    readonly property color vivid: hueSource.hslSaturation < 0.06 ? Theme.tone(primary, Theme.dark ? 0.4 : 0.7, 0) : Theme.tone(hueSource, Theme.dark ? 0.4 : 0.7, 1.1)
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
    // hard shadow and rim of raised surfaces
    // the raised look, a hard shadow in a deep shade of the accent and a lit rim, so tinted surfaces still stand off
    // the light under every key, the wallpaper's hue at full color, a grey wallpaper gives a white light
    readonly property color backlight: hueSource.hslSaturation < 0.06 ? Qt.hsla(0, 0, Theme.dark ? 0.78 : 0.6, 1) : Qt.hsla(Math.max(0, hueSource.hslHue), Math.min(1, Math.max(0.65, hueSource.hslSaturation * 1.3)), Theme.dark ? 0.6 : 0.55, 1)
    // the lit ledge fades from the dark shadow at the top to the light at the bottom
    readonly property color depthLit: Theme.depth.backlit ? backlight : depthShadow
    readonly property color depthShadow: Theme.dark ? Qt.alpha(Theme.tone(primary, 0.08, 0.8), 0.9) : Theme.tone(primary, 0.28, 0.9)
    // backlit keys get a glossy candy edge instead of the plain rim
    readonly property color depthRim: Theme.depth.backlit ? Qt.alpha(Theme.mix(backlight, "#ffffff", 0.6), Theme.dark ? 0.22 : 0.7) : Theme.dark ? Qt.alpha(Theme.mix(fgSurface, primary, 0.35), 0.16) : Qt.alpha(Theme.tone(primary, 0.28, 0.9), 0.85)
    // the wallpaper's real color, or the song's while one plays, so the island tints even on the monochrome scheme
    readonly property color source: follow && Theme.songMix > 0 ? Theme.mix(Theme.wallpaper, Theme.song, Theme.songMix) : Theme.wallpaper
    readonly property color sourceTone: Qt.hsla(Math.max(0, source.hslHue), Math.min(1, source.hslSaturation * 1.35), Theme.dark ? Math.max(0.08, Math.min(0.24, source.hslLightness)) : Math.max(0.8, Math.min(0.92, source.hslLightness)), panel.a)
    // the island and the bar pills, the plain panel with the wallpaper seeping in
    readonly property color island: Theme.mix(panel, sourceTone, Theme.islandTint)
}
