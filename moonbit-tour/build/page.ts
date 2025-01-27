import * as fs from "fs/promises";
import * as remark from "./remark";
import * as scan from "./scan-tour";
import * as shiki from "./shiki";

type Page = {
  title: string;
  toc: string;
  markdown: string;
  code: string;
  back: string;
  next: string;
  path: string;
  index: number;
  total: number;
};

export async function collectTourPage(): Promise<Page[]> {
  const pages: Page[] = [];
  const chapters = await scan.scanTour();
  const lessons = chapters.flatMap((c) => c.lessons);

  const indexMd = await fs.readFile("tour/index.md", "utf8");
  const indexMbt = await fs.readFile("tour/index.mbt", "utf8");
  const toc = scan.renderTOC(chapters);
  pages.push({
    title: "MoonBit Language Tour",
    markdown: indexMd,
    code: indexMbt,
    back: `<span class="text-zinc-500">Back</span>`,
    next: `<a href="/${scan.slug(lessons[0])}/index.html">Next</a>`,
    path: "index.html",
    index: 1,
    total: 1,
    toc,
  });

  for (const [i, l] of lessons.entries()) {
    const p: Page = {
      title: `${l.lesson} - MoonBit Language Tour`,
      toc,
      markdown: l.markdown,
      code: l.code,
      back:
        i === 0
          ? `<a href="/index.html">Back</a>`
          : `<a href="/${scan.slug(lessons[i - 1])}/index.html">Back</a>`,
      next:
        i === lessons.length - 1
          ? `<span class="text-zinc-500">Next</span>`
          : `<a href="/${scan.slug(lessons[i + 1])}/index.html">Next</a>`,
      path: `${scan.slug(l)}/index.html`,
      index: l.index + 1,
      total: l.total,
    };
    pages.push(p);
  }

  return pages;
}

export function render(template: string, page: Page): string {
  return template
    .replace("%TITLE%", page.title)
    .replace("%TOC%", page.toc)
    .replace("%MARKDOWN%", remark.mdToHtml(page.markdown))
    .replace("%CODE%", shiki.renderMoonBitCode(page.code))
    .replace("%BACK%", page.back)
    .replace("%NEXT%", page.next)
    .replace("%INDEX%", page.index.toString())
    .replace("%TOTAL%", page.total.toString());
}

export function route(page: Page): string {
  return JSON.stringify({
    title: page.title,
    markdownHtml: remark.mdToHtml(page.markdown),
    code: page.code,
    back: page.back,
    next: page.next,
    index: page.index,
    total: page.total,
  });
}
