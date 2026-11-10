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

const ICONS = {
  menu: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M4 7h16M4 12h16M4 17h16"/></svg>',
  github: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2a10 10 0 0 0-3.16 19.49c.5.09.68-.22.68-.48v-1.7c-2.78.6-3.37-1.34-3.37-1.34-.46-1.16-1.11-1.47-1.11-1.47-.91-.62.07-.6.07-.6 1 .07 1.53 1.03 1.53 1.03.9 1.52 2.34 1.08 2.91.83.09-.65.35-1.09.63-1.34-2.22-.25-4.56-1.11-4.56-4.94 0-1.09.39-1.98 1.03-2.68-.1-.25-.45-1.27.1-2.64 0 0 .84-.27 2.75 1.02a9.6 9.6 0 0 1 5 0c1.91-1.3 2.75-1.02 2.75-1.02.55 1.37.2 2.39.1 2.64.64.7 1.03 1.59 1.03 2.68 0 3.84-2.34 4.68-4.57 4.93.36.31.68.92.68 1.85v2.75c0 .27.18.58.69.48A10 10 0 0 0 12 2z"/></svg>',
  search: '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>',
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
    <a class="brand" href="index.html"><img src="img/sweeteh.svg" alt="">Sweeteh</a>
    <button class="search-button" type="button" aria-label="Search the docs">${ICONS.search}<span>Search</span><kbd>Ctrl K</kbd></button>
    <a class="bar-link${isDocs ? " optional" : ""}" href="install.html">Docs</a>
    <a class="bar-link optional" href="${REPO}/releases">Releases</a>
    <a class="icon-button" href="${REPO}" aria-label="Sweeteh on GitHub">${ICONS.github}</a>
    <button class="icon-button theme-button" type="button" aria-label="Switch between dark and light">${ICONS.sun}${ICONS.moon}</button>`;
  document.body.prepend(bar);

  bar.querySelector(".theme-button").onclick = () => setTheme(root.dataset.theme === "light" ? "dark" : "light");

  bar.querySelector(".search-button").onclick = openSearch;
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

// ---------- search ----------
// every docs page is read once, on the first search, and split into its sections

let searchIndex = null;

async function loadSearchIndex() {
  const entries = [];
  await Promise.all(NAV.flatMap(g => g.pages).map(async ([href, label]) => {
    try {
      const doc = new DOMParser().parseFromString(await (await fetch(href)).text(), "text/html");
      const content = doc.querySelector(".content");
      if (!content)
        return;
      let entry = { href, title: label, page: "", text: "" };
      entries.push(entry);
      for (const node of content.children) {
        if (node.tagName === "H2" || node.tagName === "H3") {
          entry = { href: href + "#" + (node.id || slug(node.textContent)), title: node.textContent, page: label, text: "" };
          entries.push(entry);
        } else if (node.tagName !== "H1") {
          entry.text += " " + node.textContent.replace(/\s+/g, " ");
        }
      }
    } catch (e) {}
  }));
  return entries;
}

function searchFor(query) {
  const words = query.toLowerCase().split(/\s+/).filter(Boolean);
  if (!words.length)
    return [];
  return searchIndex.map(entry => {
    const title = entry.title.toLowerCase(), text = entry.text.toLowerCase();
    let score = 0;
    for (const w of words) {
      if (title.includes(w))
        score += 10;
      else if (text.includes(w))
        score += 1;
      else
        return null;
    }
    return { entry, score, at: text.indexOf(words[0]) };
  }).filter(Boolean).sort((a, b) => b.score - a.score).slice(0, 8);
}

function escapeHtml(text) {
  return text.replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
}

let searchDialog = null;

async function openSearch() {
  if (!searchDialog) {
    searchDialog = document.createElement("dialog");
    searchDialog.className = "search";
    searchDialog.innerHTML = '<input type="search" placeholder="Search the docs" aria-label="Search the docs" autocomplete="off"><div class="search-results"></div>';
    document.body.append(searchDialog);
    const input = searchDialog.querySelector("input"), results = searchDialog.querySelector(".search-results");
    let selected = 0;
    const render = () => {
      const hits = searchFor(input.value);
      selected = Math.min(selected, Math.max(0, hits.length - 1));
      results.innerHTML = hits.length ? hits.map((h, i) => {
        const from = Math.max(0, h.at - 30);
        const excerpt = h.at >= 0 ? h.entry.text.slice(from, from + 110).trim() : h.entry.page;
        return `<a href="${h.entry.href}"${i === selected ? ' class="selected"' : ""}>${escapeHtml(h.entry.title)}<small>${escapeHtml((h.entry.page ? h.entry.page + " · " : "") + excerpt)}</small></a>`;
      }).join("") : `<p>${input.value.trim() ? "Nothing found." : "Type to search every page."}</p>`;
    };
    input.oninput = () => { selected = 0; render(); };
    input.onkeydown = e => {
      const links = results.querySelectorAll("a");
      if (e.key === "ArrowDown" || e.key === "ArrowUp") {
        e.preventDefault();
        selected = Math.max(0, Math.min(links.length - 1, selected + (e.key === "ArrowDown" ? 1 : -1)));
        render();
      } else if (e.key === "Enter" && links[selected]) {
        searchDialog.close();
        location.href = links[selected].href;
      }
    };
    // a click on the dimmed page around the box closes it
    searchDialog.onclick = e => {
      if (e.target === searchDialog || e.target.closest("a"))
        searchDialog.close();
    };
    searchDialog.render = render;
  }
  searchDialog.showModal();
  const input = searchDialog.querySelector("input");
  input.value = "";
  if (!searchIndex) {
    searchDialog.querySelector(".search-results").innerHTML = "<p>Reading the docs.</p>";
    searchIndex = await loadSearchIndex();
  }
  searchDialog.render();
  input.focus();
}

addEventListener("keydown", e => {
  if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "k") {
    e.preventDefault();
    openSearch();
  }
});

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

buildBar();
if (isDocs) {
  buildSidebar();
  buildOutline();
  buildPager();
}
buildCopyButtons();
