(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  /**
   * Minimal immutable snapshot store with subscribe/dispatch.
   */
  function createStore(initialState) {
    let state = Object.freeze(structuredClone(initialState));
    const listeners = new Set();

    function getState() {
      return state;
    }

    function notify() {
      for (const listener of listeners) listener(state);
    }

    function subscribe(listener) {
      listeners.add(listener);
      return () => listeners.delete(listener);
    }

    function dispatch(action) {
      const next = reducer(state, action);
      if (next === state) return state;
      state = Object.freeze(next);
      notify();
      return state;
    }

    return { getState, subscribe, dispatch };
  }

  function reducer(state, action) {
    switch (action.type) {
      case "REPLACE_STATE":
        return structuredClone(action.state);
      case "SELECT_NODE":
        return {
          ...state,
          player: { ...state.player, selectedNodeId: action.nodeId ?? null }
        };
      case "SET_VIEW":
        return {
          ...state,
          player: {
            ...state.player,
            view: { ...state.player.view, ...action.view }
          }
        };
      case "SET_FILTERS":
        return { ...state, filters: { ...action.filters } };
      case "SET_SEARCH":
        return { ...state, searchQuery: action.query ?? "" };
      case "SET_VIEW_MODE":
        return { ...state, viewMode: action.mode === "list" ? "list" : "map" };
      case "SET_PLAYER":
        return { ...state, player: structuredClone(action.player) };
      case "SET_ROUTE_FOCUS":
        return { ...state, routeFocusId: action.nodeId ?? null };
      case "SET_PROTOCOL_DOCK_OPEN":
        return { ...state, protocolDockOpen: Boolean(action.open) };
      case "PUSH_CAMERA_BOOKMARK":
        return {
          ...state,
          cameraBookmark: state.player.view
            ? structuredClone(state.player.view)
            : null
        };
      default:
        return state;
    }
  }

  IMMUNE.createStore = createStore;
})(globalThis);
