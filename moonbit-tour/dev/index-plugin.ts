import * as fs from "fs/promises";
import * as vite from "vite";
import { BASE } from "./const";
import * as remark from "./remark";
import { scanTour, slug } from "./scan-tour";
import * as shiki from "./shiki";

const indexPlugin = (): vite.Plugin => {
  return {
    name: "dev-index-plugin",
    async transformIndexHtml(html) {
      const md = await fs.readFile("tour/index.md", "utf8");
      const mbt = await fs.readFile("tour/index.mbt", "utf8");
      const mdHtml = remark.mdToHtml(md);
      const mbtHtml = shiki.renderMoonBitCode(mbt);
      const lessons = (await scanTour()).flatMap((c) => c.lessons);
      return html
        .replace(
          "%HEAD%",
          `<link rel="icon" href="${BASE}/favicon.ico" />
  <title>moonbit tour</title>`,
        )
        .replace("%MARKDOWN%", mdHtml)
        .replace("%CODE%", mbtHtml)
        .replace("%BACK%", `<span class="text-zinc-500">Back</span>`)
        .replace(
          "%NEXT%",
          `<a href="${BASE}/${slug(lessons[0])}/index.html">Next</a>`,
        );
    },
  };
};

export default indexPlugin;
