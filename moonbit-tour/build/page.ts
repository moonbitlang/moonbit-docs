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
    };
    pages.push(p);
  }

  const tocPage = scan.generateTOC(chapters);
  pages.push({
    title: `Table of Contents - MoonBit Language Tour`,
    toc,
    markdown: tocPage.markdown,
    code: tocPage.code,
    back: `<span class="text-zinc-500">Back</span>`,
    next: `<span class="text-zinc-500">Next</span>`,
    path: "table-of-contents/index.html",
  });
  return pages;
}

export function render(template: string, page: Page): string {
  return template
    .replace("%TITLE%", page.title)
    .replace("%TOC%", page.toc)
    .replace("%MARKDOWN%", remark.mdToHtml(page.markdown))
    .replace("%CODE%", shiki.renderMoonBitCode(page.code))
    .replace("%BACK%", page.back)
    .replace("%NEXT%", page.next);
}
