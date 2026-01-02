class_name Monster
extends CharacterBase
## Monster: Capturable enemy with corruption and purification mechanics.
## 
## CORE PHILOSOPHY: Lower corruption = STRONGER monster.
## Goal is ASCENSION (0-10% corruption) for +25% all stats and perfect loyalty.
## Corruption is the ENEMY - player is a Veilbreaker, meant to FREE creatures.

# =============================================================================
# SIGNALS
# =============================================================================

signal corruption_changed(old_value: float, new_value: float)
signal corruption_state_changed(old_state: Enums.CorruptionState, new_state: Enums.CorruptionState)
signal capture_state_changed(old_state: Enums.CaptureState, new_state: Enums.CaptureState)
signal instability_triggered(action_taken: String)
signal morale_changed(old_level: Enums.MoraleLevel, new_level: Enums.MoraleLevel)
signal ascended()
signal purification_started()
signal purification_progress_updated(progress: float)
signal purification_completed()
signal purification_failed()
signal recruited()
signal experience_changed(old_exp: int, new_exp: int)

# =============================================================================
# MONSTER-SPECIFIC PROPERTIES
# =============================================================================

@export_group("Monster Data")
@export var monster_id: String = ""
@export var monster_tier: Enums.MonsterTier = Enums.MonsterTier.COMMON
@export var rarity: Enums.Rarity = Enums.Rarity.COMMON
@export var description: String = ""

@export_group("Corruption System")
## Corruption level 0-100. LOWER = STRONGER (opposite of traditional systems)
## 0-10: ASCENDED (+25% stats), 11-25: Purified (+10%), 26-50: Unstable (normal)
## 51-75: Corrupted (-10%, 10% Instability), 76-100: Abyssal (-20%, 20% Instability)
@export var corruption_level: float = 50.0
@export var max_corruption: float = 100.0
@export var corruption_resistance: float = 0.0

@export_group("Capture Data")
## How this monster was captured (affects long-term behavior)
@export var capture_method: Enums.CaptureMethod = Enums.CaptureMethod.NONE
## State when captured (determines initial instability and abilities)
@export var capture_state: Enums.CaptureState = Enums.CaptureState.WILD

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

## Current corruption state (calculated from corruption_level)
var corruption_state: Enums.CorruptionState = Enums.CorruptionState.UNSTABLE

## Instability: % chance to ignore commands each turn (from DOMINATE or high corruption)
var instability: float = 0.0

## Whether monster has unlocked its Ascended ability
var has_ascended_ability: bool = false

## Morale system - tracks approval/disapproval of player choices
var morale_level: Enums.MoraleLevel = Enums.MoraleLevel.CONTENT
var morale_approval_count: int = 0
var morale_disapproval_count: int = 0
var battles_since_morale_event: int = 0

## Purification tracking
var purification_progress: float = 0.0
var is_being_purified: bool = false
var turns_since_last_skill: int = 0

## Whether monster is corrupted (wild enemy) or purified (allied)
## True = enemy monster, False = allied/captured monster
var is_corrupted: bool = true

## Experience tracking (for allied/recruited monsters)
var current_experience: int = 0
var total_experience: int = 0

## Stat multiplier from corruption state (cached for performance)
var _corruption_stat_mult: float = 1.0
var _corruption_brand_mult: float = 1.0

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	super._ready()
	character_type = Enums.CharacterType.BOSS if is_boss() else Enums.CharacterType.MONSTER
	_apply_tier_scaling()
	_update_corruption_state()
	_calculate_instability()

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
	# Already at minimum corruption
	if corruption_level <= 0:
		return false
	return true

func can_be_captured() -> bool:
	## Returns true if monster can be captured (bosses cannot)
	if is_boss():
		return false
	if not is_alive():
		return false
	return true

# =============================================================================
# CORRUPTION STATE SYSTEM
# =============================================================================

func _update_corruption_state() -> void:
	## Update corruption state based on current corruption level
	## CORE: Lower corruption = STRONGER monster
	var old_state := corruption_state
	
	if corruption_level <= Constants.CORRUPTION_ASCENDED_MAX:
		corruption_state = Enums.CorruptionState.ASCENDED
		_corruption_stat_mult = Constants.STAT_MULT_ASCENDED
		_corruption_brand_mult = Constants.BRAND_MULT_ASCENDED
	elif corruption_level <= Constants.CORRUPTION_PURIFIED_MAX:
		corruption_state = Enums.CorruptionState.PURIFIED
		_corruption_stat_mult = Constants.STAT_MULT_PURIFIED
		_corruption_brand_mult = Constants.BRAND_MULT_PURIFIED
	elif corruption_level <= Constants.CORRUPTION_UNSTABLE_MAX:
		corruption_state = Enums.CorruptionState.UNSTABLE
		_corruption_stat_mult = Constants.STAT_MULT_UNSTABLE
		_corruption_brand_mult = Constants.BRAND_MULT_UNSTABLE
	elif corruption_level <= Constants.CORRUPTION_CORRUPTED_MAX:
		corruption_state = Enums.CorruptionState.CORRUPTED
		_corruption_stat_mult = Constants.STAT_MULT_CORRUPTED
		_corruption_brand_mult = Constants.BRAND_MULT_CORRUPTED
	else:
		corruption_state = Enums.CorruptionState.ABYSSAL
		_corruption_stat_mult = Constants.STAT_MULT_ABYSSAL
		_corruption_brand_mult = Constants.BRAND_MULT_ABYSSAL
	
	if old_state != corruption_state:
		corruption_state_changed.emit(old_state, corruption_state)
		_on_corruption_state_changed(old_state, corruption_state)
		_calculate_instability()
		stats_changed.emit()

func _on_corruption_state_changed(old_state: Enums.CorruptionState, new_state: Enums.CorruptionState) -> void:
	## Handle corruption state transitions
	# Check for Ascension
	if new_state == Enums.CorruptionState.ASCENDED and old_state != Enums.CorruptionState.ASCENDED:
		_on_monster_ascended()
	
	# Notify event bus
	EventBus.monster_corruption_state_changed.emit(self, old_state, new_state)

func _on_monster_ascended() -> void:
	## Called when monster reaches ASCENDED state (0-10% corruption)
	has_ascended_ability = true
	instability = 0.0  # Perfect loyalty at Ascended
	ascended.emit()
	EventBus.monster_ascended.emit(self)
	EventBus.emit_notification("%s has ASCENDED to its true form!" % character_name, "success")

func get_corruption_state() -> Enums.CorruptionState:
	return corruption_state

func get_corruption_state_name() -> String:
	return Enums.CorruptionState.keys()[corruption_state]

func is_ascended() -> bool:
	return corruption_state == Enums.CorruptionState.ASCENDED

func is_purified_state() -> bool:
	## Returns true if in Purified state (11-25% corruption)
	return corruption_state == Enums.CorruptionState.PURIFIED

func is_corrupted_state() -> bool:
	## Returns true if in Corrupted or Abyssal state
	return corruption_state == Enums.CorruptionState.CORRUPTED or corruption_state == Enums.CorruptionState.ABYSSAL

# =============================================================================
# INSTABILITY SYSTEM
# =============================================================================

func _calculate_instability() -> void:
	## Calculate instability based on corruption state and capture method
	var base_instability := 0.0
	
	# Base instability from corruption state
	match corruption_state:
		Enums.CorruptionState.ASCENDED:
			base_instability = Constants.INSTABILITY_ASCENDED
		Enums.CorruptionState.PURIFIED:
			base_instability = Constants.INSTABILITY_PURIFIED
		Enums.CorruptionState.UNSTABLE:
			base_instability = Constants.INSTABILITY_UNSTABLE
		Enums.CorruptionState.CORRUPTED:
			base_instability = Constants.INSTABILITY_CORRUPTED
		Enums.CorruptionState.ABYSSAL:
			base_instability = Constants.INSTABILITY_ABYSSAL
	
	# Additional instability from DOMINATE capture
	if capture_method == Enums.CaptureMethod.DOMINATE:
		match capture_state:
			Enums.CaptureState.CORRUPTED:
				base_instability += 0.10  # +10% from DOMINATE at Corrupted
			Enums.CaptureState.DOMINATED:
				base_instability += 0.20  # +20% from DOMINATE at Abyssal
	
	# Morale affects instability
	if morale_level == Enums.MoraleLevel.REBELLIOUS:
		base_instability += Constants.MORALE_REBELLIOUS_INSTABILITY_BONUS
	
	instability = clampf(base_instability, 0.0, 0.5)  # Cap at 50%

func check_instability() -> bool:
	## Check if monster ignores command this turn due to instability
	## Returns true if monster goes rogue
	if instability <= 0:
		return false
	
	if randf() < instability:
		instability_triggered.emit("rogue_action")
		return true
	
	return false

func get_instability_action(allies: Array, enemies: Array) -> Dictionary:
	## Get a random action when instability triggers
	## Monster attacks a random target (ally or enemy)
	var all_targets: Array = []
	all_targets.append_array(allies)
	all_targets.append_array(enemies)
	
	var valid := all_targets.filter(func(t): return t.is_alive() and t != self)
	if valid.is_empty():
		return {"action": Enums.BattleAction.DEFEND, "target": self, "skill": ""}
	
	var target = valid[randi() % valid.size()]
	return {
		"action": Enums.BattleAction.ATTACK,
		"target": target,
		"skill": "",
		"is_instability": true
	}

# =============================================================================
# STAT OVERRIDES (Corruption affects all stats)
# =============================================================================

func get_max_hp() -> int:
	return int(super.get_max_hp() * _corruption_stat_mult)

func get_stat(stat: Enums.Stat) -> float:
	var base_stat := super.get_stat(stat)
	
	# Apply corruption multiplier to all stats except HP (handled above)
	if stat != Enums.Stat.MAX_HP:
		base_stat *= _corruption_stat_mult
	
	# Apply morale modifiers
	match morale_level:
		Enums.MoraleLevel.INSPIRED:
			base_stat *= (1.0 + Constants.MORALE_INSPIRED_STAT_BONUS)
		Enums.MoraleLevel.CONFLICTED:
			base_stat *= (1.0 - Constants.MORALE_CONFLICTED_STAT_PENALTY)
	
	return base_stat

func get_brand_multiplier() -> float:
	## Get Brand bonus multiplier (affected by corruption state)
	return _corruption_brand_mult

# =============================================================================
# CORRUPTION MODIFICATION
# =============================================================================

func reduce_corruption(amount: float) -> void:
	var old := corruption_level
	corruption_level = maxf(0.0, corruption_level - amount)
	if corruption_level != old:
		corruption_changed.emit(old, corruption_level)
		_update_corruption_state()

func add_corruption(amount: float) -> void:
	var old := corruption_level
	corruption_level = minf(max_corruption, corruption_level + amount)
	if corruption_level != old:
		corruption_changed.emit(old, corruption_level)
		_update_corruption_state()

func set_corruption(value: float) -> void:
	var old := corruption_level
	corruption_level = clampf(value, 0.0, max_corruption)
	if corruption_level != old:
		corruption_changed.emit(old, corruption_level)
		_update_corruption_state()

func get_purification_progress() -> float:
	## Returns purification progress as 0.0 to 1.0 (1.0 = fully ascended)
	return 1.0 - (corruption_level / max_corruption)

func is_purified() -> bool:
	## Returns true if monster is in Purified or Ascended state
	return corruption_state == Enums.CorruptionState.PURIFIED or corruption_state == Enums.CorruptionState.ASCENDED

# =============================================================================
# CAPTURE SYSTEM INTEGRATION
# =============================================================================

func on_captured(method: Enums.CaptureMethod) -> void:
	## Called when monster is successfully captured
	capture_method = method
	
	# Determine capture state from current corruption
	var old_state := capture_state
	if corruption_level <= Constants.CORRUPTION_ASCENDED_MAX:
		capture_state = Enums.CaptureState.ASCENDED
	elif corruption_level <= Constants.CORRUPTION_PURIFIED_MAX:
		capture_state = Enums.CaptureState.PURIFIED
	elif corruption_level <= Constants.CORRUPTION_UNSTABLE_MAX:
		capture_state = Enums.CaptureState.SOULBOUND
	elif corruption_level <= Constants.CORRUPTION_CORRUPTED_MAX:
		capture_state = Enums.CaptureState.CORRUPTED
	else:
		capture_state = Enums.CaptureState.DOMINATED
	
	capture_state_changed.emit(old_state, capture_state)
	_calculate_instability()
	
	# DOMINATE adds extra corruption
	if method == Enums.CaptureMethod.DOMINATE:
		add_corruption(Constants.DOMINATE_FAIL_CORRUPTION_GAIN)
	
	recruited.emit()
	EventBus.monster_recruited.emit(self)

func get_capture_state_name() -> String:
	return Enums.CaptureState.keys()[capture_state]

func was_dominated() -> bool:
	return capture_method == Enums.CaptureMethod.DOMINATE

func was_bargained() -> bool:
	return capture_method == Enums.CaptureMethod.BARGAIN

# =============================================================================
# MORALE SYSTEM
# =============================================================================

func add_morale_approval() -> void:
	## Player did something this monster's Brand approves of
	morale_approval_count += 1
	battles_since_morale_event = 0
	_update_morale_level()

func add_morale_disapproval() -> void:
	## Player did something this monster's Brand disapproves of
	morale_disapproval_count += 1
	battles_since_morale_event = 0
	_update_morale_level()

func on_battle_end() -> void:
	## Called at end of each battle for morale decay
	battles_since_morale_event += 1
	
	# Decay morale events over time
	if battles_since_morale_event >= Constants.MORALE_DECAY_BATTLES:
		if morale_approval_count > 0:
			morale_approval_count -= 1
		if morale_disapproval_count > 0:
			morale_disapproval_count -= 1
		battles_since_morale_event = 0
		_update_morale_level()

func _update_morale_level() -> void:
	var old_level := morale_level
	
	if morale_disapproval_count >= Constants.MORALE_REBELLIOUS_THRESHOLD:
		morale_level = Enums.MoraleLevel.REBELLIOUS
	elif morale_disapproval_count >= Constants.MORALE_CONFLICTED_THRESHOLD:
		morale_level = Enums.MoraleLevel.CONFLICTED
	elif morale_approval_count >= Constants.MORALE_INSPIRED_THRESHOLD:
		morale_level = Enums.MoraleLevel.INSPIRED
	else:
		morale_level = Enums.MoraleLevel.CONTENT
	
	if old_level != morale_level:
		morale_changed.emit(old_level, morale_level)
		_calculate_instability()
		stats_changed.emit()

func get_brand_approval_action(action: String) -> int:
	## Returns 1 for approval, -1 for disapproval, 0 for neutral
	## Based on monster's Brand beliefs from AGENT_SYSTEMS.md
	var approvals := _get_brand_approvals()
	var disapprovals := _get_brand_disapprovals()
	
	if action in approvals:
		return 1
	elif action in disapprovals:
		return -1
	return 0

func _get_brand_approvals() -> Array[String]:
	match brand:
		Enums.Brand.SAVAGE:
			return ["aggressive_choice", "no_mercy", "execute"]
		Enums.Brand.IRON:
			return ["protect_ally", "stand_ground", "defend"]
		Enums.Brand.VENOM:
			return ["deception", "clever_solution", "status_effect"]
		Enums.Brand.SURGE:
			return ["quick_decision", "rush_in", "first_strike"]
		Enums.Brand.DREAD:
			return ["intimidate", "fear_tactics", "dominate"]
		Enums.Brand.LEECH:
			return ["take_resources", "self_preservation", "lifesteal"]
	return []

func _get_brand_disapprovals() -> Array[String]:
	match brand:
		Enums.Brand.SAVAGE:
			return ["show_weakness", "retreat", "mercy"]
		Enums.Brand.IRON:
			return ["abandon_ally", "cowardice", "flee"]
		Enums.Brand.VENOM:
			return ["brute_force", "honest_when_lying_helps"]
		Enums.Brand.SURGE:
			return ["hesitation", "long_planning", "wait"]
		Enums.Brand.DREAD:
			return ["compassion", "mercy", "purify"]
		Enums.Brand.LEECH:
			return ["sacrifice", "give_away", "generous"]
	return []

# =============================================================================
# PURIFICATION (Legacy support + new system)
# =============================================================================

func get_purification_chance() -> float:
	if not can_be_purified():
		return 0.0

	# Base chance from corruption (lower = easier)
	var base_chance := Constants.PURIFICATION_BASE_CHANCE
	var corruption_penalty := corruption_level * Constants.PURIFICATION_CORRUPTION_PENALTY
	var resistance_penalty := corruption_resistance

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
		# Reduce corruption on failed attempt (PURIFY always reduces corruption)
		reduce_corruption(Constants.PURIFY_CORRUPTION_REDUCTION_ON_FAIL)
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
	is_being_purified = false
	purification_progress = 100.0
	# Set to Purified state (11-25%), not 0
	corruption_level = Constants.CORRUPTION_PURIFIED_MAX * 0.5  # ~12.5%
	_update_corruption_state()
	purification_completed.emit()
	EventBus.purification_succeeded.emit(self)

# =============================================================================
# RECRUITMENT
# =============================================================================

func recruit_to_party() -> bool:
	# Can recruit if captured (any method)
	if capture_state == Enums.CaptureState.WILD:
		EventBus.emit_debug("Cannot recruit wild monster: %s" % character_name)
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
		"corruption_state": get_corruption_state_name(),
		"capture_state": get_capture_state_name(),
		"instability": instability,
		"hp": get_max_hp(),
		"attack": get_stat(Enums.Stat.ATTACK),
		"defense": get_stat(Enums.Stat.DEFENSE),
		"magic": get_stat(Enums.Stat.MAGIC),
		"speed": get_stat(Enums.Stat.SPEED)
	}

# =============================================================================
# EXPERIENCE & LEVELING (for allied/recruited monsters)
# =============================================================================

func add_experience(amount: int) -> Dictionary:
	## Adds experience to the monster and handles level ups
	## Returns level up info if any levels were gained
	var old_exp := current_experience
	var old_level := level
	var levels_gained := 0
	var all_stat_gains := {}

	current_experience += amount
	total_experience += amount

	experience_changed.emit(old_exp, current_experience)
	EventBus.experience_gained.emit(self, amount)

	# Check for level ups
	while current_experience >= get_xp_for_next_level() and level < Constants.MAX_LEVEL:
		current_experience -= get_xp_for_next_level()
		var stat_gains := level_up()
		levels_gained += 1

		# Merge stat gains
		for stat in stat_gains:
			if all_stat_gains.has(stat):
				all_stat_gains[stat] += stat_gains[stat]
			else:
				all_stat_gains[stat] = stat_gains[stat]

	return {
		"old_level": old_level,
		"new_level": level,
		"levels_gained": levels_gained,
		"stat_gains": all_stat_gains,
		"experience_added": amount
	}

func get_xp_for_next_level() -> int:
	## Returns XP required for next level (monsters need slightly less XP than players)
	var base_xp := Constants.get_xp_for_level(level + 1)
	return int(base_xp * 0.8)  # Monsters level up 20% faster

func get_level_progress() -> float:
	## Returns progress to next level as 0.0 to 1.0
	var required := get_xp_for_next_level()
	if required == 0:
		return 1.0
	return float(current_experience) / float(required)

# =============================================================================
# AI DECISION MAKING
# =============================================================================

func get_ai_action(allies: Array, enemies: Array) -> Dictionary:
	turns_since_last_skill += 1
	
	# Check instability first
	if check_instability():
		return get_instability_action(allies, enemies)

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

	# Guard against no valid targets - defend if none found
	if target == null:
		return {"action": Enums.BattleAction.DEFEND, "target": self, "skill": ""}

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
			# Guard against no valid targets
			if target == null:
				return {"action": Enums.BattleAction.DEFEND, "target": self, "skill": ""}
			turns_since_last_skill = 0
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
		"corruption_resistance": corruption_resistance,
		"capture_method": capture_method,
		"capture_state": capture_state,
		"morale_level": morale_level,
		"morale_approval_count": morale_approval_count,
		"morale_disapproval_count": morale_disapproval_count,
		"has_ascended_ability": has_ascended_ability,
		"current_experience": current_experience,
		"total_experience": total_experience,
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
	corruption_resistance = data.get("corruption_resistance", 0.0)
	capture_method = data.get("capture_method", Enums.CaptureMethod.NONE)
	capture_state = data.get("capture_state", Enums.CaptureState.WILD)
	morale_level = data.get("morale_level", Enums.MoraleLevel.CONTENT)
	morale_approval_count = data.get("morale_approval_count", 0)
	morale_disapproval_count = data.get("morale_disapproval_count", 0)
	has_ascended_ability = data.get("has_ascended_ability", false)
	current_experience = data.get("current_experience", 0)
	total_experience = data.get("total_experience", 0)
	ai_pattern = data.get("ai_pattern", "aggressive")
	
	_update_corruption_state()
	_calculate_instability()

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
	monster.corruption_resistance = data.get("corruption_resistance", 0.0)

	# AI
	monster.ai_pattern = data.get("ai_pattern", "aggressive")
	monster.known_skills = data.get("skills", [])

	# Rewards
	monster.experience_reward = data.get("exp_reward", 10)
	monster.currency_reward = data.get("currency_reward", 5)
	monster.drop_table = data.get("drops", [])

	return monster
