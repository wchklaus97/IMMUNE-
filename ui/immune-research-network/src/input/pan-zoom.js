(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  /**
   * Create pan/zoom controller for tree viewport.
   */
  function createPanZoom(options) {
    const {
      viewport,
      minZoom = 0.22,
      maxZoom = 12,
      onChange
    } = options;

    let dragging = false;
    let lastX = 0;
    let lastY = 0;
    let view = { x: 1500, y: 1500, zoom: 0.55 };
    let liveRaf = 0;
    let commitTimer = 0;
    const pointers = new Map();
    let pinchDist = 0;
    let pinchZoom = 0.55;

    function clampZoom(z) {
      return Math.min(maxZoom, Math.max(minZoom, z));
    }

    function clampPan(next) {
      const margin = 300 / next.zoom;
      return {
        x: Math.min(3000 + margin, Math.max(-margin, next.x)),
        y: Math.min(3000 + margin, Math.max(-margin, next.y)),
        zoom: next.zoom
      };
    }

    function emitLive() {
      if (liveRaf) return;
      liveRaf = requestAnimationFrame(() => {
        liveRaf = 0;
        onChange?.(view, { live: true });
      });
    }

    function emitCommit() {
      if (liveRaf) {
        cancelAnimationFrame(liveRaf);
        liveRaf = 0;
      }
      if (commitTimer) {
        clearTimeout(commitTimer);
        commitTimer = 0;
      }
      onChange?.(view, { live: false, commit: true });
    }

    function setView(next, mode = "commit") {
      view = clampPan({ ...view, ...next, zoom: clampZoom(next.zoom ?? view.zoom) });
      if (mode === "live") emitLive();
      else emitCommit();
    }

    function zoomAt(factor, clientX, clientY) {
      const rect = viewport.getBoundingClientRect();
      const px = clientX - rect.left - rect.width / 2;
      const py = clientY - rect.top - rect.height / 2;
      const oldZoom = view.zoom;
      const newZoom = clampZoom(oldZoom * factor);
      const scale = newZoom / oldZoom;
      setView({
        zoom: newZoom,
        x: view.x + px * (1 - scale) / oldZoom,
        y: view.y + py * (1 - scale) / oldZoom
      }, "live");
      if (commitTimer) clearTimeout(commitTimer);
      commitTimer = setTimeout(() => emitCommit(), 120);
    }

    function pointerMidpoint() {
      const pts = [...pointers.values()];
      if (pts.length < 2) return null;
      return {
        x: (pts[0].x + pts[1].x) / 2,
        y: (pts[0].y + pts[1].y) / 2,
        dist: Math.hypot(pts[0].x - pts[1].x, pts[0].y - pts[1].y)
      };
    }

    function onPointerDown(event) {
      if (event.button !== 0 && event.pointerType !== "touch") return;
      pointers.set(event.pointerId, { x: event.clientX, y: event.clientY });
      try {
        viewport.setPointerCapture(event.pointerId);
      } catch {
        /* ignore */
      }
      if (pointers.size >= 2) {
        dragging = false;
        const mid = pointerMidpoint();
        pinchDist = mid?.dist || 1;
        pinchZoom = view.zoom;
        return;
      }
      dragging = true;
      lastX = event.clientX;
      lastY = event.clientY;
    }

    function onPointerMove(event) {
      if (!pointers.has(event.pointerId)) return;
      pointers.set(event.pointerId, { x: event.clientX, y: event.clientY });
      if (pointers.size >= 2) {
        const mid = pointerMidpoint();
        if (!mid || pinchDist < 8) return;
        const factor = mid.dist / pinchDist;
        const newZoom = clampZoom(pinchZoom * factor);
        zoomAt(newZoom / view.zoom, mid.x, mid.y);
        return;
      }
      if (!dragging) return;
      const dx = (event.clientX - lastX) / view.zoom;
      const dy = (event.clientY - lastY) / view.zoom;
      lastX = event.clientX;
      lastY = event.clientY;
      setView({ x: view.x - dx, y: view.y - dy }, "live");
    }

    function onPointerUp(event) {
      pointers.delete(event.pointerId);
      try {
        viewport.releasePointerCapture(event.pointerId);
      } catch {
        /* ignore */
      }
      if (pointers.size < 2) {
        pinchDist = 0;
      }
      if (pointers.size === 0) dragging = false;
      else if (pointers.size === 1) {
        const remain = [...pointers.values()][0];
        dragging = true;
        lastX = remain.x;
        lastY = remain.y;
      }
      emitCommit();
    }

    function onWheel(event) {
      event.preventDefault();
      const line =
        event.deltaMode === 1 ? 16 : event.deltaMode === 2 ? Math.max(viewport.clientHeight, 1) : 1;
      let dy = event.deltaY * line;
      if (event.ctrlKey || event.metaKey) dy *= 2.2;
      const factor = Math.exp(-dy * 0.0024);
      zoomAt(factor, event.clientX, event.clientY);
    }

    viewport.addEventListener("pointerdown", onPointerDown);
    viewport.addEventListener("pointermove", onPointerMove);
    viewport.addEventListener("pointerup", onPointerUp);
    viewport.addEventListener("pointercancel", onPointerUp);
    viewport.addEventListener("wheel", onWheel, { passive: false });

    return {
      getView: () => ({ ...view }),
      setView,
      fitAll() {
        setView({ x: 1500, y: 1500, zoom: 0.42 });
      },
      home() {
        setView({ x: 1500, y: 1500, zoom: 0.55 });
      },
      zoomAt,
      zoomBy(factor, clientX, clientY) {
        const rect = viewport.getBoundingClientRect();
        zoomAt(factor, clientX ?? rect.left + rect.width / 2, clientY ?? rect.top + rect.height / 2);
      },
      focusPoint(point, zoom = 5.2) {
        setView({ x: point.x, y: point.y, zoom: clampZoom(zoom) });
      },
      destroy() {
        if (liveRaf) cancelAnimationFrame(liveRaf);
        if (commitTimer) clearTimeout(commitTimer);
        viewport.removeEventListener("pointerdown", onPointerDown);
        viewport.removeEventListener("pointermove", onPointerMove);
        viewport.removeEventListener("pointerup", onPointerUp);
        viewport.removeEventListener("pointercancel", onPointerUp);
        viewport.removeEventListener("wheel", onWheel);
      }
    };
  }

  IMMUNE.createPanZoom = createPanZoom;
})(globalThis);
