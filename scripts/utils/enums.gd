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
	PURIFICATION
}

enum BattleAction {
	ATTACK,
	SKILL,
	DEFEND,
	ITEM,
	PURIFY,
	FLEE,
	SWAP
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
	PURIFYING
}

# =============================================================================
# PROGRESSION
# =============================================================================

enum Brand {
	NONE,
	BULWARK,   # Tank / Earth
	FANG,      # Physical DPS
	EMBER,     # Fire / AoE
	FROST,     # Ice / Control
	VOID,      # Dark / Debuff
	RADIANT    # Light / Healer
}

enum Path {
	SHADE = -2,      # -100 to -51
	TWILIGHT = -1,   # -50 to -26
	NEUTRAL = 0,     # -25 to +25
	LIGHT = 1,       # +26 to +50
	SERAPH = 2       # +51 to +100
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
