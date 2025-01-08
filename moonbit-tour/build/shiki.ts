import * as fs from "fs";
import * as shiki from "shiki";

const moonbitLang = JSON.parse(
  fs.readFileSync("assets/syntax/moonbit.tmLanguage.json", "utf8"),
);

const highlighter = await shiki.createHighlighter({
  themes: ["light-plus"],
  langs: [moonbitLang],
});

function renderMoonBitCode(code: string): string {
  return highlighter.codeToHtml(code, {
    lang: "moonbit",
    theme: "light-plus",
  });
}

export { renderMoonBitCode };
