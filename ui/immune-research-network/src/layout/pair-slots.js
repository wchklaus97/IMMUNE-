(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  /** Fixed polar slots [angleDeg, radius] for fifteen dual-family groups. */
  const pairLayoutSlots = {
    TB: [300, 980],
    BM: [0, 980],
    MN: [60, 980],
    NA: [120, 980],
    AD: [180, 980],
    TD: [240, 980],
    TM: [330, 1060],
    BN: [30, 1060],
    MA: [90, 1060],
    ND: [150, 1060],
    TA: [210, 1060],
    BD: [270, 1060],
    TN: [0, 1150],
    BA: [60, 1150],
    MD: [120, 1150]
  };

  IMMUNE.pairLayoutSlots = pairLayoutSlots;
})(globalThis);
