class_name MonsterData
extends Resource
## MonsterData: Defines a monster type's base stats, skills, and drops.

@export_group("Identity")
@export var monster_id: String = ""
@export var display_name: String = "Unknown Monster"
@export var description: String = ""
@export var tier: Enums.MonsterTier = Enums.MonsterTier.COMMON
@export var rarity: Enums.Rarity = Enums.Rarity.COMMON

@export_group("Brand System (v5.0)")
## Monster brand tier: PURE (3 stages), HYBRID (3 stages), PRIMAL (2 stages)
@export var brand_tier: Enums.MonsterBrandTier = Enums.MonsterBrandTier.PURE
## Primary brand (all monsters have this)
@export var brand: Enums.Brand = Enums.Brand.NONE
## Secondary brand (HYBRID: fixed, PRIMAL: assigned at evolution)
@export var secondary_brand: Enums.Brand = Enums.Brand.NONE
## Current evolution stage
@export var evolution_stage: Enums.EvolutionStage = Enums.EvolutionStage.BIRTH

@export_group("Visuals")
@export var sprite_path: String = ""
@export var spine_path: String = ""
@export var portrait_path: String = ""
@export var color_palette: Color = Color.WHITE

@export_group("Base Stats")
@export var base_hp: int = 50
@export var base_mp: int = 20
@export var base_attack: int = 10
@export var base_defense: int = 8
@export var base_magic: int = 8
@export var base_resistance: int = 8
@export var base_speed: int = 10
@export var base_luck: int = 5

@export_group("Growth Rates")
@export var hp_growth: float = 1.2
@export var mp_growth: float = 1.1
@export var attack_growth: float = 1.15
@export var defense_growth: float = 1.1
@export var magic_growth: float = 1.1
@export var resistance_growth: float = 1.1
@export var speed_growth: float = 1.05

@export_group("Skills")
@export var innate_skills: Array[String] = []
@export var learnable_skills: Dictionary = {}  # {level: skill_id}

@export_group("AI Behavior")
@export var ai_pattern: String = "aggressive"
@export var skill_weights: Dictionary = {}

@export_group("Corruption")
@export var base_corruption: float = 50.0
@export var corruption_resistance: float = 0.0

@export_group("Rewards")
@export var base_experience: int = 10
@export var base_currency: int = 5
@export var drop_table: Array[Dictionary] = []  # [{item_id, chance, quantity}]

@export_group("Lore")
@export var habitat: String = ""
@export var behavior_notes: String = ""
@export var purification_hint: String = ""

# =============================================================================
# METHODS
# =============================================================================

func get_stat_at_level(stat: String, level: int, evo_stage: Enums.EvolutionStage = Enums.EvolutionStage.BIRTH) -> int:
	var base_value: int
	var growth: float

	match stat:
		"hp":
			base_value = base_hp
			growth = hp_growth
		"mp":
			base_value = base_mp
			growth = mp_growth
		"attack":
			base_value = base_attack
			growth = attack_growth
		"defense":
			base_value = base_defense
			growth = defense_growth
		"magic":
			base_value = base_magic
			growth = magic_growth
		"resistance":
			base_value = base_resistance
			growth = resistance_growth
		"speed":
			base_value = base_speed
			growth = speed_growth
		_:
			return 0

	var raw_stat := base_value * pow(growth, level - 1)

	# Apply evolution stage stat growth bonus (v5.0)
	var evo_multiplier := _get_evolution_stat_multiplier(evo_stage, level)

	return int(raw_stat * evo_multiplier)

func _get_evolution_stat_multiplier(evo_stage: Enums.EvolutionStage, level: int) -> float:
	"""Get stat multiplier based on evolution stage and level (v5.0)"""
	match evo_stage:
		Enums.EvolutionStage.BIRTH:
			return Constants.STAT_GROWTH_NORMAL
		Enums.EvolutionStage.EVO_2:
			return Constants.STAT_GROWTH_EVO2
		Enums.EvolutionStage.EVO_3:
			return Constants.STAT_GROWTH_EVO3
		Enums.EvolutionStage.EVOLVED:
			# PRIMAL overflow stats at level 110+
			if level >= Constants.PRIMAL_OVERFLOW_LEVEL:
				var overflow_levels := level - Constants.PRIMAL_OVERFLOW_LEVEL
				return Constants.STAT_GROWTH_PRIMAL_EVOLVED * pow(Constants.STAT_GROWTH_PRIMAL_OVERFLOW, overflow_levels)
			return Constants.STAT_GROWTH_PRIMAL_EVOLVED
		_:
			return Constants.STAT_GROWTH_NORMAL

func get_max_level() -> int:
	"""Get max level based on brand tier (v5.0)"""
	match brand_tier:
		Enums.MonsterBrandTier.PRIMAL:
			return Constants.MAX_LEVEL_PRIMAL  # 120
		_:
			return Constants.MAX_LEVEL_PURE_HYBRID  # 100

func get_xp_multiplier(evo_stage: Enums.EvolutionStage) -> float:
	"""Get XP requirement multiplier based on tier and stage (v5.0)"""
	match brand_tier:
		Enums.MonsterBrandTier.PRIMAL:
			match evo_stage:
				Enums.EvolutionStage.BIRTH:
					return Constants.XP_MULT_PRIMAL_BIRTH
				Enums.EvolutionStage.EVOLVED:
					return Constants.XP_MULT_PRIMAL_EVOLVED
				_:
					return Constants.XP_MULT_PRIMAL_EVOLVED
		_:  # PURE or HYBRID
			match evo_stage:
				Enums.EvolutionStage.BIRTH:
					return Constants.XP_MULT_PURE_BIRTH
				Enums.EvolutionStage.EVO_2:
					return Constants.XP_MULT_PURE_EVO2
				Enums.EvolutionStage.EVO_3:
					return Constants.XP_MULT_PURE_EVO3
				_:
					return Constants.XP_MULT_PURE_BIRTH

func can_evolve(current_level: int, current_stage: Enums.EvolutionStage) -> bool:
	"""Check if monster can evolve at current level (v5.0)"""
	match brand_tier:
		Enums.MonsterBrandTier.PRIMAL:
			# PRIMAL: Birth → Evolved (only 1 evolution)
			return current_stage == Enums.EvolutionStage.BIRTH and current_level >= Constants.PRIMAL_EVO_LEVEL
		_:  # PURE or HYBRID
			# 3 stages: Birth → Evo2 → Evo3
			match current_stage:
				Enums.EvolutionStage.BIRTH:
					return current_level >= Constants.EVO_2_LEVEL
				Enums.EvolutionStage.EVO_2:
					return current_level >= Constants.EVO_3_LEVEL
				_:
					return false

func get_next_evolution_stage(current_stage: Enums.EvolutionStage) -> Enums.EvolutionStage:
	"""Get the next evolution stage (v5.0)"""
	match brand_tier:
		Enums.MonsterBrandTier.PRIMAL:
			if current_stage == Enums.EvolutionStage.BIRTH:
				return Enums.EvolutionStage.EVOLVED
			return current_stage  # Already at max
		_:  # PURE or HYBRID
			match current_stage:
				Enums.EvolutionStage.BIRTH:
					return Enums.EvolutionStage.EVO_2
				Enums.EvolutionStage.EVO_2:
					return Enums.EvolutionStage.EVO_3
				_:
					return current_stage  # Already at max

func get_skills_at_level(level: int) -> Array[String]:
	var skills: Array[String] = innate_skills.duplicate()

	for learn_level in learnable_skills:
		if int(learn_level) <= level:
			skills.append(learnable_skills[learn_level])

	return skills

func create_instance(level: int = 1, evo_stage: Enums.EvolutionStage = Enums.EvolutionStage.BIRTH) -> Monster:
	var monster := Monster.new()

	monster.monster_id = monster_id
	monster.character_name = display_name
	monster.level = level
	monster.brand = brand
	monster.rarity = rarity
	monster.monster_tier = tier  # Set tier from MonsterData

	# Brand System
	monster.brand_tier = brand_tier
	monster.secondary_brand = secondary_brand
	monster.evolution_stage = evo_stage

	# Set stats at level with evolution bonus
	monster.base_max_hp = get_stat_at_level("hp", level, evo_stage)
	monster.base_max_mp = get_stat_at_level("mp", level, evo_stage)
	monster.base_attack = get_stat_at_level("attack", level, evo_stage)
	monster.base_defense = get_stat_at_level("defense", level, evo_stage)
	monster.base_magic = get_stat_at_level("magic", level, evo_stage)
	monster.base_resistance = get_stat_at_level("resistance", level, evo_stage)
	monster.base_speed = get_stat_at_level("speed", level, evo_stage)
	monster.base_luck = base_luck

	monster.current_hp = monster.base_max_hp
	monster.current_mp = monster.base_max_mp

	# Corruption
	monster.corruption_level = base_corruption
	monster.corruption_resistance = corruption_resistance

	# Skills
	monster.known_skills = get_skills_at_level(level)

	# AI
	monster.ai_pattern = ai_pattern
	monster.skill_weights = skill_weights.duplicate()

	# Rewards
	monster.experience_reward = int(base_experience * pow(1.1, level - 1))
	monster.currency_reward = int(base_currency * pow(1.05, level - 1))
	monster.drop_table = drop_table.duplicate()

	return monster
