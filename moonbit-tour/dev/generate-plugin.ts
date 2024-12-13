import fs from "fs/promises";
import path from "path";
import * as vite from "vite";
import { BASE } from "./const";
import { generateTOC, scanTour, slug } from "./scan-tour";

const head = `<link rel="icon" href="${BASE}/favicon.ico" />
    <title>%TITLE%</title>
    <script type="module" crossorigin src="${BASE}/assets/index.js"></script>
    <link rel="stylesheet" crossorigin href="${BASE}/assets/index.css">`;

const generatePlugin = (): vite.Plugin => {
  return {
    name: "generate-tour",
    async generateBundle(options, bundle) {
      const template = await fs.readFile("index.html", "utf8");
      const chapters = await scanTour();
      const lessons = chapters.flatMap((c) => c.lessons);
      for (const [i, l] of lessons.entries()) {
        let res = template
          .replace("%HEAD%", head)
          .replace("%TITLE%", `${l.lesson} - MoonBit Language Tour`)
          .replace("%MARKDOWN%", l.markdown)
          .replace("%CODE%", l.code)
          .replace(
            '      <script type="module" src="/src/main.ts"></script>',
            "",
          );
        if (i === 0) {
          res = res.replace("%BACK%", `<a href="${BASE}/index.html">Back</a>`);
        }
        if (i - 1 >= 0) {
          res = res.replace(
            "%BACK%",
            `<a href="${BASE}/${slug(lessons[i - 1])}/index.html">Back</a>`,
          );
        }
        if (i + 1 < lessons.length) {
          res = res.replace(
            "%NEXT%",
            `<a href="${BASE}/${slug(lessons[i + 1])}/index.html">Next</a>`,
          );
        }
        if (i === lessons.length - 1) {
          res = res.replace(
            "%NEXT%",
            `<span class="text-zinc-500">Next</span>`,
          );
        }
        this.emitFile({
          type: "asset",
          fileName: path.join(slug(l), "index.html"),
          source: res,
        });
      }
      const toc = generateTOC(chapters);
      this.emitFile({
        type: "asset",
        fileName: path.join("table-of-contents", "index.html"),
        source: template
          .replace("%HEAD%", head)
          .replace("%TITLE%", `Table of Contents - MoonBit Language Tour`)
          .replace("%MARKDOWN%", toc.markdown)
          .replace("%CODE%", toc.code)
          .replace("%BACK%", `<span class="text-zinc-500">Back</span>`)
          .replace("%NEXT%", `<span class="text-zinc-500">Next</span>`),
      });
    },
  };
};

export default generatePlugin;
