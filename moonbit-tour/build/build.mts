import * as chokidar from "chokidar";
import * as esbuild from "esbuild";
import { tailwindPlugin } from "esbuild-plugin-tailwindcss";
import * as fs from "fs/promises";
import * as http from "http";
import * as path from "path";
import * as page from "./page";

const isDev = process.env["DEV"] === "true";
const isWatch = process.argv.includes("--watch");
const isBuild = process.argv.includes("--build");

const plugin = (): esbuild.Plugin => {
  return {
    name: "my-plugin",
    setup(build) {
      build.onStart(async () => {
        console.log("start build");
        build.initialOptions.outdir &&
          (await fs.rm(build.initialOptions.outdir, {
            recursive: true,
            force: true,
          }));
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
            await fs.mkdir(`./dist/${path.dirname(p.path)}`, {
              recursive: true,
            });
            await fs.writeFile(`./dist/${p.path}`, content, {
              encoding: "utf8",
            });
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
  banner: isDev
    ? {
        js: '(() => new EventSource("/esbuild").onmessage = () => location.reload())();',
      }
    : undefined,
  plugins: [tailwindPlugin(), plugin()],
});

await ctx.rebuild();

if (isBuild) {
  process.exit(0);
}

const clients: http.ServerResponse[] = [];

if (isDev) {
  const { host, port } = await ctx.serve({
    servedir: "dist",
  });
  const server = http.createServer((req, res) => {
    if (req.url === "/esbuild") {
      clients.push(
        res.writeHead(200, {
          "Content-Type": "text/event-stream",
          "Cache-Control": "no-cache",
          Connection: "keep-alive",
        }),
      );
      return;
    }
    req.pipe(
      http.request(
        {
          host,
          port,
          path: req.url,
          method: req.method,
          headers: req.headers,
        },
        (prxRes) => {
          res.writeHead(prxRes.statusCode || 0, prxRes.headers);
          prxRes.pipe(res, { end: true });
        },
      ),
      { end: true },
    );
  });
  server.listen(3000);
  console.log(`Local: http://localhost:3000`);
}

if (isWatch) {
  chokidar
    .watch(["index.html", "src", "tour"], {
      ignoreInitial: true,
    })
    .on("all", async (e, path) => {
      console.log(`[watch] ${e} ${path}`);
      await ctx.rebuild();
      clients.forEach((res) => res.write("data: update\n\n"));
      clients.length = 0;
    });
}
