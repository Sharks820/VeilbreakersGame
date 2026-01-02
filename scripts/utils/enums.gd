class_name Enums
extends RefCounted
## Enums: All game-wide enumerations.

# =============================================================================
# HELPER FUNCTIONS FOR SAFE ENUM ACCESS
# =============================================================================

## Safely get the name of a Brand enum value, handling NONE = -1
static func get_brand_name(brand: int) -> String:
	if brand < 0:
		return "NONE"
	var keys := Brand.keys()
	# Keys include NONE at index 0, so we need to offset by 1 for positive values
	if brand + 1 < keys.size():
		return keys[brand + 1]
	return "UNKNOWN"

## Safely get the name of a Path enum value, handling NONE = -1
static func get_path_name(path: int) -> String:
	if path < 0:
		return "NONE"
	var keys := Path.keys()
	# Keys include NONE at index 0, so we need to offset by 1 for positive values
	if path + 1 < keys.size():
		return keys[path + 1]
	return "UNKNOWN"

# =============================================================================
# GAME STATE
# =============================================================================

enum GameState {
	NONE,
	MAIN_MENU,
	LOADING,
	OVERWORLD,
	BATTLE,
	DIALOGUE,
	CUTSCENE,
	PAUSED,
	GAME_OVER,
	VICTORY
}

# =============================================================================
# CHARACTER & COMBAT
# =============================================================================

enum CharacterType {
	PLAYER,
	MONSTER,
	NPC,
	BOSS
}

enum Stat {
	HP,
	MAX_HP,
	MP,
	MAX_MP,
	ATTACK,
	DEFENSE,
	MAGIC,
	RESISTANCE,
	SPEED,
	LUCK,
	CRIT_CHANCE,
	CRIT_DAMAGE,
	ACCURACY,
	EVASION,
	HP_REGEN,
	MP_REGEN
}

enum DamageType {
	PHYSICAL,
	MAGICAL,
	TRUE,
	HEAL
}

enum TargetType {
	SELF,
	SINGLE_ALLY,
	ALL_ALLIES,
	SINGLE_ENEMY,
	ALL_ENEMIES,
	RANDOM_ENEMY,
	ALL
}

# =============================================================================
# BATTLE
# =============================================================================

enum BattleState {
	INITIALIZING,
	TURN_START,
	SELECTING_ACTION,
	SELECTING_TARGET,
	EXECUTING_ACTION,
	TURN_END,
	VICTORY,
	DEFEAT,
	FLED,
	CAPTURING,
	# Lock-in turn system states
	PARTY_LOCK_IN,      # Party members selecting actions (all before any execute)
	PARTY_EXECUTING,    # Party members executing queued actions
	ENEMY_EXECUTING,    # Enemies executing their attacks
	# Legacy alias
	PURIFICATION = CAPTURING
}

enum BattleAction {
	ATTACK,
	SKILL,
	DEFEND,
	ITEM,
	CAPTURE,   # Opens capture menu (ORB, PURIFY, BARGAIN, FORCE)
	FLEE,
	SWAP,
	# Legacy alias
	PURIFY = CAPTURE
}

enum StatusEffect {
	NONE,
	POISON,
	BURN,
	FREEZE,
	PARALYSIS,
	SLEEP,
	CONFUSION,
	BLIND,
	SILENCE,
	BLEED,
	REGEN,
	SHIELD,
	ATTACK_UP,
	ATTACK_DOWN,
	DEFENSE_UP,
	DEFENSE_DOWN,
	SPEED_UP,
	SPEED_DOWN,
	CORRUPTED,
	PURIFYING,
	SORROW,        # DREAD brand debuff - increased damage taken
	UNTARGETABLE   # Cannot be targeted (underground, intangible, etc.)
}

# =============================================================================
# PROGRESSION
# =============================================================================

## The 12 Brands - Monster type system (v5.0 - LOCKED)
## 6 Pure Brands (100% bonus, 120% at Evo 3)
## 6 Hybrid Brands (70% Primary + 30% Secondary)
enum Brand {
	NONE = -1,
	# === PURE BRANDS (6) ===
	SAVAGE = 0,       # +25% ATK - Raw destruction
	IRON = 1,         # +30% HP - Unyielding defense
	VENOM = 2,        # +20% Crit, +15% Status - Precision poison
	SURGE = 3,        # +25% SPD - Lightning speed
	DREAD = 4,        # +20% Evasion, +15% Fear - Terror incarnate
	LEECH = 5,        # +20% Lifesteal - Life drain
	# === HYBRID BRANDS (6) ===
	BLOODIRON = 6,    # SAVAGE(70%) + IRON(30%) = +17.5% ATK, +9% HP
	CORROSIVE = 7,    # IRON(70%) + VENOM(30%) = +21% HP, +6% Crit, +4.5% Status
	VENOMSTRIKE = 8,  # VENOM(70%) + SURGE(30%) = +14% Crit, +10.5% Status, +7.5% SPD
	TERRORFLUX = 9,   # SURGE(70%) + DREAD(30%) = +17.5% SPD, +6% Eva, +4.5% Fear
	NIGHTLEECH = 10,  # DREAD(70%) + LEECH(30%) = +14% Eva, +10.5% Fear, +6% Lifesteal
	RAVENOUS = 11     # LEECH(70%) + SAVAGE(30%) = +14% Lifesteal, +7.5% ATK
}

## Monster Brand Tier - Determines evolution stages and level caps (v5.0)
enum MonsterBrandTier {
	PURE = 0,    # 6 Pure brands, 3 stages (Birth→Evo2→Evo3), max level 100
	HYBRID = 1,  # 6 Hybrid brands, 3 stages (Birth→Evo2→Evo3), max level 100
	PRIMAL = 2   # Any 2 brands (assigned at evo), 2 stages (Birth→Evolved), max level 120
}

## The 4 Paths - Player skill trees (0-100% affinity each)
enum Path {
	NONE = -1,
	IRONBOUND = 0,    # Protection, order, sacrifice, duty (Tank/Defense)
	FANGBORN = 1,     # Strength, dominance, survival (Attack/DPS)
	VOIDTOUCHED = 2,  # Knowledge, truth, patience, secrets (Utility/Special)
	UNCHAINED = 3     # Freedom, chaos, adaptability (Hybrid/Disruptor)
}

## Skill Tree unlock states
enum SkillTreeState {
	LOCKED,      # Below 30% - cannot access
	UNLOCKED,    # 30%+ - can allocate points
	DARK         # Was unlocked, now below 30% - points stuck
}

# =============================================================================
# VERA / VERATH
# =============================================================================

enum VERAState {
	INTERFACE,   # 0-24: The perfect disguise. The lie.
	FRACTURE,    # 25-59: The mask is cracking. She's remembering.
	EMERGENCE,   # 60-89: She stops pretending. She knows who she is.
	APOTHEOSIS   # 90-100: VERA was always VERATH. Full reveal.
}

# =============================================================================
# ITEMS
# =============================================================================

enum ItemType {
	CONSUMABLE,
	EQUIPMENT,
	KEY_ITEM,
	MATERIAL
}

enum EquipmentSlot {
	WEAPON,
	ARMOR,
	ACCESSORY_1,
	ACCESSORY_2
}

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

# =============================================================================
# AUDIO
# =============================================================================

enum AudioBus {
	MASTER,
	MUSIC,
	SFX,
	VOICE,
	AMBIENT
}

# =============================================================================
# UI
# =============================================================================

enum MenuType {
	MAIN,
	PAUSE,
	SETTINGS,
	INVENTORY,
	PARTY,
	SKILLS,
	EQUIPMENT,
	QUESTS,
	MAP,
	SAVE,
	LOAD
}

# =============================================================================
# MONSTER TIERS
# =============================================================================

enum MonsterTier {
	COMMON,      # Tier 1: Levels 1-15
	UNCOMMON,    # Tier 2: Levels 15-30
	RARE,        # Tier 3: Levels 30-50
	BOSS         # Boss monsters
}

## Monster evolution stages
## Pure/Hybrid: Birth → Evo2 → Evo3 (3 stages, max level 100)
## PRIMAL: Birth → Evolved (2 stages, max level 120)
enum EvolutionStage {
	BIRTH = 0,      # Starting stage - all monsters
	EVO_2 = 1,      # Second stage - Pure/Hybrid only (level 26+)
	EVO_3 = 2,      # Third stage - Pure/Hybrid only (level 51+), 120% brand bonus
	EVOLVED = 3     # Final stage - PRIMAL only (level 36+), overflow stats at 110+
}

## Monster combat roles
enum MonsterRole {
	STRIKER,     # High damage dealer
	DEFENDER,    # Tank/protector
	SUPPORT,     # Healer/buffer
	DISRUPTOR    # Debuffer/controller
}

# =============================================================================
# CORRUPTION SYSTEM (v5.0 - Soulbind System)
# =============================================================================

## Corruption State - determines monster power and behavior
## CORE PHILOSOPHY: Lower corruption = STRONGER monster (goal is ASCENSION)
enum CorruptionState {
	ASCENDED = 0,   # 0-10%: TRUE form, freed from Veil, +25% all stats, perfect loyalty
	PURIFIED = 1,   # 11-25%: Stable, healthy, +10% stats
	UNSTABLE = 2,   # 26-50%: Flickering, confused, normal stats
	CORRUPTED = 3,  # 51-75%: Aggressive, in pain, -10% stats, 10% Instability
	ABYSSAL = 4     # 76-100%: Lost to darkness, -20% stats, 20% Instability, dark abilities
}

## Capture Method - how the monster was captured
enum CaptureMethod {
	NONE = -1,
	SOULBIND = 0,   # Standard: Soul Vessel item, no drawbacks
	PURIFY = 1,     # Righteous: Sanctum Energy cost, best for low corruption
	DOMINATE = 2,   # Dark: 25% HP cost, best for high corruption, causes Instability
	BARGAIN = 3     # Gamble: Immediate random price, +25% capture bonus
}

## Capture State - the state at which monster was captured (affects long-term)
enum CaptureState {
	WILD = 0,       # Not captured yet
	ASCENDED = 1,   # Captured at 0-10% corruption: perfect loyalty
	PURIFIED = 2,   # Captured at 11-25%: stable, "Inner Light" immunity
	SOULBOUND = 3,  # Captured at 26-50%: standard
	CORRUPTED = 4,  # Captured at 51-75%: 10% Instability (reducible)
	DOMINATED = 5   # Captured at 76-100%: 20% Instability (reducible), dark abilities
}

## Soul Vessel Tier - capture item quality
enum SoulVesselTier {
	CRACKED = 0,    # +10% capture, 100g, common shops
	STANDARD = 1,   # +20% capture, 400g, mid-game shops
	PRISTINE = 2,   # +35% capture, -1 pass, 1000g, late-game/crafting
	COVENANT = 3    # +50% capture, -2 passes, boss drops only
}

## Shrine Tier - rest point quality
enum ShrineTier {
	MINOR = 0,      # 3 battle cooldown, -10 corruption
	MAJOR = 1,      # Instant (1x per visit), -15 corruption
	SACRED = 2      # No cooldown, -20 corruption
}

## Morale Level - monster approval based on player actions
enum MoraleLevel {
	REBELLIOUS = 0, # 4+ disapproved choices: +10% Instability, may refuse Ascension
	CONFLICTED = 1, # 2+ disapproved choices: -5% stats, hesitant animations
	CONTENT = 2,    # Neutral: normal performance
	INSPIRED = 3    # 3+ approved choices: +10% stats, unique dialogue
}

# =============================================================================
# STORY CHAPTERS
# =============================================================================

enum Chapter {
	PROLOGUE = 0,
	CHAPTER_1 = 1,
	CHAPTER_2 = 2,
	CHAPTER_3 = 3,
	CHAPTER_4 = 4,
	EPILOGUE = 5
}

# =============================================================================
# ENDING TYPES
# =============================================================================

enum Ending {
	TRUE_LIGHT,      # Seraph + Reject VERATH
	REDEEMER,        # Light + Save VERA
	GUARDIAN,        # Neutral + Seal Veil
	PRAGMATIST,      # Neutral + Destroy VERATH
	SHADOW_KING,     # Shade + Accept VERATH
	CORRUPTED,       # Shade + Become VERATH
	SACRIFICE,       # Any + Self-seal
	BETRAYAL,        # Hidden + Trust VERA
	TRUE_ENDING      # Seraph + Perfect run
}
