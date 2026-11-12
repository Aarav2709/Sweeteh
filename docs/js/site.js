// Sweeteh docs. Builds the top bar, the sidebar and the page outline, so each page only holds its own content.

const REPO = "https://github.com/Aarav2709/Sweeteh";

// the sidebar, in reading order. A new page is one line here.
const NAV = [
  { title: "Start here", pages: [
    ["install.html", "Getting started"],
    ["command.html", "The sweeteh command"]
  ] },
  { title: "Guides", pages: [
    ["launcher.html", "Launcher"],
    ["themes.html", "Themes"],
    ["keys.html", "Keys"]
  ] },
  { title: "Reference", pages: [
    ["config.html", "Config"],
    ["troubleshooting.html", "Troubleshooting"]
  ] }
];

// the clips on the landing page, its top bar scrolls to each
const SECTIONS = [["launcher", "Launcher"], ["island", "Island"], ["media", "Media"], ["wallpapers", "Wallpapers"]];

const ICONS = {
  menu: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M4 7h16M4 12h16M4 17h16"/></svg>',
  github: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2a10 10 0 0 0-3.16 19.49c.5.09.68-.22.68-.48v-1.7c-2.78.6-3.37-1.34-3.37-1.34-.46-1.16-1.11-1.47-1.11-1.47-.91-.62.07-.6.07-.6 1 .07 1.53 1.03 1.53 1.03.9 1.52 2.34 1.08 2.91.83.09-.65.35-1.09.63-1.34-2.22-.25-4.56-1.11-4.56-4.94 0-1.09.39-1.98 1.03-2.68-.1-.25-.45-1.27.1-2.64 0 0 .84-.27 2.75 1.02a9.6 9.6 0 0 1 5 0c1.91-1.3 2.75-1.02 2.75-1.02.55 1.37.2 2.39.1 2.64.64.7 1.03 1.59 1.03 2.68 0 3.84-2.34 4.68-4.57 4.93.36.31.68.92.68 1.85v2.75c0 .27.18.58.69.48A10 10 0 0 0 12 2z"/></svg>',
  sun: '<svg class="icon-sun" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></svg>',
  moon: '<svg class="icon-moon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z"/></svg>'
};

const root = document.documentElement;
const here = location.pathname.split("/").pop() || "index.html";
const isDocs = document.body.classList.contains("docs");

// ---------- dark and light ----------

// theme.js has already picked dark or light before the page painted, this only switches it
function setTheme(theme) {
  root.dataset.theme = theme;
  try {
    localStorage.setItem("theme", theme);
  } catch (e) {}
  document.dispatchEvent(new CustomEvent("themechange", { detail: theme }));
}

// ---------- top bar ----------

function buildBar() {
  const bar = document.createElement("header");
  bar.className = "bar";
  bar.innerHTML = `
    ${isDocs ? `<button class="icon-button menu-button" type="button" aria-label="Open the menu" aria-expanded="false">${ICONS.menu}</button>` : ""}
    ${isDocs ? '<a class="brand" href="index.html">Sweeteh</a>' : SECTIONS.map(([id, label]) => `<a class="bar-link" href="#${id}">${label}</a>`).join("") + '<a class="bar-link" href="install.html">Docs</a>'}
    <a class="icon-button" href="${REPO}" aria-label="Sweeteh on GitHub">${ICONS.github}</a>
    <button class="icon-button theme-button" type="button" aria-label="Switch between dark and light">${ICONS.sun}${ICONS.moon}</button>`;
  document.body.prepend(bar);

  bar.querySelector(".theme-button").onclick = () => setTheme(root.dataset.theme === "light" ? "dark" : "light");

  const menu = bar.querySelector(".menu-button");
  if (menu)
    menu.onclick = () => menu.setAttribute("aria-expanded", String(document.body.classList.toggle("menu-open")));
}

// ---------- sidebar, outline and the links to the pages before and after ----------

function buildSidebar() {
  const side = document.querySelector(".sidebar");
  side.setAttribute("aria-label", "Docs pages");
  side.innerHTML = NAV.map(group => `
    <div class="nav-group">
      <p class="nav-title">${group.title}</p>
      ${group.pages.map(([href, label]) => `<a href="${href}"${href === here ? ' aria-current="page"' : ""}>${label}</a>`).join("")}
    </div>`).join("");
}

function slug(text) {
  return text.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
}

function buildOutline() {
  const toc = document.querySelector(".toc");
  const heads = [...document.querySelectorAll(".content h2, .content h3")];
  for (const h of heads) {
    if (!h.id)
      h.id = slug(h.textContent);
    const link = document.createElement("a");
    link.className = "anchor";
    link.href = "#" + h.id;
    link.textContent = "#";
    link.setAttribute("aria-label", "Link to this section");
    h.append(link);
  }
  if (!toc || heads.length < 2) {
    toc?.remove();
    return;
  }
  toc.setAttribute("aria-label", "On this page");
  toc.innerHTML = '<p class="toc-title">On this page</p>' + heads.map(h =>
    `<a href="#${h.id}"${h.tagName === "H3" ? ' class="sub"' : ""}>${h.firstChild.textContent}</a>`).join("");

  // the section being read is marked as the page scrolls
  const links = new Map(heads.map(h => [h, toc.querySelector(`a[href="#${CSS.escape(h.id)}"]`)]));
  const mark = () => {
    let current = heads[0];
    for (const h of heads)
      if (h.getBoundingClientRect().top < 120)
        current = h;
    links.forEach((a, h) => a.classList.toggle("active", h === current));
  };
  addEventListener("scroll", mark, { passive: true });
  mark();
}

function buildPager() {
  const pages = NAV.flatMap(g => g.pages);
  const at = pages.findIndex(p => p[0] === here);
  if (at < 0)
    return;
  const pager = document.createElement("nav");
  pager.className = "pager";
  pager.setAttribute("aria-label", "Previous and next page");
  const prev = pages[at - 1], next = pages[at + 1];
  pager.innerHTML =
    (prev ? `<a href="${prev[0]}"><small>Previous</small>${prev[1]}</a>` : "") +
    (next ? `<a class="next" href="${next[0]}"><small>Next</small>${next[1]}</a>` : "");
  document.querySelector(".content").append(pager);
}

// ---------- code blocks ----------

function buildCopyButtons() {
  for (const pre of document.querySelectorAll("pre")) {
    const box = document.createElement("div");
    box.className = "code";
    pre.replaceWith(box);
    const button = document.createElement("button");
    button.type = "button";
    button.className = "copy";
    button.textContent = "Copy";
    button.onclick = async () => {
      // comments shown dimmed are for reading, not for the terminal
      const copy = pre.cloneNode(true);
      copy.querySelectorAll(".dim").forEach(n => n.remove());
      const text = copy.textContent.split("\n").map(l => l.trimEnd()).join("\n").trim();
      try {
        await navigator.clipboard.writeText(text);
        button.textContent = "Copied";
      } catch (e) {
        button.textContent = "Press Ctrl C";
      }
      setTimeout(() => button.textContent = "Copy", 1500);
    };
    box.append(pre, button);
  }
}

// ---------- motion ----------
// sections rise into place as they are scrolled to, and the clips only play while they can be seen

function buildMotion() {
  const still = matchMedia("(prefers-reduced-motion: reduce)").matches;

  const groups = [[".feature", 0], [".home section > h2, .home section > .sub, .install-box", 0], [".home .card", 0.06]];
  const reveal = new IntersectionObserver(entries => {
    for (const entry of entries) {
      if (!entry.isIntersecting)
        continue;
      entry.target.classList.add("seen");
      reveal.unobserve(entry.target);
    }
  }, { rootMargin: "0px 0px -10% 0px" });
  for (const [selector, step] of groups) {
    document.querySelectorAll(selector).forEach(el => {
      // cards in one grid follow each other in, a beat apart
      const at = [...el.parentElement.children].indexOf(el);
      el.style.setProperty("--delay", (at % 3) * step + "s");
      el.classList.add("reveal");
      reveal.observe(el);
    });
  }

  const clips = document.querySelectorAll("video.clip");
  if (still) {
    // the clip behind the name stays a still picture, controls would sit on top of the text
    clips.forEach(clip => clip.controls = !clip.closest(".hero"));
    return;
  }
  const play = new IntersectionObserver(entries => {
    for (const entry of entries) {
      if (entry.isIntersecting)
        entry.target.play().catch(() => {});
      else
        entry.target.pause();
    }
  }, { threshold: 0.35 });
  clips.forEach(clip => play.observe(clip));
}

buildBar();
if (!isDocs)
  buildMotion();
if (isDocs) {
  buildSidebar();
  buildOutline();
  buildPager();
}
buildCopyButtons();
