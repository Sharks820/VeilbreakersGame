class_name HeroData
extends Resource
## HeroData: Defines a hero's base stats, skills, and lore.

@export_group("Identity")
@export var hero_id: String = ""
@export var display_name: String = "Unknown Hero"
@export var title: String = ""
@export var description: String = ""
@export var backstory: String = ""

@export_group("Alignment")
@export var primary_brand: Enums.Brand = Enums.Brand.NONE
@export var primary_path: Enums.Path = Enums.Path.NONE
@export var role: String = "DPS"  # DPS, Tank, Healer, Support, Illusionist

@export_group("Visuals")
@export var sprite_path: String = ""
@export var portrait_path: String = ""
@export var battle_sprite_path: String = ""
@export var color_palette: Color = Color.WHITE

@export_group("Base Stats (Level 1)")
@export var base_hp: int = 100
@export var base_mp: int = 30
@export var base_attack: int = 12
@export var base_defense: int = 10
@export var base_magic: int = 10
@export var base_resistance: int = 10
@export var base_speed: int = 10
@export var base_luck: int = 8

@export_group("Growth Rates")
@export var hp_growth: float = 0.8
@export var mp_growth: float = 0.6
@export var attack_growth: float = 0.5
@export var defense_growth: float = 0.5
@export var magic_growth: float = 0.5
@export var resistance_growth: float = 0.5
@export var speed_growth: float = 0.4
@export var luck_growth: float = 0.3

@export_group("Skills")
@export var innate_skills: Array[String] = ["attack_basic", "defend"]
@export var learnable_skills: Dictionary = {}  # {level: skill_id}
@export var ultimate_skill: String = ""

@export_group("Combat Style")
@export var combat_description: String = ""
@export var preferred_targets: String = "any"  # any, weakest, strongest, random

# =============================================================================
# METHODS
# =============================================================================

func create_instance(level: int = 1) -> PlayerCharacter:
	var hero := PlayerCharacter.new()

	hero.player_id = hero_id
	hero.character_name = display_name
	hero.level = level
	hero.current_brand = primary_brand
	# Use typed array assignment - build it explicitly
	var brands: Array[Enums.Brand] = []
	if primary_brand != Enums.Brand.NONE:
		brands.append(primary_brand)
	else:
		brands.append(Enums.Brand.NONE)
	hero.unlocked_brands = brands

	# Set base stats
	hero.base_max_hp = base_hp
	hero.base_max_mp = base_mp
	hero.base_attack = base_attack
	hero.base_defense = base_defense
	hero.base_magic = base_magic
	hero.base_resistance = base_resistance
	hero.base_speed = base_speed
	hero.base_luck = base_luck

	# Apply level scaling
	if level > 1:
		for i in range(level - 1):
			_apply_level_growth(hero)

	# Set growth rates
	hero.growth_hp = hp_growth
	hero.growth_mp = mp_growth
	hero.growth_attack = attack_growth
	hero.growth_defense = defense_growth
	hero.growth_magic = magic_growth
	hero.growth_resistance = resistance_growth
	hero.growth_speed = speed_growth
	hero.growth_luck = luck_growth

	hero.initialize_stats()

	# Add skills
	for skill_id in innate_skills:
		hero.learn_skill(skill_id)

	for learn_level in learnable_skills:
		if int(learn_level) <= level:
			hero.learn_skill(learnable_skills[learn_level])

	return hero

func _apply_level_growth(hero: PlayerCharacter) -> void:
	if randf() < hp_growth:
		hero.base_max_hp += randi_range(3, 8)
	if randf() < mp_growth:
		hero.base_max_mp += randi_range(1, 4)
	if randf() < attack_growth:
		hero.base_attack += randi_range(1, 3)
	if randf() < defense_growth:
		hero.base_defense += randi_range(1, 2)
	if randf() < magic_growth:
		hero.base_magic += randi_range(1, 3)
	if randf() < resistance_growth:
		hero.base_resistance += randi_range(1, 2)
	if randf() < speed_growth:
		hero.base_speed += randi_range(1, 2)
	if randf() < luck_growth:
		hero.base_luck += 1

func get_skills_at_level(level: int) -> Array[String]:
	var skills: Array[String] = innate_skills.duplicate()

	for learn_level in learnable_skills:
		if int(learn_level) <= level:
			skills.append(learnable_skills[learn_level])

	return skills
