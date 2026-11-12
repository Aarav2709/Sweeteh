// Landing page: a small launcher you can type in. It answers from a made-up desktop, the way the real one answers from yours.

const APPS = [
  ["Firefox", "Fast and private browser"], ["Files", "Browse your folders"], ["Kitty", "Terminal"], ["Zed", "Code editor"],
  ["Vesktop", "Discord, themed to match"], ["Spotify", "Music"], ["Steam", "Games"], ["Settings", "Every option, searchable"]
];
const COMMANDS = [
  ["wifi_off", "Turn Wi-Fi off"], ["wallpaper", "Pick a wallpaper"], ["lock", "Lock screen"], ["screenshot_region", "Capture a region"],
  ["palette", "Use the Gruvbox theme"], ["dark_mode", "Use the light theme"], ["content_paste", "Clipboard history"], ["restart_alt", "Reboot"]
];
const EMOJI = [
  ["🔥", "fire"], ["❤️", "red heart"], ["🌹", "rose"], ["✨", "sparkles"], ["🚀", "rocket"], ["🎧", "headphone"], ["🌙", "crescent moon"],
  ["🍓", "strawberry"], ["👀", "eyes"], ["🎉", "party popper"], ["☕", "hot beverage"], ["🏝️", "desert island"]
];
const WINDOWS = [["Sweeteh, GitHub", "firefox, workspace 1"], ["~/GitHub/Sweeteh", "kitty, workspace 2"], ["LauncherView.qml", "zed, workspace 2"], ["#general", "vesktop, workspace 3"]];
const CLIPS = ["https://github.com/Aarav2709/Sweeteh", "sweeteh ipc launcher toggle", "#c81e2b", "Meet at 6, bring the charger"];
const FILES = [["notes.md", "~/Documents"], ["wallpaper.png", "~/Pictures/Wallpapers"], ["config.json", "~/.config/sweeteh"], ["invoice-november.pdf", "~/Downloads"]];
const HOSTS = ["homelab", "pi", "work-bastion"];
const PREFIXES = [
  ["terminal", "> Commands", "Every shell action, timers, dates and more", ">"],
  ["mood", ": Emoji and symbols", "Search by name, Enter copies", ":"],
  ["select_window", "@ Windows", "Switch to an open window", "@"],
  ["content_paste", "\" Clipboard", "Search what you copied", "\""],
  ["history", "/ Files", "Opened lately, or search your home folder", "/"],
  ["dns", "$ SSH", "Connect to a host from your ssh config", "$"]
];
// what the launcher types by itself until someone takes over
const SCRIPT = ["fire", ">timer 5m", ":heart", "12 * 4.5", "@", "?"];

const box = document.querySelector(".mock");
const input = box.querySelector("input");
const list = box.querySelector(".mock-rows");

function has(text, query) {
  return text.toLowerCase().includes(query.toLowerCase());
}

function row(icon, title, sub, hint, fill) {
  return { icon, title, sub, hint, fill };
}

function answer(raw) {
  const q = raw.trim();
  const rest = q.slice(1).trim();
  if (q === "")
    return [row("search", "Search apps, files and sums", "Or type ? to see what else it does", "")];
  if (q === "?")
    return PREFIXES.map(p => row(p[0], p[1], p[2], "", p[3]));
  if (q[0] === ">") {
    const timer = rest.match(/^timer\s+(\d+)\s*([smh]?)/);
    if (timer)
      return [row("timer", "Timer for " + timer[1] + " " + ({ s: "seconds", h: "hours" }[timer[2]] || "minutes"), "Counts down in the island", "Action")];
    return COMMANDS.filter(c => has(c[1], rest)).map(c => row(c[0], c[1], "", "Action")).concat(rest ? [row("terminal", rest, "Run in a shell", "Shell")] : []);
  }
  if (q[0] === ":")
    return EMOJI.filter(e => has(e[1], rest)).map(e => row(e[0], e[1][0].toUpperCase() + e[1].slice(1), "", "Copy"));
  if (q[0] === "@")
    return WINDOWS.filter(w => has(w[0] + w[1], rest)).map(w => row("select_window", w[0], w[1], "Switch"));
  if (q[0] === "\"")
    return CLIPS.filter(c => has(c, rest)).map(c => row("content_paste", c, "", "Copy"));
  if (q[0] === "/")
    return FILES.filter(f => has(f[0], rest)).map(f => row(rest ? "description" : "history", f[0], f[1], "File"));
  if (q[0] === "$")
    return HOSTS.filter(h => has(h, rest)).map(h => row("dns", h, "From your ssh config", "SSH")).concat(rest && !HOSTS.includes(rest) ? [row("terminal", rest, "Connect to this host", "SSH")] : []);
  // a sum is only ever digits and operators, so it is safe to work out
  if (/^[\d\s.+\-*/()]+$/.test(q) && /\d\s*[+\-*/]\s*\(?\d/.test(q)) {
    try {
      const sum = Function('"use strict"; return (' + q + ")")();
      if (Number.isFinite(sum))
        return [row("calculate", String(Math.round(sum * 1e6) / 1e6), "Press enter to copy", "Copy")];
    } catch (e) {}
  }
  return APPS.filter(a => has(a[0], q)).map(a => row("apps", a[0], a[1], "")).concat([row("travel_explore", q, "Search the web", "Web")]);
}

function render() {
  const rows = answer(input.value).slice(0, 6);
  list.replaceChildren(...rows.map((r, i) => {
    const el = document.createElement(r.fill ? "button" : "div");
    el.className = "mock-row" + (i === 0 ? " first" : "");
    el.style.setProperty("--i", i);
    const icon = document.createElement("span");
    // emoji rows show the emoji itself, the rest a symbol
    icon.className = /^[a-z_]+$/.test(r.icon) ? "mock-icon symbol" : "mock-icon";
    icon.textContent = r.icon;
    const text = document.createElement("span");
    text.className = "mock-text";
    const title = document.createElement("b");
    title.textContent = r.title;
    text.append(title);
    if (r.sub) {
      const sub = document.createElement("small");
      sub.textContent = r.sub;
      text.append(sub);
    }
    el.append(icon, text);
    if (r.hint) {
      const hint = document.createElement("span");
      hint.className = "mock-hint";
      hint.textContent = r.hint;
      el.append(hint);
    }
    if (r.fill) {
      el.type = "button";
      el.onclick = () => take(r.fill);
    }
    return el;
  }));
}

// ---------- typing by itself ----------

let auto = !matchMedia("(prefers-reduced-motion: reduce)").matches;
let timer = null;

function wait(ms) {
  return new Promise(done => timer = setTimeout(done, ms));
}

async function play() {
  for (let at = 0; auto; at = (at + 1) % SCRIPT.length) {
    for (const ch of SCRIPT[at]) {
      if (!auto)
        return;
      input.value += ch;
      render();
      await wait(110 + Math.random() * 90);
    }
    await wait(2100);
    while (auto && input.value) {
      input.value = input.value.slice(0, -1);
      render();
      await wait(38);
    }
    await wait(450);
  }
}

// the visitor takes over, the demo stops for good
function take(text) {
  auto = false;
  clearTimeout(timer);
  box.classList.add("taken");
  if (text !== undefined) {
    input.value = text;
    input.focus();
  }
  render();
}

input.addEventListener("pointerdown", () => {
  if (auto) {
    input.value = "";
    take();
  }
});
input.addEventListener("keydown", () => {
  if (auto) {
    input.value = "";
    take();
  }
});
input.addEventListener("input", () => take());
for (const chip of document.querySelectorAll("[data-fill]"))
  chip.onclick = () => take(chip.dataset.fill);

render();
// it starts typing once it is on screen, not before
new IntersectionObserver((entries, watch) => {
  if (entries[0].isIntersecting) {
    watch.disconnect();
    play();
  }
}, { threshold: 0.5 }).observe(box);
