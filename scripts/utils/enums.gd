class_name Enums
extends RefCounted
## Enums: All game-wide enumerations.

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

enum Element {
	NONE,
	PHYSICAL,
	FIRE,
	ICE,
	LIGHTNING,
	EARTH,
	WIND,
	WATER,
	LIGHT,
	DARK,
	HOLY,
	VOID
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

## The 6 Brands - Monster element/type system (NEW SYSTEM)
enum Brand {
	NONE = -1,
	SAVAGE = 0,    # Raw power, physical damage, direct attacks
	IRON = 1,      # Defense, endurance, protection
	VENOM = 2,     # DOT, debuffs, weakening
	SURGE = 3,     # Speed, energy, chain attacks
	DREAD = 4,     # Fear, mental, damage amplification
	LEECH = 5,     # Life drain, healing, sustain
	# Legacy brands (backwards compatibility)
	BULWARK = 6,   # Tank / Earth (legacy)
	FANG = 7,      # Physical DPS (legacy)
	EMBER = 8,     # Fire / AoE (legacy)
	FROST = 9,     # Ice / Control (legacy)
	VOID = 10,     # Dark / Debuff (legacy)
	RADIANT = 11   # Light / Healer (legacy)
}

## The 4 Paths - Player skill trees (0-100% affinity each) (NEW SYSTEM)
enum Path {
	NONE = -1,
	IRONBOUND = 0,    # Protection, order, sacrifice, duty (Tank/Defense)
	FANGBORN = 1,     # Strength, dominance, survival (Attack/DPS)
	VOIDTOUCHED = 2,  # Knowledge, truth, patience, secrets (Utility/Special)
	UNCHAINED = 3,    # Freedom, chaos, adaptability (Hybrid/Disruptor)
	# Legacy path alignment system (backwards compatibility)
	SHADE = 4,        # -100 to -51 (legacy)
	TWILIGHT = 5,     # -50 to -26 (legacy)
	NEUTRAL = 6,      # -25 to +25 (legacy)
	LIGHT = 7,        # +26 to +50 (legacy)
	SERAPH = 8        # +51 to +100 (legacy)
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

## Monster evolution stages (The Bargain system)
enum EvolutionStage {
	CORRUPTED,   # Wild/enemy state - hostile
	AWAKENED,    # Just captured - basic loyalty
	ASCENDED,    # High loyalty - evolved form
	PURIFIED     # Max loyalty - true form unlocked
}

## Monster combat roles
enum MonsterRole {
	STRIKER,     # High damage dealer
	DEFENDER,    # Tank/protector
	SUPPORT,     # Healer/buffer
	DISRUPTOR    # Debuffer/controller
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
