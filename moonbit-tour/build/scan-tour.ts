import { Dirent } from "fs";
import fs from "fs/promises";
import path from "path";

export type Locale = "en" | "zh";

export type Chapter = {
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
  locale: Locale;
};

type Tour = {
  en: Chapter[];
  zh: Chapter[];
};

async function dirs(path: string, filter?: (d: Dirent) => boolean) {
  return (await fs.readdir(path, { withFileTypes: true }))
    .filter((i) => i.isDirectory())
    .filter(filter ?? (() => true))
    .sort((a, b) => {
      const na = +a.name.slice(a.name.search(/\d+/), a.name.search("_"));
      const nb = +b.name.slice(b.name.search(/\d+/), b.name.search("_"));
      return na - nb;
    });
}

async function scanTour(): Promise<Tour> {
  async function getChapters(
    folders: Dirent[],
    locale: Locale,
  ): Promise<Chapter[]> {
    const chapters: Chapter[] = [];
    for (const f of folders) {
      const chapter = f.name.split("_").slice(1).join(" ");
      const ds = await dirs(path.join(f.parentPath, f.name));
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
            locale,
          };
        }),
      );
      chapters.push({ chapter, lessons });
    }
    return chapters;
  }
  const enChapterFolders = await dirs("tour", (d) => d.name !== "zh");
  const zhChapterFolders = await dirs("tour/zh");
  const [enChapters, zhChapters] = await Promise.all([
    getChapters(enChapterFolders, "en"),
    getChapters(zhChapterFolders, "zh"),
  ]);
  return {
    en: enChapters,
    zh: zhChapters,
  };
}

function slug(lesson: Lesson): string {
  const prefix = lesson.locale === "zh" ? "zh/" : "";
  const postfix = `${lesson.chapter.replaceAll(" ", "-")}/${lesson.lesson.replaceAll(" ", "-")}`;
  return prefix + postfix;
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
