class_name CharacterBase
extends Node2D
## CharacterBase: Base class for all battle participants (players and monsters).

# =============================================================================
# SIGNALS
# =============================================================================

signal stats_changed()
signal hp_changed(old_value: int, new_value: int)
signal mp_changed(old_value: int, new_value: int)
signal status_effect_added(effect: int)
signal status_effect_removed(effect: int)
signal died()
signal revived()

# =============================================================================
# EXPORTED PROPERTIES
# =============================================================================

@export var character_name: String = "Character"
@export var character_type: Enums.CharacterType = Enums.CharacterType.PLAYER
@export var level: int = 1
@export var elements: Array[Enums.Element] = []
@export var brand: Enums.Brand = Enums.Brand.NONE
@export var is_protagonist: bool = false

# =============================================================================
# BASE STATS (before modifiers)
# =============================================================================

@export_group("Base Stats")
@export var base_max_hp: int = 100
@export var base_max_mp: int = 50
@export var base_attack: int = 10
@export var base_defense: int = 10
@export var base_magic: int = 10
@export var base_resistance: int = 10
@export var base_speed: int = 10
@export var base_luck: int = 5
@export var base_crit_chance: float = 0.05
@export var base_crit_damage: float = 1.5
@export var base_accuracy: float = 0.95
@export var base_evasion: float = 0.05

# =============================================================================
# CURRENT VALUES
# =============================================================================

var current_hp: int = 100
var current_mp: int = 50
var status_effects: Dictionary = {}  # {effect_id: {duration, stacks, source}}
var stat_modifiers: Dictionary = {}  # {stat: [{value, duration, source}]}

# Cached autoload references for performance
var _inventory_system_cached: Node = null
var _inventory_cache_valid: bool = false

# =============================================================================
# EQUIPMENT (for player characters)
# =============================================================================

var equipped_weapon: String = ""
var equipped_armor: String = ""
var equipped_accessory_1: String = ""
var equipped_accessory_2: String = ""

# =============================================================================
# SKILLS
# =============================================================================

var known_skills: Array[String] = []

# =============================================================================
# VISUAL
# =============================================================================

var battle_position: Vector2 = Vector2.ZERO
var is_defending: bool = false

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	current_hp = get_max_hp()
	current_mp = get_max_mp()

func initialize_stats() -> void:
	current_hp = get_max_hp()
	current_mp = get_max_mp()
	status_effects.clear()
	stat_modifiers.clear()
	is_defending = false

# =============================================================================
# STAT CALCULATIONS
# =============================================================================

func get_stat(stat: Enums.Stat) -> float:
	var base_value := _get_base_stat(stat)
	var modifier := _get_stat_modifier(stat)
	var equipment_bonus := _get_equipment_bonus(stat)
	return maxf(1.0, base_value + modifier + equipment_bonus)

func _get_base_stat(stat: Enums.Stat) -> float:
	match stat:
		Enums.Stat.HP: return float(current_hp)
		Enums.Stat.MAX_HP: return float(base_max_hp)
		Enums.Stat.MP: return float(current_mp)
		Enums.Stat.MAX_MP: return float(base_max_mp)
		Enums.Stat.ATTACK: return float(base_attack)
		Enums.Stat.DEFENSE: return float(base_defense)
		Enums.Stat.MAGIC: return float(base_magic)
		Enums.Stat.RESISTANCE: return float(base_resistance)
		Enums.Stat.SPEED: return float(base_speed)
		Enums.Stat.LUCK: return float(base_luck)
		Enums.Stat.CRIT_CHANCE: return base_crit_chance
		Enums.Stat.CRIT_DAMAGE: return base_crit_damage
		Enums.Stat.ACCURACY: return base_accuracy
		Enums.Stat.EVASION: return base_evasion
	return 0.0

func _get_stat_modifier(stat: Enums.Stat) -> float:
	if not stat_modifiers.has(stat):
		return 0.0

	var total := 0.0
	for mod in stat_modifiers[stat]:
		total += mod.value
	return total

func _get_equipment_bonus(stat: Enums.Stat) -> float:
	var total := 0.0

	# Cache inventory reference for performance (called frequently during combat)
	if not _inventory_cache_valid:
		_inventory_system_cached = get_node_or_null("/root/InventorySystem")
		_inventory_cache_valid = true

	if _inventory_system_cached == null:
		return total

	# Get bonuses from each equipment slot
	var equipment_ids := [equipped_weapon, equipped_armor, equipped_accessory_1, equipped_accessory_2]

	for item_id in equipment_ids:
		if item_id == "":
			continue

		var item_data: ItemData = _inventory_system_cached.get_item_data(item_id) if _inventory_system_cached.has_method("get_item_data") else null
		if item_data and item_data.stat_bonuses.has(stat):
			total += item_data.stat_bonuses[stat]

	return total

func get_max_hp() -> int:
	return int(get_stat(Enums.Stat.MAX_HP))

func get_max_mp() -> int:
	return int(get_stat(Enums.Stat.MAX_MP))

func get_hp_percent() -> float:
	return float(current_hp) / float(get_max_hp())

func get_mp_percent() -> float:
	var max_mp := get_max_mp()
	if max_mp == 0:
		return 1.0
	return float(current_mp) / float(max_mp)

# =============================================================================
# HEALTH & MANA
# =============================================================================

func take_damage(amount: int, source: Node = null, is_critical: bool = false) -> Dictionary:
	# Capture defending state before clearing it
	var was_defending := is_defending

	# Apply defense reduction if defending
	var actual_amount := amount
	if is_defending:
		actual_amount = int(amount * 0.5)
		is_defending = false

	var actual_damage := mini(actual_amount, current_hp)
	var old_hp := current_hp
	current_hp = maxi(0, current_hp - actual_damage)

	hp_changed.emit(old_hp, current_hp)
	EventBus.damage_dealt.emit(source, self, actual_damage, is_critical)

	# Wake from sleep on damage
	if has_status_effect(Enums.StatusEffect.SLEEP) and actual_damage > 0:
		remove_status_effect(Enums.StatusEffect.SLEEP)

	if current_hp <= 0:
		_on_death()

	return {
		"damage": actual_damage,
		"remaining_hp": current_hp,
		"is_dead": current_hp <= 0,
		"was_defending": was_defending
	}

func heal(amount: int, source: Node = null) -> int:
	var max_hp := get_max_hp()
	var actual_heal := mini(amount, max_hp - current_hp)
	var old_hp := current_hp
	current_hp = mini(max_hp, current_hp + actual_heal)

	hp_changed.emit(old_hp, current_hp)
	if actual_heal > 0:
		EventBus.healing_done.emit(source, self, actual_heal)

	return actual_heal

func use_mp(amount: int) -> bool:
	if current_mp < amount:
		return false

	var old_mp := current_mp
	current_mp -= amount
	mp_changed.emit(old_mp, current_mp)
	return true

func restore_mp(amount: int) -> int:
	var max_mp := get_max_mp()
	var actual_restore := mini(amount, max_mp - current_mp)
	var old_mp := current_mp
	current_mp = mini(max_mp, current_mp + actual_restore)

	mp_changed.emit(old_mp, current_mp)
	return actual_restore

func is_alive() -> bool:
	return current_hp > 0

func is_dead() -> bool:
	return current_hp <= 0

func _on_death() -> void:
	clear_all_status_effects()
	died.emit()
	EventBus.character_died.emit(self)

func revive(hp_percent: float = 0.5) -> void:
	if is_alive():
		return

	current_hp = maxi(1, int(get_max_hp() * hp_percent))
	revived.emit()
	EventBus.character_revived.emit(self)

func full_restore() -> void:
	current_hp = get_max_hp()
	current_mp = get_max_mp()
	clear_all_status_effects()

# =============================================================================
# STATUS EFFECTS
# =============================================================================

func add_status_effect(effect: Enums.StatusEffect, duration: int, source: Node = null) -> void:
	if status_effects.has(effect):
		# Refresh duration
		status_effects[effect].duration = maxi(status_effects[effect].duration, duration)
		status_effects[effect].stacks = mini(status_effects[effect].stacks + 1, 9)
	else:
		status_effects[effect] = {
			"duration": duration,
			"stacks": 1,
			"source": source
		}
		status_effect_added.emit(effect)
		EventBus.status_effect_applied.emit(self, effect, duration)

func remove_status_effect(effect: Enums.StatusEffect) -> void:
	if status_effects.has(effect):
		status_effects.erase(effect)
		status_effect_removed.emit(effect)
		EventBus.status_effect_removed.emit(self, effect)

func has_status_effect(effect: Enums.StatusEffect) -> bool:
	return status_effects.has(effect)

func get_status_effect_stacks(effect: Enums.StatusEffect) -> int:
	if status_effects.has(effect):
		return status_effects[effect].stacks
	return 0

func tick_status_effects() -> Array[Dictionary]:
	var tick_results: Array[Dictionary] = []
	var effects_to_remove: Array[Enums.StatusEffect] = []

	for effect in status_effects:
		var data: Dictionary = status_effects[effect]

		# Process effect tick
		var tick_damage := 0
		var tick_heal := 0

		match effect:
			Enums.StatusEffect.POISON:
				tick_damage = int(get_max_hp() * 0.05 * data.stacks)
			Enums.StatusEffect.BURN:
				tick_damage = int(get_max_hp() * 0.08 * data.stacks)
			Enums.StatusEffect.BLEED:
				tick_damage = int(get_max_hp() * 0.03 * data.stacks)
			Enums.StatusEffect.REGEN:
				tick_heal = int(get_max_hp() * 0.05 * data.stacks)

		if tick_damage > 0:
			take_damage(tick_damage, data.source)
			EventBus.status_effect_tick.emit(self, effect, tick_damage)
			tick_results.append({"effect": effect, "damage": tick_damage})

		if tick_heal > 0:
			heal(tick_heal, data.source)
			tick_results.append({"effect": effect, "heal": tick_heal})

		# Reduce duration
		data.duration -= 1
		if data.duration <= 0:
			effects_to_remove.append(effect)

	# Remove expired effects
	for effect in effects_to_remove:
		remove_status_effect(effect)

	return tick_results

func clear_all_status_effects() -> void:
	var effects := status_effects.keys().duplicate()
	for effect in effects:
		remove_status_effect(effect)

func can_act() -> bool:
	if is_dead():
		return false
	if has_status_effect(Enums.StatusEffect.SLEEP):
		return false
	if has_status_effect(Enums.StatusEffect.FREEZE):
		return false
	if has_status_effect(Enums.StatusEffect.PARALYSIS):
		# 50% chance to be unable to act
		return randf() > 0.5
	return true

# =============================================================================
# STAT MODIFIERS
# =============================================================================

func add_stat_modifier(stat: Enums.Stat, value: float, duration: int, source: String = "") -> void:
	if not stat_modifiers.has(stat):
		stat_modifiers[stat] = []

	stat_modifiers[stat].append({
		"value": value,
		"duration": duration,
		"source": source
	})
	stats_changed.emit()

func tick_stat_modifiers() -> void:
	var changed := false

	for stat in stat_modifiers:
		var to_remove := []
		for i in range(stat_modifiers[stat].size()):
			stat_modifiers[stat][i].duration -= 1
			if stat_modifiers[stat][i].duration <= 0:
				to_remove.append(i)
				changed = true

		# Remove expired modifiers (reverse order)
		for i in range(to_remove.size() - 1, -1, -1):
			stat_modifiers[stat].remove_at(to_remove[i])

	if changed:
		stats_changed.emit()

func clear_stat_modifiers() -> void:
	stat_modifiers.clear()
	stats_changed.emit()

func remove_stat_modifiers_by_source(source: String) -> void:
	## Remove all stat modifiers with the given source string
	var changed := false

	for stat in stat_modifiers:
		var to_remove := []
		for i in range(stat_modifiers[stat].size()):
			if stat_modifiers[stat][i].source == source:
				to_remove.append(i)
				changed = true

		# Remove in reverse order to preserve indices
		for i in range(to_remove.size() - 1, -1, -1):
			stat_modifiers[stat].remove_at(to_remove[i])

	if changed:
		stats_changed.emit()

# =============================================================================
# SKILLS
# =============================================================================

func can_use_skill(skill_id: String) -> bool:
	if skill_id not in known_skills:
		return false

	# Check silence status
	if has_status_effect(Enums.StatusEffect.SILENCE):
		return false

	# Check MP cost from skill data
	var skill_data: SkillData = DataManager.get_skill(skill_id) if DataManager else null
	if skill_data:
		if current_mp < skill_data.mp_cost:
			return false
		if current_hp <= skill_data.hp_cost:
			return false

	return true

func learn_skill(skill_id: String) -> void:
	if skill_id not in known_skills:
		known_skills.append(skill_id)
		EventBus.skill_learned.emit(self, skill_id)

func forget_skill(skill_id: String) -> void:
	if skill_id in known_skills:
		known_skills.erase(skill_id)

# =============================================================================
# DEFEND
# =============================================================================

func set_defending(defending: bool) -> void:
	is_defending = defending
	if defending:
		add_stat_modifier(Enums.Stat.DEFENSE, base_defense * 0.5, 1, "defend")

# =============================================================================
# LEVEL UP
# =============================================================================

func level_up() -> Dictionary:
	level += 1

	# Calculate stat gains (randomized growth)
	var stat_gains := {
		"max_hp": randi_range(5, 15),
		"max_mp": randi_range(2, 8),
		"attack": randi_range(1, 4),
		"defense": randi_range(1, 4),
		"magic": randi_range(1, 4),
		"resistance": randi_range(1, 4),
		"speed": randi_range(1, 3),
		"luck": randi_range(0, 2)
	}

	# Apply stat gains
	base_max_hp += stat_gains.max_hp
	base_max_mp += stat_gains.max_mp
	base_attack += stat_gains.attack
	base_defense += stat_gains.defense
	base_magic += stat_gains.magic
	base_resistance += stat_gains.resistance
	base_speed += stat_gains.speed
	base_luck += stat_gains.luck

	# Fully heal on level up
	current_hp = get_max_hp()
	current_mp = get_max_mp()

	EventBus.level_up.emit(self, level, stat_gains)

	return stat_gains

# =============================================================================
# SERIALIZATION
# =============================================================================

func get_save_data() -> Dictionary:
	return {
		"name": character_name,
		"type": character_type,
		"level": level,
		"elements": elements,
		"brand": brand,
		"is_protagonist": is_protagonist,
		"current_hp": current_hp,
		"current_mp": current_mp,
		"base_max_hp": base_max_hp,
		"base_max_mp": base_max_mp,
		"base_attack": base_attack,
		"base_defense": base_defense,
		"base_magic": base_magic,
		"base_resistance": base_resistance,
		"base_speed": base_speed,
		"base_luck": base_luck,
		"base_crit_chance": base_crit_chance,
		"base_crit_damage": base_crit_damage,
		"known_skills": known_skills,
		"equipped_weapon": equipped_weapon,
		"equipped_armor": equipped_armor,
		"equipped_accessory_1": equipped_accessory_1,
		"equipped_accessory_2": equipped_accessory_2
	}

func load_save_data(data: Dictionary) -> void:
	character_name = data.get("name", "Character")
	character_type = data.get("type", Enums.CharacterType.PLAYER)
	level = data.get("level", 1)
	elements = data.get("elements", [])
	brand = data.get("brand", Enums.Brand.NONE)
	is_protagonist = data.get("is_protagonist", false)
	current_hp = data.get("current_hp", 100)
	current_mp = data.get("current_mp", 50)
	base_max_hp = data.get("base_max_hp", 100)
	base_max_mp = data.get("base_max_mp", 50)
	base_attack = data.get("base_attack", 10)
	base_defense = data.get("base_defense", 10)
	base_magic = data.get("base_magic", 10)
	base_resistance = data.get("base_resistance", 10)
	base_speed = data.get("base_speed", 10)
	base_luck = data.get("base_luck", 5)
	base_crit_chance = data.get("base_crit_chance", 0.05)
	base_crit_damage = data.get("base_crit_damage", 1.5)
	known_skills = data.get("known_skills", [])
	equipped_weapon = data.get("equipped_weapon", "")
	equipped_armor = data.get("equipped_armor", "")
	equipped_accessory_1 = data.get("equipped_accessory_1", "")
	equipped_accessory_2 = data.get("equipped_accessory_2", "")
