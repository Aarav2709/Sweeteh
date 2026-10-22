import QtQuick

// material color roles, filled from the active palette
QtObject {
    readonly property color background: Colors.pick("background")
    readonly property color error: Colors.pick("error")
    readonly property color errorContainer: Colors.pick("error_container")
    readonly property color inverseOnSurface: Colors.pick("inverse_on_surface")
    readonly property color inversePrimary: Colors.pick("inverse_primary")
    readonly property color inverseSurface: Colors.pick("inverse_surface")
    readonly property color fgBackground: Colors.pick("on_background")
    readonly property color fgError: Colors.pick("on_error")
    readonly property color fgErrorContainer: Colors.pick("on_error_container")
    readonly property color fgPrimary: Colors.pick("on_primary")
    readonly property color fgPrimaryContainer: Colors.pick("on_primary_container")
    readonly property color fgPrimaryFixed: Colors.pick("on_primary_fixed")
    readonly property color fgPrimaryFixedVariant: Colors.pick("on_primary_fixed_variant")
    readonly property color fgSecondary: Colors.pick("on_secondary")
    readonly property color fgSecondaryContainer: Colors.pick("on_secondary_container")
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
    readonly property color primary: Colors.pick("primary")
    readonly property color primaryContainer: Colors.pick("primary_container")
    readonly property color primaryFixed: Colors.pick("primary_fixed")
    readonly property color primaryFixedDim: Colors.pick("primary_fixed_dim")
    readonly property color scrim: Colors.pick("scrim")
    readonly property color secondary: Colors.pick("secondary")
    readonly property color secondaryContainer: Colors.pick("secondary_container")
    readonly property color secondaryFixed: Colors.pick("secondary_fixed")
    readonly property color secondaryFixedDim: Colors.pick("secondary_fixed_dim")
    readonly property color shadow: Colors.pick("shadow")
    readonly property color surface: Colors.pick("surface")
    readonly property color surfaceBright: Colors.pick("surface_bright")
    readonly property color surfaceContainer: Colors.pick("surface_container")
    readonly property color surfaceContainerHigh: Colors.pick("surface_container_high")
    readonly property color surfaceContainerHighest: Colors.pick("surface_container_highest")
    readonly property color surfaceContainerLow: Colors.pick("surface_container_low")
    readonly property color surfaceContainerLowest: Colors.pick("surface_container_lowest")
    readonly property color surfaceDim: Colors.pick("surface_dim")
    readonly property color surfaceTint: Colors.pick("surface_tint")
    readonly property color surfaceVariant: Colors.pick("surface_variant")
    readonly property color tertiary: Colors.pick("tertiary")
    readonly property color tertiaryContainer: Colors.pick("tertiary_container")
    readonly property color tertiaryFixed: Colors.pick("tertiary_fixed")
    readonly property color tertiaryFixedDim: Colors.pick("tertiary_fixed_dim")

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
    // hard shadow and rim of raised surfaces
    readonly property color depthShadow: Theme.dark ? Qt.alpha("#000000", 0.7) : Theme.mix(primary, "#000000", 0.55)
    readonly property color depthRim: Theme.dark ? Qt.alpha(fgSurface, 0.09) : Qt.alpha(Theme.mix(primary, "#000000", 0.55), 0.85)
}
