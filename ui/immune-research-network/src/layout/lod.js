(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  /**
   * Map zoom level to one of four approved information-density bands.
   * @param {number} zoom
   * @returns {"overview"|"structure"|"detail"|"inspect"}
   */
  function getLod(zoom) {
    if (zoom <= 0.55) return "overview";
    if (zoom <= 0.95) return "structure";
    if (zoom <= 1.45) return "detail";
    return "inspect";
  }

  IMMUNE.getLod = getLod;
})(globalThis);
