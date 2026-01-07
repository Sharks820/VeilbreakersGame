extends Node
## DataManager - Centralized resource loading and caching for all game data
## Loads and provides access to all .tres resources (monsters, heroes, skills, items)

# Cached data dictionaries
var monsters: Dictionary = {}
var heroes: Dictionary = {}
var skills: Dictionary = {}
var items: Dictionary = {}

# Resource paths
const MONSTER_PATH := "res://data/monsters/"
const HERO_PATH := "res://data/heroes/"
const SKILL_PATH := "res://data/skills/"
const ITEM_PATH := "res://data/items/"

# Loading state
var _is_loaded := false

signal data_loaded


func _ready() -> void:
	load_all_data()


func load_all_data() -> void:
	if _is_loaded:
		return

	_load_monsters()
	_load_heroes()
	_load_skills()
	_load_items()

	_is_loaded = true
	data_loaded.emit()
	# Safety check for ErrorLogger autoload order
	if has_node("/root/ErrorLogger"):
		ErrorLogger.log_info(
			(
				"[DataManager] All data loaded: %d monsters, %d heroes, %d skills, %d items"
				% [monsters.size(), heroes.size(), skills.size(), items.size()]
			)
		)
	else:
		print(
			(
				"[DataManager] All data loaded: %d monsters, %d heroes, %d skills, %d items"
				% [monsters.size(), heroes.size(), skills.size(), items.size()]
			)
		)


# =============================================================================
# GENERIC RESOURCE LOADER (eliminates duplicate directory loading code)
# =============================================================================


func _load_resources_from_dir(path: String, id_property: String, target_dict: Dictionary) -> void:
	## Generic loader: loads all .tres files from a directory into a dictionary
	## @param path: Directory path to scan
	## @param id_property: Property name to use as dictionary key (e.g., "monster_id")
	## @param target_dict: Dictionary to store loaded resources
	var dir := DirAccess.open(path)
	if not dir:
		push_warning("[DataManager] Could not open directory: " + path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource := load(path + file_name)
			if resource and id_property in resource:
				target_dict[resource.get(id_property)] = resource
		file_name = dir.get_next()
	dir.list_dir_end()


func _load_monsters() -> void:
	_load_resources_from_dir(MONSTER_PATH, "monster_id", monsters)


func _load_heroes() -> void:
	_load_resources_from_dir(HERO_PATH, "hero_id", heroes)


func _load_skills() -> void:
	# Load skills from root skills directory (attack_basic, defend, hero skills, etc.)
	_load_resources_from_dir(SKILL_PATH, "skill_id", skills)
	# Load hero skills from subdirectory (if any exist there)
	_load_resources_from_dir(SKILL_PATH + "heroes/", "skill_id", skills)
	# Load monster skills from subdirectory
	_load_resources_from_dir(SKILL_PATH + "monsters/", "skill_id", skills)


func _load_items() -> void:
	# Load consumables
	_load_resources_from_dir(ITEM_PATH + "consumables/", "item_id", items)
	# Load equipment
	_load_resources_from_dir(ITEM_PATH + "equipment/", "item_id", items)


# ============================================================================
# PUBLIC API - Getters
# ============================================================================


func get_monster(monster_id: String) -> Resource:
	if monsters.has(monster_id):
		return monsters[monster_id]
	push_warning("[DataManager] Monster not found: " + monster_id)
	return null


func get_hero(hero_id: String) -> Resource:
	if heroes.has(hero_id):
		return heroes[hero_id]
	push_warning("[DataManager] Hero not found: " + hero_id)
	return null


func get_skill(skill_id: String) -> Resource:
	if skills.has(skill_id):
		return skills[skill_id]
	push_warning("[DataManager] Skill not found: " + skill_id)
	return null


func get_item(item_id: String) -> Resource:
	if items.has(item_id):
		return items[item_id]
	push_warning("[DataManager] Item not found: " + item_id)
	return null


# ============================================================================
# PUBLIC API - Collection Getters
# ============================================================================


func get_all_monsters() -> Array:
	return monsters.values()


func get_all_heroes() -> Array:
	return heroes.values()


func get_all_skills() -> Array:
	return skills.values()


func get_all_items() -> Array:
	return items.values()


func get_monsters_by_tier(tier: int) -> Array:
	var result: Array = []
	for monster in monsters.values():
		if monster.tier == tier:
			result.append(monster)
	return result


func get_skills_by_brand(brand: int) -> Array:
	var result: Array = []
	for skill in skills.values():
		if "brand_type" in skill and skill.brand_type == brand:
			result.append(skill)
	return result


func get_skills_for_monster(monster_id: String) -> Array:
	var monster := get_monster(monster_id)
	if not monster:
		return []

	var result: Array = []
	# Include innate skills
	for skill_id in monster.innate_skills:
		var skill := get_skill(skill_id)
		if skill:
			result.append(skill)
	# Include learnable skills (Dictionary {level: skill_id} - iterate values)
	for skill_id in monster.learnable_skills.values():
		var skill := get_skill(skill_id)
		if skill:
			result.append(skill)
	return result


func get_skills_for_hero(hero_id: String) -> Array:
	var hero := get_hero(hero_id)
	if not hero:
		return []

	var result: Array = []
	# Include innate skills (was incorrectly referencing starting_skills)
	for skill_id in hero.innate_skills:
		var skill := get_skill(skill_id)
		if skill:
			result.append(skill)
	# Include learnable skills (Dictionary {level: skill_id} - iterate values)
	for skill_id in hero.learnable_skills.values():
		var skill := get_skill(skill_id)
		if skill:
			result.append(skill)
	return result


func get_items_by_type(item_type: int) -> Array:
	var result: Array = []
	for item in items.values():
		if item.item_type == item_type:
			result.append(item)
	return result


func get_equipment_by_slot(slot: int) -> Array:
	var result: Array = []
	for item in items.values():
		if item.item_type == 1 and item.equipment_slot == slot:  # 1 = EQUIPMENT
			result.append(item)
	return result


# ============================================================================
# UTILITY
# ============================================================================


func is_loaded() -> bool:
	return _is_loaded


func reload_all() -> void:
	monsters.clear()
	heroes.clear()
	skills.clear()
	items.clear()
	_is_loaded = false
	load_all_data()


func get_random_monster(tier: int = -1) -> Resource:
	var pool: Array
	if tier >= 0:
		pool = get_monsters_by_tier(tier)
	else:
		pool = get_all_monsters()

	if pool.is_empty():
		return null
	return pool[randi() % pool.size()]


func get_random_item(item_type: int = -1) -> Resource:
	var pool: Array
	if item_type >= 0:
		pool = get_items_by_type(item_type)
	else:
		pool = get_all_items()

	if pool.is_empty():
		return null
	return pool[randi() % pool.size()]
