(() => {
  "use strict";

  const preloaded = globalThis.__moonbitSemanticHoverPayloads;
  let payloadPromise = preloaded && typeof preloaded === "object"
    ? Promise.resolve(preloaded)
    : undefined;
  let tooltip;
  let tooltipContent;
  let activeTarget;
  let targetHovered = false;
  let tooltipHovered = false;
  let openTimer;
  let closeTimer;
  let positionFrame;
  let generation = 0;
  let suppressedFocusTarget;

  const viewportMargin = 8;
  const tooltipGap = 6;
  const openDelay = 80;
  const closeDelay = 160;
  const hoverUrl = new URL("hovers.json", document.currentScript?.src || document.baseURI);
  const payloads = () => payloadPromise ||= fetch(hoverUrl, {credentials: "same-origin"})
    .then(response => response.ok ? response.json() : {})
    .catch(() => ({}));

  const clearOpenTimer = () => {
    if (openTimer !== undefined) {
      clearTimeout(openTimer);
      openTimer = undefined;
    }
  };

  const clearCloseTimer = () => {
    if (closeTimer !== undefined) {
      clearTimeout(closeTimer);
      closeTimer = undefined;
    }
  };

  const targetOrTooltipHasFocus = () => {
    const focused = document.activeElement;
    return Boolean(
      focused &&
      ((activeTarget && (focused === activeTarget || activeTarget.contains(focused))) ||
       (tooltip && tooltip.contains(focused)))
    );
  };

  const setTargetExpanded = (target, expanded) => {
    if (!target) return;
    target.setAttribute("aria-expanded", String(expanded));
    if (expanded) {
      target.setAttribute("aria-controls", "mbt-semantic-tooltip");
    } else {
      target.removeAttribute("aria-controls");
    }
  };

  const viewportRect = () => {
    const viewport = globalThis.visualViewport;
    return viewport
      ? {
          left: viewport.offsetLeft,
          top: viewport.offsetTop,
          right: viewport.offsetLeft + viewport.width,
          bottom: viewport.offsetTop + viewport.height,
        }
      : {left: 0, top: 0, right: innerWidth, bottom: innerHeight};
  };

  const position = () => {
    positionFrame = undefined;
    if (!tooltip || tooltip.hidden || !activeTarget || !activeTarget.isConnected) return;

    tooltip.style.visibility = "hidden";
    tooltip.style.removeProperty("--mbt-hover-max-height");
    const viewport = viewportRect();
    const box = activeTarget.getBoundingClientRect();
    const naturalHeight = tooltip.offsetHeight;
    const belowSpace = Math.max(
      0,
      viewport.bottom - box.bottom - tooltipGap - viewportMargin,
    );
    const aboveSpace = Math.max(
      0,
      box.top - viewport.top - tooltipGap - viewportMargin,
    );
    const placeBelow = belowSpace >= naturalHeight ||
      (aboveSpace < naturalHeight && belowSpace >= aboveSpace);
    const availableHeight = Math.max(1, placeBelow ? belowSpace : aboveSpace);
    tooltip.style.setProperty("--mbt-hover-max-height", `${availableHeight}px`);

    const width = tooltip.offsetWidth;
    const height = tooltip.offsetHeight;
    const minLeft = viewport.left + viewportMargin;
    const maxLeft = Math.max(minLeft, viewport.right - width - viewportMargin);
    const left = Math.max(minLeft, Math.min(box.left, maxLeft));
    const desiredTop = placeBelow
      ? box.bottom + tooltipGap
      : box.top - tooltipGap - height;
    const minTop = viewport.top + viewportMargin;
    const maxTop = Math.max(minTop, viewport.bottom - height - viewportMargin);
    const top = Math.max(minTop, Math.min(desiredTop, maxTop));

    tooltip.dataset.placement = placeBelow ? "bottom" : "top";
    tooltip.style.left = `${left}px`;
    tooltip.style.top = `${top}px`;
    tooltip.style.visibility = "";
  };

  const requestPosition = () => {
    if (!tooltip || tooltip.hidden || positionFrame !== undefined) return;
    positionFrame = requestAnimationFrame(position);
  };

  const ensureTooltip = () => {
    if (tooltip) return tooltip;
    tooltip = document.createElement("div");
    tooltip.id = "mbt-semantic-tooltip";
    tooltip.className = "mbt-semantic-tooltip";
    tooltip.role = "dialog";
    tooltip.setAttribute("aria-label", "Symbol information");
    tooltip.hidden = true;

    tooltipContent = document.createElement("div");
    tooltipContent.className = "mbt-semantic-tooltip__content";
    tooltipContent.tabIndex = -1;
    tooltip.appendChild(tooltipContent);
    document.body.appendChild(tooltip);

    tooltip.addEventListener("pointerenter", () => {
      tooltipHovered = true;
      clearCloseTimer();
    });
    tooltip.addEventListener("pointerleave", () => {
      tooltipHovered = false;
      scheduleHide();
    });
    tooltip.addEventListener("focusin", clearCloseTimer);
    tooltip.addEventListener("focusout", () => {
      queueMicrotask(() => scheduleHide());
    });

    if ("ResizeObserver" in globalThis) {
      new ResizeObserver(requestPosition).observe(tooltipContent);
    }
    return tooltip;
  };

  const hideNow = ({restoreFocus = false} = {}) => {
    clearOpenTimer();
    clearCloseTimer();
    generation += 1;
    const previousTarget = activeTarget;
    const restoreTargetFocus = Boolean(
      restoreFocus && previousTarget?.isConnected &&
      tooltip?.contains(document.activeElement),
    );
    setTargetExpanded(previousTarget, false);
    activeTarget = undefined;
    targetHovered = false;
    tooltipHovered = false;
    if (tooltip) tooltip.hidden = true;
    if (restoreTargetFocus) {
      suppressedFocusTarget = previousTarget;
      previousTarget.focus();
      queueMicrotask(() => {
        if (suppressedFocusTarget === previousTarget) suppressedFocusTarget = undefined;
      });
    }
  };

  function scheduleHide() {
    clearCloseTimer();
    closeTimer = setTimeout(() => {
      closeTimer = undefined;
      if (!targetHovered && !tooltipHovered && !targetOrTooltipHasFocus()) {
        hideNow();
      }
    }, closeDelay);
  }

  const mountPayload = raw => {
    if (raw && raw.kind === "html" && typeof raw.value === "string") {
      // This HTML is generated and sanitised by the Sphinx extension at build
      // time.  Runtime Markdown parsing or arbitrary LSP HTML is never accepted.
      tooltipContent.innerHTML = raw.value;
      return true;
    }
    const fallback = typeof raw === "string"
      ? raw
      : raw?.markdown || raw?.value || (raw == null ? "" : JSON.stringify(raw));
    tooltipContent.textContent = fallback;
    return fallback !== "";
  };

  const show = async target => {
    const id = target.dataset.mbtHover;
    if (!id) return;

    clearOpenTimer();
    if (!targetHovered && document.activeElement !== target && !target.contains(document.activeElement)) {
      return;
    }
    clearCloseTimer();
    if (activeTarget !== target) {
      setTargetExpanded(activeTarget, false);
      activeTarget = target;
    }
    const requestGeneration = ++generation;
    const all = await payloads();
    if (requestGeneration !== generation || activeTarget !== target) return;
    if (!targetHovered && !targetOrTooltipHasFocus()) return;
    const raw = all[id];
    if (raw == null) {
      hideNow();
      return;
    }

    ensureTooltip();
    if (!mountPayload(raw)) {
      hideNow();
      return;
    }
    tooltip.hidden = false;
    setTargetExpanded(target, true);
    position();
  };

  const scheduleShow = (target, delay = openDelay) => {
    clearOpenTimer();
    clearCloseTimer();
    if (activeTarget !== target) {
      setTargetExpanded(activeTarget, false);
      activeTarget = target;
      generation += 1;
    }
    openTimer = setTimeout(() => {
      openTimer = undefined;
      show(target);
    }, delay);
  };

  document.addEventListener("pointerover", event => {
    const target = event.target.closest?.("[data-mbt-hover]");
    if (!target || (event.relatedTarget && target.contains(event.relatedTarget))) return;
    targetHovered = true;
    scheduleShow(target);
  });

  document.addEventListener("pointerout", event => {
    const target = event.target.closest?.("[data-mbt-hover]");
    if (!target || (event.relatedTarget && target.contains(event.relatedTarget))) return;
    if (target === activeTarget) {
      targetHovered = false;
      clearOpenTimer();
    }
    if (tooltip && event.relatedTarget && tooltip.contains(event.relatedTarget)) {
      tooltipHovered = true;
      clearCloseTimer();
      return;
    }
    scheduleHide();
  });

  document.addEventListener("focusin", event => {
    const target = event.target.closest?.("[data-mbt-hover]");
    if (target && target === suppressedFocusTarget) {
      suppressedFocusTarget = undefined;
      return;
    }
    if (target) scheduleShow(target, 0);
  });

  document.addEventListener("focusout", event => {
    const target = event.target.closest?.("[data-mbt-hover]");
    if (!target) return;
    if (tooltip && event.relatedTarget && tooltip.contains(event.relatedTarget)) {
      clearCloseTimer();
      return;
    }
    queueMicrotask(() => scheduleHide());
  });

  document.addEventListener("keydown", event => {
    if (event.key === "Escape" && activeTarget) {
      event.preventDefault();
      hideNow({restoreFocus: true});
      return;
    }
    if (
      event.key === "ArrowDown" &&
      activeTarget &&
      !tooltip?.hidden &&
      (event.target === activeTarget || activeTarget.contains(event.target))
    ) {
      event.preventDefault();
      const interactive = tooltipContent.querySelector(
        "a[href], button:not([disabled]), [tabindex]:not([tabindex='-1'])",
      );
      (interactive || tooltipContent).focus();
    }
  });

  document.addEventListener("scroll", event => {
    if (tooltip && event.target && tooltip.contains(event.target)) return;
    requestPosition();
  }, true);
  globalThis.addEventListener("resize", requestPosition);
  globalThis.visualViewport?.addEventListener("resize", requestPosition);
  globalThis.visualViewport?.addEventListener("scroll", requestPosition);
})();
