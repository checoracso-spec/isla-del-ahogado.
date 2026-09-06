class_name StyleTokens
extends RefCounted

## Tokens visuales compartidos por HUD, menús y paneles de sistemas.

const INK := Color("#142329")
const SEA_SLATE := Color("#263D46")
const SEA_SLATE_ALT := Color("#2D4850")
const WEATHERED_TEAL := Color("#527176")
const OLD_WOOD := Color("#6B4A35")
const WOOD_HIGHLIGHT := Color("#8A6147")
const MOSS := Color("#526B43")
const DEEP_SEA := Color("#1B3B46")
const ABYSS_DARK := Color("#0E2933")
const RITUAL_GOLD := Color("#D6A24A")
const CREAM := Color("#F4D38C")
const TEXT := Color("#FFE4C7")
const DANGER := Color("#E4A18F")
const SUCCESS := Color("#9BE6AF")

const PANEL_BG := Color("#0F1B21E8")
const PANEL_BORDER := WEATHERED_TEAL

static func scaled_font(base_size: int, scale: float) -> int:
	return maxi(11, int(round(float(base_size) * scale)))
