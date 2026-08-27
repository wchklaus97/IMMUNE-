(function (global) {
  const IMMUNE = global.IMMUNE || (global.IMMUNE = {});

  /**
   * Character identity model: lineage + logic, then one characteristic set
   * per catalog id. Art generation must read this file; do not invent IDs
   * and do not stamp TB visuals onto other bodies.
   */
  const LOGIC = {
    order: ["identity", "catalog", "fixed", "mobile"],
    rules: [
      "只跟 catalog id、中文名、職責、本檔特徵走；不跟家族零件表走。",
      "一隻角色只有一張臉、一顆分不開的身體。炮台／移動是同一隻的兩種姿勢。",
      "融合不是 1 級基礎臉加小零件。2 級要換新剪影，3 級再更強、更複雜。",
      "基礎頭標（T 孔、B 三包、M 窩、N 鰭、A 准星、D 角）可以蓋住、融化或改寫，不要原樣留著。",
      "顏色跟材料跟家族走；身份跟新剪影走。落地，不寫字母。",
      "禁止把記憶獵手当模具。參考圖只能是該角色自己的目錄臉（或本檔）。",
      "禁止胸口 Y、金屬 Y 冠、膜上成林的 C／Y 夾、同一顆高爾夫皮複製到全員。",
      "兩隻並排必須剪影不同；只換漸層算不合格。",
      "CHAR-BASE-* 與已鎖 12 張基礎 3D 禁止重畫。",
      "已鎖融合目錄臉禁止重畫：CHAR-PAIR-TA 精準抗體、CHAR-PAIR-BN 標記處決、CHAR-PAIR-AD 免疫網絡、CHAR-TRIPLE-MAD 組織防衛聖域、CHAR-PRIME 全域免疫核心。",
      "綠幕 #00FF00，正面目錄鏡頭，主體約 70%。"
    ]
  };

  const ATTACK_VFX = {
    T: { idleMouth: "小圓嘴孔", attack: "從嘴噴一條橘細胞毒柱", standout: "單柱、近距毒殺" },
    B: { idleMouth: "略寬軟口", attack: "從嘴扇出紫金抗體滴，不是字母 Y", standout: "多滴播種" },
    M: { idleMouth: "大吞口", attack: "嘴裂開把目標吸進去", standout: "吞噬不是射擊" },
    N: { idleMouth: "細刃縫", attack: "從嘴射出一條細毒針", standout: "刺殺線" },
    A: { idleMouth: "精準噴嘴", attack: "懸浮，從嘴打出會拐彎的金導引線", standout: "鎖定追蹤" },
    D: { idleMouth: "廣播小口", attack: "從嘴放出掃描光錐，冠瓣一起亮", standout: "情報錐不是子彈" }
  };
  const FORBID_GLOBAL = [
    "chest Y glow or gold Y medallion",
    "skin forest of C/Y pincer nubs copied from TB",
    "identical golf-ball bump shader on every body",
    "two bodies, split paint, unscrewable kits",
    "letters, text, watermark",
    "generic five blob turret feet copied across the set"
  ];

  function entry(partial) {
    return {
      artLocked: false,
      hover: false,
      catalogStatus: "needs_redraw",
      formStatus: "needs_redraw",
      ...partial
    };
  }

  const CHARACTERS = {
    "CHAR-BASE-T": entry({
      name: "T 細胞",
      families: ["T"],
      duty: "適應毒殺",
      artLocked: true,
      catalogStatus: "locked",
      formStatus: "locked",
      silhouette: { catalog: "locked CHAR-BASE-T.png", fixed: "locked turret", mobile: "locked wheels" },
      skin: "locked orange cytotoxic jelly",
      unique: "已鎖基礎，不重畫"
    }),
    "CHAR-BASE-B": entry({
      name: "B 細胞",
      families: ["B"],
      duty: "抗體分泌",
      artLocked: true,
      catalogStatus: "locked",
      formStatus: "locked",
      silhouette: { catalog: "locked CHAR-BASE-B.png", fixed: "locked", mobile: "locked" },
      skin: "locked violet jelly",
      unique: "已鎖基礎，不重畫。Y 只屬於這一隻基礎與記憶獵手，不外借。"
    }),
    "CHAR-BASE-M": entry({
      name: "巨噬細胞",
      families: ["M"],
      duty: "吞噬回收",
      artLocked: true,
      catalogStatus: "locked",
      formStatus: "locked",
      silhouette: { catalog: "locked CHAR-BASE-M.png", fixed: "locked", mobile: "locked" },
      skin: "locked lavender macrophage jelly — material lock",
      unique: "已鎖基礎，不重畫"
    }),
    "CHAR-BASE-N": entry({
      name: "NK 細胞",
      families: ["N"],
      duty: "天然獵殺",
      artLocked: true,
      catalogStatus: "locked",
      formStatus: "locked",
      silhouette: { catalog: "locked CHAR-BASE-N.png", fixed: "locked", mobile: "locked" },
      skin: "locked olive jelly",
      unique: "已鎖基礎，不重畫"
    }),
    "CHAR-BASE-A": entry({
      name: "抗體構造體",
      families: ["A"],
      duty: "抗原中和 · 固定中繼",
      artLocked: true,
      hover: true,
      catalogStatus: "locked",
      formStatus: "locked",
      silhouette: { catalog: "locked CHAR-BASE-A.png", fixed: "locked hover turret", mobile: "locked relay hover" },
      skin: "locked gold jelly",
      unique: "已鎖基礎，不重畫。移動檔是中繼不是輪。"
    }),
    "CHAR-BASE-D": entry({
      name: "樹突細胞",
      families: ["D"],
      duty: "抗原掃描 · 免疫信標",
      artLocked: true,
      catalogStatus: "locked",
      formStatus: "locked",
      silhouette: { catalog: "locked CHAR-BASE-D.png", fixed: "locked", mobile: "locked" },
      skin: "locked dendritic orange jelly",
      unique: "已鎖基礎，不重畫"
    }),

    "CHAR-PAIR-TB": entry({
      name: "記憶獵手",
      families: ["T", "B"],
      duty: "帶著記憶去打獵",
      catalogStatus: "keep_catalog",
      formStatus: "pilot_forms",
      unique: "皮下琥珀記憶光可以有，但是霧光不是字母。頭髮只是果凍叢，禁止 C／Y 夾當髮刺。",
      silhouette: {
        catalog: "one wet sphere, one face, memory-glow under skin",
        fixed: "planted hunter nest — flared jelly saucer unique to this belly",
        mobile: "same hunter rolling on jelly wheels grown from this belly"
      },
      skin: "smooth orange-to-violet membrane; sparse papillae not a pincer forest"
    }),
    "CHAR-PAIR-TM": entry({
      name: "吞噬突擊",
      families: ["T", "M"],
      duty: "衝上去把目標吞掉",
      catalogStatus: "pilot_catalog",
      unique: "身體前方是吞口／食窪，像正在咬進戰場。沒有胸口 Y。",
      silhouette: {
        catalog: "front swallow-cleft sphere, hungry face, side masses as chew-cheeks",
        fixed: "belly slumped into the floor as if engulfing the ground",
        mobile: "lunge-roll, mouth-cleft leading"
      },
      skin: "orange into lavender, wet, few large chew-folds not hundreds of identical nubs"
    }),
    "CHAR-PAIR-TN": entry({
      name: "細胞毒刃",
      families: ["T", "N"],
      duty: "把細胞毒收成一刃",
      catalogStatus: "pilot_catalog",
      unique: "整顆身體是一把毒刃，有脊、有刃緣。不是加特林臉、不是 Y。",
      silhouette: {
        catalog: "keeled blade-body, edge facing camera",
        fixed: "blade stabbed into place, no wheels",
        mobile: "body streamed forward like a thrown knife"
      },
      skin: "orange-olive toxin sheen, sharp highlight along the keel"
    }),
    "CHAR-PAIR-TA": entry({
      name: "精準抗體",
      families: ["T", "A"],
      duty: "鎖定後精準中和",
      hover: true,
      artLocked: true,
      catalogStatus: "locked",
      formStatus: "locked",
      unique: "已鎖。懸浮瞄準筒就是身體，頂部開井。禁止重畫 CHAR-PAIR-TA-alt.png。",
      silhouette: {
        catalog: "locked CHAR-PAIR-TA-alt.png hovering scope-cylinder",
        fixed: "locked shared catalog face",
        mobile: "locked shared catalog face"
      },
      skin: "locked orange-gold wet-gel cylinder"
    }),
    "CHAR-PAIR-TD": entry({
      catalogStatus: "pilot_catalog",
      name: "免疫指揮",
      families: ["T", "D"],
      duty: "在場上發令",
      unique: "指揮冠是信號枝，像活的指揮塔，不是複製樹突貼紙。",
      silhouette: {
        catalog: "upright commander with a unique antler-crown",
        fixed: "crown spread as a rooted signal post",
        mobile: "crown swept back, relocating the post"
      },
      skin: "command orange, crown translucent, body less busy than TB"
    }),
    "CHAR-PAIR-BM": entry({
      name: "抗原處理",
      families: ["B", "M"],
      duty: "把抗原拆開處理",
      catalogStatus: "pilot_catalog",
      unique: "肚子是處理室：可見分選囊袋。禁止胸口 Y。",
      silhouette: {
        catalog: "workshop-gut sphere, chambers under the face",
        fixed: "chambers planted, processing in place",
        mobile: "chambers sloshing as it relocates"
      },
      skin: "violet-lavender, internal pockets, smooth outer membrane"
    }),
    "CHAR-PAIR-BN": entry({
      name: "標記處決",
      families: ["B", "N"],
      duty: "先標記再處決",
      artLocked: true,
      catalogStatus: "locked",
      formStatus: "locked",
      unique: "已鎖。面罩罩住上半頭的紫橄欖濕凝膠體。禁止重畫 CHAR-PAIR-BN-alt.png。",
      silhouette: {
        catalog: "locked CHAR-PAIR-BN-alt.png hooded brand-visor blob",
        fixed: "locked shared catalog face",
        mobile: "locked shared catalog face"
      },
      skin: "locked violet-olive wet-gel visor"
    }),
    "CHAR-PAIR-BA": entry({
      catalogStatus: "pilot_catalog",
      name: "抗體風暴",
      families: ["B", "A"],
      duty: "抗體像天氣一樣罩過去",
      hover: true,
      unique: "一隻身體，膜外有風暴緞帶在轉，不是插滿 Y。",
      silhouette: {
        catalog: "hover sphere wrapped in living storm ribbons",
        fixed: "storm held as a stationary cell",
        mobile: "storm stretched into travel"
      },
      skin: "violet-gold, ribbons are membrane not metal"
    }),
    "CHAR-PAIR-BD": entry({
      catalogStatus: "pilot_catalog",
      name: "抗原呈現",
      families: ["B", "D"],
      duty: "把抗原舉給別人看",
      unique: "腹前長出展示托盤／講台膜，像活的呈現台。",
      silhouette: {
        catalog: "lectern-belly sphere presenting a held sample-lobe",
        fixed: "lectern planted",
        mobile: "lectern tucked while moving"
      },
      skin: "violet-orange, one presentation lobe, no Y forest"
    }),
    "CHAR-PAIR-MN": entry({
      catalogStatus: "pilot_catalog",
      name: "感染清除",
      families: ["M", "N"],
      duty: "把感染刮乾淨",
      unique: "從標記處決那張面罩果凍臉延伸：紫罩、檸綠臉，雙手寬刮板＋下緣刮裙。禁止改 BN 原圖。",
      silhouette: {
        catalog: "BN-face extended with paddle hands and scraper-skirt",
        fixed: "skirt splayed as a cleanse pad",
        mobile: "skirt trailing like a mop-charge"
      },
      skin: "lavender-olive, cleaner fewer bumps"
    }),
    "CHAR-PAIR-MA": entry({
      catalogStatus: "pilot_catalog",
      name: "免疫壁壘",
      families: ["M", "A"],
      duty: "變成牆擋住",
      unique: "從標記處決那張面罩果凍臉延伸：紫罩、檸綠臉，額上厚面罩＋寬盾腹。禁止改 BN 原圖。",
      silhouette: {
        catalog: "BN-face extended with brow visor and shield-belly",
        fixed: "dome locked as a wall",
        mobile: "dome tilted into a flying shield"
      },
      skin: "lavender-gold, flatter, sparse surface"
    }),
    "CHAR-PAIR-MD": entry({
      catalogStatus: "pilot_catalog",
      name: "抗原中樞",
      families: ["M", "D"],
      duty: "抗原在這裡交會",
      unique: "輻射接口像交換機，孔口長在赤道。",
      silhouette: {
        catalog: "hub sphere with radial ports",
        fixed: "ports open as a station",
        mobile: "ports folded for transit"
      },
      skin: "lavender-orange, port rims, quiet skin between"
    }),
    "CHAR-PAIR-NA": entry({
      catalogStatus: "pilot_catalog",
      name: "抗體追獵",
      families: ["N", "A"],
      duty: "帶著抗體去追",
      hover: true,
      unique: "前傾獵犬體，鼻／額是追蹤凹槽，懸浮。",
      silhouette: {
        catalog: "lean hound-hover, nose-notch forward",
        fixed: "hovering lock-on hound",
        mobile: "stretched pursuit hover"
      },
      skin: "olive-gold, sleek, almost no nubs"
    }),
    "CHAR-PAIR-ND": entry({
      catalogStatus: "pilot_catalog",
      name: "獵殺信標",
      families: ["N", "D"],
      duty: "當燈塔給獵殺照明",
      unique: "直立燈塔冠，光從冠頂來，不是胸口 Y。",
      silhouette: {
        catalog: "beacon-tower on a round body",
        fixed: "beacon planted",
        mobile: "beacon tilted while rolling"
      },
      skin: "olive-orange, crown glow, dark quiet hull"
    }),
    "CHAR-PAIR-AD": entry({
      name: "免疫網絡",
      families: ["A", "D"],
      duty: "把免疫連成網",
      hover: true,
      artLocked: true,
      catalogStatus: "locked",
      formStatus: "locked",
      unique: "已鎖。金橙網結就是身體，標準濕凝膠臉。禁止重畫 CHAR-PAIR-AD-alt.png。",
      silhouette: {
        catalog: "locked CHAR-PAIR-AD-alt.png gold mesh-knot",
        fixed: "locked shared catalog face",
        mobile: "locked shared catalog face"
      },
      skin: "locked gold-orange wet-gel mesh"
    }),

    "CHAR-TRIPLE-TBA": entry({
      catalogStatus: "pilot_catalog",
      name: "適應免疫核心",
      families: ["T", "B", "A"],
      duty: "三系適應核心",
      hover: true,
      unique: "身體像正在改寫自己：色塊在膜下流動，仍是一張臉。懸浮。無胸口 Y。",
      silhouette: {
        catalog: "rewriting core, shifting inner patches",
        fixed: "hover core locked",
        mobile: "hover core streaming"
      },
      skin: "orange-violet-gold mix as weather under one membrane"
    }),
    "CHAR-TRIPLE-TND": entry({
      catalogStatus: "pilot_catalog",
      name: "全域截擊中樞",
      families: ["T", "N", "D"],
      duty: "全域攔截指揮",
      unique: "能走的果凍截擊：短手水窪腳，雙臂是凝膠長矛。禁止肌肉人、翼肩。",
      silhouette: {
        catalog: "gel-walker lance-arm interceptor",
        fixed: "keel planted as a hub",
        mobile: "keel as a rushing prow"
      },
      skin: "orange-olive command, large planes not nub forest"
    }),
    "CHAR-TRIPLE-MAD": entry({
      name: "組織防衛聖域",
      families: ["M", "A", "D"],
      duty: "把組織護成聖域",
      artLocked: true,
      catalogStatus: "locked",
      formStatus: "locked",
      unique: "已鎖。能走，肩上金光環領，胸口實心。禁止重畫 CHAR-TRIPLE-MAD-alt.png。",
      silhouette: {
        catalog: "locked CHAR-TRIPLE-MAD-alt.png walking halo-collar",
        fixed: "locked shared catalog face",
        mobile: "locked shared catalog face"
      },
      skin: "locked lavender-gold halo-collar"
    }),
    "CHAR-TRIPLE-BMD": entry({
      catalogStatus: "pilot_catalog",
      name: "組織再生工廠",
      families: ["B", "M", "D"],
      duty: "在場上長回組織",
      unique: "工廠肚：出芽的修復瓣，像正在生產。無 Y。",
      silhouette: {
        catalog: "factory-gut with budding repair lobes",
        fixed: "lobes planted as a plant",
        mobile: "lobes tucked, still one body"
      },
      skin: "violet-lavender-orange, budding not pincer forest"
    }),
    "CHAR-TRIPLE-BNA": entry({
      catalogStatus: "pilot_catalog",
      name: "抗體獵殺蜂群",
      families: ["B", "N", "A"],
      duty: "一隻身體裡的蜂群獵殺",
      hover: true,
      unique: "一張臉，身邊癒合著小同胞芽（仍分不開）。懸浮。不是許多 Y。",
      silhouette: {
        catalog: "hive-one with fused sibling buds",
        fixed: "hover hive locked",
        mobile: "hover hive in flight"
      },
      skin: "violet-olive-gold, buds are the same membrane"
    }),
    "CHAR-TRIPLE-TMN": entry({
      catalogStatus: "pilot_catalog",
      name: "凋亡反應爐",
      families: ["T", "M", "N"],
      duty: "把凋亡當爐火",
      unique: "爐腹：內熱、裂開的反應口，不是刃也不是 Y。",
      silhouette: {
        catalog: "chunky furnace-belly with an inner fire mouth",
        fixed: "furnace seated",
        mobile: "furnace rumbling on the move"
      },
      skin: "orange-lavender-olive, heat glow from inside"
    }),

    "CHAR-APEX-MEMORY": entry({
      catalogStatus: "pilot_catalog",
      name: "長期免疫記憶庫",
      families: ["T", "B", "A", "D"],
      duty: "把記憶存成庫",
      hover: true,
      unique: "層疊琥珀檔案層，像圖書館長在細胞裡。光是層，不是胸口 Y 字母。",
      silhouette: {
        catalog: "stacked archive strata in one sphere",
        fixed: "archive hovering as a vault",
        mobile: "archive drifting"
      },
      skin: "quiet amber layers, almost no nubs"
    }),
    "CHAR-APEX-STERILE": entry({
      catalogStatus: "pilot_catalog",
      name: "無菌聖域",
      families: ["M", "A", "D"],
      duty: "維持無菌",
      hover: true,
      unique: "能走的無菌體：淡金白、極光滑，短手水窪腳。禁止黃蛋無手脚、禁止抄 MAD 金環領。",
      silhouette: {
        catalog: "pale glass-clean gel walker",
        fixed: "sterile ward hover",
        mobile: "sterile travel hover"
      },
      skin: "pale gold, glass-clean, blackout-forbidden"
    }),
    "CHAR-APEX-SILENT": entry({
      catalogStatus: "pilot_catalog",
      name: "靜默獵殺網",
      families: ["T", "N", "A"],
      duty: "不出聲地網殺",
      hover: true,
      unique: "暗、扁、網緣，少五官高光。安靜。",
      silhouette: {
        catalog: "muted net-disc with a quiet face",
        fixed: "net hovering as a trap",
        mobile: "net gliding"
      },
      skin: "dark olive-gold, matte-wet, almost featureless hull"
    }),
    "CHAR-PRIME": entry({
      name: "IMMUNE PRIME",
      families: ["T", "B", "M", "N", "A", "D"],
      duty: "六系合一的最終體",
      artLocked: true,
      catalogStatus: "locked",
      formStatus: "locked",
      unique: "已鎖。能走的皇帝，腹內六色核心圍成一圈，中間一顆金心。禁止重畫 CHAR-PRIME-alt.png。",
      silhouette: {
        catalog: "locked CHAR-PRIME-alt.png six-core ring emperor",
        fixed: "locked shared catalog face",
        mobile: "locked shared catalog face"
      },
      skin: "locked imperial gel, six cores around a gold heart"
    })
  };

  function listNeedingCatalogRedraw() {
    return Object.entries(CHARACTERS)
      .filter(
        ([, c]) =>
          !c.artLocked &&
          c.catalogStatus !== "keep_catalog" &&
          c.catalogStatus !== "pilot_catalog"
      )
      .map(([id]) => id);
  }

  function listNeedingFormRedraw() {
    return Object.entries(CHARACTERS)
      .filter(([, c]) => !c.artLocked && c.formStatus !== "pilot_forms")
      .map(([id]) => id);
  }

  function artBrief(id, form) {
    const c = CHARACTERS[id];
    if (!c) return "";
    const sil = c.silhouette?.[form] || c.silhouette?.catalog || "";
    return [
      `IMMUNE 2D ${id} ${c.name} (${form})`,
      `職責：${c.duty}`,
      `獨特：${c.unique}`,
      `剪影：${sil}`,
      `皮膜：${c.skin}`,
      c.hover ? "懸浮，無輪無走地腳。" : "非 A：炮台無輪；移動才有與這隻身體對應的移動器。",
      `禁止：${FORBID_GLOBAL.join("; ")}`,
      "一張臉，一顆分不開的濕果凍身體，綠幕 #00FF00，正面，約 70%。"
    ].join("\n");
  }

  IMMUNE.characterIdentity = {
    LOGIC,
    FORBID_GLOBAL,
    ATTACK_VFX,
    CHARACTERS,
    listNeedingCatalogRedraw,
    listNeedingFormRedraw,
    artBrief
  };
})(globalThis);
