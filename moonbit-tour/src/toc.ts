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
  const highlightClass = ["font-bold", "border-l-2", "border-purple-500"];
  for (const [i, section] of sections.entries()) {
    const links = section.querySelectorAll<HTMLAnchorElement>(".toc-link")!;
    for (const link of links) {
      if (link.href === location.href) {
        openSectionIndex = i;
        for (const c of highlightClass) {
          link.classList.add(c);
        }
      } else {
        for (const c of highlightClass) {
          link.classList.remove(c);
        }
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

let tocVisible = false;
const isMd = window.matchMedia("(min-width: 768px)").matches;
function showToc() {
  if (isMd) {
    toc.classList.remove("md:right-[-400px]");
  } else {
    toc.classList.toggle("hidden");
  }
}
function hideToc() {
  if (isMd) {
    toc.classList.add("md:right-[-400px]");
  } else {
    toc.classList.toggle("hidden");
  }
}
export function init() {
  tocButton.onclick = () => {
    const targetVisible = !tocVisible;
    if (targetVisible) {
      showToc();
    } else {
      hideToc();
    }
    tocVisible = targetVisible;
  };

  if (isMd) {
    toc.classList.remove("hidden");
  }

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
      if (!tocVisible) return;
      hideToc();
    },
    { capture: true },
  );
  window.addEventListener("route-change", () => {
    highlightCurrent();
  });
  highlightCurrent();
}
