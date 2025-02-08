const localeButton =
  document.querySelector<HTMLButtonElement>("#locale-button")!;
const locales = document.querySelector<HTMLDivElement>("#locales")!;

export function init() {
  localeButton.addEventListener("mouseenter", () => {
    locales.classList.remove("hidden");
  });
  localeButton.addEventListener("mouseleave", () => {
    locales.classList.add("hidden");
  });
}
