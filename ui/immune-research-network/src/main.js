(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  function boot() {
    const catalog = IMMUNE.buildCatalog();
    const layout = IMMUNE.layoutCatalog(catalog);
    const edges = IMMUNE.buildEdges(catalog);
    const demoDefaults = IMMUNE.createDemoPlayer(catalog);
    const player = IMMUNE.loadPlayer(catalog, demoDefaults);

    const iconUrls = {};
    const store = IMMUNE.createStore({
      catalog,
      layout,
      edges,
      player,
      filters: {},
      searchQuery: "",
      viewMode: "map",
      routeFocusId: null,
      protocolDockOpen: true,
      cameraBookmark: null,
      iconUrls
    });

    const appRoot = document.getElementById("app");
    const shell = IMMUNE.mountResearchApp(appRoot, {
      onAction: handleShellAction
    });

    const panZoom = IMMUNE.createPanZoom({
      viewport: shell.viewport,
      minZoom: 0.22,
      maxZoom: 12,
      onChange(view, meta = {}) {
        store.dispatch({
          type: "SET_VIEW",
          view
        });
        if (meta.commit) {
          const state = store.getState();
          IMMUNE.savePlayer({ ...state.player, view });
        }
      }
    });

    panZoom.setView(player.view || { x: 1500, y: 1500, zoom: 0.55 });

    const keyboard = IMMUNE.createKeyboardGamepad({
      viewport: shell.viewport,
      catalog,
      layout,
      getPlayer: () => store.getState().player,
      onSelectNode: (nodeId) => selectNode(nodeId),
      onResearch: (nodeId) => performResearch(nodeId),
      onTrack: (nodeId, tracked) => performTrack(nodeId, tracked),
      onHome: () => panZoom.home(),
      onZoomIn: () => panZoom.zoomBy(1.28),
      onZoomOut: () => panZoom.zoomBy(1 / 1.28),
      onRestoreCamera: () => {
        const bookmark = store.getState().cameraBookmark;
        if (bookmark) panZoom.setView(bookmark);
        else panZoom.home();
      },
      onPushCameraBookmark: () => {
        store.dispatch({ type: "PUSH_CAMERA_BOOKMARK" });
      }
    });

    shell.viewport.addEventListener("click", (event) => {
      const target = event.target.closest("[data-node-id]");
      if (target) selectNode(target.getAttribute("data-node-id"));
    });

    shell.viewport.addEventListener("dblclick", (event) => {
      const target = event.target.closest("[data-node-id]");
      if (target) {
        const nodeId = target.getAttribute("data-node-id");
        const point = layout.get(nodeId);
        if (!point) return;
        const current = panZoom.getView().zoom;
        panZoom.focusPoint(point, current >= 6 ? 10.5 : 6.4);
        selectNode(nodeId);
        return;
      }
      panZoom.zoomBy(1.7, event.clientX, event.clientY);
    });

    store.subscribe(render);

    function buildViewModel(state) {
      const { emphasis } = IMMUNE.applyFilters(catalog, state.player, state.filters);
      const searchHits =
        state.searchQuery.trim().length > 0
          ? IMMUNE.searchCatalog(catalog, state.player, state.searchQuery)
          : [];
      const lod = IMMUNE.getLod(state.player.view?.zoom ?? 0.55);
      return {
        ...state,
        emphasis,
        searchHits,
        lod
      };
    }

    function persist(playerState) {
      IMMUNE.savePlayer(playerState);
    }

    function selectNode(nodeId) {
      store.dispatch({ type: "SELECT_NODE", nodeId });
      store.dispatch({ type: "SET_ROUTE_FOCUS", nodeId });
      const state = store.getState();
      persist({ ...state.player, selectedNodeId: nodeId });
      IMMUNE.playSelectFeedback?.(shell.svg, nodeId);
      if (shell.detailPanel) {
        shell.detailPanel.classList.remove("is-punched");
        void shell.detailPanel.offsetWidth;
        shell.detailPanel.classList.add("is-punched");
      }
    }

    function performTrack(nodeId, tracked) {
      const state = store.getState();
      const result = IMMUNE.trackNode(catalog, state.player, nodeId, tracked);
      if (!result.ok) {
        IMMUNE.showToast(shell.toastRegion, result.error || "無法追蹤");
        return;
      }
      store.dispatch({ type: "SET_PLAYER", player: result.state });
      persist(result.state);
    }

    function performResearch(nodeId) {
      const state = store.getState();
      const beforeRevealed = new Set(state.player.revealedNodeIds);
      const result = IMMUNE.researchNode(catalog, state.player, nodeId);
      if (!result.ok) {
        IMMUNE.showToast(shell.toastRegion, result.error || "研究失敗");
        return;
      }
      const newlyRevealed = result.state.revealedNodeIds.filter((id) => !beforeRevealed.has(id));
      store.dispatch({ type: "SET_PLAYER", player: result.state });
      persist(result.state);
      IMMUNE.playUnlockFeedback(shell.svg, { ...result, nodeId, newlyRevealed: newlyRevealed }, shell.toastRegion);
    }

    function performEquip(nodeId) {
      const state = store.getState();
      const result = IMMUNE.equipProtocol(catalog, state.player, nodeId);
      if (!result.ok) {
        IMMUNE.showToast(shell.toastRegion, result.error || "無法裝備");
        return;
      }
      store.dispatch({ type: "SET_PLAYER", player: result.state });
      persist(result.state);
    }

    function performUnequip(nodeId) {
      const state = store.getState();
      const result = IMMUNE.unequipProtocol(state.player, nodeId);
      if (!result.ok) {
        IMMUNE.showToast(shell.toastRegion, result.error || "無法卸下");
        return;
      }
      store.dispatch({ type: "SET_PLAYER", player: result.state });
      persist(result.state);
    }

    function handleShellAction(action) {
      switch (action.type) {
        case "SET_SEARCH":
          store.dispatch(action);
          if (action.query?.trim()) {
            const hits = IMMUNE.searchCatalog(catalog, store.getState().player, action.query);
            if (hits.length === 1) {
              selectNode(hits[0].id);
              const point = layout.get(hits[0].id);
              if (point) panZoom.focusPoint(point, 5.2);
            }
          }
          break;
        case "SET_FILTERS":
        case "SET_VIEW_MODE":
          store.dispatch(action);
          break;
        case "CAMERA_FIT_ALL":
          panZoom.fitAll();
          break;
        case "CAMERA_HOME":
          panZoom.home();
          break;
        case "CAMERA_FOCUS_ROUTE": {
          const focusId = store.getState().player.selectedNodeId;
          if (focusId) {
            store.dispatch({ type: "SET_ROUTE_FOCUS", nodeId: focusId });
            const point = layout.get(focusId);
            if (point) panZoom.focusPoint(point, 5.2);
          }
          break;
        }
        default:
          store.dispatch(action);
      }
    }

    let lastSceneKey = "";
    let lastLod = "";

    function sceneKey(state) {
      const player = state.player || {};
      return [
        player.selectedNodeId || "",
        (player.completedNodeIds || []).join(","),
        (player.trackedNodeIds || []).join(","),
        JSON.stringify(state.filters || {}),
        state.searchQuery || "",
        state.viewMode || "",
        state.routeFocusId || "",
        state.protocolDockOpen ? "1" : "0"
      ].join("|");
    }

    function render(state) {
      const viewModel = buildViewModel(state);
      const key = sceneKey(state);
      const lod = viewModel.lod;
      const cameraOnly = key === lastSceneKey && lod === lastLod;
      lastSceneKey = key;
      lastLod = lod;

      if (cameraOnly) {
        IMMUNE.applyCameraTransform?.(shell.svg, state.player.view);
        IMMUNE.renderMinimap(shell.minimap, viewModel, {
          onPanTo: (point) => {
            const current = store.getState().player.view?.zoom ?? 0.55;
            panZoom.setView({ x: point.x, y: point.y, zoom: current });
          }
        }, { cameraOnly: true });
        return;
      }

      IMMUNE.renderAppChrome(shell, viewModel);
      IMMUNE.renderTreeMap(shell.svg, viewModel);
      IMMUNE.renderDetailPanel(shell.detailPanel, viewModel, {
        onSelectNode: selectNode,
        onResearch: performResearch,
        onTrack: performTrack
      });
      IMMUNE.renderMinimap(shell.minimap, viewModel, {
        onPanTo: (point) => {
          const current = store.getState().player.view?.zoom ?? 0.55;
          panZoom.setView({ x: point.x, y: point.y, zoom: current });
        }
      });
      IMMUNE.renderProtocolDock(shell.protocolDock, viewModel, {
        onEquip: performEquip,
        onUnequip: performUnequip
      });
      IMMUNE.renderResearchList(shell.researchList, viewModel, {
        onSelectNode: selectNode,
        onSwitchToMap: () => store.dispatch({ type: "SET_VIEW_MODE", mode: "map" })
      });

      shell.viewport.classList.toggle("hidden", viewModel.viewMode === "list");
      shell.researchList.classList.toggle("hidden", viewModel.viewMode !== "list");
      shell.minimap.style.display = viewModel.viewMode === "list" ? "none" : "";
    }

    render(store.getState());

    IMMUNE.assets?.loadManifest().then(async () => {
      const urls = await Promise.all(
        catalog.nodes.map((node) => IMMUNE.assets.getNodeIconUrl(node.id))
      );
      catalog.nodes.forEach((node, index) => {
        iconUrls[node.id] = urls[index];
      });
      render(store.getState());
    });

    IMMUNE._app = { store, panZoom, keyboard, shell, catalog, layout };
    IMMUNE.applyCoverMode?.(IMMUNE._app);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot);
  } else {
    boot();
  }
})(globalThis);
