# =============================================================================
# VEILBREAKERS Turn-Based Battle Sequencer
# Orchestrates the dramatic flow of turn-based combat
# Every action is a performance - timing, camera, impact
# =============================================================================

class_name BattleSequencer
extends Node

# -----------------------------------------------------------------------------
# SIGNALS - Battle Flow
# -----------------------------------------------------------------------------
signal battle_started(player_party: Array, enemy_party: Array)
signal battle_ended(victory: bool)

signal turn_order_determined(order: Array)
signal turn_started(entity: Node, turn_number: int)
signal turn_ended(entity: Node)

signal action_selected(entity: Node, action: Dictionary)
signal action_execution_started(action: Dictionary)
signal action_execution_completed(action: Dictionary)

signal phase_changed(boss: Node, phase: int)
signal capture_attempt_started(target: Node)
signal capture_result(target: Node, success: bool)

# For UI/Camera coordination
signal camera_command(command: String, data: Dictionary)
signal ui_command(command: String, data: Dictionary)
signal vfx_command(command: String, data: Dictionary)
signal audio_command(command: String, data: Dictionary)

# -----------------------------------------------------------------------------
# ENUMS
# -----------------------------------------------------------------------------
enum BattleState {
	INACTIVE,
	INITIALIZING,
	TURN_ORDER,
	AWAITING_INPUT,
	EXECUTING_ACTION,
	PROCESSING_EFFECTS,
	CHECKING_STATE,
	VICTORY,
	DEFEAT,
	FLED
}

enum ActionType {
	ATTACK,
	SKILL,
	ITEM,
	CAPTURE,
	SWAP,
	DEFEND,
	FLEE
}

# -----------------------------------------------------------------------------
# EXPORTS
# -----------------------------------------------------------------------------
@export_group("Timing - Dramatic Pacing")
@export var turn_start_delay: float = 0.4
@export var action_windup_time: float = 0.3
@export var impact_pause_time: float = 0.08
@export var action_recovery_time: float = 0.4
@export var between_hits_delay: float = 0.15
@export var turn_end_delay: float = 0.3
@export var death_dramatic_pause: float = 0.8
@export var boss_phase_transition_time: float = 2.0

@export_group("Camera Timing")
@export var camera_focus_time: float = 0.25
@export var camera_return_time: float = 0.3
@export var boss_intro_time: float = 3.0

@export_group("Capture Timing")
@export var capture_throw_time: float = 0.5
@export var capture_shake_count: int = 3
@export var capture_shake_interval: float = 0.8
@export var capture_result_delay: float = 0.5

# -----------------------------------------------------------------------------
# STATE
# -----------------------------------------------------------------------------
var state: BattleState = BattleState.INACTIVE
var current_turn: int = 0
var turn_order: Array = []  # Array of entities in speed order
var current_actor: Node = null
var current_action: Dictionary = {}

var player_party: Array = []
var enemy_party: Array = []
var all_combatants: Array = []

var action_queue: Array = []  # For multi-hit attacks, combos, etc.
var pending_effects: Array = []  # Status effects to process

# Boss tracking
var active_bosses: Array = []
var boss_phases: Dictionary = {}  # boss_node -> current_phase

# Battle statistics
var battle_stats: Dictionary = {
	"turns_taken": 0,
	"damage_dealt": 0,
	"damage_received": 0,
	"captures_attempted": 0,
	"captures_successful": 0,
}

# -----------------------------------------------------------------------------
# LIFECYCLE
# -----------------------------------------------------------------------------
func _ready() -> void:
	pass

# -----------------------------------------------------------------------------
# BATTLE INITIALIZATION
# -----------------------------------------------------------------------------
func start_battle(players: Array, enemies: Array, is_boss_battle: bool = false) -> void:
	player_party = players
	enemy_party = enemies
	all_combatants = players + enemies
	
	state = BattleState.INITIALIZING
	current_turn = 0
	battle_stats = {"turns_taken": 0, "damage_dealt": 0, "damage_received": 0, "captures_attempted": 0, "captures_successful": 0}
	
	# Identify bosses
	active_bosses.clear()
	boss_phases.clear()
	for enemy in enemies:
		if enemy.has_method("is_boss") and enemy.is_boss():
			active_bosses.append(enemy)
			boss_phases[enemy] = 1
	
	# Camera: Wide shot of battlefield
	camera_command.emit("battle_intro", {"duration": 1.5})
	
	# If boss battle, dramatic intro
	if is_boss_battle and active_bosses.size() > 0:
		await _play_boss_intro(active_bosses[0])
	
	battle_started.emit(player_party, enemy_party)
	
	# Begin turn cycle
	await get_tree().create_timer(0.5).timeout
	_begin_turn_cycle()

func _play_boss_intro(boss: Node) -> void:
	"""Dramatic boss introduction sequence"""
	ui_command.emit("hide_ui", {})
	camera_command.emit("boss_intro", {"target": boss, "duration": boss_intro_time})
	audio_command.emit("play_music", {"track": "boss_theme", "fade_in": 1.0})
	
	# Boss roar/intro animation
	if boss.has_method("play_intro"):
		boss.play_intro()
	
	vfx_command.emit("boss_title_card", {"name": boss.display_name, "title": boss.title})
	
	await get_tree().create_timer(boss_intro_time).timeout
	ui_command.emit("show_ui", {})

# -----------------------------------------------------------------------------
# TURN CYCLE
# -----------------------------------------------------------------------------
func _begin_turn_cycle() -> void:
	current_turn += 1
	battle_stats.turns_taken += 1
	
	state = BattleState.TURN_ORDER
	
	# Calculate turn order based on speed
	turn_order = _calculate_turn_order()
	turn_order_determined.emit(turn_order)
	
	# UI: Show turn order bar
	ui_command.emit("show_turn_order", {"order": turn_order})
	
	await get_tree().create_timer(turn_start_delay).timeout
	
	_process_next_turn()

func _calculate_turn_order() -> Array:
	"""Sort combatants by speed, with status modifiers"""
	var order = all_combatants.filter(func(c): return c.is_alive() if c.has_method("is_alive") else true)
	
	order.sort_custom(func(a, b):
		var speed_a = a.get_speed() if a.has_method("get_speed") else 10
		var speed_b = b.get_speed() if b.has_method("get_speed") else 10
		# Add randomness factor for ties
		speed_a += randf() * 0.1
		speed_b += randf() * 0.1
		return speed_a > speed_b
	)
	
	return order

func _process_next_turn() -> void:
	if turn_order.is_empty():
		# All entities have acted, new cycle
		_begin_turn_cycle()
		return
	
	current_actor = turn_order.pop_front()
	
	# Skip dead entities
	if current_actor.has_method("is_alive") and not current_actor.is_alive():
		_process_next_turn()
		return
	
	# Skip stunned entities
	if current_actor.has_method("is_stunned") and current_actor.is_stunned():
		ui_command.emit("show_message", {"text": current_actor.display_name + " is stunned!"})
		await get_tree().create_timer(0.5).timeout
		turn_ended.emit(current_actor)
		_process_next_turn()
		return
	
	turn_started.emit(current_actor, current_turn)
	
	# Camera: Focus on active entity
	camera_command.emit("focus", {"target": current_actor, "duration": camera_focus_time})
	
	# Determine if player or AI controlled
	if current_actor in player_party:
		state = BattleState.AWAITING_INPUT
		ui_command.emit("show_action_menu", {"entity": current_actor})
	else:
		state = BattleState.EXECUTING_ACTION
		await _execute_ai_turn(current_actor)

func _execute_ai_turn(entity: Node) -> void:
	"""AI decides and executes action"""
	var action = {}

	if entity.has_method("decide_action"):
		action = entity.decide_action(player_party, enemy_party)
	else:
		# Default: basic attack on random player
		# Guard against empty player_party
		if player_party.is_empty():
			push_warning("_execute_ai_turn: No player targets available")
			return
		action = {
			"type": ActionType.ATTACK,
			"source": entity,
			"targets": [player_party.pick_random()],
			"skill": null
		}

	await execute_action(action)

# -----------------------------------------------------------------------------
# ACTION EXECUTION - The Core Performance System
# -----------------------------------------------------------------------------
func submit_player_action(action: Dictionary) -> void:
	"""Called by UI when player selects action"""
	if state != BattleState.AWAITING_INPUT:
		return
	
	action.source = current_actor
	action_selected.emit(current_actor, action)
	
	ui_command.emit("hide_action_menu", {})
	
	await execute_action(action)

func execute_action(action: Dictionary) -> void:
	"""Execute a single action with full dramatic choreography"""
	state = BattleState.EXECUTING_ACTION
	current_action = action
	action_execution_started.emit(action)
	
	var source = action.source
	var targets = action.get("targets", [])
	var action_type = action.get("type", ActionType.ATTACK)
	
	match action_type:
		ActionType.ATTACK:
			await _execute_attack(source, targets, action)
		ActionType.SKILL:
			await _execute_skill(source, targets, action)
		ActionType.ITEM:
			await _execute_item(source, targets, action)
		ActionType.CAPTURE:
			if targets.is_empty():
				push_warning("CAPTURE action with no targets")
			else:
				await _execute_capture(source, targets[0], action)
		ActionType.SWAP:
			await _execute_swap(source, action.get("swap_target"))
		ActionType.DEFEND:
			await _execute_defend(source)
		ActionType.FLEE:
			await _attempt_flee(source)
	
	action_execution_completed.emit(action)
	
	# Process any pending effects (poison tick, etc.)
	await _process_pending_effects()
	
	# Check for deaths
	await _check_battle_state()
	
	# End turn
	if state != BattleState.VICTORY and state != BattleState.DEFEAT:
		await get_tree().create_timer(turn_end_delay).timeout
		turn_ended.emit(current_actor)
		_process_next_turn()

# -----------------------------------------------------------------------------
# ATTACK EXECUTION
# -----------------------------------------------------------------------------
func _execute_attack(source: Node, targets: Array, action: Dictionary) -> void:
	"""Standard attack with full choreography"""
	# Guard against empty targets array
	if targets.is_empty():
		push_warning("_execute_attack called with empty targets array")
		return

	var brand = source.get_brand() if source.has_method("get_brand") else "NEUTRAL"
	var is_critical = randf() < (source.get_crit_chance() if source.has_method("get_crit_chance") else 0.1)

	# 1. WINDUP - Attacker prepares
	camera_command.emit("focus_between", {
		"from": source,
		"to": targets[0],
		"bias": 0.3,
		"duration": action_windup_time
	})
	
	if source.has_method("play_attack_windup"):
		source.play_attack_windup()
	audio_command.emit("play_sfx", {"sound": "attack_whoosh", "position": source.global_position})
	
	await get_tree().create_timer(action_windup_time).timeout
	
	# 2. STRIKE - The hit moment
	for target in targets:
		await _perform_single_hit(source, target, brand, is_critical, action)
		
		if targets.size() > 1:
			await get_tree().create_timer(between_hits_delay).timeout
	
	# 3. RECOVERY - Return to idle
	camera_command.emit("return_to_battle", {"duration": camera_return_time})
	
	if source.has_method("play_attack_recovery"):
		source.play_attack_recovery()
	
	await get_tree().create_timer(action_recovery_time).timeout

func _perform_single_hit(source: Node, target: Node, brand: String, is_critical: bool, action: Dictionary) -> void:
	"""Single hit with impact, damage, effects"""
	
	# Strike animation
	if source.has_method("play_attack_strike"):
		source.play_attack_strike()
	
	# Calculate damage
	var base_damage = source.get_attack() if source.has_method("get_attack") else 10
	var defense = target.get_defense() if target.has_method("get_defense") else 5
	var damage = max(1, base_damage - defense)
	
	if is_critical:
		damage = int(damage * 1.5)
	
	# Apply brand effectiveness
	damage = _apply_brand_modifier(damage, brand, target)
	
	# IMPACT MOMENT - Everything happens here
	# Hitstop
	camera_command.emit("impact_freeze", {"duration": impact_pause_time if not is_critical else impact_pause_time * 2})
	
	# Screen shake
	var shake_intensity = 6.0 if not is_critical else 12.0
	camera_command.emit("shake", {"intensity": shake_intensity, "duration": 0.2})
	
	# Hit flash on target
	if target.has_method("flash_hit"):
		target.flash_hit()
	
	# VFX
	vfx_command.emit("spawn_hit_effect", {
		"brand": brand,
		"position": target.global_position,
		"is_critical": is_critical
	})
	
	# Screen flash for crits
	if is_critical:
		vfx_command.emit("screen_flash", {"color": _get_brand_color(brand), "duration": 0.1})
	
	# Damage number
	vfx_command.emit("spawn_damage_number", {
		"position": target.global_position,
		"amount": damage,
		"is_critical": is_critical,
		"brand": brand
	})
	
	# Audio
	audio_command.emit("play_sfx", {
		"sound": "hit_" + brand.to_lower(),
		"position": target.global_position
	})
	if is_critical:
		audio_command.emit("play_sfx", {"sound": "critical_hit"})
	
	# Apply damage
	if target.has_method("take_damage"):
		target.take_damage(damage, brand, source)
	
	battle_stats.damage_dealt += damage if source in player_party else 0
	battle_stats.damage_received += damage if target in player_party else 0
	
	# Target reaction
	if target.has_method("play_hurt"):
		target.play_hurt(is_critical)
	
	# Check for boss phase transition
	if target in active_bosses:
		_check_boss_phase(target)
	
	await get_tree().create_timer(impact_pause_time).timeout

# -----------------------------------------------------------------------------
# SKILL EXECUTION
# -----------------------------------------------------------------------------
func _execute_skill(source: Node, targets: Array, action: Dictionary) -> void:
	"""Skill/ability execution with custom choreography"""
	var skill = action.get("skill", {})
	var skill_name = skill.get("name", "Unknown Skill")
	var brand = skill.get("brand", source.get_brand() if source.has_method("get_brand") else "NEUTRAL")
	
	# 1. SKILL ANNOUNCEMENT
	ui_command.emit("show_skill_name", {"name": skill_name, "brand": brand})
	audio_command.emit("play_sfx", {"sound": "skill_announce"})
	
	# 2. CAST ANIMATION
	camera_command.emit("focus", {"target": source, "zoom": 1.2, "duration": 0.3})
	
	if source.has_method("play_skill_cast"):
		source.play_skill_cast(skill_name)
	
	vfx_command.emit("skill_charge", {
		"position": source.global_position,
		"brand": brand,
		"duration": skill.get("cast_time", 0.5)
	})
	
	await get_tree().create_timer(skill.get("cast_time", 0.5)).timeout
	
	# 3. SKILL EXECUTION
	var skill_type = skill.get("type", "damage")
	
	match skill_type:
		"damage":
			await _execute_damage_skill(source, targets, skill, brand)
		"heal":
			await _execute_heal_skill(source, targets, skill)
		"buff":
			await _execute_buff_skill(source, targets, skill)
		"debuff":
			await _execute_debuff_skill(source, targets, skill)
		"status":
			await _execute_status_skill(source, targets, skill, brand)
	
	# 4. RECOVERY
	camera_command.emit("return_to_battle", {"duration": camera_return_time})
	await get_tree().create_timer(action_recovery_time).timeout

func _execute_damage_skill(source: Node, targets: Array, skill: Dictionary, brand: String) -> void:
	"""Multi-target damage skill"""
	var hit_count = skill.get("hits", 1)
	var base_power = skill.get("power", 1.5)
	
	# Camera to show all targets
	if targets.size() > 1:
		camera_command.emit("focus_group", {"targets": targets, "duration": 0.3})
	else:
		camera_command.emit("focus", {"target": targets[0], "duration": 0.3})
	
	await get_tree().create_timer(0.3).timeout
	
	for hit in range(hit_count):
		for target in targets:
			var damage = int((source.get_attack() if source.has_method("get_attack") else 10) * base_power)
			var is_crit = randf() < 0.15
			if is_crit:
				damage = int(damage * 1.5)
			
			# Impact
			camera_command.emit("shake", {"intensity": 8.0, "duration": 0.15})
			
			vfx_command.emit("spawn_hit_effect", {
				"brand": brand,
				"position": target.global_position,
				"is_critical": is_crit,
				"skill_effect": skill.get("vfx", "default")
			})
			
			vfx_command.emit("spawn_damage_number", {
				"position": target.global_position,
				"amount": damage,
				"is_critical": is_crit,
				"brand": brand
			})
			
			if target.has_method("take_damage"):
				target.take_damage(damage, brand, source)
			
			if target.has_method("play_hurt"):
				target.play_hurt(is_crit)
			
			audio_command.emit("play_sfx", {"sound": "hit_" + brand.to_lower()})
		
		if hit < hit_count - 1:
			await get_tree().create_timer(between_hits_delay).timeout

func _execute_heal_skill(source: Node, targets: Array, skill: Dictionary) -> void:
	"""Healing skill"""
	var heal_power = skill.get("power", 1.0)
	
	for target in targets:
		var heal_amount = int((source.get_magic() if source.has_method("get_magic") else 10) * heal_power)
		
		vfx_command.emit("heal_effect", {"position": target.global_position})
		vfx_command.emit("spawn_damage_number", {
			"position": target.global_position,
			"amount": heal_amount,
			"is_heal": true
		})
		
		if target.has_method("heal"):
			target.heal(heal_amount)
		
		audio_command.emit("play_sfx", {"sound": "heal"})
	
	await get_tree().create_timer(0.5).timeout

func _execute_buff_skill(source: Node, targets: Array, skill: Dictionary) -> void:
	"""Apply buff to targets"""
	var buff_type = skill.get("buff_type", "attack")
	var buff_value = skill.get("buff_value", 1.2)
	var duration = skill.get("duration", 3)
	
	for target in targets:
		vfx_command.emit("buff_effect", {
			"position": target.global_position,
			"buff_type": buff_type
		})
		
		if target.has_method("apply_buff"):
			target.apply_buff(buff_type, buff_value, duration)
		
		ui_command.emit("show_status_popup", {
			"target": target,
			"status": buff_type.to_upper() + " UP",
			"positive": true
		})
	
	audio_command.emit("play_sfx", {"sound": "buff_apply"})
	await get_tree().create_timer(0.5).timeout

func _execute_debuff_skill(source: Node, targets: Array, skill: Dictionary) -> void:
	"""Apply debuff to targets"""
	var debuff_type = skill.get("debuff_type", "defense")
	var debuff_value = skill.get("debuff_value", 0.8)
	var duration = skill.get("duration", 3)
	
	for target in targets:
		vfx_command.emit("debuff_effect", {
			"position": target.global_position,
			"debuff_type": debuff_type
		})
		
		if target.has_method("apply_debuff"):
			target.apply_debuff(debuff_type, debuff_value, duration)
		
		ui_command.emit("show_status_popup", {
			"target": target,
			"status": debuff_type.to_upper() + " DOWN",
			"positive": false
		})
	
	audio_command.emit("play_sfx", {"sound": "debuff_apply"})
	await get_tree().create_timer(0.5).timeout

func _execute_status_skill(source: Node, targets: Array, skill: Dictionary, brand: String) -> void:
	"""Apply status effect (poison, burn, etc.)"""
	var status = skill.get("status", "poison")
	var chance = skill.get("chance", 0.8)
	var duration = skill.get("duration", 3)
	
	for target in targets:
		if randf() < chance:
			vfx_command.emit("status_apply", {
				"position": target.global_position,
				"status": status,
				"brand": brand
			})
			
			if target.has_method("apply_status"):
				target.apply_status(status, duration, source)
			
			ui_command.emit("show_status_popup", {
				"target": target,
				"status": status.to_upper(),
				"positive": false
			})
			
			audio_command.emit("play_sfx", {"sound": "status_" + status})
		else:
			ui_command.emit("show_message", {"text": "RESISTED!", "position": target.global_position})
	
	await get_tree().create_timer(0.5).timeout

# -----------------------------------------------------------------------------
# CAPTURE SYSTEM
# -----------------------------------------------------------------------------
func _execute_capture(source: Node, target: Node, action: Dictionary) -> void:
	"""VEILBREAKERS capture sequence - dramatic tension"""
	battle_stats.captures_attempted += 1
	capture_attempt_started.emit(target)
	
	# Calculate capture chance
	var base_chance = 0.3
	var hp_modifier = 1.0 - (target.get_hp_percent() if target.has_method("get_hp_percent") else 0.5)
	var status_modifier = 0.1 if (target.has_method("has_status") and target.has_status("any")) else 0.0
	var capture_chance = base_chance + (hp_modifier * 0.5) + status_modifier
	
	# 1. THROW
	camera_command.emit("focus", {"target": source, "duration": 0.2})
	
	if source.has_method("play_capture_throw"):
		source.play_capture_throw()
	
	audio_command.emit("play_sfx", {"sound": "capture_throw"})
	
	vfx_command.emit("capture_projectile", {
		"from": source.global_position,
		"to": target.global_position,
		"duration": capture_throw_time
	})
	
	await get_tree().create_timer(capture_throw_time).timeout
	
	# 2. CAPTURE BEAM
	camera_command.emit("focus", {"target": target, "zoom": 1.3, "duration": 0.3})
	
	vfx_command.emit("capture_beam", {
		"position": target.global_position,
		"brand": target.get_brand() if target.has_method("get_brand") else "NEUTRAL"
	})
	
	if target.has_method("play_capture_react"):
		target.play_capture_react()
	
	audio_command.emit("play_sfx", {"sound": "capture_beam"})
	
	await get_tree().create_timer(0.5).timeout
	
	# 3. STRUGGLE SEQUENCE - Build tension
	var success = randf() < capture_chance
	var shake_results = []
	
	for i in range(capture_shake_count):
		# Each shake has drama
		camera_command.emit("shake", {"intensity": 4.0, "duration": 0.3})
		
		vfx_command.emit("capture_shake", {"position": target.global_position, "shake_number": i + 1})
		
		if target.has_method("play_capture_struggle"):
			target.play_capture_struggle()
		
		audio_command.emit("play_sfx", {"sound": "capture_struggle"})
		
		await get_tree().create_timer(capture_shake_interval).timeout
		
		# Determine if this shake succeeds (for visual tension)
		var shake_success = true
		if not success and i == capture_shake_count - 1:
			shake_success = false  # Final shake fails
		elif not success and randf() < 0.3:
			shake_success = false  # Random early break
			# Early break!
			break
	
	await get_tree().create_timer(capture_result_delay).timeout
	
	# 4. RESULT
	if success:
		await _capture_success(source, target)
	else:
		await _capture_failure(source, target)

func _capture_success(source: Node, target: Node) -> void:
	"""Successful capture celebration"""
	battle_stats.captures_successful += 1
	
	# Flash
	vfx_command.emit("screen_flash", {"color": Color.WHITE, "duration": 0.15})
	
	# Capture complete VFX
	vfx_command.emit("capture_success", {"position": target.global_position})
	
	# Sound
	audio_command.emit("play_sfx", {"sound": "capture_success"})
	audio_command.emit("play_jingle", {"jingle": "capture_fanfare"})
	
	# Player celebration
	if source.has_method("play_capture_celebrate"):
		source.play_capture_celebrate()
	
	# UI announcement
	ui_command.emit("capture_announcement", {
		"monster_name": target.display_name,
		"brand": target.get_brand() if target.has_method("get_brand") else "NEUTRAL"
	})
	
	# Remove from battle
	enemy_party.erase(target)
	all_combatants.erase(target)
	
	# The target becomes yours!
	capture_result.emit(target, true)
	
	await get_tree().create_timer(2.0).timeout

func _capture_failure(source: Node, target: Node) -> void:
	"""Capture failed - monster breaks free"""
	# Break free VFX
	camera_command.emit("shake", {"intensity": 10.0, "duration": 0.3})
	
	vfx_command.emit("capture_break", {"position": target.global_position})
	
	if target.has_method("play_capture_break"):
		target.play_capture_break()
	
	audio_command.emit("play_sfx", {"sound": "capture_fail"})
	
	ui_command.emit("show_message", {"text": target.display_name + " broke free!"})
	
	capture_result.emit(target, false)
	
	await get_tree().create_timer(1.0).timeout

# -----------------------------------------------------------------------------
# OTHER ACTIONS
# -----------------------------------------------------------------------------
func _execute_item(source: Node, targets: Array, action: Dictionary) -> void:
	"""Use item"""
	var item = action.get("item", {})
	
	if source.has_method("play_item_use"):
		source.play_item_use()
	
	audio_command.emit("play_sfx", {"sound": "item_use"})
	
	# Item effect based on type
	var item_type = item.get("type", "heal")
	
	match item_type:
		"heal":
			for target in targets:
				var amount = item.get("amount", 50)
				vfx_command.emit("heal_effect", {"position": target.global_position})
				vfx_command.emit("spawn_damage_number", {
					"position": target.global_position,
					"amount": amount,
					"is_heal": true
				})
				if target.has_method("heal"):
					target.heal(amount)
		"revive":
			for target in targets:
				vfx_command.emit("revive_effect", {"position": target.global_position})
				if target.has_method("revive"):
					target.revive(item.get("hp_percent", 0.5))
		"cure":
			for target in targets:
				if target.has_method("clear_status"):
					target.clear_status(item.get("status", "all"))
	
	await get_tree().create_timer(0.5).timeout

func _execute_swap(source: Node, new_monster: Node) -> void:
	"""Swap active monster"""
	camera_command.emit("focus", {"target": source, "duration": 0.3})
	
	# Return animation
	vfx_command.emit("monster_return", {"position": source.global_position})
	
	await get_tree().create_timer(0.5).timeout
	
	# Swap in party
	var idx = player_party.find(source)
	if idx >= 0:
		player_party[idx] = new_monster
		all_combatants[all_combatants.find(source)] = new_monster
	
	# Summon animation
	vfx_command.emit("monster_summon", {
		"position": source.global_position,
		"brand": new_monster.get_brand() if new_monster.has_method("get_brand") else "NEUTRAL"
	})
	
	if new_monster.has_method("play_spawn"):
		new_monster.play_spawn()
	
	audio_command.emit("play_sfx", {"sound": "monster_summon"})
	
	await get_tree().create_timer(0.5).timeout

func _execute_defend(source: Node) -> void:
	"""Defend/guard stance"""
	if source.has_method("set_defending"):
		source.set_defending(true)
	
	vfx_command.emit("defend_effect", {"position": source.global_position})
	audio_command.emit("play_sfx", {"sound": "defend"})
	
	ui_command.emit("show_status_popup", {
		"target": source,
		"status": "DEFENDING",
		"positive": true
	})
	
	await get_tree().create_timer(0.3).timeout

func _attempt_flee(source: Node) -> void:
	"""Attempt to flee battle"""
	var flee_chance = 0.5  # Base 50%
	
	# Can't flee from bosses
	if active_bosses.size() > 0:
		ui_command.emit("show_message", {"text": "Can't escape!"})
		audio_command.emit("play_sfx", {"sound": "flee_fail"})
		await get_tree().create_timer(0.5).timeout
		return
	
	if randf() < flee_chance:
		ui_command.emit("show_message", {"text": "Got away safely!"})
		audio_command.emit("play_sfx", {"sound": "flee_success"})
		state = BattleState.FLED
		battle_ended.emit(false)
	else:
		ui_command.emit("show_message", {"text": "Couldn't escape!"})
		audio_command.emit("play_sfx", {"sound": "flee_fail"})
	
	await get_tree().create_timer(0.5).timeout

# -----------------------------------------------------------------------------
# STATUS EFFECT PROCESSING
# -----------------------------------------------------------------------------
func _process_pending_effects() -> void:
	"""Process end-of-turn status effects"""
	state = BattleState.PROCESSING_EFFECTS
	
	for entity in all_combatants:
		if not entity.has_method("get_active_statuses"):
			continue
		
		var statuses = entity.get_active_statuses()
		
		for status in statuses:
			match status.type:
				"poison":
					await _apply_poison_tick(entity, status)
				"burn":
					await _apply_burn_tick(entity, status)
				"regen":
					await _apply_regen_tick(entity, status)
				"bleed":
					await _apply_bleed_tick(entity, status)
			
			# Reduce duration
			if entity.has_method("tick_status"):
				entity.tick_status(status.type)

func _apply_poison_tick(entity: Node, status: Dictionary) -> void:
	var damage = status.get("damage", 5)
	
	vfx_command.emit("poison_tick", {"position": entity.global_position})
	vfx_command.emit("spawn_damage_number", {
		"position": entity.global_position,
		"amount": damage,
		"brand": "VENOM"
	})
	
	if entity.has_method("take_damage"):
		entity.take_damage(damage, "VENOM", null)
	
	audio_command.emit("play_sfx", {"sound": "poison_tick"})
	await get_tree().create_timer(0.3).timeout

func _apply_burn_tick(entity: Node, status: Dictionary) -> void:
	var damage = status.get("damage", 8)
	
	vfx_command.emit("burn_tick", {"position": entity.global_position})
	vfx_command.emit("spawn_damage_number", {
		"position": entity.global_position,
		"amount": damage,
		"brand": "SURGE"
	})
	
	if entity.has_method("take_damage"):
		entity.take_damage(damage, "SURGE", null)
	
	audio_command.emit("play_sfx", {"sound": "burn_tick"})
	await get_tree().create_timer(0.3).timeout

func _apply_regen_tick(entity: Node, status: Dictionary) -> void:
	var heal = status.get("heal", 10)
	
	vfx_command.emit("regen_tick", {"position": entity.global_position})
	vfx_command.emit("spawn_damage_number", {
		"position": entity.global_position,
		"amount": heal,
		"is_heal": true
	})
	
	if entity.has_method("heal"):
		entity.heal(heal)
	
	await get_tree().create_timer(0.3).timeout

func _apply_bleed_tick(entity: Node, status: Dictionary) -> void:
	var damage = status.get("damage", 6)
	
	vfx_command.emit("bleed_tick", {"position": entity.global_position})
	vfx_command.emit("spawn_damage_number", {
		"position": entity.global_position,
		"amount": damage,
		"brand": "SAVAGE"
	})
	
	if entity.has_method("take_damage"):
		entity.take_damage(damage, "SAVAGE", null)
	
	await get_tree().create_timer(0.3).timeout

# -----------------------------------------------------------------------------
# BOSS PHASE SYSTEM
# -----------------------------------------------------------------------------
func _check_boss_phase(boss: Node) -> void:
	"""Check if boss should transition phases"""
	if not boss.has_method("get_phase_thresholds"):
		return
	
	var current_phase = boss_phases.get(boss, 1)
	var thresholds = boss.get_phase_thresholds()  # e.g., [0.7, 0.4, 0.15]
	var hp_percent = boss.get_hp_percent() if boss.has_method("get_hp_percent") else 1.0
	
	var new_phase = 1
	for i in range(thresholds.size()):
		if hp_percent <= thresholds[i]:
			new_phase = i + 2
	
	if new_phase > current_phase:
		await _trigger_boss_phase_transition(boss, new_phase)

func _trigger_boss_phase_transition(boss: Node, new_phase: int) -> void:
	"""Dramatic boss phase transition"""
	boss_phases[boss] = new_phase
	
	# Pause everything
	ui_command.emit("hide_ui", {})
	
	# Camera drama
	camera_command.emit("boss_phase_transition", {
		"target": boss,
		"duration": boss_phase_transition_time
	})
	
	# Boss rage animation
	if boss.has_method("play_phase_transition"):
		boss.play_phase_transition(new_phase)
	
	# Screen effects
	vfx_command.emit("screen_flash", {"color": Color.RED, "duration": 0.3})
	vfx_command.emit("boss_rage_aura", {"position": boss.global_position, "phase": new_phase})
	
	# Shake
	camera_command.emit("shake", {"intensity": 15.0, "duration": 1.0})
	
	# Audio
	audio_command.emit("play_sfx", {"sound": "boss_roar"})
	audio_command.emit("intensify_music", {"phase": new_phase})
	
	# Phase announcement
	ui_command.emit("phase_announcement", {
		"boss_name": boss.display_name,
		"phase": new_phase,
		"phase_name": boss.get_phase_name(new_phase) if boss.has_method("get_phase_name") else "Phase " + str(new_phase)
	})
	
	phase_changed.emit(boss, new_phase)
	
	await get_tree().create_timer(boss_phase_transition_time).timeout
	
	ui_command.emit("show_ui", {})

# -----------------------------------------------------------------------------
# BATTLE STATE CHECKING
# -----------------------------------------------------------------------------
func _check_battle_state() -> void:
	"""Check for victory/defeat after actions"""
	state = BattleState.CHECKING_STATE
	
	# Check for all enemies dead
	var enemies_alive = enemy_party.filter(func(e): 
		return e.is_alive() if e.has_method("is_alive") else true
	)
	
	if enemies_alive.is_empty():
		await _handle_victory()
		return
	
	# Check for all players dead
	var players_alive = player_party.filter(func(p):
		return p.is_alive() if p.has_method("is_alive") else true
	)
	
	if players_alive.is_empty():
		await _handle_defeat()
		return
	
	# Check for deaths that just happened
	for entity in all_combatants:
		if entity.has_method("just_died") and entity.just_died():
			await _handle_death(entity)

func _handle_death(entity: Node) -> void:
	"""Handle a single entity death with drama"""
	# Pause
	await get_tree().create_timer(death_dramatic_pause * 0.3).timeout
	
	# Camera focus
	camera_command.emit("focus", {"target": entity, "zoom": 1.1, "duration": 0.3})
	
	# Death animation
	if entity.has_method("play_death"):
		entity.play_death()
	
	# VFX
	vfx_command.emit("death_effect", {
		"position": entity.global_position,
		"brand": entity.get_brand() if entity.has_method("get_brand") else "NEUTRAL"
	})
	
	# Audio
	audio_command.emit("play_sfx", {"sound": "death"})
	
	# Extra drama for bosses
	if entity in active_bosses:
		camera_command.emit("shake", {"intensity": 20.0, "duration": 1.5})
		vfx_command.emit("boss_death_explosion", {"position": entity.global_position})
		await get_tree().create_timer(1.5).timeout
	
	await get_tree().create_timer(death_dramatic_pause).timeout
	
	camera_command.emit("return_to_battle", {"duration": camera_return_time})

func _handle_victory() -> void:
	"""Victory sequence"""
	state = BattleState.VICTORY
	
	ui_command.emit("hide_action_menu", {})
	
	# Victory fanfare
	audio_command.emit("play_jingle", {"jingle": "victory_fanfare"})
	
	# Camera victory shot
	camera_command.emit("victory_pan", {"targets": player_party})
	
	# Player celebrations
	for player in player_party:
		if player.has_method("play_victory"):
			player.play_victory()
	
	# Victory UI
	ui_command.emit("show_victory_screen", {
		"exp_gained": _calculate_exp(),
		"items_dropped": _calculate_drops(),
		"stats": battle_stats
	})
	
	await get_tree().create_timer(2.0).timeout
	
	battle_ended.emit(true)

func _handle_defeat() -> void:
	"""Defeat sequence"""
	state = BattleState.DEFEAT
	
	ui_command.emit("hide_action_menu", {})
	
	# Somber audio
	audio_command.emit("play_jingle", {"jingle": "defeat"})
	
	# Camera defeat shot
	camera_command.emit("defeat_pan", {"targets": player_party})
	
	# Defeat UI
	ui_command.emit("show_defeat_screen", {"stats": battle_stats})
	
	await get_tree().create_timer(2.0).timeout
	
	battle_ended.emit(false)

# -----------------------------------------------------------------------------
# UTILITY
# -----------------------------------------------------------------------------
func _apply_brand_modifier(damage: int, attacker_brand: String, target: Node) -> int:
	"""Apply brand effectiveness using the Brand Wheel (v5.0)
	
	Brand Effectiveness Wheel: SAVAGE → IRON → VENOM → SURGE → DREAD → LEECH → SAVAGE
	Each brand is STRONG (1.5x) against the next, WEAK (0.67x) against the previous.
	Hybrid brands use their PRIMARY brand for effectiveness calculations.
	"""
	if not target.has_method("get_brand"):
		return damage
	
	var target_brand = target.get_brand()
	var modifier = 1.0
	
	# Resolve hybrid brands to their primary brand for effectiveness
	var resolved_attacker = _resolve_hybrid_brand(attacker_brand)
	var resolved_target = _resolve_hybrid_brand(target_brand)
	
	# Brand effectiveness chart (v5.0 - matches Constants.BRAND_EFFECTIVENESS)
	# Wheel: SAVAGE → IRON → VENOM → SURGE → DREAD → LEECH → SAVAGE
	# Strong = 1.5x (Constants.BRAND_STRONG), Weak = 0.67x (Constants.BRAND_WEAK)
	var effectiveness = {
		"SAVAGE": {"IRON": 1.5, "LEECH": 0.67},    # Strong vs IRON, Weak vs LEECH
		"IRON": {"VENOM": 1.5, "SAVAGE": 0.67},    # Strong vs VENOM, Weak vs SAVAGE
		"VENOM": {"SURGE": 1.5, "IRON": 0.67},     # Strong vs SURGE, Weak vs IRON
		"SURGE": {"DREAD": 1.5, "VENOM": 0.67},    # Strong vs DREAD, Weak vs VENOM
		"DREAD": {"LEECH": 1.5, "SURGE": 0.67},    # Strong vs LEECH, Weak vs SURGE
		"LEECH": {"SAVAGE": 1.5, "DREAD": 0.67},   # Strong vs SAVAGE, Weak vs DREAD
	}
	
	if resolved_attacker in effectiveness and resolved_target in effectiveness[resolved_attacker]:
		modifier = effectiveness[resolved_attacker][resolved_target]
	
	return int(damage * modifier)

func _resolve_hybrid_brand(brand: String) -> String:
	"""Resolve hybrid brands to their primary brand for effectiveness calculations"""
	# Hybrid brand -> Primary brand mapping (70% primary, 30% secondary)
	var hybrid_to_primary = {
		"BLOODIRON": "SAVAGE",     # SAVAGE(70%) + IRON(30%)
		"CORROSIVE": "IRON",       # IRON(70%) + VENOM(30%)
		"VENOMSTRIKE": "VENOM",    # VENOM(70%) + SURGE(30%)
		"TERRORFLUX": "SURGE",     # SURGE(70%) + DREAD(30%)
		"NIGHTLEECH": "DREAD",     # DREAD(70%) + LEECH(30%)
		"RAVENOUS": "LEECH",       # LEECH(70%) + SAVAGE(30%)
	}
	
	var upper_brand = brand.to_upper()
	if upper_brand in hybrid_to_primary:
		return hybrid_to_primary[upper_brand]
	return upper_brand

func _get_brand_color(brand: String) -> Color:
	match brand.to_upper():
		"SAVAGE": return Color("c73e3e")
		"IRON": return Color("7b8794")
		"VENOM": return Color("6b9b37")
		"SURGE": return Color("4a90d9")
		"DREAD": return Color("5d3e8c")
		"LEECH": return Color("c75b8a")
		_: return Color.WHITE

func _calculate_exp() -> int:
	# Placeholder
	return 100

func _calculate_drops() -> Array:
	# Placeholder
	return []
