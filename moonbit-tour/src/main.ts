import * as moonbitMode from "@moonbit/moonpad-monaco";
import lspWorker from "@moonbit/moonpad-monaco/lsp-server.js?worker";
import mooncWorker from "@moonbit/moonpad-monaco/moonc-worker.js?worker";
import wasmUrl from "@moonbit/moonpad-monaco/onig.wasm?url";
import * as monaco from "monaco-editor-core";
import editorWorker from "monaco-editor-core/esm/vs/editor/editor.worker?worker";
import "./style.css";

const moon = moonbitMode.init({
  onigWasmUrl: wasmUrl,
  lspWorker: new lspWorker(),
  mooncWorkerFactory: () => new mooncWorker(),
});

// @ts-ignore
self.MonacoEnvironment = {
  getWorker() {
    return new editorWorker();
  },
};

const sunSvg = `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
  <path stroke-linecap="round" stroke-linejoin="round" d="M12 3v2.25m6.364.386-1.591 1.591M21 12h-2.25m-.386 6.364-1.591-1.591M12 18.75V21m-4.773-4.227-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0Z" />
</svg>
`;

const moonSvg = `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
  <path stroke-linecap="round" stroke-linejoin="round" d="M21.752 15.002A9.72 9.72 0 0 1 18 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 0 0 3 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 0 0 9.002-5.998Z" />
</svg>
`;

let theme: "light" | "dark" = "light";
// TODO: Preserve theme across multiple pages of the tour.

const themeButton = document.querySelector<HTMLDivElement>("#theme")!;

function toggleTheme() {
  if (theme === "light") {
    theme = "dark";
    document.querySelector("html")?.classList.add("dark");
    monaco.editor.setTheme("dark-plus");
    themeButton.innerHTML = moonSvg;
  } else {
    theme = "light";
    document.querySelector("html")?.classList.remove("dark");
    monaco.editor.setTheme("light-plus");
    themeButton.innerHTML = sunSvg;
  }
}

themeButton.addEventListener("click", toggleTheme);

function debounce<P extends any[], R>(f: (...args: P) => R, timeout: number) {
  let timer: ReturnType<typeof setTimeout> | null = null;
  return (...args: P) => {
    if (timer !== null) {
      clearTimeout(timer);
    }
    timer = setTimeout(() => {
      f(...args);
      timer = null;
    }, timeout);
  };
}

const codePre = document.querySelector<HTMLPreElement>(".shiki")!;

const model = monaco.editor.createModel(codePre.textContent ?? "", "moonbit");

const output = document.querySelector<HTMLPreElement>("#output")!;

async function run() {
  const content = model.getValue();
  const result = await moon.compile({ libContents: [content] });
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
}

model.onDidChangeContent(debounce(run, 100));

monaco.editor.onDidCreateEditor(() => {
  codePre.remove();
});

const editor = document.getElementById("editor")!;
editor.classList.remove("pl-[10px]", "text-[14px]");
monaco.editor.create(editor, {
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
  theme: "light-plus",
});

run();
