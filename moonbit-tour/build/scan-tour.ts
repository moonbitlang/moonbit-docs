import fs from "fs/promises";
import path from "path";
import * as remark from "./remark";

export type Locale = "en" | "zh";

export type Chapter = {
  chapter: string;
  lessons: Lesson[];
};

type Lesson = {
  chapter: string;
  chapterSlug: string;
  lesson: string;
  slug: string;
  title: string;
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

type TourIndex = {
  chapters: {
    path: string;
    slug: string;
    lessons: { path: string; slug: string }[];
  }[];
};

async function scanTour(): Promise<Tour> {
  async function getChapters(
    index: TourIndex,
    locale: Locale,
  ): Promise<Chapter[]> {
    const chapters: Chapter[] = [];
    const root = locale === "en" ? "tour" : "tour/zh";
    for (const chapterEntry of index.chapters) {
      const chapter = chapterEntry.slug.replaceAll("-", " ");
      const lessons: Lesson[] = await Promise.all(
        chapterEntry.lessons.map(async (lessonEntry, i, arr) => {
          const lesson = lessonEntry.slug.replaceAll("-", " ");
          const lessonPath = path.join(
            root,
            chapterEntry.path,
            lessonEntry.path,
          );
          const mdPath = path.join(lessonPath, "index.md");
          const mbtPath = path.join(lessonPath, "index.mbt");
          const md = await fs.readFile(mdPath, "utf8");
          const mbt = await fs.readFile(mbtPath, "utf8");
          const title = remark.getFirstH1Title(md) ?? lesson;
          return {
            chapter,
            chapterSlug: chapterEntry.slug,
            lesson,
            slug: lessonEntry.slug,
            title,
            index: i,
            total: arr.length,
            markdown: md,
            code: mbt,
            locale,
          };
        }),
      );
      chapters.push({
        chapter,
        lessons,
      });
    }
    return chapters;
  }
  const index = JSON.parse(
    await fs.readFile("tour/toc.json", "utf8"),
  ) as TourIndex;
  const [enChapters, zhChapters] = await Promise.all([
    getChapters(index, "en"),
    getChapters(index, "zh"),
  ]);
  return {
    en: enChapters,
    zh: zhChapters,
  };
}

function slug(lesson: Lesson): string {
  const prefix = lesson.locale === "zh" ? "zh/" : "";
  const postfix = `${lesson.chapterSlug}/${lesson.slug}`;
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
        `<li class="hover:bg-purple-100 dark:hover:bg-zinc-700"><a class="toc-link text-base capitalize pl-2 py-1 block" href="/${slug(l)}/index.html">${l.title}</a></li>`,
      );
    }
    lines.push(`</ul>`);
    lines.push("</div></li>");
  }
  lines.push(`</ul>`);
  return lines.join("\n");
}

export { renderTOC, scanTour, slug };
