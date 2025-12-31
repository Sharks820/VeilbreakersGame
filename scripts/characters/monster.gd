class_name Monster
extends CharacterBase
## Monster: Capturable enemy with corruption and purification mechanics.

# =============================================================================
# SIGNALS
# =============================================================================

signal corruption_changed(old_value: float, new_value: float)
signal purification_started()
signal purification_progress_updated(progress: float)
signal purification_completed()
signal purification_failed()
signal recruited()

# =============================================================================
# MONSTER-SPECIFIC PROPERTIES
# =============================================================================

@export_group("Monster Data")
@export var monster_id: String = ""
@export var monster_tier: Enums.MonsterTier = Enums.MonsterTier.COMMON
@export var rarity: Enums.Rarity = Enums.Rarity.COMMON
@export var description: String = ""

@export_group("Corruption")
@export var corruption_level: float = 50.0  # 0-100, lower = easier to purify
@export var max_corruption: float = 100.0  # Maximum corruption level
@export var corruption_resistance: float = 0.0  # Resistance to purification
@export var purification_resistance: float = 0.0  # Additional resistance (deprecated, use corruption_resistance)
@export var is_corrupted: bool = true
@export var _can_purify_flag: bool = true  ## Internal flag - use can_be_purified() method

@export_group("Rewards")
@export var experience_reward: int = 10
@export var currency_reward: int = 5
@export var drop_table: Array[Dictionary] = []  # [{item_id, chance, quantity}]

@export_group("AI Behavior")
@export var ai_pattern: String = "aggressive"  # aggressive, defensive, support, random, boss
@export var skill_weights: Dictionary = {}  # {skill_id: weight}
@export var preferred_targets: String = "lowest_hp"  # lowest_hp, highest_hp, random, healer

# =============================================================================
# RUNTIME STATE
# =============================================================================

var purification_progress: float = 0.0
var is_being_purified: bool = false
var turns_since_last_skill: int = 0

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	super._ready()
	character_type = Enums.CharacterType.BOSS if is_boss() else Enums.CharacterType.MONSTER
	_apply_tier_scaling()

func _apply_tier_scaling() -> void:
	# Scale stats based on tier
	var tier_mult := 1.0
	match monster_tier:
		Enums.MonsterTier.COMMON:
			tier_mult = 1.0
		Enums.MonsterTier.UNCOMMON:
			tier_mult = 1.5
		Enums.MonsterTier.RARE:
			tier_mult = 2.0
		Enums.MonsterTier.BOSS:
			tier_mult = 3.0

	base_max_hp = int(base_max_hp * tier_mult)
	base_attack = int(base_attack * tier_mult)
	base_defense = int(base_defense * tier_mult)
	base_magic = int(base_magic * tier_mult)
	experience_reward = int(experience_reward * tier_mult)
	currency_reward = int(currency_reward * tier_mult)

	current_hp = get_max_hp()

func is_boss() -> bool:
	return rarity == Enums.Rarity.LEGENDARY or monster_tier == Enums.MonsterTier.BOSS

func can_be_purified() -> bool:
	## Returns true if monster can currently be purified
	if not is_alive():
		return false
	if not is_corrupted:
		return false
	# Check the exported flag (renamed to _purifiable to avoid name conflict)
	return _can_purify_flag

# =============================================================================
# CORRUPTION & PURIFICATION
# =============================================================================

func get_purification_chance() -> float:
	if not can_be_purified():
		return 0.0

	# Base chance decreases with corruption level
	var base_chance := Constants.PURIFICATION_BASE_CHANCE
	var corruption_penalty := corruption_level * Constants.PURIFICATION_CORRUPTION_PENALTY
	var resistance_penalty := purification_resistance

	# HP factor - easier to purify when weakened
	var hp_percent := get_hp_percent()
	var hp_bonus := (1.0 - hp_percent) * 0.3  # Up to 30% bonus at low HP

	# Rarity penalty
	var rarity_penalty := 0.0
	match rarity:
		Enums.Rarity.UNCOMMON:
			rarity_penalty = 0.05
		Enums.Rarity.RARE:
			rarity_penalty = 0.1
		Enums.Rarity.EPIC:
			rarity_penalty = 0.2
		Enums.Rarity.LEGENDARY:
			rarity_penalty = 0.3

	var final_chance := base_chance - corruption_penalty - resistance_penalty - rarity_penalty + hp_bonus
	return clampf(final_chance, 0.05, 0.95)

func attempt_purification(purifier_power: float = 1.0) -> Dictionary:
	if not can_be_purified():
		return {
			"success": false,
			"reason": "Cannot be purified",
			"monster": self
		}

	is_being_purified = true
	purification_started.emit()
	EventBus.purification_started.emit(self)

	var chance := get_purification_chance() * purifier_power
	var roll := randf()
	var success := roll <= chance

	if success:
		_complete_purification()
		return {
			"success": true,
			"chance": chance,
			"roll": roll,
			"monster": self
		}
	else:
		# Reduce corruption slightly on failed attempt
		reduce_corruption(5.0 + purifier_power * 5.0)
		is_being_purified = false
		purification_failed.emit()
		EventBus.purification_failed.emit(self)
		return {
			"success": false,
			"chance": chance,
			"roll": roll,
			"monster": self
		}

func start_purification_minigame() -> void:
	is_being_purified = true
	purification_progress = 0.0
	purification_started.emit()
	EventBus.purification_started.emit(self)

func update_purification_progress(delta_progress: float) -> void:
	purification_progress = clampf(purification_progress + delta_progress, 0.0, 100.0)
	purification_progress_updated.emit(purification_progress)
	EventBus.purification_progress.emit(self, purification_progress)

	if purification_progress >= 100.0:
		_complete_purification()

func cancel_purification() -> void:
	is_being_purified = false
	purification_progress = 0.0
	purification_failed.emit()

func _complete_purification() -> void:
	is_corrupted = false
	is_being_purified = false
	corruption_level = 0.0
	purification_progress = 100.0
	purification_completed.emit()
	EventBus.purification_succeeded.emit(self)

func reduce_corruption(amount: float) -> void:
	var old := corruption_level
	corruption_level = maxf(0.0, corruption_level - amount)
	if corruption_level != old:
		corruption_changed.emit(old, corruption_level)

func add_corruption(amount: float) -> void:
	var old := corruption_level
	corruption_level = minf(max_corruption, corruption_level + amount)
	if corruption_level != old:
		corruption_changed.emit(old, corruption_level)

func get_purification_progress() -> float:
	## Returns purification progress as 0.0 to 1.0 (1.0 = fully purified)
	return 1.0 - (corruption_level / max_corruption)

func is_purified() -> bool:
	## Returns true if monster is fully purified
	return corruption_level <= 0.0 and not is_corrupted

# =============================================================================
# RECRUITMENT
# =============================================================================

func recruit_to_party() -> bool:
	if is_corrupted:
		EventBus.emit_debug("Cannot recruit corrupted monster: %s" % character_name)
		return false

	recruited.emit()
	EventBus.monster_recruited.emit(self)
	return true

func get_recruitment_stats() -> Dictionary:
	return {
		"name": character_name,
		"level": level,
		"brand": Enums.Brand.keys()[brand],
		"rarity": Enums.Rarity.keys()[rarity],
		"hp": get_max_hp(),
		"attack": base_attack,
		"defense": base_defense,
		"magic": base_magic,
		"speed": base_speed
	}

# =============================================================================
# AI DECISION MAKING
# =============================================================================

func get_ai_action(allies: Array, enemies: Array) -> Dictionary:
	turns_since_last_skill += 1

	match ai_pattern:
		"aggressive":
			return _ai_aggressive(allies, enemies)
		"defensive":
			return _ai_defensive(allies, enemies)
		"support":
			return _ai_support(allies, enemies)
		"boss":
			return _ai_boss(allies, enemies)
		_:
			return _ai_random(allies, enemies)

func _get_preferred_target(enemies: Array) -> CharacterBase:
	var valid_enemies := enemies.filter(func(e): return e.is_alive())
	if valid_enemies.is_empty():
		return null

	match preferred_targets:
		"lowest_hp":
			var target: CharacterBase = valid_enemies[0]
			for enemy in valid_enemies:
				if enemy.current_hp < target.current_hp:
					target = enemy
			return target
		"highest_hp":
			var target: CharacterBase = valid_enemies[0]
			for enemy in valid_enemies:
				if enemy.current_hp > target.current_hp:
					target = enemy
			return target
		"healer":
			# TODO: Check for healer role
			return valid_enemies[randi() % valid_enemies.size()]
		_:
			return valid_enemies[randi() % valid_enemies.size()]

func _ai_aggressive(_allies: Array, enemies: Array) -> Dictionary:
	var target := _get_preferred_target(enemies)

	# Use skill if available and enough turns have passed
	if turns_since_last_skill >= 2 and known_skills.size() > 0:
		var skill_id := known_skills[randi() % known_skills.size()]
		if can_use_skill(skill_id):
			turns_since_last_skill = 0
			return {
				"action": Enums.BattleAction.SKILL,
				"target": target,
				"skill": skill_id
			}

	return {
		"action": Enums.BattleAction.ATTACK,
		"target": target,
		"skill": ""
	}

func _ai_defensive(allies: Array, enemies: Array) -> Dictionary:
	# Defend if HP < 30%
	if get_hp_percent() < 0.3:
		return {"action": Enums.BattleAction.DEFEND, "target": self, "skill": ""}

	# Heal self or allies if available
	for ally in allies:
		if ally.is_alive() and ally.get_hp_percent() < 0.5:
			# TODO: Check for healing skill
			pass

	return _ai_aggressive(allies, enemies)

func _ai_support(allies: Array, enemies: Array) -> Dictionary:
	# Find lowest HP ally
	var lowest_ally: CharacterBase = null
	var lowest_percent: float = 1.0

	for ally in allies:
		if ally.is_alive():
			var hp_percent: float = ally.get_hp_percent()
			if hp_percent < lowest_percent:
				lowest_percent = hp_percent
				lowest_ally = ally

	# Heal if any ally below 50%
	if lowest_ally and lowest_percent < 0.5:
		# TODO: Use healing skill
		pass

	# Buff allies
	# TODO: Check for buff skills

	return _ai_aggressive(allies, enemies)

func _ai_boss(allies: Array, enemies: Array) -> Dictionary:
	# Bosses use skills more frequently
	if known_skills.size() > 0 and randf() > 0.4:
		var skill_id := known_skills[randi() % known_skills.size()]
		if can_use_skill(skill_id):
			var target := _get_preferred_target(enemies)
			return {
				"action": Enums.BattleAction.SKILL,
				"target": target,
				"skill": skill_id
			}

	# Phase changes based on HP (for future implementation)
	var hp_percent := get_hp_percent()
	if hp_percent < 0.25:
		# Enraged phase - more aggressive
		pass
	elif hp_percent < 0.5:
		# Desperate phase
		pass

	return _ai_aggressive(allies, enemies)

func _ai_random(_allies: Array, enemies: Array) -> Dictionary:
	var actions := [Enums.BattleAction.ATTACK, Enums.BattleAction.DEFEND]
	var action: Enums.BattleAction = actions[randi() % actions.size()]

	var target: CharacterBase = null
	if action == Enums.BattleAction.ATTACK:
		var valid := enemies.filter(func(e): return e.is_alive())
		if valid.size() > 0:
			target = valid[randi() % valid.size()]

	return {"action": action, "target": target, "skill": ""}

# =============================================================================
# REWARDS
# =============================================================================

func get_rewards() -> Dictionary:
	var drops: Array[Dictionary] = []

	for drop in drop_table:
		var chance: float = drop.get("chance", 0.1)
		if randf() <= chance:
			drops.append({
				"item_id": drop.get("item_id", ""),
				"quantity": drop.get("quantity", 1)
			})

	# Rarity bonus
	var rarity_mult := 1.0
	match rarity:
		Enums.Rarity.UNCOMMON:
			rarity_mult = 1.25
		Enums.Rarity.RARE:
			rarity_mult = 1.5
		Enums.Rarity.EPIC:
			rarity_mult = 2.0
		Enums.Rarity.LEGENDARY:
			rarity_mult = 3.0

	return {
		"experience": int(experience_reward * rarity_mult),
		"currency": int(currency_reward * rarity_mult),
		"items": drops
	}

# =============================================================================
# SERIALIZATION
# =============================================================================

func get_save_data() -> Dictionary:
	var data := super.get_save_data()
	data.merge({
		"monster_id": monster_id,
		"monster_tier": monster_tier,
		"rarity": rarity,
		"description": description,
		"corruption_level": corruption_level,
		"max_corruption": max_corruption,
		"is_corrupted": is_corrupted,
		"can_purify_flag": _can_purify_flag,
		"ai_pattern": ai_pattern
	})
	return data

func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)
	monster_id = data.get("monster_id", "")
	monster_tier = data.get("monster_tier", Enums.MonsterTier.COMMON)
	rarity = data.get("rarity", Enums.Rarity.COMMON)
	description = data.get("description", "")
	corruption_level = data.get("corruption_level", 50.0)
	max_corruption = data.get("max_corruption", 100.0)
	is_corrupted = data.get("is_corrupted", true)
	_can_purify_flag = data.get("can_purify_flag", true)
	ai_pattern = data.get("ai_pattern", "aggressive")

# =============================================================================
# FACTORY METHOD
# =============================================================================

static func create_from_data(data: Dictionary) -> Monster:
	var monster := Monster.new()
	monster.monster_id = data.get("id", "unknown")
	monster.character_name = data.get("name", "Unknown Monster")
	monster.description = data.get("description", "")
	monster.level = data.get("level", 1)
	monster.monster_tier = data.get("tier", Enums.MonsterTier.COMMON)
	monster.brand = data.get("brand", Enums.Brand.NONE)
	monster.rarity = data.get("rarity", Enums.Rarity.COMMON)
	monster.elements = data.get("elements", [])

	# Stats
	monster.base_max_hp = data.get("hp", 100)
	monster.base_max_mp = data.get("mp", 50)
	monster.base_attack = data.get("attack", 10)
	monster.base_defense = data.get("defense", 10)
	monster.base_magic = data.get("magic", 10)
	monster.base_resistance = data.get("resistance", 10)
	monster.base_speed = data.get("speed", 10)

	# Corruption
	monster.corruption_level = data.get("corruption", 50.0)
	monster.max_corruption = data.get("max_corruption", 100.0)
	monster._can_purify_flag = data.get("can_purify", true)

	# AI
	monster.ai_pattern = data.get("ai_pattern", "aggressive")
	monster.known_skills = data.get("skills", [])

	# Rewards
	monster.experience_reward = data.get("exp_reward", 10)
	monster.currency_reward = data.get("currency_reward", 5)
	monster.drop_table = data.get("drops", [])

	return monster
