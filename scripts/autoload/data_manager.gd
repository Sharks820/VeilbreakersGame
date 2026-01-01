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
	ErrorLogger.log_info("[DataManager] All data loaded: %d monsters, %d heroes, %d skills, %d items" % [
		monsters.size(), heroes.size(), skills.size(), items.size()
	])


func _load_monsters() -> void:
	var dir := DirAccess.open(MONSTER_PATH)
	if not dir:
		push_warning("[DataManager] Could not open monster directory: " + MONSTER_PATH)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource := load(MONSTER_PATH + file_name)
			if resource and "monster_id" in resource:
				monsters[resource.monster_id] = resource
		file_name = dir.get_next()
	dir.list_dir_end()


func _load_heroes() -> void:
	var dir := DirAccess.open(HERO_PATH)
	if not dir:
		push_warning("[DataManager] Could not open hero directory: " + HERO_PATH)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource := load(HERO_PATH + file_name)
			if resource and "hero_id" in resource:
				heroes[resource.hero_id] = resource
		file_name = dir.get_next()
	dir.list_dir_end()


func _load_skills() -> void:
	# Load hero skills
	_load_skills_from_dir(SKILL_PATH + "heroes/")
	# Load monster skills
	_load_skills_from_dir(SKILL_PATH + "monsters/")


func _load_skills_from_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		push_warning("[DataManager] Could not open skill directory: " + path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource := load(path + file_name)
			if resource and "skill_id" in resource:
				skills[resource.skill_id] = resource
		file_name = dir.get_next()
	dir.list_dir_end()


func _load_items() -> void:
	# Load consumables
	_load_items_from_dir(ITEM_PATH + "consumables/")
	# Load equipment
	_load_items_from_dir(ITEM_PATH + "equipment/")


func _load_items_from_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		push_warning("[DataManager] Could not open item directory: " + path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource := load(path + file_name)
			if resource and "item_id" in resource:
				items[resource.item_id] = resource
		file_name = dir.get_next()
	dir.list_dir_end()


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


func get_skills_by_element(element: int) -> Array:
	var result: Array = []
	for skill in skills.values():
		if skill.element == element:
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
