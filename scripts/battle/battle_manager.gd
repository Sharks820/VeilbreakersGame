class_name BattleManager
extends Node
## BattleManager: Orchestrates the entire battle flow.
## Enhanced with dramatic camera choreography, boss phases, and cinematic timing.

# =============================================================================
# SIGNALS - Battle Flow
# =============================================================================

signal battle_initialized()
signal round_started(round_number: int)
signal round_ended(round_number: int)
signal turn_started_signal(character: CharacterBase)
signal turn_ended_signal(character: CharacterBase)
signal waiting_for_player_input(character: CharacterBase)
signal action_animation_started(character: CharacterBase, action: int)
signal action_animation_finished(character: CharacterBase)
signal battle_victory(rewards: Dictionary)
signal battle_defeat()
signal battle_fled()

# =============================================================================
# SIGNALS - Camera/VFX/UI Commands (for BattleCameraController, VFXManager, etc.)
# =============================================================================

signal camera_command(command: String, data: Dictionary)
signal vfx_command(command: String, data: Dictionary)
signal ui_command(command: String, data: Dictionary)
signal audio_command(command: String, data: Dictionary)

# Boss phase signals
signal phase_changed(boss: Node, phase: int)
signal capture_attempt_started(target: Node)
signal capture_result(target: Node, success: bool)

# =============================================================================
# EXPORTS - Dramatic Timing (from BattleSequencer)
# =============================================================================

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

@export_group("Capture/Purify Timing")
@export var capture_throw_time: float = 0.5
@export var capture_shake_count: int = 3
@export var capture_shake_interval: float = 0.8
@export var capture_result_delay: float = 0.5

# =============================================================================
# STATE
# =============================================================================

var battle_state: Enums.BattleState = Enums.BattleState.INITIALIZING
var player_party: Array[CharacterBase] = []
var enemy_party: Array[CharacterBase] = []
var turn_order: Array[CharacterBase] = []
var current_turn_index: int = 0
var current_round: int = 0
var total_rewards: Dictionary = {"experience": 0, "currency": 0, "items": []}

# Action queue for current turn
var pending_action: Dictionary = {}
var is_executing_action: bool = false

# Boss tracking (from BattleSequencer)
var active_bosses: Array = []
var boss_phases: Dictionary = {}  # boss_node -> current_phase

# Battle statistics (from BattleSequencer)
var battle_stats: Dictionary = {
	"turns_taken": 0,
	"damage_dealt": 0,
	"damage_received": 0,
	"captures_attempted": 0,
	"captures_successful": 0,
}

# References to subsystems
var turn_manager: TurnManager
var damage_calculator: DamageCalculator
var status_effect_manager: StatusEffectManager
var ai_controller: AIController
var purification_system: PurificationSystem
var capture_system: CaptureSystem

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_setup_subsystems()

func _setup_subsystems() -> void:
	turn_manager = TurnManager.new()
	turn_manager.name = "TurnManager"
	add_child(turn_manager)

	damage_calculator = DamageCalculator.new()
	damage_calculator.name = "DamageCalculator"
	add_child(damage_calculator)

	status_effect_manager = StatusEffectManager.new()
	status_effect_manager.name = "StatusEffectManager"
	add_child(status_effect_manager)

	ai_controller = AIController.new()
	ai_controller.name = "AIController"
	add_child(ai_controller)

	purification_system = PurificationSystem.new()
	purification_system.name = "PurificationSystem"
	add_child(purification_system)

	capture_system = CaptureSystem.new()
	capture_system.name = "CaptureSystem"
	add_child(capture_system)
	_connect_capture_signals()

func _connect_capture_signals() -> void:
	capture_system.capture_succeeded.connect(_on_capture_succeeded)
	capture_system.capture_failed.connect(_on_capture_failed)
	capture_system.shake_progress.connect(_on_capture_shake)
	capture_system.corruption_reduced.connect(_on_corruption_reduced)

func _on_capture_succeeded(monster: Node, method: int, bonus_data: Dictionary) -> void:
	battle_stats.captures_successful += 1
	vfx_command.emit("screen_flash", {"color": Color.WHITE, "duration": 0.15})
	vfx_command.emit("capture_success", {"position": monster.global_position})
	audio_command.emit("play_sfx", {"sound": "capture_success"})
	audio_command.emit("play_jingle", {"jingle": "capture_fanfare"})
	ui_command.emit("capture_announcement", {"monster_name": monster.character_name})
	EventBus.emit_debug("%s was captured! (method: %d)" % [monster.character_name, method])
	if monster is Monster:
		_add_monster_to_rewards(monster as Monster)
	capture_result.emit(monster, true)

func _on_capture_failed(monster: Node, method: int, reason: String) -> void:
	camera_command.emit("shake", {"intensity": 10.0, "duration": 0.3})
	vfx_command.emit("capture_break", {"position": monster.global_position})
	audio_command.emit("play_sfx", {"sound": "capture_fail"})
	ui_command.emit("show_message", {"text": reason})
	EventBus.emit_debug("Capture failed: %s" % reason)
	capture_result.emit(monster, false)

func _on_capture_shake(monster: Node, current: int, total: int) -> void:
	camera_command.emit("shake", {"intensity": 4.0, "duration": 0.3})
	vfx_command.emit("capture_shake", {"position": monster.global_position, "shake_number": current})
	audio_command.emit("play_sfx", {"sound": "capture_struggle"})

func _on_corruption_reduced(monster: Node, old_val: float, new_val: float) -> void:
	var reduction := old_val - new_val
	vfx_command.emit("purify_effect", {"position": monster.global_position})
	ui_command.emit("show_message", {"text": "Corruption -%.0f%%" % reduction, "position": monster.global_position})
	EventBus.emit_debug("%s corruption: %.0f%% -> %.0f%%" % [monster.character_name, old_val, new_val])

# =============================================================================
# BATTLE FLOW
# =============================================================================

func start_battle(players: Array, enemies: Array, is_boss_battle: bool = false) -> void:
	player_party.clear()
	enemy_party.clear()
	active_bosses.clear()
	boss_phases.clear()

	# Reset statistics
	battle_stats = {
		"turns_taken": 0,
		"damage_dealt": 0,
		"damage_received": 0,
		"captures_attempted": 0,
		"captures_successful": 0,
	}

	# Convert to typed arrays
	for p in players:
		if p is CharacterBase:
			player_party.append(p)

	for e in enemies:
		if e is CharacterBase:
			enemy_party.append(e)
			# Track bosses
			if e is Monster and e.is_boss():
				active_bosses.append(e)
				boss_phases[e] = 1

	current_round = 0
	current_turn_index = 0
	total_rewards = {"experience": 0, "currency": 0, "items": []}
	is_executing_action = false

	battle_state = Enums.BattleState.INITIALIZING

	# Connect signals for all participants
	for character in player_party + enemy_party:
		if not character.died.is_connected(_on_character_died):
			character.died.connect(_on_character_died.bind(character))

	# Camera: Wide shot of battlefield
	camera_command.emit("battle_intro", {"duration": 1.5})

	# If boss battle, dramatic intro
	if is_boss_battle and active_bosses.size() > 0:
		await _play_boss_intro(active_bosses[0])

	EventBus.battle_started.emit(enemies)
	GameManager.change_state(Enums.GameState.BATTLE)
	GameManager.battle_count += 1

	battle_initialized.emit()
	EventBus.emit_debug("Battle started: %d players vs %d enemies" % [player_party.size(), enemy_party.size()])

	await get_tree().create_timer(0.5).timeout

	_start_round()

func _play_boss_intro(boss: Node) -> void:
	"""Dramatic boss introduction sequence"""
	ui_command.emit("hide_ui", {})
	camera_command.emit("boss_intro", {"target": boss, "duration": boss_intro_time})
	audio_command.emit("play_music", {"track": "boss_theme", "fade_in": 1.0})

	# Boss roar/intro animation
	if boss.has_method("play_intro"):
		boss.play_intro()

	var boss_name := boss.character_name if boss is CharacterBase else "Boss"
	var boss_title := ""
	if boss.has_method("get_title"):
		boss_title = boss.get_title()

	vfx_command.emit("boss_title_card", {"name": boss_name, "title": boss_title})

	await get_tree().create_timer(boss_intro_time).timeout
	ui_command.emit("show_ui", {})

func _start_round() -> void:
	current_round += 1
	battle_stats.turns_taken += 1
	battle_state = Enums.BattleState.TURN_START

	# Calculate turn order based on speed
	turn_order = turn_manager.calculate_turn_order(player_party + enemy_party)
	current_turn_index = 0

	# UI: Show turn order bar
	ui_command.emit("show_turn_order", {"order": turn_order})

	round_started.emit(current_round)
	EventBus.emit_debug("Round %d started" % current_round)

	await get_tree().create_timer(turn_start_delay).timeout

	_start_next_turn()

func _start_next_turn() -> void:
	if _check_battle_end():
		return

	if current_turn_index >= turn_order.size():
		_end_round()
		return

	var current_character := turn_order[current_turn_index]

	# Skip dead characters
	if current_character.is_dead():
		current_turn_index += 1
		_start_next_turn()
		return

	# Process start-of-turn effects
	var tick_results := current_character.tick_status_effects()
	current_character.tick_stat_modifiers()

	# Log status effect damage
	for result in tick_results:
		if result.has("damage"):
			EventBus.emit_debug("%s took %d damage from %s" % [
				current_character.character_name,
				result.damage,
				Enums.StatusEffect.keys()[result.effect]
			])

	# Check if character is still alive after status ticks
	if current_character.is_dead():
		current_turn_index += 1
		_start_next_turn()
		return

	# Check if character can act (stunned, frozen, etc.)
	if not current_character.can_act():
		EventBus.emit_debug("%s cannot act due to status effect" % current_character.character_name)
		ui_command.emit("show_message", {"text": current_character.character_name + " is stunned!"})
		EventBus.turn_ended.emit(current_character)
		turn_ended_signal.emit(current_character)
		current_turn_index += 1
		await get_tree().create_timer(0.5).timeout
		_start_next_turn()
		return

	EventBus.turn_started.emit(current_character)
	turn_started_signal.emit(current_character)

	# Camera: Focus on active entity
	camera_command.emit("focus", {"target": current_character, "duration": camera_focus_time})

	# Player or AI?
	if current_character in player_party:
		battle_state = Enums.BattleState.SELECTING_ACTION
		ui_command.emit("show_action_menu", {"entity": current_character})
		waiting_for_player_input.emit(current_character)
	else:
		# AI turn
		await get_tree().create_timer(0.3).timeout
		_execute_ai_turn(current_character)

func _execute_ai_turn(character: CharacterBase) -> void:
	var ai_decision := ai_controller.get_action(character, enemy_party, player_party)

	await get_tree().create_timer(0.3).timeout

	execute_action(character, ai_decision.action, ai_decision.target, ai_decision.get("skill", ""))

# =============================================================================
# ACTION EXECUTION
# =============================================================================

func submit_player_action(action: Enums.BattleAction, target: CharacterBase = null, skill: String = "") -> void:
	if battle_state != Enums.BattleState.SELECTING_ACTION and battle_state != Enums.BattleState.SELECTING_TARGET:
		return

	if is_executing_action:
		return

	ui_command.emit("hide_action_menu", {})

	var current_character := turn_order[current_turn_index]
	execute_action(current_character, action, target, skill)

func execute_action(character: CharacterBase, action: Enums.BattleAction, target: CharacterBase, skill: String = "") -> void:
	if is_executing_action:
		return

	is_executing_action = true
	battle_state = Enums.BattleState.EXECUTING_ACTION
	action_animation_started.emit(character, action)

	var result: Dictionary = {}

	match action:
		Enums.BattleAction.ATTACK:
			result = await _execute_attack(character, target)
		Enums.BattleAction.SKILL:
			result = await _execute_skill(character, target, skill)
		Enums.BattleAction.DEFEND:
			result = _execute_defend(character)
		Enums.BattleAction.ITEM:
			result = _execute_item(character, target, skill)  # skill = item_id
		Enums.BattleAction.PURIFY:
			result = await _execute_purify(character, target)
		Enums.BattleAction.FLEE:
			result = _execute_flee(character)

	EventBus.action_executed.emit(character, action, result)

	# Camera return to battle view
	camera_command.emit("return_to_battle", {"duration": camera_return_time})

	await get_tree().create_timer(action_recovery_time).timeout

	action_animation_finished.emit(character)
	is_executing_action = false

	if battle_state != Enums.BattleState.FLED:
		_end_turn()

func _execute_attack(attacker: CharacterBase, target: CharacterBase) -> Dictionary:
	if not target or target.is_dead():
		# Find a valid target
		target = _get_first_alive_target(enemy_party if attacker in player_party else player_party)
		if not target:
			return {"success": false, "reason": "No valid target"}

	# 1. WINDUP - Camera focus between attacker and target
	camera_command.emit("focus_between", {
		"from": attacker,
		"to": target,
		"bias": 0.3,
		"duration": action_windup_time
	})

	audio_command.emit("play_sfx", {"sound": "attack_whoosh", "position": attacker.global_position})
	await get_tree().create_timer(action_windup_time).timeout

	# 2. CALCULATE AND APPLY DAMAGE
	var result := damage_calculator.calculate_damage(attacker, target, null)

	if result.is_miss:
		ui_command.emit("show_message", {"text": "MISS!", "position": target.global_position})
		EventBus.emit_debug("%s's attack missed!" % attacker.character_name)
		return {"success": true, "is_miss": true}

	# 3. IMPACT MOMENT
	# Hitstop
	var freeze_time := impact_pause_time * 2 if result.is_critical else impact_pause_time
	camera_command.emit("impact_freeze", {"duration": freeze_time})

	# Screen shake
	var shake_intensity := 12.0 if result.is_critical else 6.0
	camera_command.emit("shake", {"intensity": shake_intensity, "duration": 0.2})

	# VFX
	vfx_command.emit("spawn_hit_effect", {
		"position": target.global_position,
		"is_critical": result.is_critical
	})

	# Screen flash for crits
	if result.is_critical:
		vfx_command.emit("screen_flash", {"color": Color.WHITE, "duration": 0.1})
		audio_command.emit("play_sfx", {"sound": "critical_hit"})

	# Damage number
	vfx_command.emit("spawn_damage_number", {
		"position": target.global_position,
		"amount": result.damage,
		"is_critical": result.is_critical
	})

	# Apply damage
	target.take_damage(result.damage, attacker, result.is_critical)

	# Track stats
	if attacker in player_party:
		battle_stats.damage_dealt += result.damage
	else:
		battle_stats.damage_received += result.damage

	# Check for boss phase transition
	if target in active_bosses:
		await _check_boss_phase(target)

	EventBus.emit_debug("%s dealt %d damage to %s%s" % [
		attacker.character_name,
		result.damage,
		target.character_name,
		" (CRITICAL!)" if result.is_critical else ""
	])

	await get_tree().create_timer(impact_pause_time).timeout

	return result

func _execute_skill(caster: CharacterBase, target: CharacterBase, skill_id: String) -> Dictionary:
	# Load skill data from DataManager
	var skill_data: SkillData = DataManager.get_skill(skill_id)
	if not skill_data:
		return {"success": false, "reason": "Unknown skill: %s" % skill_id}

	# Check if caster can use the skill
	var can_use_result := skill_data.can_use(caster)
	if not can_use_result.can_use:
		return {"success": false, "reason": can_use_result.reasons[0] if can_use_result.reasons.size() > 0 else "Cannot use skill"}

	# Check for silence status
	if caster.has_status_effect(Enums.StatusEffect.SILENCE):
		return {"success": false, "reason": "Silenced!"}

	# Deduct costs
	if skill_data.mp_cost > 0:
		caster.use_mp(skill_data.mp_cost)
	if skill_data.hp_cost > 0:
		caster.take_damage(skill_data.hp_cost, null, false)

	# SKILL ANNOUNCEMENT
	ui_command.emit("show_skill_name", {"name": skill_data.display_name})
	audio_command.emit("play_sfx", {"sound": "skill_announce"})

	# CAST ANIMATION
	camera_command.emit("focus", {"target": caster, "zoom": 1.2, "duration": 0.3})

	vfx_command.emit("skill_charge", {
		"position": caster.global_position,
		"duration": 0.5
	})

	await get_tree().create_timer(0.5).timeout

	var result := {"success": true, "skill_id": skill_id, "effects": []}

	# Get targets based on target type
	var targets: Array[CharacterBase] = _get_skill_targets(caster, target, skill_data.target_type)

	# Camera to show all targets
	if targets.size() > 1:
		camera_command.emit("focus_group", {"targets": targets, "duration": 0.3})
	elif targets.size() == 1:
		camera_command.emit("focus", {"target": targets[0], "duration": 0.3})

	await get_tree().create_timer(0.3).timeout

	# Execute based on skill type
	match skill_data.skill_type:
		SkillData.SkillType.DAMAGE:
			for t in targets:
				var dmg_result := damage_calculator.calculate_damage(caster, t, skill_data)
				if not dmg_result.is_miss:
					# Impact effects
					camera_command.emit("shake", {"intensity": 8.0, "duration": 0.15})
					vfx_command.emit("spawn_hit_effect", {"position": t.global_position, "is_critical": dmg_result.is_critical})
					vfx_command.emit("spawn_damage_number", {"position": t.global_position, "amount": dmg_result.damage, "is_critical": dmg_result.is_critical})
					t.take_damage(dmg_result.damage, caster, dmg_result.is_critical)
					result.effects.append({"target": t.character_name, "damage": dmg_result.damage, "critical": dmg_result.is_critical})
					# Track stats
					if caster in player_party:
						battle_stats.damage_dealt += dmg_result.damage
				else:
					result.effects.append({"target": t.character_name, "miss": true})
				await get_tree().create_timer(between_hits_delay).timeout

		SkillData.SkillType.HEAL:
			for t in targets:
				var heal_result := damage_calculator.calculate_healing(caster, t, skill_data)
				var actual_heal := t.heal(heal_result.heal_amount, caster)
				vfx_command.emit("heal_effect", {"position": t.global_position})
				vfx_command.emit("spawn_damage_number", {"position": t.global_position, "amount": actual_heal, "is_heal": true})
				result.effects.append({"target": t.character_name, "heal": actual_heal})

		SkillData.SkillType.BUFF, SkillData.SkillType.DEBUFF:
			for t in targets:
				_apply_skill_modifiers(t, skill_data, caster)
				vfx_command.emit("buff_effect", {"position": t.global_position, "is_buff": skill_data.skill_type == SkillData.SkillType.BUFF})
				result.effects.append({"target": t.character_name, "buffs_applied": true})

		SkillData.SkillType.STATUS:
			for t in targets:
				_apply_skill_status_effects(t, skill_data, caster)
				vfx_command.emit("status_apply", {"position": t.global_position})
				result.effects.append({"target": t.character_name, "status_applied": true})

		SkillData.SkillType.UTILITY:
			# Handle special effects
			for effect_id in skill_data.special_effects:
				_handle_special_effect(caster, targets, effect_id, skill_data)

	# Apply status effects from damage/heal skills too
	if skill_data.skill_type in [SkillData.SkillType.DAMAGE, SkillData.SkillType.HEAL]:
		for t in targets:
			_apply_skill_status_effects(t, skill_data, caster)
			_apply_skill_modifiers(t, skill_data, caster)

	EventBus.emit_debug("%s used %s!" % [caster.character_name, skill_data.display_name])
	EventBus.skill_used.emit(caster, skill_id)

	return result

func _get_skill_targets(caster: CharacterBase, primary_target: CharacterBase, target_type: Enums.TargetType) -> Array[CharacterBase]:
	var targets: Array[CharacterBase] = []
	var is_player := caster in player_party

	match target_type:
		Enums.TargetType.SELF:
			targets.append(caster)

		Enums.TargetType.SINGLE_ALLY:
			if primary_target and ((is_player and primary_target in player_party) or (not is_player and primary_target in enemy_party)):
				targets.append(primary_target)
			else:
				targets.append(caster)

		Enums.TargetType.SINGLE_ENEMY:
			if primary_target:
				targets.append(primary_target)
			else:
				var enemy_group := enemy_party if is_player else player_party
				for e in enemy_group:
					if e.is_alive():
						targets.append(e)
						break

		Enums.TargetType.ALL_ALLIES:
			var ally_group := player_party if is_player else enemy_party
			for ally in ally_group:
				if ally.is_alive():
					targets.append(ally)

		Enums.TargetType.ALL_ENEMIES:
			var enemy_group := enemy_party if is_player else player_party
			for enemy in enemy_group:
				if enemy.is_alive():
					targets.append(enemy)

		Enums.TargetType.ALL:
			for p in player_party:
				if p.is_alive():
					targets.append(p)
			for e in enemy_party:
				if e.is_alive():
					targets.append(e)

	return targets

func _apply_skill_status_effects(target: CharacterBase, skill_data: SkillData, source: CharacterBase) -> void:
	for effect_data in skill_data.status_effects:
		var chance: float = effect_data.get("chance", 1.0)
		var roll := randf()
		if roll <= chance:
			var effect: Enums.StatusEffect = effect_data.effect
			var duration: int = effect_data.get("duration", 3)
			target.add_status_effect(effect, duration, source)
		else:
			ui_command.emit("show_message", {"text": "RESISTED!", "position": target.global_position})

func _apply_skill_modifiers(target: CharacterBase, skill_data: SkillData, source: CharacterBase) -> void:
	for mod_data in skill_data.stat_modifiers:
		var stat: Enums.Stat = mod_data.stat
		var amount: float = mod_data.amount
		var duration: int = mod_data.get("duration", 3)
		target.add_stat_modifier(stat, amount, duration, skill_data.skill_id)

func _handle_special_effect(caster: CharacterBase, targets: Array[CharacterBase], effect_id: String, _skill_data: SkillData) -> void:
	match effect_id:
		"extend_on_kill":
			# Handled by listening to death signals
			pass
		"life_steal":
			# Already handled in damage calculation
			pass
		"dispel":
			for t in targets:
				t.clear_all_status_effects()
		"revive":
			for t in targets:
				if t.is_dead():
					t.revive(0.5)
					vfx_command.emit("revive_effect", {"position": t.global_position})
		_:
			EventBus.emit_debug("Unknown special effect: %s" % effect_id)

func _execute_defend(character: CharacterBase) -> Dictionary:
	character.set_defending(true)

	vfx_command.emit("defend_effect", {"position": character.global_position})
	audio_command.emit("play_sfx", {"sound": "defend"})

	ui_command.emit("show_status_popup", {
		"target": character,
		"status": "DEFENDING",
		"positive": true
	})

	EventBus.emit_debug("%s is defending" % character.character_name)
	return {"success": true, "defense_boost": character.base_defense * 0.5}

func _execute_item(user: CharacterBase, target: CharacterBase, item_id: String) -> Dictionary:
	# Use item through inventory system
	var use_target := target if target else user
	var result := InventorySystem.use_item(item_id, use_target)

	if result.success:
		audio_command.emit("play_sfx", {"sound": "item_use"})
		EventBus.emit_debug("%s used %s on %s" % [user.character_name, item_id, use_target.character_name])
		# Log effects with VFX
		for effect in result.get("effects", []):
			if effect.has("heal_hp"):
				vfx_command.emit("heal_effect", {"position": use_target.global_position})
				vfx_command.emit("spawn_damage_number", {"position": use_target.global_position, "amount": effect.heal_hp, "is_heal": true})
				EventBus.emit_debug("  Restored %d HP" % effect.heal_hp)
			if effect.has("heal_mp"):
				EventBus.emit_debug("  Restored %d MP" % effect.heal_mp)
			if effect.has("revive"):
				vfx_command.emit("revive_effect", {"position": use_target.global_position})
				EventBus.emit_debug("  Revived!")
	else:
		EventBus.emit_debug("Failed to use item: %s" % result.get("reason", "Unknown error"))

	return result

func _execute_purify(purifier: CharacterBase, target: CharacterBase) -> Dictionary:
	# This is now a wrapper that delegates to CaptureSystem
	# The PURIFY action reduces corruption to improve capture odds
	if not target is Monster:
		return {"success": false, "reason": "Target is not a monster"}

	var monster: Monster = target as Monster

	if not monster.can_be_purified():
		return {"success": false, "reason": "Monster cannot be purified"}

	battle_state = Enums.BattleState.PURIFICATION
	battle_stats.captures_attempted += 1
	capture_attempt_started.emit(target)

	# Use the new CaptureSystem with PURIFY method
	# This reduces corruption rather than attempting direct capture
	await capture_system.attempt_capture(monster, purifier, CaptureSystem.CaptureMethod.PURIFY)

	# Return basic result - actual success/fail handled by signals
	return {"success": true, "delegated": true}

## Execute capture with orb (called when using capture items)
func execute_orb_capture(caster: CharacterBase, target: CharacterBase, orb_tier: int) -> Dictionary:
	if not target is Monster:
		return {"success": false, "reason": "Target is not a monster"}

	var monster: Monster = target as Monster

	# Check for boss (tier 3+ = BOSS, rarity 4+ = LEGENDARY)
	if monster.monster_tier >= Enums.MonsterTier.BOSS or monster.rarity >= Enums.Rarity.LEGENDARY:
		ui_command.emit("show_message", {"text": "Cannot capture boss monsters!"})
		return {"success": false, "reason": "Boss monsters cannot be captured"}

	battle_state = Enums.BattleState.PURIFICATION
	battle_stats.captures_attempted += 1
	capture_attempt_started.emit(target)

	# Camera focus
	camera_command.emit("focus", {"target": caster, "duration": 0.2})
	audio_command.emit("play_sfx", {"sound": "capture_throw"})

	vfx_command.emit("capture_projectile", {
		"from": caster.global_position,
		"to": monster.global_position,
		"duration": capture_throw_time
	})

	await get_tree().create_timer(capture_throw_time).timeout

	# Use CaptureSystem
	var tier_enum: CaptureSystem.OrbTier = orb_tier as CaptureSystem.OrbTier
	await capture_system.attempt_capture(monster, caster, CaptureSystem.CaptureMethod.ORB, tier_enum)

	return {"success": true, "delegated": true}

## Execute bargain capture attempt
func execute_bargain_capture(caster: CharacterBase, target: CharacterBase) -> Dictionary:
	if not target is Monster:
		return {"success": false, "reason": "Target is not a monster"}

	var monster: Monster = target as Monster

	battle_state = Enums.BattleState.PURIFICATION
	capture_attempt_started.emit(target)

	await capture_system.attempt_capture(monster, caster, CaptureSystem.CaptureMethod.BARGAIN)

	return {"success": true, "delegated": true}

## Execute force capture attempt
func execute_force_capture(caster: CharacterBase, target: CharacterBase) -> Dictionary:
	if not target is Monster:
		return {"success": false, "reason": "Target is not a monster"}

	var monster: Monster = target as Monster

	# Validate force conditions
	var check := capture_system.can_use_method(monster, caster, CaptureSystem.CaptureMethod.FORCE)
	if not check.available:
		ui_command.emit("show_message", {"text": check.reason})
		return {"success": false, "reason": check.reason}

	battle_state = Enums.BattleState.PURIFICATION
	capture_attempt_started.emit(target)

	await capture_system.attempt_capture(monster, caster, CaptureSystem.CaptureMethod.FORCE)

	return {"success": true, "delegated": true}

## Get capture chance preview for UI
func get_capture_chance_preview(caster: CharacterBase, target: CharacterBase, method: int, orb_tier: int = 0) -> Dictionary:
	if not target is Monster:
		return {"available": false, "chance": 0.0, "reason": "Not a monster"}

	var capture_method := method as CaptureSystem.CaptureMethod
	var check := capture_system.can_use_method(target, caster, capture_method)

	if capture_method == CaptureSystem.CaptureMethod.ORB:
		var tier := orb_tier as CaptureSystem.OrbTier
		check.capture_chance = capture_system.calculate_orb_capture_chance(target, caster, tier)
		check.chance_text = capture_system.get_capture_chance_text(check.capture_chance)

	return check

func _execute_flee(character: CharacterBase) -> Dictionary:
	var flee_chance := Constants.ESCAPE_BASE_CHANCE

	# Modify by speed difference
	var party_speed := 0.0
	var enemy_speed := 0.0

	for p in player_party:
		if p.is_alive():
			party_speed += p.get_stat(Enums.Stat.SPEED)
	for e in enemy_party:
		if e.is_alive():
			enemy_speed += e.get_stat(Enums.Stat.SPEED)

	var alive_players := player_party.filter(func(p): return p.is_alive())
	var alive_enemies := enemy_party.filter(func(e): return e.is_alive())

	if alive_players.size() > 0:
		party_speed /= alive_players.size()
	if alive_enemies.size() > 0:
		enemy_speed /= alive_enemies.size()

	flee_chance += (party_speed - enemy_speed) * 0.01
	flee_chance = clampf(flee_chance, 0.1, 0.9)

	# Can't flee from bosses
	if active_bosses.size() > 0:
		ui_command.emit("show_message", {"text": "Can't escape from boss!"})
		audio_command.emit("play_sfx", {"sound": "flee_fail"})
		flee_chance = 0.0
		return {"success": false, "chance": flee_chance}

	if randf() <= flee_chance:
		battle_state = Enums.BattleState.FLED
		GameManager.flee_count += 1
		ui_command.emit("show_message", {"text": "Got away safely!"})
		audio_command.emit("play_sfx", {"sound": "flee_success"})
		EventBus.emit_debug("Successfully fled from battle!")
		battle_fled.emit()
		EventBus.battle_ended.emit(false, {})
		return {"success": true}

	ui_command.emit("show_message", {"text": "Couldn't escape!"})
	audio_command.emit("play_sfx", {"sound": "flee_fail"})
	EventBus.emit_debug("Failed to flee! (%.1f%% chance)" % [flee_chance * 100])
	return {"success": false, "chance": flee_chance}

# =============================================================================
# BOSS PHASE SYSTEM (from BattleSequencer)
# =============================================================================

func _check_boss_phase(boss: Node) -> void:
	"""Check if boss should transition phases"""
	if not boss.has_method("get_phase_thresholds"):
		return

	var current_phase: int = boss_phases.get(boss, 1)
	var thresholds: Array = boss.get_phase_thresholds()  # e.g., [0.7, 0.4, 0.15]
	var hp_percent: float = boss.get_hp_percent() if boss.has_method("get_hp_percent") else 1.0

	var new_phase := 1
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

	var boss_name: String = boss.character_name if boss is CharacterBase else "Boss"
	var phase_name := "Phase " + str(new_phase)
	if boss.has_method("get_phase_name"):
		phase_name = boss.get_phase_name(new_phase)

	# Phase announcement
	ui_command.emit("phase_announcement", {
		"boss_name": boss_name,
		"phase": new_phase,
		"phase_name": phase_name
	})

	phase_changed.emit(boss, new_phase)

	await get_tree().create_timer(boss_phase_transition_time).timeout

	ui_command.emit("show_ui", {})

# =============================================================================
# TURN MANAGEMENT
# =============================================================================

func _end_turn() -> void:
	battle_state = Enums.BattleState.TURN_END

	var current_character := turn_order[current_turn_index]
	EventBus.turn_ended.emit(current_character)
	turn_ended_signal.emit(current_character)

	current_turn_index += 1

	if not _check_battle_end():
		await get_tree().create_timer(turn_end_delay).timeout
		_start_next_turn()

func _end_round() -> void:
	round_ended.emit(current_round)
	EventBus.emit_debug("Round %d ended" % current_round)

	if not _check_battle_end():
		_start_round()

# =============================================================================
# BATTLE END CONDITIONS
# =============================================================================

func _check_battle_end() -> bool:
	# Check for player defeat
	var all_players_dead := true
	for player in player_party:
		if player.is_alive():
			all_players_dead = false
			break

	if all_players_dead:
		_on_battle_defeat()
		return true

	# Check for victory (all enemies dead or purified)
	var all_enemies_defeated := true
	for enemy in enemy_party:
		if enemy.is_alive():
			if enemy is Monster:
				if enemy.is_corrupted:
					all_enemies_defeated = false
					break
			else:
				all_enemies_defeated = false
				break

	if all_enemies_defeated:
		_on_battle_victory()
		return true

	return false

func _on_battle_victory() -> void:
	battle_state = Enums.BattleState.VICTORY
	EventBus.emit_debug("Battle Victory!")

	ui_command.emit("hide_action_menu", {})

	# Victory fanfare
	audio_command.emit("play_jingle", {"jingle": "victory_fanfare"})

	# Camera victory shot
	camera_command.emit("victory_pan", {"targets": player_party})

	# Player celebrations
	for player in player_party:
		if player.has_method("play_victory"):
			player.play_victory()

	# Collect rewards from defeated enemies
	for enemy in enemy_party:
		if enemy is Monster:
			var monster: Monster = enemy as Monster
			if not monster.is_corrupted:
				# Monster was purified, don't add kill rewards
				continue

			var rewards := monster.get_rewards()
			total_rewards.experience += rewards.experience
			total_rewards.currency += rewards.currency
			total_rewards.items.append_array(rewards.items)
			GameManager.monsters_defeated += 1

	# Apply rewards
	GameManager.add_currency(total_rewards.currency)

	# Distribute experience to party
	var alive_players := player_party.filter(func(p): return p.is_alive())
	var exp_per_player := total_rewards.experience / maxi(1, alive_players.size())

	for player in alive_players:
		if player is PlayerCharacter:
			player.add_experience(exp_per_player)

	for item in total_rewards.items:
		EventBus.item_obtained.emit(item.item_id, item.quantity)

	GameManager.victory_count += 1

	# Victory UI
	ui_command.emit("show_victory_screen", {
		"exp_gained": total_rewards.experience,
		"items_dropped": total_rewards.items,
		"stats": battle_stats
	})

	battle_victory.emit(total_rewards)
	EventBus.battle_ended.emit(true, total_rewards)

func _on_battle_defeat() -> void:
	battle_state = Enums.BattleState.DEFEAT
	GameManager.defeat_count += 1
	EventBus.emit_debug("Battle Defeat!")

	ui_command.emit("hide_action_menu", {})

	# Somber audio
	audio_command.emit("play_jingle", {"jingle": "defeat"})

	# Camera defeat shot
	camera_command.emit("defeat_pan", {"targets": player_party})

	# Defeat UI
	ui_command.emit("show_defeat_screen", {"stats": battle_stats})

	battle_defeat.emit()
	EventBus.battle_ended.emit(false, {})
	GameManager.change_state(Enums.GameState.GAME_OVER)

func _on_character_died(character: CharacterBase) -> void:
	EventBus.emit_debug("%s has been defeated!" % character.character_name)

	# Dramatic death sequence
	await get_tree().create_timer(death_dramatic_pause * 0.3).timeout

	# Camera focus on dying character
	camera_command.emit("focus", {"target": character, "zoom": 1.1, "duration": 0.3})

	# Death VFX
	vfx_command.emit("death_effect", {"position": character.global_position})
	audio_command.emit("play_sfx", {"sound": "death"})

	# Extra drama for bosses
	if character in active_bosses:
		camera_command.emit("shake", {"intensity": 20.0, "duration": 1.5})
		vfx_command.emit("boss_death_explosion", {"position": character.global_position})
		await get_tree().create_timer(1.5).timeout

	await get_tree().create_timer(death_dramatic_pause).timeout

	camera_command.emit("return_to_battle", {"duration": camera_return_time})

	# Remove from turn order
	if character in turn_order:
		var index := turn_order.find(character)
		if index < current_turn_index and current_turn_index > 0:
			current_turn_index -= 1
		turn_order.erase(character)

func _add_monster_to_rewards(monster: Monster) -> void:
	# Monster was purified, add to party
	if monster.recruit_to_party():
		if GameManager.add_to_party(monster):
			EventBus.emit_notification("%s joined your party!" % monster.character_name, "success")
		else:
			EventBus.emit_notification("Party is full! %s was sent to reserves." % monster.character_name, "info")

# =============================================================================
# QUERIES
# =============================================================================

func get_current_character() -> CharacterBase:
	if current_turn_index < turn_order.size():
		return turn_order[current_turn_index]
	return null

func get_valid_targets(action: Enums.BattleAction, skill_or_item: String = "") -> Array[CharacterBase]:
	var targets: Array[CharacterBase] = []

	match action:
		Enums.BattleAction.ATTACK, Enums.BattleAction.PURIFY:
			for enemy in enemy_party:
				if enemy.is_alive():
					targets.append(enemy)

		Enums.BattleAction.SKILL:
			# Check skill target type
			var skill_data: SkillData = DataManager.get_skill(skill_or_item)
			if skill_data:
				match skill_data.target_type:
					Enums.TargetType.SELF:
						var current := get_current_character()
						if current:
							targets.append(current)
					Enums.TargetType.SINGLE_ALLY, Enums.TargetType.ALL_ALLIES:
						for player in player_party:
							if player.is_alive():
								targets.append(player)
					Enums.TargetType.SINGLE_ENEMY, Enums.TargetType.ALL_ENEMIES:
						for enemy in enemy_party:
							if enemy.is_alive():
								targets.append(enemy)
					Enums.TargetType.ALL:
						for player in player_party:
							if player.is_alive():
								targets.append(player)
						for enemy in enemy_party:
							if enemy.is_alive():
								targets.append(enemy)
			else:
				# Unknown skill, allow all targets
				for player in player_party:
					if player.is_alive():
						targets.append(player)
				for enemy in enemy_party:
					if enemy.is_alive():
						targets.append(enemy)

		Enums.BattleAction.ITEM:
			# Check item target type
			var item_data: ItemData = InventorySystem.get_item_data(skill_or_item)
			if item_data:
				match item_data.target_type:
					Enums.TargetType.SELF:
						var current := get_current_character()
						if current:
							targets.append(current)
					Enums.TargetType.SINGLE_ALLY, Enums.TargetType.ALL_ALLIES:
						for player in player_party:
							if player.is_alive() or item_data.revives:
								targets.append(player)
					Enums.TargetType.SINGLE_ENEMY, Enums.TargetType.ALL_ENEMIES:
						for enemy in enemy_party:
							if enemy.is_alive():
								targets.append(enemy)
					_:
						for player in player_party:
							if player.is_alive():
								targets.append(player)
			else:
				# Unknown item, allow all allies
				for player in player_party:
					if player.is_alive():
						targets.append(player)

		Enums.BattleAction.DEFEND, Enums.BattleAction.FLEE:
			# No target needed
			pass

	return targets

func is_player_turn() -> bool:
	var current := get_current_character()
	return current != null and current in player_party

func _get_first_alive_target(party: Array[CharacterBase]) -> CharacterBase:
	for character in party:
		if character.is_alive():
			return character
	return null

func get_battle_summary() -> Dictionary:
	return {
		"round": current_round,
		"state": Enums.BattleState.keys()[battle_state],
		"player_party_alive": player_party.filter(func(p): return p.is_alive()).size(),
		"enemy_party_alive": enemy_party.filter(func(e): return e.is_alive()).size(),
		"current_character": get_current_character().character_name if get_current_character() else "None",
		"stats": battle_stats
	}
