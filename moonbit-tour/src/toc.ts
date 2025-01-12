function tocChapter(div: HTMLDivElement) {
  const title = div.querySelector<HTMLButtonElement>(".toc-chapter-title")!;
  const sections = div.querySelector<HTMLUListElement>(".toc-sections")!;
  title.onclick = () => {
    sections.classList.toggle("hidden");
  };
}

export function init() {
  const tocButton = document.getElementById("toc-button")!;
  const toc = document.getElementById("toc")!;
  tocButton.onclick = () => {
    toc.classList.toggle("hidden");
  };

  for (const div of document.querySelectorAll<HTMLDivElement>(".toc-chapter")) {
    tocChapter(div);
  }

  document.addEventListener("click", (e) => {
    if (!(e.target instanceof Node)) return;
    if (toc.contains(e.target) || tocButton.contains(e.target)) return;
    if (toc.classList.contains("hidden")) return;
    toc.classList.add("hidden");
  });
}
