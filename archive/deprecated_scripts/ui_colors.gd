class_name UIColors
extends RefCounted
## UIColors: Centralized color constants for UI elements.
##
## PROBLEM SOLVED:
## The codebase had 273+ hardcoded Color() calls with duplicate values.
## This made theming impossible and caused inconsistencies.
##
## SOLUTION:
## Define all UI colors as constants in one place.
## Easy to theme, consistent, and no runtime Color allocations.

# =============================================================================
# TEXT COLORS
# =============================================================================

const TEXT_PRIMARY := Color(0.95, 0.9, 0.8, 1.0)
const TEXT_SECONDARY := Color(0.7, 0.7, 0.7, 1.0)
const TEXT_MUTED := Color(0.5, 0.5, 0.5, 1.0)
const TEXT_DISABLED := Color(0.5, 0.5, 0.5, 1.0)
const TEXT_HIGHLIGHT := Color(1.0, 0.9, 0.7, 1.0)

const TEXT_DAMAGE := Color(1.0, 0.3, 0.3, 1.0)
const TEXT_HEAL := Color(0.3, 1.0, 0.4, 1.0)
const TEXT_CRITICAL := Color(1.0, 0.8, 0.2, 1.0)
const TEXT_MISS := Color(0.6, 0.6, 0.6, 1.0)

# =============================================================================
# PANEL BACKGROUNDS
# =============================================================================

const PANEL_BG_DARK := Color(0.1, 0.1, 0.15, 0.85)
const PANEL_BG_DARKER := Color(0.08, 0.08, 0.1, 0.9)
const PANEL_BG_ENEMY := Color(0.15, 0.1, 0.1, 0.85)
const PANEL_BG_ALLY := Color(0.1, 0.1, 0.18, 0.85)
const PANEL_BG_TRANSPARENT := Color(0, 0, 0, 0)

const PANEL_BORDER_DEFAULT := Color(0.3, 0.25, 0.4, 1.0)
const PANEL_BORDER_ENEMY := Color(0.5, 0.25, 0.25, 1.0)
const PANEL_BORDER_ALLY := Color(0.25, 0.3, 0.5, 1.0)
const PANEL_BORDER_HIGHLIGHT := Color(0.7, 0.55, 0.4, 1.0)

# =============================================================================
# BUTTON COLORS
# =============================================================================

const BTN_BG_NORMAL := Color(0.12, 0.12, 0.15, 0.95)
const BTN_BG_HOVER := Color(0.18, 0.18, 0.22, 0.98)
const BTN_BG_PRESSED := Color(0.08, 0.08, 0.1, 0.98)
const BTN_BG_DISABLED := Color(0.08, 0.08, 0.1, 0.7)
const BTN_BG_FOCUS := Color(0.18, 0.14, 0.22, 0.95)

const BTN_BORDER_NORMAL := Color(0.4, 0.35, 0.3, 0.8)
const BTN_BORDER_HOVER := Color(0.6, 0.5, 0.4, 1.0)
const BTN_BORDER_PRESSED := Color(0.5, 0.4, 0.3, 1.0)
const BTN_BORDER_DISABLED := Color(0.3, 0.3, 0.3, 0.5)
const BTN_BORDER_FOCUS := Color(0.7, 0.55, 0.4, 1.0)

# =============================================================================
# HP/MP/RESOURCE BARS
# =============================================================================

const HP_FILL_ALLY := Color(0.2, 0.8, 0.3, 1.0)
const HP_FILL_ENEMY := Color(0.8, 0.2, 0.2, 1.0)
const HP_BG := Color(0.15, 0.1, 0.1, 0.9)

const MP_FILL := Color(0.2, 0.4, 0.9, 1.0)
const MP_BG := Color(0.1, 0.1, 0.15, 0.9)

const CORRUPTION_FILL := Color(0.5, 0.1, 0.6, 1.0)
const CORRUPTION_BG := Color(0.1, 0.05, 0.1, 0.9)

const XP_FILL := Color(0.9, 0.7, 0.2, 1.0)
const XP_BG := Color(0.15, 0.12, 0.08, 0.9)

# =============================================================================
# ACTION BUTTON COLORS
# =============================================================================

const ACTION_ATTACK := Color(0.9, 0.3, 0.3, 1.0)
const ACTION_SKILL := Color(0.3, 0.5, 0.9, 1.0)
const ACTION_PURIFY := Color(0.8, 0.6, 0.9, 1.0)
const ACTION_ITEM := Color(0.3, 0.8, 0.4, 1.0)
const ACTION_DEFEND := Color(0.6, 0.6, 0.7, 1.0)
const ACTION_FLEE := Color(0.8, 0.7, 0.3, 1.0)

# =============================================================================
# BRAND COLORS
# =============================================================================

const BRAND_SAVAGE := Color(0.9, 0.2, 0.2, 1.0)
const BRAND_IRON := Color(0.5, 0.5, 0.6, 1.0)
const BRAND_VENOM := Color(0.3, 0.8, 0.2, 1.0)
const BRAND_SURGE := Color(0.3, 0.6, 1.0, 1.0)
const BRAND_DREAD := Color(0.5, 0.2, 0.7, 1.0)
const BRAND_LEECH := Color(0.8, 0.2, 0.5, 1.0)

const BRAND_BLOODIRON := Color(0.7, 0.3, 0.3, 1.0)
const BRAND_CORROSIVE := Color(0.4, 0.6, 0.3, 1.0)
const BRAND_VENOMSTRIKE := Color(0.4, 0.7, 0.5, 1.0)
const BRAND_TERRORFLUX := Color(0.4, 0.4, 0.8, 1.0)
const BRAND_NIGHTLEECH := Color(0.4, 0.2, 0.5, 1.0)
const BRAND_RAVENOUS := Color(0.6, 0.2, 0.3, 1.0)

const BRAND_NONE := Color(0.8, 0.8, 0.8, 1.0)

# =============================================================================
# STATUS EFFECT COLORS
# =============================================================================

const STATUS_POISON := Color(0.4, 0.8, 0.3, 1.0)
const STATUS_BURN := Color(1.0, 0.5, 0.2, 1.0)
const STATUS_FREEZE := Color(0.4, 0.7, 1.0, 1.0)
const STATUS_STUN := Color(1.0, 1.0, 0.3, 1.0)
const STATUS_BLEED := Color(0.8, 0.2, 0.2, 1.0)
const STATUS_BUFF := Color(0.3, 0.9, 0.5, 1.0)
const STATUS_DEBUFF := Color(0.9, 0.3, 0.3, 1.0)

# =============================================================================
# HIGHLIGHT/SELECTION COLORS
# =============================================================================

const HIGHLIGHT_ALLY := Color(0.3, 0.5, 1.0, 1.0)
const HIGHLIGHT_ENEMY := Color(1.0, 0.4, 0.4, 1.0)
const HIGHLIGHT_NEUTRAL := Color(1.0, 0.9, 0.5, 1.0)
const HIGHLIGHT_SELECTED := Color(0.4, 0.7, 1.0, 1.0)

const GLOW_ALLY := Color(0.4, 0.6, 1.0, 0.5)
const GLOW_ENEMY := Color(1.0, 0.4, 0.4, 0.5)

# =============================================================================
# TOOLTIP COLORS
# =============================================================================

const TOOLTIP_BG := Color(0.08, 0.08, 0.12, 0.95)
const TOOLTIP_BORDER := Color(0.4, 0.35, 0.5, 1.0)
const TOOLTIP_TEXT := Color(0.9, 0.85, 0.8, 1.0)

# =============================================================================
# PORTRAIT FRAMES
# =============================================================================

const PORTRAIT_BG_ALLY := Color(0.15, 0.15, 0.2, 1.0)
const PORTRAIT_BG_ENEMY := Color(0.2, 0.1, 0.1, 1.0)
const PORTRAIT_BORDER_ALLY := Color(0.4, 0.35, 0.5, 1.0)
const PORTRAIT_BORDER_ENEMY := Color(0.6, 0.3, 0.3, 1.0)

# =============================================================================
# SCROLLBAR COLORS
# =============================================================================

const SCROLLBAR_GRABBER := Color(0.5, 0.45, 0.4, 0.8)
const SCROLLBAR_BG := Color(0.15, 0.12, 0.1, 0.6)

# =============================================================================
# FLASH/EFFECT COLORS
# =============================================================================

const FLASH_DAMAGE := Color(1.0, 0.3, 0.3, 1.0)
const FLASH_HEAL := Color(0.3, 1.0, 0.5, 1.0)
const FLASH_CRITICAL := Color(1.0, 1.0, 1.0, 1.0)
const FLASH_WHITE := Color(1.5, 1.5, 1.5, 1.0)

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

static func get_brand_color(brand: Enums.Brand) -> Color:
	## Get the color for a brand type
	match brand:
		Enums.Brand.SAVAGE:
			return BRAND_SAVAGE
		Enums.Brand.IRON:
			return BRAND_IRON
		Enums.Brand.VENOM:
			return BRAND_VENOM
		Enums.Brand.SURGE:
			return BRAND_SURGE
		Enums.Brand.DREAD:
			return BRAND_DREAD
		Enums.Brand.LEECH:
			return BRAND_LEECH
		Enums.Brand.BLOODIRON:
			return BRAND_BLOODIRON
		Enums.Brand.CORROSIVE:
			return BRAND_CORROSIVE
		Enums.Brand.VENOMSTRIKE:
			return BRAND_VENOMSTRIKE
		Enums.Brand.TERRORFLUX:
			return BRAND_TERRORFLUX
		Enums.Brand.NIGHTLEECH:
			return BRAND_NIGHTLEECH
		Enums.Brand.RAVENOUS:
			return BRAND_RAVENOUS
		_:
			return BRAND_NONE

static func get_action_color(action: Enums.BattleAction) -> Color:
	## Get the color for an action type
	match action:
		Enums.BattleAction.ATTACK:
			return ACTION_ATTACK
		Enums.BattleAction.SKILL:
			return ACTION_SKILL
		Enums.BattleAction.PURIFY:
			return ACTION_PURIFY
		Enums.BattleAction.ITEM:
			return ACTION_ITEM
		Enums.BattleAction.DEFEND:
			return ACTION_DEFEND
		Enums.BattleAction.FLEE:
			return ACTION_FLEE
		_:
			return TEXT_PRIMARY

static func with_alpha(color: Color, alpha: float) -> Color:
	## Return a color with modified alpha
	return Color(color.r, color.g, color.b, alpha)

static func brighten(color: Color, amount: float = 0.2) -> Color:
	## Return a brighter version of the color
	return Color(
		minf(color.r + amount, 1.0),
		minf(color.g + amount, 1.0),
		minf(color.b + amount, 1.0),
		color.a
	)

static func darken(color: Color, amount: float = 0.2) -> Color:
	## Return a darker version of the color
	return Color(
		maxf(color.r - amount, 0.0),
		maxf(color.g - amount, 0.0),
		maxf(color.b - amount, 0.0),
		color.a
	)
