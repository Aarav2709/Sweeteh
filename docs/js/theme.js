// Runs before the page paints, so a light page never flashes dark first.
(function () {
  var theme = null;
  try {
    theme = localStorage.getItem("theme");
  } catch (e) {}
  if (!theme)
    theme = matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark";
  document.documentElement.dataset.theme = theme;
  // lets the stylesheet hide what scripts will reveal, and nothing when scripts are off
  document.documentElement.classList.add("js");
})();
