import fs from "fs/promises";
import path from "path";

type Chapter = {
  chapter: string;
  lessons: Lesson[];
};

type Lesson = {
  chapter: string;
  lesson: string;
  index: number;
  total: number;
  markdown: string;
  code: string;
};

async function dirs(path: string) {
  return (await fs.readdir(path, { withFileTypes: true }))
    .filter((i) => i.isDirectory())
    .sort((a, b) => {
      const na = +a.name.slice(a.name.search(/\d+/), a.name.search("_"));
      const nb = +b.name.slice(b.name.search(/\d+/), b.name.search("_"));
      return na - nb;
    });
}

async function scanTour(): Promise<Chapter[]> {
  const chapterFolders = await dirs("tour");
  const chapters: Chapter[] = [];
  for (const c of chapterFolders) {
    const chapter = c.name.split("_").slice(1).join(" ");
    const ds = await dirs(path.join(c.parentPath, c.name));
    const lessons: Lesson[] = await Promise.all(
      ds.map(async (d, i, arr) => {
        const lesson = d.name.split("_").slice(1).join(" ");
        const mdPath = path.join(d.parentPath, d.name, "index.md");
        const mbtPath = path.join(d.parentPath, d.name, "index.mbt");
        const md = await fs.readFile(mdPath, "utf8");
        const mbt = await fs.readFile(mbtPath, "utf8");
        return {
          chapter,
          lesson,
          index: i,
          total: arr.length,
          markdown: md,
          code: mbt,
        };
      }),
    );
    chapters.push({ chapter, lessons });
  }
  return chapters;
}

function slug(lesson: Lesson): string {
  return `${lesson.chapter.replaceAll(" ", "-")}/${lesson.lesson.replaceAll(" ", "-")}`;
}

function renderTOC(chapters: Chapter[]): string {
  const lines: string[] = [];
  lines.push(
    `<ul class="border-l-4 border-l-purple-100 dark:border-l-zinc-800">`,
  );
  for (const c of chapters) {
    lines.push(`<li><div class="toc-chapter pl-1">`);
    lines.push(
      `<button class="toc-chapter-title block w-full text-start cursor-pointer capitalize py-1">${c.chapter}</button>`,
    );
    lines.push(`<ul class="toc-sections bg-gray-50 dark:bg-zinc-700">`);
    for (const l of c.lessons) {
      lines.push(
        `<li><a class="toc-link text-base capitalize pl-2 py-1 block" href="/${slug(l)}/index.html">${l.lesson}</a></li>`,
      );
    }
    lines.push(`</ul>`);
    lines.push("</div></li>");
  }
  lines.push(`</ul>`);
  return lines.join("\n");
}

export { renderTOC, scanTour, slug };
