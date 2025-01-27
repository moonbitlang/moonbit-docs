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
  locale: "English" | "中文";
  enHref: string;
  zhHref: string;
  homePage: string;
  homePageHref: string;
};

async function chapterPages(
  chapters: scan.Chapter[],
  locale_: scan.Locale,
): Promise<Page[]> {
  const pages: Page[] = [];
  const lessons = chapters.flatMap((c) => c.lessons);
  const locale = locale_ === "en" ? "English" : "中文";
  const indexPath = locale_ === "en" ? "tour" : "tour/zh";
  const indexMd = await fs.readFile(`${indexPath}/index.md`, "utf8");
  const indexMbt = await fs.readFile(`${indexPath}/index.mbt`, "utf8");
  const toc = scan.renderTOC(chapters);
  const next = locale_ === "en" ? "Next" : "下一节";
  const back = locale_ === "en" ? "Back" : "上一节";
  const title = locale_ === "en" ? "MoonBit Language Tour" : "MoonBit 语言导览";
  const homePage = title;
  const homePageHref = locale_ === "en" ? "/index.html" : "/zh/index.html";
  pages.push({
    title,
    markdown: indexMd,
    code: indexMbt,
    back: `<span class="text-zinc-500">${back}</span>`,
    next: `<a href="/${scan.slug(lessons[0])}/index.html">${next}</a>`,
    path: locale_ === "en" ? "index.html" : "zh/index.html",
    index: 1,
    total: 1,
    toc,
    locale,
    enHref: "/index.html",
    zhHref: "/zh/index.html",
    homePage,
    homePageHref,
  });

  for (const [i, l] of lessons.entries()) {
    const path = `${scan.slug(l)}/index.html`;
    const p: Page = {
      title: `${l.lesson} - ${title}`,
      toc,
      markdown: l.markdown,
      code: l.code,
      back:
        i === 0
          ? `<a href="${homePageHref}">${back}</a>`
          : `<a href="/${scan.slug(lessons[i - 1])}/index.html">${back}</a>`,
      next:
        i === lessons.length - 1
          ? `<span class="text-zinc-500">${next}</span>`
          : `<a href="/${scan.slug(lessons[i + 1])}/index.html">${next}</a>`,
      path,
      index: l.index + 1,
      total: l.total,
      locale,
      enHref:
        locale_ === "en" ? `/${path}` : `/${path.slice(`${locale_}/`.length)}`,
      zhHref: locale_ === "en" ? `/zh/${path}` : `/${path}`,
      homePage,
      homePageHref,
    };
    pages.push(p);
  }
  return pages;
}

export async function collectTourPage(): Promise<Page[]> {
  const { en, zh } = await scan.scanTour();
  const enPages = await chapterPages(en, "en");
  const zhPages = await chapterPages(zh, "zh");
  return [...enPages, ...zhPages];
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
    .replace("%TOTAL%", page.total.toString())
    .replace("%LOCALE%", page.locale)
    .replace("%EN_HREF%", page.enHref)
    .replace("%ZH_HREF%", page.zhHref)
    .replace("%HOMEPAGE%", page.homePage)
    .replace("%HOMEPAGE_HREF%", page.homePageHref);
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
    locale: page.locale,
    enHref: page.enHref,
    zhHref: page.zhHref,
    homePage: page.homePage,
    homePageHref: page.homePageHref,
    toc: page.toc,
  });
}
