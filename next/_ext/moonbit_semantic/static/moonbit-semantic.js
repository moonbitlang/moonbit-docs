(() => {
  "use strict";
  const preloaded = globalThis.__moonbitSemanticHoverPayloads;
  let payloadPromise = preloaded && typeof preloaded === "object"
    ? Promise.resolve(preloaded)
    : undefined;
  let tooltip;
  let activeTarget;
  const viewportMargin = 8;
  const tooltipGap = 6;
  const hoverUrl = new URL("hovers.json", document.currentScript?.src || document.baseURI);
  const payloads = () => payloadPromise ||= fetch(hoverUrl, {credentials: "same-origin"})
    .then(r => r.ok ? r.json() : {})
    .catch(() => ({}));
  const hide = target => {
    if (target && activeTarget !== target) return;
    activeTarget = undefined;
    if (tooltip) tooltip.hidden = true;
  };
  const position = target => {
    tooltip.style.maxHeight = "";
    const box = target.getBoundingClientRect();
    const naturalHeight = tooltip.offsetHeight;
    const belowSpace = Math.max(0, innerHeight - box.bottom - tooltipGap - viewportMargin);
    const aboveSpace = Math.max(0, box.top - tooltipGap - viewportMargin);
    const placeBelow = belowSpace >= naturalHeight ||
      (aboveSpace < naturalHeight && belowSpace >= aboveSpace);
    const availableHeight = placeBelow ? belowSpace : aboveSpace;
    if (naturalHeight > availableHeight) {
      tooltip.style.maxHeight = `${availableHeight}px`;
    }
    const width = tooltip.offsetWidth;
    const height = tooltip.offsetHeight;
    const maxLeft = Math.max(viewportMargin, innerWidth - width - viewportMargin);
    const left = Math.max(viewportMargin, Math.min(box.left, maxLeft));
    const desiredTop = placeBelow
      ? box.bottom + tooltipGap
      : box.top - tooltipGap - height;
    const maxTop = Math.max(viewportMargin, innerHeight - height - viewportMargin);
    const top = Math.max(viewportMargin, Math.min(desiredTop, maxTop));
    tooltip.style.left = `${left}px`;
    tooltip.style.top = `${top}px`;
  };
  const show = async target => {
    const id = target.dataset.mbtHover;
    if (!id) return;
    activeTarget = target;
    const all = await payloads();
    if (activeTarget !== target) return;
    const raw = all[id];
    if (raw == null) {
      hide(target);
      return;
    }
    tooltip ||= Object.assign(document.body.appendChild(document.createElement("div")), {className: "mbt-semantic-tooltip", role: "tooltip"});
    tooltip.textContent = typeof raw === "string" ? raw : raw.markdown || raw.value || JSON.stringify(raw);
    tooltip.hidden = false;
    position(target);
  };
  document.addEventListener("pointerover", e => {
    const t = e.target.closest?.("[data-mbt-hover]");
    if (t && !(e.relatedTarget && t.contains(e.relatedTarget))) show(t);
  });
  document.addEventListener("pointerout", e => {
    const t = e.target.closest?.("[data-mbt-hover]");
    if (t && !(e.relatedTarget && t.contains(e.relatedTarget)) && t !== document.activeElement) hide(t);
  });
  document.addEventListener("focusin", e => { const t = e.target.closest?.("[data-mbt-hover]"); if (t) show(t); });
  document.addEventListener("focusout", e => {
    const t = e.target.closest?.("[data-mbt-hover]");
    if (t && !(e.relatedTarget && t.contains(e.relatedTarget))) hide(t);
  });
  document.addEventListener("keydown", e => { if (e.key === "Escape") hide(activeTarget); });
})();
