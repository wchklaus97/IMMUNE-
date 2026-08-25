(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  let toastTimer = null;

  function prefersReducedMotion() {
    return (
      typeof matchMedia !== "undefined" &&
      matchMedia("(prefers-reduced-motion: reduce)").matches
    );
  }

  function showToast(region, message) {
    if (!region) return;
    region.textContent = message;
    region.classList.add("visible");
    if (toastTimer) clearTimeout(toastTimer);
    toastTimer = setTimeout(() => {
      region.classList.remove("visible");
      region.textContent = "";
    }, prefersReducedMotion() ? 1500 : 3200);
  }

  /**
   * Play unlock feedback after successful research.
   */
  function playUnlockFeedback(svg, result, toastRegion) {
    const { ok, state, nodeId } = result;
    if (!ok) return;

    showToast(toastRegion, "研究完成，永久進度已更新。");

    const feedbackLayer = svg?.querySelector("#feedback-layer");
    if (!feedbackLayer) return;

    const pulse = document.createElementNS("http://www.w3.org/2000/svg", "circle");
    pulse.setAttribute("class", "unlock-pulse");
    pulse.setAttribute("r", "40");
    pulse.dataset.nodeId = nodeId || "";

    const nodeEl = svg.querySelector(`[data-node-id="${nodeId}"]`);
    if (nodeEl) {
      const transform = nodeEl.getAttribute("transform") || "";
      const match = /translate\(([^,]+),([^)]+)\)/.exec(transform);
      if (match) {
        pulse.setAttribute("cx", match[1]);
        pulse.setAttribute("cy", match[2]);
      }
    } else {
      pulse.setAttribute("cx", "1500");
      pulse.setAttribute("cy", "1500");
    }

    feedbackLayer.appendChild(pulse);

    const duration = prefersReducedMotion() ? 150 : 900;
    pulse.style.opacity = "1";
    if (prefersReducedMotion()) {
      pulse.style.transition = "opacity 150ms ease";
      requestAnimationFrame(() => {
        pulse.style.opacity = "0";
      });
    } else {
      pulse.style.transition = `r ${duration}ms ease, opacity ${duration}ms ease`;
      requestAnimationFrame(() => {
        pulse.setAttribute("r", "80");
        pulse.style.opacity = "0";
      });
    }

    setTimeout(() => pulse.remove(), duration + 50);

    for (const revealedId of result?.newlyRevealed || []) {
      const target = svg.querySelector(`[data-node-id="${revealedId}"]`);
      if (target) {
        target.classList.add("newly-revealed");
        setTimeout(() => target.classList.remove("newly-revealed"), duration + 200);
      }
    }
  }

  /**
   * Play a short membrane ping when a node is selected.
   */
  function playSelectFeedback(svg, nodeId) {
    const feedbackLayer = svg?.querySelector("#feedback-layer");
    if (!feedbackLayer || !nodeId) return;

    const pulse = document.createElementNS("http://www.w3.org/2000/svg", "circle");
    pulse.setAttribute("class", "select-pulse");
    pulse.setAttribute("r", "22");
    pulse.dataset.nodeId = nodeId;

    const nodeEl = svg.querySelector(`[data-node-id="${nodeId}"]`);
    if (nodeEl) {
      const transform = nodeEl.getAttribute("transform") || "";
      const match = /translate\(([^,]+),([^)]+)\)/.exec(transform);
      if (match) {
        pulse.setAttribute("cx", match[1]);
        pulse.setAttribute("cy", match[2]);
      }
    } else {
      pulse.setAttribute("cx", "1500");
      pulse.setAttribute("cy", "1500");
    }

    feedbackLayer.appendChild(pulse);
    const duration = prefersReducedMotion() ? 120 : 320;
    pulse.style.opacity = "1";
    requestAnimationFrame(() => {
      pulse.style.transition = prefersReducedMotion()
        ? "opacity 120ms ease"
        : `r ${duration}ms ease, opacity ${duration}ms ease`;
      pulse.setAttribute("r", "52");
      pulse.style.opacity = "0";
    });
    setTimeout(() => pulse.remove(), duration + 40);

    if (nodeEl) {
      nodeEl.classList.add("is-hot");
      setTimeout(() => nodeEl.classList.remove("is-hot"), duration + 80);
    }
  }

  IMMUNE.showToast = showToast;
  IMMUNE.playUnlockFeedback = playUnlockFeedback;
  IMMUNE.playSelectFeedback = playSelectFeedback;
})(globalThis);
