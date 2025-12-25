class_name Constants
extends RefCounted
## Constants: All game-wide constants and balance values.

# =============================================================================
# GAME BALANCE CONSTANTS
# =============================================================================

# Party
const MAX_PARTY_SIZE: int = 4
const MAX_RESERVE_SIZE: int = 12
const MAX_MONSTERS_OWNED: int = 100

# Stats
const MAX_LEVEL: int = 99
const BASE_XP_REQUIREMENT: int = 100
const XP_GROWTH_RATE: float = 1.15

# Battle
const MAX_TURNS_PER_BATTLE: int = 999
const ESCAPE_BASE_CHANCE: float = 0.5
const CRITICAL_HIT_MULTIPLIER: float = 1.5
const ELEMENTAL_WEAKNESS_MULTIPLIER: float = 1.5
const ELEMENTAL_RESISTANCE_MULTIPLIER: float = 0.5
const DAMAGE_VARIANCE: float = 0.1  # +/-10%

# Purification
const PURIFICATION_BASE_CHANCE: float = 0.3
const PURIFICATION_CORRUPTION_PENALTY: float = 0.01  # Per corruption point
const MAX_CORRUPTION: float = 100.0

# VERA / VERATH - Memory Awakening Thresholds
const VERA_CORRUPTION_DECAY_RATE: float = 0.1  # Per minute
const VERA_INTERFACE_THRESHOLD: float = 0.0    # The lie
const VERA_FRACTURE_THRESHOLD: float = 25.0    # The mask cracks
const VERA_EMERGENCE_THRESHOLD: float = 60.0   # She remembers
const VERA_APOTHEOSIS_THRESHOLD: float = 90.0  # VERATH awakens

# Glitch System
const VERA_MIN_GLITCH_INTERVAL: float = 30.0   # Seconds between random glitches
const VERA_BASE_GLITCH_CHANCE: float = 0.05    # 5% base chance even at 0 corruption
const VERA_GLITCH_DURATION_MIN: float = 0.1
const VERA_GLITCH_DURATION_MAX: float = 0.5

# Path
const PATH_MIN: float = -100.0  # Full Shade
const PATH_MAX: float = 100.0   # Full Seraph
const PATH_NEUTRAL_RANGE: float = 25.0

# =============================================================================
# TIMING CONSTANTS
# =============================================================================

const SCENE_TRANSITION_DURATION: float = 0.5
const BATTLE_ACTION_DELAY: float = 0.3
const DAMAGE_NUMBER_DURATION: float = 1.0
const DIALOGUE_CHAR_DELAY: float = 0.02
const AUTOSAVE_INTERVAL: float = 300.0  # 5 minutes

# =============================================================================
# FILE PATHS
# =============================================================================

const SAVE_DIR: String = "user://saves/"
const SAVE_FILE_EXTENSION: String = ".vbsave"
const SETTINGS_FILE: String = "user://settings.cfg"
const MAX_SAVE_SLOTS: int = 3

# =============================================================================
# UI CONSTANTS
# =============================================================================

const UI_ANIMATION_SPEED: float = 0.2
const TOOLTIP_DELAY: float = 0.5
const NOTIFICATION_DURATION: float = 3.0

# =============================================================================
# BRAND STAT BONUSES
# =============================================================================

const BRAND_BONUSES: Dictionary = {
	"BULWARK": {"hp_mult": 1.3, "def_mult": 1.2, "spd_mult": 0.8},
	"FANG": {"atk_mult": 1.3, "crit_mult": 1.2, "def_mult": 0.9},
	"EMBER": {"mag_mult": 1.2, "spd_mult": 1.1, "res_mult": 0.9},
	"FROST": {"mag_mult": 1.2, "def_mult": 1.1, "spd_mult": 0.9},
	"VOID": {"mag_mult": 1.3, "spd_mult": 1.1, "hp_mult": 0.9},
	"RADIANT": {"mag_mult": 1.2, "hp_mult": 1.1, "atk_mult": 0.9}
}

# =============================================================================
# EXPERIENCE CURVE
# =============================================================================

static func get_xp_for_level(level: int) -> int:
	if level <= 1:
		return 0
	return int(BASE_XP_REQUIREMENT * pow(XP_GROWTH_RATE, level - 1))

static func get_total_xp_for_level(level: int) -> int:
	var total: int = 0
	for i in range(1, level + 1):
		total += get_xp_for_level(i)
	return total
