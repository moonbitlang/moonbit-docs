import * as editor from "./editor";
import * as locale from "./locale";
import * as router from "./router";
import "./style.css";
import * as theme from "./theme";
import * as toc from "./toc";

router.init();
theme.init();
toc.init();
locale.init();

const markdown = document.querySelector<HTMLDivElement>("#tour-content")!;
const next = document.querySelector<HTMLDivElement>("#nav-next")!;
const back = document.querySelector<HTMLDivElement>("#nav-back")!;
const lessonIndex = document.querySelector<HTMLSpanElement>("#lesson-index")!;
const lessonTotal = document.querySelector<HTMLSpanElement>("#lesson-total")!;
const localeText = document.querySelector<HTMLButtonElement>("#locale-text")!;
const enHref = document.querySelector<HTMLAnchorElement>("#en-href")!;
const zhHref = document.querySelector<HTMLAnchorElement>("#zh-href")!;
const homePage = document.querySelector<HTMLAnchorElement>("#homepage")!;
const tocDiv = document.querySelector<HTMLDivElement>("#toc")!;

window.addEventListener("route-change", async (e) => {
  const state = e.detail;
  editor.model.setValue(state.code);
  markdown.innerHTML = state.markdownHtml;
  next.innerHTML = state.next;
  back.innerHTML = state.back;
  document.title = state.title;
  lessonIndex.textContent = state.index.toString();
  lessonTotal.textContent = state.total.toString();
  localeText.innerText = state.locale;
  enHref.href = state.enHref;
  zhHref.href = state.zhHref;
  homePage.textContent = state.homePage;
  homePage.href = state.homePageHref;
  tocDiv.innerHTML = state.toc;
  toc.init();
});
