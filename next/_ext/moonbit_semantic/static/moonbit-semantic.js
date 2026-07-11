(() => {
  "use strict";
  let payloadPromise;
  let tooltip;
  const hoverUrl = new URL("hovers.json", document.currentScript?.src || document.baseURI);
  const payloads = () => payloadPromise ||= fetch(hoverUrl, {credentials: "same-origin"}).then(r => r.ok ? r.json() : {});
  const hide = () => { if (tooltip) tooltip.hidden = true; };
  const show = async target => {
    const id = target.dataset.mbtHover;
    if (!id) return;
    const all = await payloads();
    const raw = all[id];
    if (raw == null) return;
    tooltip ||= Object.assign(document.body.appendChild(document.createElement("div")), {className: "mbt-semantic-tooltip", role: "tooltip"});
    tooltip.textContent = typeof raw === "string" ? raw : raw.markdown || raw.value || JSON.stringify(raw);
    tooltip.hidden = false;
    const box = target.getBoundingClientRect();
    tooltip.style.left = `${Math.max(8, Math.min(box.left, innerWidth - tooltip.offsetWidth - 8))}px`;
    tooltip.style.top = `${Math.min(innerHeight - tooltip.offsetHeight - 8, box.bottom + 6)}px`;
  };
  document.addEventListener("pointerover", e => { const t = e.target.closest?.("[data-mbt-hover]"); if (t) show(t); });
  document.addEventListener("pointerout", e => { if (e.target.closest?.("[data-mbt-hover]")) hide(); });
  document.addEventListener("focusin", e => { const t = e.target.closest?.("[data-mbt-hover]"); if (t) show(t); });
  document.addEventListener("focusout", hide);
  document.addEventListener("keydown", e => { if (e.key === "Escape") hide(); });
})();
