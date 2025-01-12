import * as moonbitMode from "@moonbit/moonpad-monaco";
import * as monaco from "monaco-editor-core";
import * as util from "./util";

const moon = moonbitMode.init({
  onigWasmUrl: new URL("./onig.wasm", import.meta.url).toString(),
  lspWorker: new Worker("/lsp-server.js"),
  mooncWorkerFactory: () => new Worker("/moonc-worker.js"),
  codeLensFilter(l) {
    return l.command?.command === "moonbit-lsp/debug-main";
  },
});

// @ts-ignore
self.MonacoEnvironment = {
  getWorkerUrl: function () {
    return "/editor.worker.js";
  },
};

const codePre = document.querySelector<HTMLPreElement>(".shiki")!;
export const model = monaco.editor.createModel(
  codePre.textContent ?? "",
  "moonbit",
  monaco.Uri.file("/main.mbt"),
);

const output = document.querySelector<HTMLPreElement>("#output")!;
const trace = moonbitMode.traceCommandFactory();

async function run(debug: boolean) {
  if (debug) {
    const result = await moon.compile({
      libInputs: [["main.mbt", model.getValue()]],
      debugMain: true,
    });
    switch (result.kind) {
      case "success": {
        const js = result.js;
        const stream = await moon.run(js);
        let buffer = "";
        await stream.pipeTo(
          new WritableStream({
            write(chunk) {
              buffer += `${chunk}\n`;
            },
          }),
        );
        output.textContent = buffer;
        return;
      }
      case "error": {
        console.error(result.diagnostics);
      }
    }
    return;
  }
  const stdout = await trace(monaco.Uri.file("/main.mbt").toString());
  if (stdout === undefined) return;
  output.textContent = stdout;
}

model.onDidChangeContent(util.debounce(() => run(false), 100));

monaco.editor.onDidCreateEditor(() => {
  codePre.remove();
});

const editorContainer = document.getElementById("editor")!;
editorContainer.classList.remove("pl-[10px]", "text-[14px]");
monaco.editor.create(editorContainer, {
  model,
  lineNumbers: "off",
  glyphMargin: false,
  minimap: {
    enabled: false,
  },
  automaticLayout: true,
  folding: false,
  fontSize: 14,
  scrollBeyondLastLine: false,
  scrollbar: {
    alwaysConsumeMouseWheel: false,
  },
  fontFamily: "monospace",
  theme: util.getTheme() === "light" ? "light-plus" : "dark-plus",
});

monaco.editor.registerCommand("moonbit-lsp/debug-main", () => {
  run(true);
});

run(false);

window.addEventListener("theme-change", (e) => {
  monaco.editor.setTheme(e.detail === "light" ? "light-plus" : "dark-plus");
});
