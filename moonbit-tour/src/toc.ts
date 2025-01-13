function tocChapter(div: HTMLDivElement) {
  const title = div.querySelector<HTMLButtonElement>(".toc-chapter-title")!;
  const sections = div.querySelector<HTMLUListElement>(".toc-sections")!;
  title.onclick = () => {
    sections.classList.toggle("hidden");
  };
}

function highlightCurrent() {
  const sections =
    document.querySelectorAll<HTMLUListElement>(".toc-sections")!;
  let openSectionIndex = -1;
  for (const [i, section] of sections.entries()) {
    const links = section.querySelectorAll<HTMLAnchorElement>(".toc-link")!;
    for (const link of links) {
      if (link.href === location.href) {
        openSectionIndex = i;
        link.classList.add("font-bold");
      } else {
        link.classList.remove("font-bold");
      }
    }
  }
  if (openSectionIndex === -1) {
    for (const section of sections) {
      section.classList.remove("hidden");
    }
  } else {
    for (const [i, section] of sections.entries()) {
      if (i === openSectionIndex) {
        section.classList.remove("hidden");
      } else {
        section.classList.add("hidden");
      }
    }
  }
}

const tocButton = document.getElementById("toc-button")!;
const toc = document.getElementById("toc")!;
const themeButton = document.querySelector<HTMLButtonElement>("#theme")!;

export function init() {
  tocButton.onclick = () => {
    toc.classList.toggle("hidden");
  };

  for (const div of document.querySelectorAll<HTMLDivElement>(".toc-chapter")) {
    tocChapter(div);
  }

  window.addEventListener(
    "click",
    (e) => {
      if (!(e.target instanceof Node)) return;
      if (
        toc.contains(e.target) ||
        tocButton.contains(e.target) ||
        themeButton.contains(e.target)
      )
        return;
      if (toc.classList.contains("hidden")) return;
      toc.classList.add("hidden");
    },
    { capture: true },
  );
  window.addEventListener("route-change", () => {
    highlightCurrent();
  });
  highlightCurrent();
}
