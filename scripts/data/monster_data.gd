class_name MonsterData
extends Resource
## MonsterData: Defines a monster type's base stats, skills, and drops.

@export_group("Identity")
@export var monster_id: String = ""
@export var display_name: String = "Unknown Monster"
@export var description: String = ""
@export var tier: Enums.MonsterTier = Enums.MonsterTier.COMMON
@export var brand: Enums.Brand = Enums.Brand.NONE
@export var rarity: Enums.Rarity = Enums.Rarity.COMMON

@export_group("Visuals")
@export var sprite_path: String = ""
@export var spine_path: String = ""
@export var portrait_path: String = ""
@export var color_palette: Color = Color.WHITE

@export_group("Elements")
@export var primary_element: Enums.Element = Enums.Element.NONE
@export var secondary_element: Enums.Element = Enums.Element.NONE
@export var weaknesses: Array[Enums.Element] = []
@export var resistances: Array[Enums.Element] = []

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

func get_stat_at_level(stat: String, level: int) -> int:
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

	return int(base_value * pow(growth, level - 1))

func get_elements() -> Array[Enums.Element]:
	var elements: Array[Enums.Element] = []
	if primary_element != Enums.Element.NONE:
		elements.append(primary_element)
	if secondary_element != Enums.Element.NONE:
		elements.append(secondary_element)
	return elements

func get_skills_at_level(level: int) -> Array[String]:
	var skills: Array[String] = innate_skills.duplicate()

	for learn_level in learnable_skills:
		if int(learn_level) <= level:
			skills.append(learnable_skills[learn_level])

	return skills

func create_instance(level: int = 1) -> Monster:
	var monster := Monster.new()

	monster.monster_id = monster_id
	monster.character_name = display_name
	monster.level = level
	monster.brand = brand
	monster.rarity = rarity
	monster.elements = get_elements()

	# Set stats at level
	monster.base_max_hp = get_stat_at_level("hp", level)
	monster.base_max_mp = get_stat_at_level("mp", level)
	monster.base_attack = get_stat_at_level("attack", level)
	monster.base_defense = get_stat_at_level("defense", level)
	monster.base_magic = get_stat_at_level("magic", level)
	monster.base_resistance = get_stat_at_level("resistance", level)
	monster.base_speed = get_stat_at_level("speed", level)
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
