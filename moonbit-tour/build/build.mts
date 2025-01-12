import * as chokidar from "chokidar";
import * as esbuild from "esbuild";
import { tailwindPlugin } from "esbuild-plugin-tailwindcss";
import * as fs from "fs/promises";
import * as path from "path";
import * as page from "./page";

const isDev = process.env["DEV"] === "true";
const isWatch = process.argv.includes("--watch");

async function exists(path: string) {
  try {
    await fs.access(path);
    return true;
  } catch {
    return false;
  }
}

async function clearDirectory(dir: string) {
  if (!(await exists(dir))) return;
  const items = await fs.readdir(dir);
  await Promise.all(
    items.map((i) =>
      fs.rm(path.join(dir, i), { recursive: true, force: true }),
    ),
  );
}

const plugin = (): esbuild.Plugin => {
  return {
    name: "my-plugin",
    setup(build) {
      build.onStart(async () => {
        console.log("start build");
        build.initialOptions.outdir &&
          (await clearDirectory(build.initialOptions.outdir));
      });
      build.onEnd(async () => {
        console.log("end build");

        await fs.cp("./public", "./dist", { recursive: true });

        const names = ["lsp-server.js", "moonc-worker.js", "onig.wasm"];
        await Promise.all(
          names.map((name) => {
            fs.copyFile(
              `./node_modules/@moonbit/moonpad-monaco/dist/${name}`,
              `./dist/${name}`,
            );
          }),
        );

        const template = await fs.readFile("index.html", "utf8");

        const pages = await page.collectTourPage();
        await Promise.all(
          pages.map(async (p) => {
            const content = page.render(template, p);
            const data = page.route(p);
            await fs.mkdir(`./dist/${path.dirname(p.path)}`, {
              recursive: true,
            });
            await fs.writeFile(`./dist/${p.path}`, content, {
              encoding: "utf8",
            });
            await fs.writeFile(
              `./dist/${p.path.replace(".html", ".json")}`,
              data,
            );
          }),
        );
      });
    },
  };
};

const ctx = await esbuild.context({
  entryPoints: [
    "./src/main.ts",
    "./node_modules/monaco-editor-core/esm/vs/editor/editor.worker.js",
  ],
  bundle: true,
  minify: !isDev,
  format: "esm",
  outdir: "./dist",
  entryNames: "[name]",
  loader: {
    ".ttf": "file",
    ".woff2": "file",
  },
  drop: isDev ? [] : ["console", "debugger"],
  dropLabels: isDev ? [] : ["DEV"],
  plugins: [tailwindPlugin(), plugin()],
});

await ctx.rebuild();

if (!isDev) {
  process.exit(0);
}

if (isWatch) {
  chokidar
    .watch(["index.html", "src", "tour"], {
      ignoreInitial: true,
    })
    .on("all", async (e, path) => {
      console.log(`[watch] ${e} ${path}`);
      await ctx.rebuild();
    });
}
