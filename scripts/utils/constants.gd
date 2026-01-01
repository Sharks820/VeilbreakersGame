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

# Stats - Level Caps by Monster Tier (v5.0)
const MAX_LEVEL_PURE_HYBRID: int = 100  # Pure/Hybrid monsters
const MAX_LEVEL_PRIMAL: int = 120       # PRIMAL monsters (overflow stats at 110+)
const MAX_LEVEL: int = 120              # Absolute max (PRIMAL cap)
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

# Monster Control (Party Monsters)
const MONSTER_AUTO_ATTACK_CORRUPTION_THRESHOLD: float = 70.0  # If corruption >= this, monster attacks on its own
const MONSTER_CAN_USE_ITEMS: bool = false  # Monsters cannot use items in battle
const MONSTER_CAN_CAPTURE: bool = false    # Monsters cannot capture other monsters

# Timed Defense System
const TIMED_DEFENSE_POPUP_DELAY_MIN: float = 0.3   # Random delay before popup appears (min)
const TIMED_DEFENSE_POPUP_DELAY_MAX: float = 0.7   # Random delay before popup appears (max)
const TIMED_DEFENSE_WINDOW: float = 0.8            # Window to press defend button
const TIMED_DEFENSE_PERFECT_WINDOW: float = 0.15   # Window for perfect defense
const TIMED_DEFENSE_REDUCTION: float = 0.3         # 30% damage reduction on success
const TIMED_DEFENSE_PERFECT_REDUCTION: float = 0.5 # 50% damage reduction on perfect

# =============================================================================
# BRAND EFFECTIVENESS SYSTEM (v5.0 - LOCKED)
# =============================================================================

# Effectiveness multipliers
const BRAND_STRONG: float = 1.5     # Strong brand vs weak: 150% damage
const BRAND_WEAK: float = 0.67      # Weak brand vs strong: 67% damage (updated from 0.75)
const BRAND_NEUTRAL: float = 1.0    # Neutral matchup

# Brand Effectiveness Wheel: SAVAGE → IRON → VENOM → SURGE → DREAD → LEECH → SAVAGE
# Each brand is STRONG against the next, WEAK against the previous
const BRAND_EFFECTIVENESS: Dictionary = {
	# Pure Brands - effectiveness against other brands
	# Format: {attacker_brand: {defender_brand: multiplier}}
	"SAVAGE": {"IRON": 1.5, "LEECH": 0.67, "SAVAGE": 1.0, "VENOM": 1.0, "SURGE": 1.0, "DREAD": 1.0},
	"IRON": {"VENOM": 1.5, "SAVAGE": 0.67, "IRON": 1.0, "SURGE": 1.0, "DREAD": 1.0, "LEECH": 1.0},
	"VENOM": {"SURGE": 1.5, "IRON": 0.67, "VENOM": 1.0, "SAVAGE": 1.0, "DREAD": 1.0, "LEECH": 1.0},
	"SURGE": {"DREAD": 1.5, "VENOM": 0.67, "SURGE": 1.0, "SAVAGE": 1.0, "IRON": 1.0, "LEECH": 1.0},
	"DREAD": {"LEECH": 1.5, "SURGE": 0.67, "DREAD": 1.0, "SAVAGE": 1.0, "IRON": 1.0, "VENOM": 1.0},
	"LEECH": {"SAVAGE": 1.5, "DREAD": 0.67, "LEECH": 1.0, "IRON": 1.0, "VENOM": 1.0, "SURGE": 1.0},
	# Hybrid Brands - use PRIMARY brand for effectiveness
	"BLOODIRON": {"IRON": 1.5, "LEECH": 0.67},    # Primary: SAVAGE
	"CORROSIVE": {"VENOM": 1.5, "SAVAGE": 0.67},  # Primary: IRON
	"VENOMSTRIKE": {"SURGE": 1.5, "IRON": 0.67},  # Primary: VENOM
	"TERRORFLUX": {"DREAD": 1.5, "VENOM": 0.67},  # Primary: SURGE
	"NIGHTLEECH": {"LEECH": 1.5, "SURGE": 0.67},  # Primary: DREAD
	"RAVENOUS": {"SAVAGE": 1.5, "DREAD": 0.67}    # Primary: LEECH
}

# Hybrid brand primary/secondary mapping
const HYBRID_BRAND_COMPONENTS: Dictionary = {
	"BLOODIRON": {"primary": "SAVAGE", "secondary": "IRON"},
	"CORROSIVE": {"primary": "IRON", "secondary": "VENOM"},
	"VENOMSTRIKE": {"primary": "VENOM", "secondary": "SURGE"},
	"TERRORFLUX": {"primary": "SURGE", "secondary": "DREAD"},
	"NIGHTLEECH": {"primary": "DREAD", "secondary": "LEECH"},
	"RAVENOUS": {"primary": "LEECH", "secondary": "SAVAGE"}
}

# Path-Brand Weakness (Heroes are weak to these brands)
const PATH_BRAND_WEAKNESS: Dictionary = {
	"IRONBOUND": "VENOM",   # Steel corroded by acid
	"FANGBORN": "IRON",     # Fangs can't pierce steel
	"VOIDTOUCHED": "DREAD", # Void fears the abyss
	"UNCHAINED": "LEECH"    # Draining binds the free
}

# Path-Brand Strength (Heroes are strong against these brands)
const PATH_BRAND_STRENGTH: Dictionary = {
	"IRONBOUND": "SAVAGE",  # Steel stops brutes
	"FANGBORN": "LEECH",    # Fangs drain life
	"VOIDTOUCHED": "SURGE", # Void absorbs energy
	"UNCHAINED": "DREAD"    # Freedom conquers fear
}

const PATH_STRONG_MULTIPLIER: float = 1.35  # Heroes deal 135% vs weak brand
const PATH_WEAK_MULTIPLIER: float = 0.70    # Heroes deal 70% vs strong brand

# Path System
const PATH_SKILL_TREE_UNLOCK: float = 30.0    # 30% affinity to unlock skill tree
const PATH_MONSTER_REQUIREMENT: float = 30.0  # 30% affinity to catch aligned monsters
const PATH_MAX_AFFINITY: float = 100.0
const PATH_MIN_AFFINITY: float = 0.0

# =============================================================================
# EVOLUTION & LEVELING SYSTEM (v5.0 - LOCKED)
# =============================================================================

# Evolution level thresholds
const EVO_2_LEVEL: int = 26          # Pure/Hybrid evolve to Evo 2
const EVO_3_LEVEL: int = 51          # Pure/Hybrid evolve to Evo 3
const PRIMAL_EVO_LEVEL: int = 36     # PRIMAL evolve to Evolved
const PRIMAL_OVERFLOW_LEVEL: int = 110  # PRIMAL overflow stats start

# XP Multipliers by tier and stage (lower = faster leveling)
const XP_MULT_PURE_BIRTH: float = 1.0       # Normal speed
const XP_MULT_PURE_EVO2: float = 1.5        # 50% slower
const XP_MULT_PURE_EVO3: float = 2.5        # 150% slower
const XP_MULT_HYBRID_BIRTH: float = 1.0     # Same as pure
const XP_MULT_HYBRID_EVO2: float = 1.5
const XP_MULT_HYBRID_EVO3: float = 2.5
const XP_MULT_PRIMAL_BIRTH: float = 0.6     # 40% faster
const XP_MULT_PRIMAL_EVOLVED: float = 0.8   # 20% faster
const XP_MULT_PRIMAL_OVERFLOW: float = 1.0  # Normal at overflow

# Stat growth bonuses per level
const STAT_GROWTH_NORMAL: float = 1.0       # Birth stage
const STAT_GROWTH_EVO2: float = 1.15        # +15% per level
const STAT_GROWTH_EVO3: float = 1.30        # +30% per level
const STAT_GROWTH_PRIMAL_EVOLVED: float = 1.10  # +10% per level
const STAT_GROWTH_PRIMAL_OVERFLOW: float = 1.05  # +5% ALL stats per level (110-120)

# Brand bonus at Evo 3 (Pure brands only)
const EVO3_BRAND_BONUS_MULTIPLIER: float = 1.20  # 120% instead of 100%

# PRIMAL dual brand scaling (both brands count as primary)
const PRIMAL_BRAND_SCALE: float = 0.50  # 50% of each brand (total 100%)

# Legacy - kept for backwards compatibility
const LOYALTY_MIN: float = 0.0
const LOYALTY_MAX: float = 100.0
const LOYALTY_AWAKENED_THRESHOLD: float = 25.0   # @deprecated
const LOYALTY_ASCENDED_THRESHOLD: float = 60.0   # @deprecated
const LOYALTY_PURIFIED_THRESHOLD: float = 90.0   # @deprecated

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

# =============================================================================
# BRAND STAT BONUSES (v5.0 - LOCKED)
# =============================================================================

const BRAND_BONUSES: Dictionary = {
	# === PURE BRANDS (6) - 100% bonus (120% at Evo 3) ===
	"SAVAGE": {
		"atk_mult": 1.25        # +25% ATK - Raw destruction
	},
	"IRON": {
		"hp_mult": 1.30         # +30% HP - Unyielding defense
	},
	"VENOM": {
		"crit_mult": 1.20,      # +20% Crit chance
		"status_mult": 1.15     # +15% Status proc chance
	},
	"SURGE": {
		"spd_mult": 1.25        # +25% SPD - Lightning speed
	},
	"DREAD": {
		"eva_mult": 1.20,       # +20% Evasion
		"fear_mult": 1.15       # +15% Fear proc chance
	},
	"LEECH": {
		"lifesteal_mult": 1.20  # +20% Lifesteal
	},
	# === HYBRID BRANDS (6) - 70% Primary + 30% Secondary ===
	"BLOODIRON": {
		"atk_mult": 1.175,      # 70% of SAVAGE (+17.5% ATK)
		"hp_mult": 1.09         # 30% of IRON (+9% HP)
	},
	"CORROSIVE": {
		"hp_mult": 1.21,        # 70% of IRON (+21% HP)
		"crit_mult": 1.06,      # 30% of VENOM (+6% Crit)
		"status_mult": 1.045    # 30% of VENOM (+4.5% Status)
	},
	"VENOMSTRIKE": {
		"crit_mult": 1.14,      # 70% of VENOM (+14% Crit)
		"status_mult": 1.105,   # 70% of VENOM (+10.5% Status)
		"spd_mult": 1.075       # 30% of SURGE (+7.5% SPD)
	},
	"TERRORFLUX": {
		"spd_mult": 1.175,      # 70% of SURGE (+17.5% SPD)
		"eva_mult": 1.06,       # 30% of DREAD (+6% Eva)
		"fear_mult": 1.045      # 30% of DREAD (+4.5% Fear)
	},
	"NIGHTLEECH": {
		"eva_mult": 1.14,       # 70% of DREAD (+14% Eva)
		"fear_mult": 1.105,     # 70% of DREAD (+10.5% Fear)
		"lifesteal_mult": 1.06  # 30% of LEECH (+6% Lifesteal)
	},
	"RAVENOUS": {
		"lifesteal_mult": 1.14, # 70% of LEECH (+14% Lifesteal)
		"atk_mult": 1.075       # 30% of SAVAGE (+7.5% ATK)
	}
}

# PRIMAL brand bonuses (50% Primary + 50% Secondary, calculated dynamically)
# PRIMAL monsters get their brands assigned at evolution based on behavior
const PRIMAL_BRAND_BONUS_SCALE: float = 0.50  # Each brand at 50%

# Legacy Brands (deprecated - kept for save file compatibility)
const BRAND_BONUSES_DEPRECATED: Dictionary = {
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
