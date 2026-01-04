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
const STATUS_BUFF_DEBUFF_MULTIPLIER: float = 0.25  # Standard ±25% for ATK/DEF/SPD buffs/debuffs

# Purification (Legacy - see CORRUPTION SYSTEM below)
const PURIFICATION_BASE_CHANCE: float = 0.3
const PURIFICATION_CORRUPTION_PENALTY: float = 0.01  # Per corruption point
const MAX_CORRUPTION: float = 100.0

# =============================================================================
# CORRUPTION & ASCENSION SYSTEM (v5.0 - Soulbind System)
# =============================================================================

# Corruption State Thresholds (0-100 scale)
# CORE PHILOSOPHY: Lower corruption = STRONGER monster (goal is ASCENSION)
const CORRUPTION_ASCENDED_MAX: float = 10.0    # 0-10%: ASCENDED (TRUE form, +25% stats)
const CORRUPTION_PURIFIED_MAX: float = 25.0    # 11-25%: Purified (+10% stats)
const CORRUPTION_UNSTABLE_MAX: float = 50.0    # 26-50%: Unstable (normal stats)
const CORRUPTION_CORRUPTED_MAX: float = 75.0   # 51-75%: Corrupted (-10% stats, 10% Instability)
# 76-100%: Abyssal (-20% stats, 20% Instability, dark abilities)

# Stat Multipliers by Corruption State
const STAT_MULT_ASCENDED: float = 1.25      # +25% all stats at ASCENDED
const STAT_MULT_PURIFIED: float = 1.10      # +10% all stats at Purified
const STAT_MULT_UNSTABLE: float = 1.0       # Normal stats at Unstable
const STAT_MULT_CORRUPTED: float = 0.90     # -10% all stats at Corrupted
const STAT_MULT_ABYSSAL: float = 0.80       # -20% all stats at Abyssal

# Instability by Corruption State (% chance to ignore commands per turn)
const INSTABILITY_ASCENDED: float = 0.0     # Perfect loyalty
const INSTABILITY_PURIFIED: float = 0.0     # Stable
const INSTABILITY_UNSTABLE: float = 0.05    # 5% minor instability
const INSTABILITY_CORRUPTED: float = 0.10   # 10% Instability
const INSTABILITY_ABYSSAL: float = 0.20     # 20% Instability

# Brand Power Multiplier by Corruption State
const BRAND_MULT_ASCENDED: float = 1.30     # 130% brand bonus + Ascended ability
const BRAND_MULT_PURIFIED: float = 1.10     # 110% brand bonus
const BRAND_MULT_UNSTABLE: float = 1.0      # 100% brand bonus
const BRAND_MULT_CORRUPTED: float = 0.90    # 90% brand bonus + dark ability access
const BRAND_MULT_ABYSSAL: float = 0.80      # 80% brand bonus + enhanced dark ability

# Corruption Drift (In-Battle)
const CORRUPTION_DRIFT_ATTACK: float = 5.0      # +5 when attacking monster
const CORRUPTION_DRIFT_WAIT: float = -5.0       # -5 when waiting/defending
const CORRUPTION_DRIFT_HEAL_ENEMY: float = -10.0 # -10 when healing enemy
const CORRUPTION_DRIFT_PURIFY: float = -15.0    # -15 when using PURIFY (even on fail)
const CORRUPTION_DRIFT_DOMINATE: float = 10.0   # +10 when using DOMINATE

# =============================================================================
# SOULBIND CAPTURE SYSTEM (v5.0)
# =============================================================================

# Base Capture Chances by Rarity
const CAPTURE_BASE_COMMON: float = 0.50        # 50%
const CAPTURE_BASE_UNCOMMON: float = 0.40      # 40%
const CAPTURE_BASE_RARE: float = 0.30          # 30%
const CAPTURE_BASE_EPIC: float = 0.15          # 15%
const CAPTURE_BASE_LEGENDARY: float = 0.05     # 5%

# Health Modifier: +1% per 2% HP missing (max +40%)
const CAPTURE_HP_BONUS_PER_MISSING: float = 0.005  # 0.5% per 1% HP missing
const CAPTURE_HP_BONUS_MAX: float = 0.40           # Max +40% bonus

# Soul Vessel Bonuses
const SOUL_VESSEL_CRACKED_BONUS: float = 0.10      # +10%
const SOUL_VESSEL_STANDARD_BONUS: float = 0.20     # +20%
const SOUL_VESSEL_PRISTINE_BONUS: float = 0.35     # +35%
const SOUL_VESSEL_COVENANT_BONUS: float = 0.50     # +50%

# Capture Passes Required (Corruption Battle animation)
const CAPTURE_PASSES_COMMON: int = 1
const CAPTURE_PASSES_UNCOMMON: int = 2
const CAPTURE_PASSES_RARE: int = 3
const CAPTURE_PASSES_EPIC: int = 4
const CAPTURE_PASSES_LEGENDARY: int = 5
const CAPTURE_PASS_TIME_SHORT: float = 1.5         # Common/Uncommon
const CAPTURE_PASS_TIME_MEDIUM: float = 2.0        # Rare/Epic
const CAPTURE_PASS_TIME_LONG: float = 2.5          # Legendary

# Pass Reduction Factors
const CAPTURE_PASS_REDUCTION_LOW_HP: int = 1       # -1 pass if <25% HP
const CAPTURE_PASS_REDUCTION_LOW_CORRUPTION: int = 1  # -1 pass if <25 corruption
const CAPTURE_PASS_REDUCTION_PURIFY: int = 1       # -1 pass for PURIFY method
const CAPTURE_PASS_REDUCTION_PRISTINE: int = 1     # -1 pass for Pristine Vessel
const CAPTURE_PASS_REDUCTION_COVENANT: int = 2     # -2 passes for Covenant Vessel

# SOULBIND Method (Item-Based) - No special modifiers

# PURIFY Method (Sanctum Energy Cost)
const PURIFY_ENERGY_BASE: float = 10.0             # Base energy cost
const PURIFY_ENERGY_CORRUPTION_MULT: float = 0.5   # +0.5 per corruption point
const PURIFY_LOW_CORRUPTION_BONUS: float = 0.20    # +20% if corruption <25
const PURIFY_HIGH_CORRUPTION_PENALTY: float = 0.30 # -30% if corruption >75
const PURIFY_CORRUPTION_REDUCTION_ON_FAIL: float = 15.0  # -15 corruption even on fail

# DOMINATE Method (HP Cost)
const DOMINATE_HP_COST_PERCENT: float = 0.25       # 25% of current HP
const DOMINATE_HIGH_CORRUPTION_BONUS: float = 0.20 # +20% if corruption >75
const DOMINATE_MIN_CORRUPTION: float = 26.0        # Unavailable if corruption <26
const DOMINATE_FAIL_CORRUPTION_GAIN: float = 15.0  # Monster gains +15 corruption on fail
const DOMINATE_FAIL_DEFIANT_DURATION: int = 3      # Defiant buff lasts 3 turns
const DOMINATE_FAIL_DEFIANT_DAMAGE_BONUS: float = 0.20  # +20% damage during Defiant

# BARGAIN Method (Immediate Price)
const BARGAIN_CAPTURE_BONUS: float = 0.25          # +25% capture chance

# =============================================================================
# SANCTUM SHRINE SYSTEM
# =============================================================================

# Shrine Tiers
const SHRINE_MINOR_COOLDOWN: int = 3               # 3 battles
const SHRINE_MAJOR_USES: int = 1                   # 1 use per visit
const SHRINE_SACRED_COOLDOWN: int = 0              # No cooldown

# Corruption Reduction per Tier
const SHRINE_MINOR_CORRUPTION_REDUCTION: float = 10.0
const SHRINE_MAJOR_CORRUPTION_REDUCTION: float = 15.0
const SHRINE_SACRED_CORRUPTION_REDUCTION: float = 20.0

# Shrine Cleansing Cost
const SHRINE_CLEANSE_ENERGY_COST: float = 10.0     # Per monster

# =============================================================================
# BRAND ALIGNMENT SYSTEM (Player)
# =============================================================================

# Equipment Alignment Requirements
const BRAND_EQUIPMENT_THRESHOLD: float = 55.0      # 55%+ to wield
const BRAND_HYBRID_EQUIPMENT_THRESHOLD: float = 40.0  # 40%+ in BOTH parent brands

# Equipment Decay Stages (battles below threshold)
const EQUIPMENT_RESISTANCE_BATTLES: int = 3        # 0-3: Resistance stage
const EQUIPMENT_REJECTION_BATTLES: int = 6         # 4-6: Rejection stage
const EQUIPMENT_CORRUPTION_BATTLES: int = 10       # 7-10: Corruption stage
const EQUIPMENT_SHATTER_BATTLES: int = 11          # 11+: Shatter

# Equipment Decay Penalties
const EQUIPMENT_RESISTANCE_SPEED_PENALTY: float = 0.05   # -5% SPD
const EQUIPMENT_REJECTION_SPEED_PENALTY: float = 0.10    # -10% SPD
const EQUIPMENT_REJECTION_BONUS_PENALTY: float = 0.10    # -10% weapon bonus
const EQUIPMENT_CORRUPTION_SPEED_PENALTY: float = 0.20   # -20% SPD
const EQUIPMENT_SHATTER_HP_DAMAGE: float = 0.25          # 25% max HP damage

# Alignment Change (Story Choices - Major Impact)
const ALIGNMENT_MAJOR_POSITIVE: float = 15.0       # Large positive shift
const ALIGNMENT_MAJOR_NEGATIVE: float = -10.0      # Large negative shift
const ALIGNMENT_STORY_MAXIMUM: float = 30.0        # Max from single story choice

# Alignment Change (Battle Actions - Minor Impact)
const ALIGNMENT_BATTLE_DOMINATE_DREAD: float = 3.0
const ALIGNMENT_BATTLE_DOMINATE_LEECH: float = 2.0
const ALIGNMENT_BATTLE_PURIFY_IRON: float = 2.0
const ALIGNMENT_BATTLE_PURIFY_VENOM: float = -1.0
const ALIGNMENT_BATTLE_EXECUTE_SAVAGE: float = 3.0

# Passive Drift (Party Composition)
const ALIGNMENT_PASSIVE_DRIFT_RATE: float = 1.0    # +1% per 10 battles toward dominant

# =============================================================================
# MORALE SYSTEM
# =============================================================================

const MORALE_INSPIRED_THRESHOLD: int = 3           # 3+ approved choices
const MORALE_CONFLICTED_THRESHOLD: int = 2         # 2+ disapproved choices
const MORALE_REBELLIOUS_THRESHOLD: int = 4         # 4+ disapproved choices
const MORALE_DECAY_BATTLES: int = 5                # 1 choice fades per 5 battles

const MORALE_INSPIRED_STAT_BONUS: float = 0.10     # +10% stats
const MORALE_CONFLICTED_STAT_PENALTY: float = 0.05 # -5% stats
const MORALE_REBELLIOUS_INSTABILITY_BONUS: float = 0.10  # +10% Instability

# =============================================================================
# PATH-BRAND SYNERGY SYSTEM
# =============================================================================

const SYNERGY_TIER_1_MONSTERS: int = 1             # Half bonus (+5%)
const SYNERGY_TIER_2_MONSTERS: int = 2             # Full bonus (+10%)
const SYNERGY_TIER_3_MONSTERS: int = 3             # Full + 5% secondary

const SYNERGY_TIER_1_BONUS: float = 0.05           # +5%
const SYNERGY_TIER_2_BONUS: float = 0.10           # +10%
const SYNERGY_TIER_3_SECONDARY_BONUS: float = 0.05 # Additional +5%

const SYNERGY_ASCENDED_COUNT_MULTIPLIER: int = 2   # Ascended = 2 for synergy
const SYNERGY_PLAYER_ALIGNMENT_BONUS: float = 0.15 # +15% if player 55%+ aligned

# Path-Brand Synergy Mapping
const PATH_SYNERGY_BRANDS: Dictionary = {
	"IRONBOUND": ["IRON", "BLOODIRON", "CORROSIVE"],
	"FANGBORN": ["SAVAGE", "RAVENOUS", "BLOODIRON"],
	"VOIDTOUCHED": ["LEECH", "NIGHTLEECH", "DREAD"],
	"UNCHAINED": ["SURGE", "TERRORFLUX", "VENOMSTRIKE"]
}

const PATH_SYNERGY_BONUSES: Dictionary = {
	"IRONBOUND": {"def_mult": 1.10, "hp_mult": 1.05},
	"FANGBORN": {"atk_mult": 1.10, "crit_mult": 1.05},
	"VOIDTOUCHED": {"lifesteal_mult": 1.10, "sp_regen_mult": 1.05},
	"UNCHAINED": {"eva_mult": 1.10, "spd_mult": 1.05}
}

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

# =============================================================================
# COLOR CONSTANTS
# =============================================================================

# Transparent/Basic
const COLOR_TRANSPARENT := Color(0.0, 0.0, 0.0, 0.0)
const COLOR_NORMAL := Color(1.0, 1.0, 1.0, 1.0)

# =============================================================================
# ANIMATION TIMING CONSTANTS (v0.98 - Eliminate 700+ hardcoded values)
# =============================================================================

# Standard Duration Tiers (sorted by duration)
const ANIM_INSTANT: float = 0.0           # No animation
const ANIM_HITSTOP: float = 0.05          # Freeze frames, impact pause
const ANIM_FLASH: float = 0.1             # Quick feedback, button press
const ANIM_SNAP: float = 0.15             # Button hover, quick transitions
const ANIM_QUICK: float = 0.2             # Rapid animations, attack phases
const ANIM_QUARTER: float = 0.25          # Quarter-second transitions
const ANIM_MEDIUM: float = 0.3            # Standard transition (scene fade)
const ANIM_EXTENDED: float = 0.4          # Longer animations
const ANIM_HALF: float = 0.5              # Half-second (capture, skills)
const ANIM_SLOW: float = 0.8              # Slow transitions
const ANIM_STANDARD: float = 1.0          # One second (common fade)
const ANIM_PULSE: float = 1.2             # Pulse/breathing cycles
const ANIM_DRAMATIC: float = 1.5          # Skill announcements, entrances
const ANIM_CINEMATIC: float = 2.0         # Boss phases, cinematics
const ANIM_EPIC: float = 3.0              # Boss intros, major events

# UI Animation Presets (from CLAUDE.md)
const UI_BUTTON_HOVER: float = 0.15       # Button hover state
const UI_BUTTON_PRESS: float = 0.1        # Button press feedback
const UI_SCENE_FADE: float = 0.3          # Scene transitions
const UI_MENU_SLIDE: float = 0.25         # Menu slide animations
const UI_POPUP_ENTER: float = 0.25        # Popup entrance
const UI_POPUP_EXIT: float = 0.2          # Popup exit
const UI_TOOLTIP_DELAY: float = 0.3       # Tooltip show delay

# Battle Animation Presets
const BATTLE_ATTACK_WINDUP: float = 0.2   # Attack preparation
const BATTLE_HIT_IMPACT: float = 0.1      # Hit impact flash
const BATTLE_DAMAGE_NUMBER: float = 1.0   # Damage number display
const BATTLE_BETWEEN_HITS: float = 0.15   # Multi-hit delay
const BATTLE_TURN_END: float = 0.3        # Turn end delay
const BATTLE_SKILL_ANNOUNCE: float = 1.5  # Skill name display

# =============================================================================
# COMBAT MULTIPLIER CONSTANTS (v0.98 - Eliminate 72+ hardcoded values)
# =============================================================================

# Damage Calculation
const DAMAGE_LEVEL_SCALE: float = 0.02          # 1% per level difference
const DAMAGE_BASE_RATIO: float = 0.8            # 80% of power as base damage
const DAMAGE_DEFENSE_FACTOR: float = 0.3        # 30% of DEF applies to reduction
const DAMAGE_STAT_SCALE: float = 0.5            # ATK-DEF scaling multiplier
const DAMAGE_FLOOR_RATIO: float = 0.5           # Minimum 50% of power as damage
const DAMAGE_SORROW_MULT: float = 1.15          # DREAD brand SORROW debuff

# Accuracy and Evasion
const ACCURACY_BLIND_PENALTY: float = 0.5       # -50% accuracy when blinded
const EVASION_SPEED_FACTOR: float = 0.002       # +0.2% evasion per SPD point

# Healing
const HEALING_LEVEL_SCALE: float = 0.1          # Level / 10 bonus
const HEALING_VARIANCE: float = 0.05            # ±5% healing variance
const HEALING_REGEN_MULT: float = 1.2           # +20% with REGEN status

# Status Effects
const STATUS_MAGIC_CHANCE_FACTOR: float = 0.002   # +0.2% per MAGIC stat
const STATUS_LUCK_DIFF_FACTOR: float = 0.01       # +1% per luck difference
const STATUS_RESIST_FACTOR: float = 0.001         # -0.1% per resistance

# Skill Effect Multipliers
const SKILL_BONUS_VS_BLEED: float = 1.25        # +25% vs bleeding targets
const SKILL_BONUS_LOW_HP_30: float = 1.3        # +30% vs low HP targets
const SKILL_BONUS_LOW_HP_50: float = 1.5        # +50% vs very low HP targets
const SKILL_BONUS_PER_ALLY: float = 0.15        # +15% per ally of same type
const SKILL_BONUS_TRAINER_HURT: float = 1.4     # +40% when trainer is hurt
const SKILL_BONUS_VS_SORROW: float = 1.5        # +50% vs SORROW debuff
const SKILL_BONUS_VS_CASTING: float = 1.5       # +50% vs casting enemies
const SKILL_PENALTY_DOUBLE_ACTION: float = 0.6  # 40% penalty for weak double

# Lifesteal Values
const SKILL_LIFESTEAL_50: float = 0.5           # 50% of damage healed
const SKILL_LIFESTEAL_25: float = 0.25          # 25% of damage healed

# HP Thresholds
const HP_THRESHOLD_10: float = 0.1              # 10% HP trigger
const HP_THRESHOLD_25: float = 0.25             # 25% HP (low)
const HP_THRESHOLD_30: float = 0.3              # 30% HP (very low)
const HP_THRESHOLD_50: float = 0.5              # 50% HP (medium)

# Combat Actions
const SKILL_CONSUME_CORPSE_HEAL: float = 0.3    # 30% max HP from corpse
const SKILL_EVASION_BOOST_1TURN: float = 0.3    # +30% SPD for 1 turn
const SKILL_EVASION_BOOST_2TURN: float = 0.2    # +20% SPD for 2 turns
const SKILL_DAMAGE_REFLECT: float = 0.3         # 30% damage reflected
const SKILL_POWER_PER_DEAD: float = 0.1         # +10% power per dead ally
const SKILL_REVIVE_HEALTH: float = 0.25         # 25% HP on revive
const SKILL_HEAL_ON_CONSUME: float = 0.2        # 20% HP on consume buff
const SKILL_UNDERGROUND_BONUS: float = 1.5      # +50% after underground
const SKILL_REDIRECT_REDUCTION: float = 0.25    # 25% reduction on redirect
const SKILL_BONUS_PER_SOUL: float = 0.2         # +20% per harvested soul
const SKILL_PASSIVE_EVASION: float = 0.3        # 30% passive evasion
const SKILL_ATTACK_PER_ALLY: float = 0.1        # +10% ATK per ally passive
const SKILL_HARVEST_DEF_BONUS: float = 0.1      # +10% DEF on harvest

# Defend Action
const DEFEND_BOOST_RATIO: float = 0.5           # +50% base DEF when defending
const GUARDED_DAMAGE_REDUCTION: float = 0.3     # 30% damage reduction (GUARDED)

# Battle Actions Speed Modifiers (for turn order)
const ACTION_SPEED_ATTACK: float = 1.0          # Normal speed
const ACTION_SPEED_SKILL: float = 0.8           # Skills are slower
const ACTION_SPEED_DEFEND: float = 1.5          # Defending is faster
const ACTION_SPEED_ITEM: float = 1.2            # Items are quick
const ACTION_SPEED_FLEE: float = 1.3            # Fleeing is fast
const ACTION_SPEED_PURIFY: float = 0.5          # Purification is slowest

# Flee Calculation
const FLEE_SPEED_MODIFIER: float = 0.01         # +1% per SPD difference

# MP Regeneration
const MP_REGEN_PER_TURN: float = 0.05           # 5% max MP per turn

# AI Scoring Weights
const AI_BRAND_EFFECTIVE_WEIGHT: float = 1.5    # Super effective bonus
const AI_VERY_LOW_HP_WEIGHT: float = 2.0        # Priority on very low HP
const AI_MEDIUM_HP_WEIGHT: float = 0.5          # Reduced priority
const AI_THREAT_SCALE: float = 0.01             # Threat per 100 damage

# Siphon Heal
const SKILL_SIPHON_HEAL_MULT: float = 1.5       # 150% heal on siphon

# =============================================================================
# PURIFICATION MULTIPLIERS
# =============================================================================

const PURIFY_MAGIC_SCALE: float = 0.5           # magic/50 + 0.5
const PURIFY_LEVEL_SCALE: float = 0.05          # 5% per level difference
const PURIFY_HP_THRESHOLD_MULT: float = 2.0     # 2x bonus for HP threshold
const PURIFY_IRON_BRAND_BONUS: float = 1.25     # +25% for IRON brand
const PURIFY_DARK_BRAND_PENALTY: float = 0.75   # -25% for dark brands
const PURIFY_ALIGNMENT_FACTOR: float = 0.3      # Up to 15% alignment bonus
const PURIFY_SUCCESS_LEVEL_SCALE: float = 0.02  # 2% per level modifier
const PURIFY_SUCCESS_HP_BONUS: float = 0.2      # +20% for HP bonus
const CORRUPTION_TICK_DAMAGE: float = 0.05      # 5% max HP per turn
const CORRUPTION_TICK_HEAL: float = 0.03        # 3% max HP heal per turn
const PURIFY_POWER_MULT: float = 2.0            # Double purification power

# =============================================================================
# CAPTURE SYSTEM MULTIPLIERS
# =============================================================================

const CAPTURE_HP_REDUCTION_FAIL: float = 0.15   # -15% HP on failed capture
const CAPTURE_ESCAPE_CHANCE: float = 0.3        # 30% escape factor
const CAPTURE_LEVEL_MODIFIER: float = 0.02      # 2% per level difference
