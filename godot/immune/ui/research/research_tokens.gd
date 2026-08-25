class_name ImmuneResearchTokens
extends RefCounted

## HUD colors from the HTML research map (not 3D jelly body colors).

const VOID := Color(0.015686, 0.039216, 0.070588, 1.0)
const NAVY := Color(0.023529, 0.066667, 0.113725, 1.0)
const CYAN := Color(0.364706, 0.894118, 1.0, 1.0)
const GOLD := Color(0.956863, 0.764706, 0.356863, 1.0)
const TEXT := Color(0.913725, 0.964706, 1.0, 1.0)
const MUTED := Color(0.568627, 0.682353, 0.756863, 1.0)
const PANEL := Color(0.047, 0.11, 0.173, 0.92)
const LINE := Color(0.365, 0.894, 1.0, 0.22)

const FAMILY_ORDER: PackedStringArray = ["T", "B", "M", "N", "A", "D"]

const FAMILY_BLURB := {
	"T": "適應毒殺 · 固定／移動",
	"B": "抗體分泌 · 記憶增幅",
	"M": "吞噬回收 · 組織清除",
	"N": "天然獵殺 · 快速截擊",
	"A": "抗原中和 · 固定中繼",
	"D": "抗原掃描 · 免疫信標",
}

const FAMILY_ROLE := {
	"T": "精準追擊、連擊",
	"B": "抗體生產核心",
	"M": "吞噬、推擠、救援",
	"N": "高速截擊精英",
	"A": "浮游追蹤彈群",
	"D": "偵察感染區",
}

const FAMILY_SYMBOL := {
	"T": "T",
	"B": "B",
	"M": "巨噬",
	"N": "NK",
	"A": "抗體",
	"D": "樹突",
}

const RESOURCE_LABEL := {
	"antigen": "抗原樣本",
	"protomass": "一度原質",
	"fusionCore": "融合核心",
	"biomass": "生物質",
}


static func family_symbol(family: String) -> String:
	match family:
		"T":
			return "T"
		"B":
			return "B"
		"M":
			return "巨噬"
		"N":
			return "NK"
		"A":
			return "抗體"
		"D":
			return "樹突"
		_:
			return family


static func family_color(family: String) -> Color:
	match family:
		"T":
			return Color(0.270588, 0.741176, 0.94902, 1.0)
		"B":
			return Color(0.658824, 0.470588, 1.0, 1.0)
		"M":
			return Color(0.823529, 0.54902, 1.0, 1.0)
		"N":
			return Color(0.65098, 0.788235, 0.290196, 1.0)
		"A":
			return Color(0.94902, 0.721569, 0.294118, 1.0)
		"D":
			return Color(1.0, 0.607843, 0.345098, 1.0)
		_:
			return CYAN


static func node_family(node: Dictionary) -> String:
	var ids: Variant = node.get("familyIds", [])
	if ids is Array and (ids as Array).size() > 0:
		return str((ids as Array)[0])
	var hint: Variant = node.get("layoutHint", {})
	if hint is Dictionary:
		return str((hint as Dictionary).get("sector", ""))
	return ""
