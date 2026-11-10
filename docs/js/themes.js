// Themes page: the fixed themes, previewed on a small mock of the shell.
// Each list is ground, three raised layers, text, soft text, hairline, accent and second accent, the same colors the shell uses.

const THEMES = {
  "catppuccin": {
    "name": "Catppuccin",
    "dark": [
      "#1e1e2e",
      "#181825",
      "#313244",
      "#45475a",
      "#cdd6f4",
      "#a6adc8",
      "#4f5165",
      "#cba6f7",
      "#f5c2e7"
    ],
    "light": [
      "#eff1f5",
      "#e6e9ef",
      "#dce0e8",
      "#ccd0da",
      "#4c4f69",
      "#6c6f85",
      "#bec0cb",
      "#8839ef",
      "#ea76cb"
    ]
  },
  "gruvbox": {
    "name": "Gruvbox",
    "dark": [
      "#282828",
      "#32302f",
      "#3c3836",
      "#504945",
      "#ebdbb2",
      "#bdae93",
      "#5d564e",
      "#fabd2f",
      "#8ec07c"
    ],
    "light": [
      "#fbf1c7",
      "#f2e5bc",
      "#ebdbb2",
      "#d5c4a1",
      "#3c3836",
      "#665c54",
      "#c7ba9e",
      "#b57614",
      "#427b58"
    ]
  },
  "rose-pine": {
    "name": "Rosé Pine",
    "dark": [
      "#191724",
      "#1f1d2e",
      "#26233a",
      "#403d52",
      "#e0def4",
      "#908caa",
      "#444155",
      "#c4a7e7",
      "#ebbcba"
    ],
    "light": [
      "#faf4ed",
      "#f4ede8",
      "#f2e9e1",
      "#dfdad9",
      "#575279",
      "#797593",
      "#c9c4c9",
      "#907aa9",
      "#d7827e"
    ]
  },
  "nord": {
    "name": "Nord",
    "dark": [
      "#2e3440",
      "#363b47",
      "#3d434e",
      "#474c57",
      "#eceff4",
      "#d8dee9",
      "#595e69",
      "#88c0d0",
      "#b48ead"
    ],
    "light": [
      "#eceff4",
      "#e4e8ed",
      "#dde0e6",
      "#d3d7dd",
      "#2e3440",
      "#4c566a",
      "#c2c5cc",
      "#5e81ac",
      "#b48ead"
    ]
  },
  "tokyo-night": {
    "name": "Tokyo Night",
    "dark": [
      "#1a1b26",
      "#1f2335",
      "#24283b",
      "#292e42",
      "#c0caf5",
      "#a9b1d6",
      "#383d58",
      "#7aa2f7",
      "#bb9af7"
    ],
    "light": [
      "#e1e2e7",
      "#dadde5",
      "#d3d8e4",
      "#cbd1e2",
      "#3760bf",
      "#6172b0",
      "#b3b7ce",
      "#2e7de9",
      "#9854f1"
    ]
  },
  "everforest": {
    "name": "Everforest",
    "dark": [
      "#2d353b",
      "#343f44",
      "#3d484d",
      "#475258",
      "#d3c6aa",
      "#9da9a0",
      "#596462",
      "#a7c080",
      "#83c092"
    ],
    "light": [
      "#fdf6e3",
      "#f4f0d9",
      "#efebd4",
      "#e6e2cc",
      "#5c6a72",
      "#829181",
      "#c8cbba",
      "#8da101",
      "#35a77c"
    ]
  }
};

const preview = document.querySelector(".preview");
const chips = document.querySelector(".swatch-row");
const palette = document.querySelector(".preview-palette");
let current = Object.keys(THEMES)[0];

function show() {
  const mode = document.documentElement.dataset.theme === "light" ? "light" : "dark";
  const c = THEMES[current][mode];
  const names = ["--p-bg", "--p-low", "--p-layer1", "--p-layer2", "--p-text", "--p-soft", "--p-line", "--p-accent", "--p-accent2"];
  names.forEach((name, i) => preview.style.setProperty(name, c[i]));
  palette.innerHTML = c.map(color => `<span style="background:${color}"></span>`).join("");
  for (const chip of chips.children)
    chip.setAttribute("aria-pressed", String(chip.dataset.theme === current));
}

for (const id of Object.keys(THEMES)) {
  const chip = document.createElement("button");
  chip.type = "button";
  chip.className = "chip";
  chip.dataset.theme = id;
  const dot = document.createElement("i");
  dot.style.background = THEMES[id].dark[7];
  chip.append(dot, THEMES[id].name);
  chip.onclick = () => {
    current = id;
    show();
  };
  chips.append(chip);
}

// the site's own dark and light switch flips the preview too
document.addEventListener("themechange", show);
show();
