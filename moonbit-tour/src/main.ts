import * as editor from "./editor";
import * as router from "./router";
import "./style.css";
import * as theme from "./theme";
import * as toc from "./toc";

router.init();
theme.init();
toc.init();

const markdown = document.querySelector<HTMLDivElement>("#tour-content")!;
const next = document.querySelector<HTMLDivElement>("#nav-next")!;
const back = document.querySelector<HTMLDivElement>("#nav-back")!;

window.addEventListener("route-change", async (e) => {
  const state = e.detail;
  editor.model.setValue(state.code);
  markdown.innerHTML = state.markdownHtml;
  next.innerHTML = state.next;
  back.innerHTML = state.back;
  document.title = state.title;
});
