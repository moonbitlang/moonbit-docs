import * as fs from "fs";
import * as shiki from "shiki";

const moonbitLang = JSON.parse(
  fs.readFileSync("assets/syntax/moonbit.tmLanguage.json", "utf8"),
);

const highlighter = await shiki.createHighlighter({
  themes: ["light-plus", "dark-plus"],
  langs: [moonbitLang],
});

function renderMoonBitCode(code: string): string {
  return highlighter.codeToHtml(code, {
    lang: "moonbit",
    themes: {
      light: "light-plus",
      dark: "dark-plus",
    },
  });
}

export { renderMoonBitCode };
