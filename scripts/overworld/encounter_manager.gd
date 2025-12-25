extends Node
## EncounterManager: Handles random encounters and battle transitions.

# =============================================================================
# SIGNALS
# =============================================================================

signal encounter_triggered(enemies: Array)

# =============================================================================
# CONFIGURATION
# =============================================================================

@export var base_encounter_rate: float = 0.05  # 5% per step
@export var steps_per_check: int = 10
@export var min_steps_between_encounters: int = 20

# =============================================================================
# STATE
# =============================================================================

var steps_taken: int = 0
var steps_since_encounter: int = 0
var encounters_disabled: bool = false
var current_area_encounters: Array[Dictionary] = []

# Encounter rate modifiers
var rate_modifier: float = 1.0  # Items/abilities can modify this

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	EventBus.emit_debug("EncounterManager initialized")

# =============================================================================
# STEP TRACKING
# =============================================================================

func register_step() -> void:
	if encounters_disabled:
		return

	steps_taken += 1
	steps_since_encounter += 1

	if steps_taken % steps_per_check == 0:
		_check_encounter()

func _check_encounter() -> void:
	if steps_since_encounter < min_steps_between_encounters:
		return

	if current_area_encounters.is_empty():
		return

	var encounter_chance := base_encounter_rate * rate_modifier

	# Increase chance the longer since last encounter
	var steps_over_min := steps_since_encounter - min_steps_between_encounters
	encounter_chance += steps_over_min * 0.001  # +0.1% per step over minimum

	if randf() < encounter_chance:
		_trigger_encounter()

func _trigger_encounter() -> void:
	steps_since_encounter = 0

	var encounter := _select_encounter()
	if encounter.is_empty():
		return

	var enemies := _create_enemies(encounter)

	encounter_triggered.emit(enemies)
	EventBus.battle_started.emit(enemies)

# =============================================================================
# ENCOUNTER SELECTION
# =============================================================================

func _select_encounter() -> Dictionary:
	if current_area_encounters.is_empty():
		return {}

	# Weight-based selection
	var total_weight := 0.0
	for enc in current_area_encounters:
		total_weight += enc.get("weight", 1.0)

	var roll := randf() * total_weight
	var cumulative := 0.0

	for enc in current_area_encounters:
		cumulative += enc.get("weight", 1.0)
		if roll <= cumulative:
			return enc

	return current_area_encounters[0]

func _create_enemies(encounter: Dictionary) -> Array[CharacterBase]:
	var enemies: Array[CharacterBase] = []

	var monster_list: Array = encounter.get("monsters", [])

	for monster_def in monster_list:
		var monster_id: String = monster_def.get("id", "")
		var level: int = monster_def.get("level", 1)
		var count: int = monster_def.get("count", 1)

		# Random level variance
		var level_variance: int = monster_def.get("level_variance", 0)

		for i in range(count):
			var actual_level := level + randi_range(-level_variance, level_variance)
			actual_level = maxi(1, actual_level)

			var monster := _create_monster(monster_id, actual_level)
			if monster:
				enemies.append(monster)

	return enemies

func _create_monster(monster_id: String, level: int) -> Monster:
	# Load monster data and create instance
	var data_path := "res://data/monsters/%s.tres" % monster_id

	if ResourceLoader.exists(data_path):
		var monster_data: MonsterData = load(data_path)
		return monster_data.create_instance(level)

	# Fallback: create basic monster
	var monster := Monster.new()
	monster.monster_id = monster_id
	monster.character_name = monster_id.capitalize().replace("_", " ")
	monster.level = level
	monster.base_max_hp = 30 + (level * 10)
	monster.base_attack = 8 + (level * 2)
	monster.base_defense = 5 + level
	monster.base_magic = 5 + level
	monster.base_speed = 8 + level
	monster.current_hp = monster.base_max_hp
	monster.corruption_level = 40.0 + randf() * 30.0
	return monster

# =============================================================================
# AREA MANAGEMENT
# =============================================================================

func set_area_encounters(encounters: Array[Dictionary]) -> void:
	"""
	Set encounters for current area.
	Format:
	[
		{
			"weight": 1.0,
			"monsters": [
				{"id": "shadow_imp", "level": 5, "count": 2, "level_variance": 1}
			]
		}
	]
	"""
	current_area_encounters = encounters

func clear_encounters() -> void:
	current_area_encounters.clear()

func disable_encounters() -> void:
	encounters_disabled = true

func enable_encounters() -> void:
	encounters_disabled = false

func set_rate_modifier(modifier: float) -> void:
	rate_modifier = maxf(0.0, modifier)

func reset_rate_modifier() -> void:
	rate_modifier = 1.0

# =============================================================================
# SCRIPTED ENCOUNTERS
# =============================================================================

func trigger_scripted_encounter(encounter: Dictionary) -> void:
	"""Trigger a specific encounter, bypassing random selection."""
	var enemies := _create_enemies(encounter)

	if enemies.size() > 0:
		encounter_triggered.emit(enemies)
		EventBus.battle_started.emit(enemies)

func trigger_boss_encounter(boss_id: String, level: int, minions: Array[Dictionary] = []) -> void:
	"""Trigger a boss encounter."""
	var enemies: Array[CharacterBase] = []

	var boss := _create_monster(boss_id, level)
	if boss:
		boss.rarity = Enums.Rarity.LEGENDARY
		boss.monster_tier = Enums.MonsterTier.BOSS
		enemies.append(boss)

	for minion_def in minions:
		var minion := _create_monster(minion_def.get("id", ""), minion_def.get("level", level - 5))
		if minion:
			enemies.append(minion)

	if enemies.size() > 0:
		encounter_triggered.emit(enemies)
		EventBus.battle_started.emit(enemies)
