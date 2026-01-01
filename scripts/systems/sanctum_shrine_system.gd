# =============================================================================
# VEILBREAKERS - SANCTUM SHRINE SYSTEM (v5.2)
# Rest points for saving, healing, and purifying monsters
# =============================================================================

class_name SanctumShrineSystem
extends Node

# -----------------------------------------------------------------------------
# SIGNALS
# -----------------------------------------------------------------------------
signal shrine_activated(shrine_tier: Enums.ShrineTier)
signal shrine_rest_completed(hp_restored: int, debuffs_cleared: int)
signal monster_purified_at_shrine(monster: Monster, corruption_reduced: float)
signal shrine_cooldown_started(shrine_id: String, battles_remaining: int)
signal shrine_cooldown_ended(shrine_id: String)
signal sanctum_energy_changed(old_value: float, new_value: float)

# -----------------------------------------------------------------------------
# STATE
# -----------------------------------------------------------------------------

## Current Sanctum Energy (used for PURIFY captures and shrine actions)
var sanctum_energy: float = 100.0
var max_sanctum_energy: float = 100.0

## Shrine cooldowns: {shrine_id: battles_remaining}
var shrine_cooldowns: Dictionary = {}

## Major shrine uses this visit: {shrine_id: uses_remaining}
var major_shrine_uses: Dictionary = {}

## Current shrine being used (for UI)
var active_shrine_id: String = ""
var active_shrine_tier: Enums.ShrineTier = Enums.ShrineTier.MINOR

## Monsters purified this visit (each can only be purified once per visit)
var purified_this_visit: Array[String] = []

# -----------------------------------------------------------------------------
# LIFECYCLE
# -----------------------------------------------------------------------------

func _ready() -> void:
	# Connect to battle system to track cooldowns
	EventBus.battle_ended.connect(_on_battle_ended)

# -----------------------------------------------------------------------------
# SHRINE ACTIVATION
# -----------------------------------------------------------------------------

func activate_shrine(shrine_id: String, tier: Enums.ShrineTier) -> Dictionary:
	## Activate a shrine for use
	var result := {
		"success": false,
		"reason": "",
		"available_actions": []
	}
	
	# Check cooldown
	if shrine_cooldowns.has(shrine_id) and shrine_cooldowns[shrine_id] > 0:
		result.reason = "Shrine on cooldown (%d battles remaining)" % shrine_cooldowns[shrine_id]
		return result
	
	# Check major shrine uses
	if tier == Enums.ShrineTier.MAJOR:
		if major_shrine_uses.has(shrine_id) and major_shrine_uses[shrine_id] <= 0:
			result.reason = "Major shrine already used this visit"
			return result
	
	active_shrine_id = shrine_id
	active_shrine_tier = tier
	purified_this_visit.clear()
	
	result.success = true
	result.available_actions = get_available_actions(tier)
	
	shrine_activated.emit(tier)
	return result

func get_available_actions(tier: Enums.ShrineTier) -> Array[String]:
	## Get available actions at this shrine tier
	var actions: Array[String] = ["rest", "save"]
	
	# All shrines can purify monsters
	actions.append("purify_monster")
	
	# All shrines have commune (Vera dialogue)
	actions.append("commune")
	
	return actions

func leave_shrine() -> void:
	## Leave the current shrine
	if active_shrine_id == "":
		return
	
	# Apply cooldown for minor shrines
	if active_shrine_tier == Enums.ShrineTier.MINOR:
		shrine_cooldowns[active_shrine_id] = Constants.SHRINE_MINOR_COOLDOWN
		shrine_cooldown_started.emit(active_shrine_id, Constants.SHRINE_MINOR_COOLDOWN)
	
	# Mark major shrine as used
	if active_shrine_tier == Enums.ShrineTier.MAJOR:
		major_shrine_uses[active_shrine_id] = 0
	
	active_shrine_id = ""
	purified_this_visit.clear()

# -----------------------------------------------------------------------------
# SHRINE ACTIONS
# -----------------------------------------------------------------------------

func rest() -> Dictionary:
	## Rest at the shrine - restore HP/SP and clear temporary debuffs
	var result := {
		"hp_restored": 0,
		"sp_restored": 0,
		"debuffs_cleared": 0
	}
	
	var party := _get_player_party()
	if party.is_empty():
		return result
	
	for character in party:
		if not is_instance_valid(character):
			continue
		
		# Restore HP
		var hp_before: int = character.current_hp
		character.current_hp = character.get_max_hp()
		result.hp_restored += character.current_hp - hp_before
		
		# Restore MP/SP
		if "current_mp" in character and "max_mp" in character:
			var mp_before: int = character.current_mp
			character.current_mp = character.base_max_mp
			result.sp_restored += character.current_mp - mp_before
		
		# Clear temporary debuffs
		if character.has_method("clear_temporary_debuffs"):
			var cleared: int = character.clear_temporary_debuffs()
			result.debuffs_cleared += cleared
		
		# Clear Blood Tithe from BARGAIN
		if character.has_method("remove_stat_modifiers_by_source"):
			character.remove_stat_modifiers_by_source("blood_tithe")
	
	shrine_rest_completed.emit(result.hp_restored, result.debuffs_cleared)
	return result

func purify_monster(monster: Monster) -> Dictionary:
	## Purify a monster at the shrine to reduce corruption
	var result := {
		"success": false,
		"reason": "",
		"corruption_reduced": 0.0,
		"new_corruption": 0.0,
		"new_state": Enums.CorruptionState.UNSTABLE
	}
	
	if not is_instance_valid(monster):
		result.reason = "Invalid monster"
		return result
	
	# Check if already purified this visit
	if monster.monster_id in purified_this_visit:
		result.reason = "Monster already purified this visit"
		return result
	
	# Check Sanctum Energy cost
	if sanctum_energy < Constants.SHRINE_CLEANSE_ENERGY_COST:
		result.reason = "Not enough Sanctum Energy (%d required)" % int(Constants.SHRINE_CLEANSE_ENERGY_COST)
		return result
	
	# Calculate corruption reduction based on shrine tier
	var reduction := 0.0
	match active_shrine_tier:
		Enums.ShrineTier.MINOR:
			reduction = Constants.SHRINE_MINOR_CORRUPTION_REDUCTION
		Enums.ShrineTier.MAJOR:
			reduction = Constants.SHRINE_MAJOR_CORRUPTION_REDUCTION
		Enums.ShrineTier.SACRED:
			reduction = Constants.SHRINE_SACRED_CORRUPTION_REDUCTION
	
	# Consume energy
	_consume_sanctum_energy(Constants.SHRINE_CLEANSE_ENERGY_COST)
	
	# Apply corruption reduction
	var old_corruption := monster.corruption_level
	monster.reduce_corruption(reduction)
	
	# Mark as purified this visit
	purified_this_visit.append(monster.monster_id)
	
	result.success = true
	result.corruption_reduced = old_corruption - monster.corruption_level
	result.new_corruption = monster.corruption_level
	result.new_state = monster.get_corruption_state()
	
	monster_purified_at_shrine.emit(monster, result.corruption_reduced)
	
	# Check if monster reached Ascended state
	if monster.is_ascended():
		EventBus.emit_notification("%s has ASCENDED!" % monster.character_name, "success")
	
	return result

func commune() -> Dictionary:
	## Commune with Vera at the shrine
	var result := {
		"dialogue_triggered": false,
		"hint_given": false,
		"glitch_occurred": false
	}
	
	var vera_system := get_node_or_null("/root/VERASystem")
	if vera_system == null:
		return result
	
	# Trigger Vera dialogue
	if vera_system.has_method("trigger_dialogue"):
		vera_system.trigger_dialogue("shrine_commune")
		result.dialogue_triggered = true
	
	# Chance for hint based on Vera state
	if vera_system.has_method("get_dialogue"):
		result.hint_given = true
	
	# Resting at sanctuary suppresses Vera
	if vera_system.has_method("reduce_corruption"):
		vera_system.reduce_corruption("rest_at_sanctuary")
	
	return result

func save_game() -> bool:
	## Save game at the shrine
	var game_manager := get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("save_game"):
		return game_manager.save_game()
	return false

# -----------------------------------------------------------------------------
# SANCTUM ENERGY MANAGEMENT
# -----------------------------------------------------------------------------

func add_sanctum_energy(amount: float) -> void:
	var old := sanctum_energy
	sanctum_energy = minf(sanctum_energy + amount, max_sanctum_energy)
	if sanctum_energy != old:
		sanctum_energy_changed.emit(old, sanctum_energy)

func _consume_sanctum_energy(amount: float) -> void:
	var old := sanctum_energy
	sanctum_energy = maxf(0.0, sanctum_energy - amount)
	if sanctum_energy != old:
		sanctum_energy_changed.emit(old, sanctum_energy)

func get_sanctum_energy() -> float:
	return sanctum_energy

func get_sanctum_energy_percent() -> float:
	if max_sanctum_energy <= 0:
		return 0.0
	return sanctum_energy / max_sanctum_energy

# -----------------------------------------------------------------------------
# COOLDOWN MANAGEMENT
# -----------------------------------------------------------------------------

func _on_battle_ended(_victory: bool, _rewards: Dictionary) -> void:
	## Called when a battle ends - reduce shrine cooldowns
	var shrines_to_remove: Array[String] = []
	
	for shrine_id in shrine_cooldowns:
		shrine_cooldowns[shrine_id] -= 1
		if shrine_cooldowns[shrine_id] <= 0:
			shrines_to_remove.append(shrine_id)
			shrine_cooldown_ended.emit(shrine_id)
	
	for shrine_id in shrines_to_remove:
		shrine_cooldowns.erase(shrine_id)

func get_shrine_cooldown(shrine_id: String) -> int:
	return shrine_cooldowns.get(shrine_id, 0)

func is_shrine_available(shrine_id: String, tier: Enums.ShrineTier) -> bool:
	# Check cooldown
	if shrine_cooldowns.has(shrine_id) and shrine_cooldowns[shrine_id] > 0:
		return false
	
	# Check major shrine uses
	if tier == Enums.ShrineTier.MAJOR:
		if major_shrine_uses.has(shrine_id) and major_shrine_uses[shrine_id] <= 0:
			return false
	
	return true

func reset_major_shrine_uses() -> void:
	## Called when entering a new area/dungeon
	major_shrine_uses.clear()

# -----------------------------------------------------------------------------
# INSTABILITY REMOVAL
# -----------------------------------------------------------------------------

func can_remove_instability(monster: Monster) -> bool:
	## Check if monster's instability can be removed
	## Instability is removed when corruption drops below 26%
	if not is_instance_valid(monster):
		return false
	
	return monster.corruption_level < Constants.CORRUPTION_UNSTABLE_MAX

func get_purifications_needed(monster: Monster) -> int:
	## Calculate how many shrine purifications needed to remove instability
	if not is_instance_valid(monster):
		return 0
	
	var target_corruption := Constants.CORRUPTION_PURIFIED_MAX  # 25%
	var current := monster.corruption_level
	
	if current <= target_corruption:
		return 0
	
	var reduction_per_purify := Constants.SHRINE_MINOR_CORRUPTION_REDUCTION
	match active_shrine_tier:
		Enums.ShrineTier.MAJOR:
			reduction_per_purify = Constants.SHRINE_MAJOR_CORRUPTION_REDUCTION
		Enums.ShrineTier.SACRED:
			reduction_per_purify = Constants.SHRINE_SACRED_CORRUPTION_REDUCTION
	
	var needed := current - target_corruption
	return ceili(needed / reduction_per_purify)

# -----------------------------------------------------------------------------
# HELPER METHODS
# -----------------------------------------------------------------------------

func _get_player_party() -> Array:
	var game_manager := get_node_or_null("/root/GameManager")
	if game_manager and "player_party" in game_manager:
		return game_manager.player_party
	return []

# -----------------------------------------------------------------------------
# SERIALIZATION
# -----------------------------------------------------------------------------

func get_save_data() -> Dictionary:
	return {
		"sanctum_energy": sanctum_energy,
		"max_sanctum_energy": max_sanctum_energy,
		"shrine_cooldowns": shrine_cooldowns,
		"major_shrine_uses": major_shrine_uses
	}

func load_save_data(data: Dictionary) -> void:
	sanctum_energy = data.get("sanctum_energy", 100.0)
	max_sanctum_energy = data.get("max_sanctum_energy", 100.0)
	shrine_cooldowns = data.get("shrine_cooldowns", {})
	major_shrine_uses = data.get("major_shrine_uses", {})
