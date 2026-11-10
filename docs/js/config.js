// Config page: the box at the top narrows every table to the options that match.

const filter = document.querySelector(".filter");
const empty = document.querySelector(".empty");
const sections = [...document.querySelectorAll(".content h2")].map(h => ({ head: h, table: h.nextElementSibling }));

filter.addEventListener("input", () => {
  const words = filter.value.toLowerCase().split(/\s+/).filter(Boolean);
  let shown = 0;
  for (const { head, table } of sections) {
    let any = false;
    for (const row of table.querySelectorAll("tbody tr")) {
      const text = row.textContent.toLowerCase();
      const match = words.every(w => text.includes(w));
      row.hidden = !match;
      any = any || match;
    }
    head.hidden = table.hidden = !any;
    if (any)
      shown++;
  }
  empty.hidden = shown > 0;
});
