function getRouteDataHref(href: string) {
  if (href.endsWith("/")) {
    return href + "index.json";
  } else if (href.endsWith("/index.html")) {
    return href.slice(0, -"/index.html".length) + "/index.json";
  } else {
    return href + "/index.json";
  }
}

async function getRouteData(href: string) {
  const url = getRouteDataHref(href);
  document.querySelector("html")!.classList.add("cursor-wait");
  const res = await fetch(url);
  document.querySelector("html")!.classList.remove("cursor-wait");
  return await res.json();
}

export async function init() {
  const state = await getRouteData(location.href);

  history.replaceState(state, "", location.href);

  window.addEventListener("popstate", (e) => {
    window.dispatchEvent(new CustomEvent("route-change", { detail: e.state }));
  });

  document.addEventListener("click", async (e) => {
    if (!(e.target instanceof HTMLAnchorElement)) return;
    const a = e.target;
    const url = new URL(a.href);
    if (url.origin !== location.origin) return;
    e.preventDefault();
    const data = await getRouteData(url.toString());
    history.pushState(data, "", url.toString());
    window.dispatchEvent(new CustomEvent("route-change", { detail: data }));
  });
}
