.pragma library

// fixed color themes, each a short list of its own colors that the material roles are filled from
// layers run from the ground up, the furthest back first
const list = {
    "catppuccin": {
        name: "Catppuccin",
        dark: { bg: "#1e1e2e", layers: ["#11111b", "#181825", "#313244", "#45475a", "#585b70"], text: "#cdd6f4", sub: "#a6adc8", outline: "#7f849c", primary: "#cba6f7", tertiary: "#f5c2e7", error: "#f38ba8" },
        light: { bg: "#eff1f5", layers: ["#eff1f5", "#e6e9ef", "#dce0e8", "#ccd0da", "#bcc0cc"], text: "#4c4f69", sub: "#6c6f85", outline: "#8c8fa1", primary: "#8839ef", tertiary: "#ea76cb", error: "#d20f39" }
    },
    "gruvbox": {
        name: "Gruvbox",
        dark: { bg: "#282828", layers: ["#1d2021", "#32302f", "#3c3836", "#504945", "#665c54"], text: "#ebdbb2", sub: "#bdae93", outline: "#928374", primary: "#fabd2f", tertiary: "#8ec07c", error: "#fb4934" },
        light: { bg: "#fbf1c7", layers: ["#f9f5d7", "#f2e5bc", "#ebdbb2", "#d5c4a1", "#bdae93"], text: "#3c3836", sub: "#665c54", outline: "#928374", primary: "#b57614", tertiary: "#427b58", error: "#9d0006" }
    },
    "rose-pine": {
        name: "Rosé Pine",
        dark: { bg: "#191724", layers: ["#191724", "#1f1d2e", "#26233a", "#403d52", "#524f67"], text: "#e0def4", sub: "#908caa", outline: "#6e6a86", primary: "#c4a7e7", tertiary: "#ebbcba", error: "#eb6f92" },
        light: { bg: "#faf4ed", layers: ["#fffaf3", "#f4ede8", "#f2e9e1", "#dfdad9", "#cecacd"], text: "#575279", sub: "#797593", outline: "#9893a5", primary: "#907aa9", tertiary: "#d7827e", error: "#b4637a" }
    },
    "nord": {
        name: "Nord",
        dark: { bg: "#2e3440", text: "#eceff4", sub: "#d8dee9", primary: "#88c0d0", tertiary: "#b48ead", error: "#bf616a" },
        light: { bg: "#eceff4", text: "#2e3440", sub: "#4c566a", primary: "#5e81ac", tertiary: "#b48ead", error: "#bf616a" }
    },
    "tokyo-night": {
        name: "Tokyo Night",
        dark: { bg: "#1a1b26", layers: ["#16161e", "#1f2335", "#24283b", "#292e42", "#414868"], text: "#c0caf5", sub: "#a9b1d6", outline: "#565f89", primary: "#7aa2f7", tertiary: "#bb9af7", error: "#f7768e" },
        light: { bg: "#e1e2e7", text: "#3760bf", sub: "#6172b0", outline: "#848cb5", primary: "#2e7de9", tertiary: "#9854f1", error: "#f52a65" }
    },
    "everforest": {
        name: "Everforest",
        dark: { bg: "#2d353b", layers: ["#232a2e", "#343f44", "#3d484d", "#475258", "#4f585e"], text: "#d3c6aa", sub: "#9da9a0", outline: "#859289", primary: "#a7c080", tertiary: "#83c092", error: "#e67e80" },
        light: { bg: "#fdf6e3", layers: ["#fdf6e3", "#f4f0d9", "#efebd4", "#e6e2cc", "#e0dcc7"], text: "#5c6a72", sub: "#829181", outline: "#939f91", primary: "#8da101", tertiary: "#35a77c", error: "#f85552" }
    }
};

const names = Object.keys(list);

function label(id) {
    return list[id] ? list[id].name : "";
}

function mix(a, b, amount) {
    const pa = parseInt(a.slice(1), 16), pb = parseInt(b.slice(1), 16);
    let out = "#";
    for (const shift of [16, 8, 0]) {
        const ca = (pa >> shift) & 255, cb = (pb >> shift) & 255;
        out += Math.round(ca + (cb - ca) * amount).toString(16).padStart(2, "0");
    }
    return out;
}

// the material roles of one theme, null when the name is not a theme
function roles(id, mode) {
    const p = list[id] ? list[id][mode] : null;
    if (!p)
        return null;
    // themes without layers of their own get them as steps from the ground toward the text
    const l = p.layers || [p.bg, mix(p.bg, p.text, 0.04), mix(p.bg, p.text, 0.08), mix(p.bg, p.text, 0.13), mix(p.bg, p.text, 0.19)];
    const outline = p.outline || mix(p.bg, p.text, 0.45);
    return {
        background: p.bg, surface: p.bg, surface_dim: l[0], surface_bright: l[4],
        surface_container_lowest: l[0], surface_container_low: l[1], surface_container: l[2], surface_container_high: l[3], surface_container_highest: l[4],
        surface_variant: l[3], on_background: p.text, on_surface: p.text, on_surface_variant: p.sub,
        outline: outline, outline_variant: mix(p.bg, outline, 0.5),
        inverse_surface: p.text, inverse_on_surface: p.bg, inverse_primary: p.primary, surface_tint: p.primary,
        primary: p.primary, on_primary: p.bg, primary_container: mix(p.bg, p.primary, 0.3), on_primary_container: p.text,
        primary_fixed: p.primary, primary_fixed_dim: mix(p.bg, p.primary, 0.8), on_primary_fixed: p.bg, on_primary_fixed_variant: p.bg,
        secondary: mix(p.sub, p.primary, 0.5), on_secondary: p.bg, secondary_container: mix(p.bg, p.primary, 0.2), on_secondary_container: p.text,
        secondary_fixed: mix(p.sub, p.primary, 0.5), secondary_fixed_dim: mix(p.bg, p.primary, 0.6), on_secondary_fixed: p.bg, on_secondary_fixed_variant: p.bg,
        tertiary: p.tertiary, on_tertiary: p.bg, tertiary_container: mix(p.bg, p.tertiary, 0.3), on_tertiary_container: p.text,
        tertiary_fixed: p.tertiary, tertiary_fixed_dim: mix(p.bg, p.tertiary, 0.8), on_tertiary_fixed: p.bg, on_tertiary_fixed_variant: p.bg,
        error: p.error, on_error: p.bg, error_container: mix(p.bg, p.error, 0.3), on_error_container: p.text,
        shadow: "#000000", scrim: "#000000", source_color: p.primary
    };
}
