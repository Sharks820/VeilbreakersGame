class_name BattleManager
extends Node
## BattleManager: Orchestrates the entire battle flow.
## Enhanced with dramatic camera choreography, boss phases, and cinematic timing.

# Load CaptureSystem dynamically to avoid circular dependency issues
# The CaptureSystem class is created in _setup_subsystems()

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

# Lock-in turn system
var queued_party_actions: Dictionary = {}  # {character: {action, target, skill}}
var party_lock_in_index: int = 0           # Which party member is selecting
var party_execution_index: int = 0         # Which queued action to execute
var enemy_attacks_remaining: int = 0       # Enemies get attacks = alive party count
var enemy_attack_index: int = 0            # Which enemy is attacking

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

# References to subsystems (untyped to avoid cyclic dependency issues)
var turn_manager = null
var damage_calculator = null
var status_effect_manager = null
var ai_controller = null
var purification_system = null
var capture_system = null

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_setup_subsystems()

func _setup_subsystems() -> void:
	# Check if subsystems already exist as scene children (from battle_arena.tscn)
	# Only create new instances if they don't exist to avoid duplicates
	
	var existing_turn_manager := get_node_or_null("TurnManager")
	if existing_turn_manager:
		turn_manager = existing_turn_manager
	else:
		turn_manager = TurnManager.new()
		turn_manager.name = "TurnManager"
		add_child(turn_manager)

	var existing_damage_calc := get_node_or_null("DamageCalculator")
	if existing_damage_calc:
		damage_calculator = existing_damage_calc
	else:
		damage_calculator = DamageCalculator.new()
		damage_calculator.name = "DamageCalculator"
		add_child(damage_calculator)

	var existing_status_mgr := get_node_or_null("StatusEffectManager")
	if existing_status_mgr:
		status_effect_manager = existing_status_mgr
	else:
		status_effect_manager = StatusEffectManager.new()
		status_effect_manager.name = "StatusEffectManager"
		add_child(status_effect_manager)

	var existing_ai := get_node_or_null("AIController")
	if existing_ai:
		ai_controller = existing_ai
	else:
		ai_controller = AIController.new()
		ai_controller.name = "AIController"
		add_child(ai_controller)

	var existing_purify := get_node_or_null("PurificationSystem")
	if existing_purify:
		purification_system = existing_purify
	else:
		purification_system = PurificationSystem.new()
		purification_system.name = "PurificationSystem"
		add_child(purification_system)

	# Load CaptureSystem dynamically to avoid circular dependency
	var existing_capture := get_node_or_null("CaptureSystem")
	if existing_capture:
		capture_system = existing_capture
		_connect_capture_signals()
	else:
		var capture_script = load("res://scripts/battle/capture_system.gd")
		if capture_script:
			capture_system = capture_script.new()
			capture_system.name = "CaptureSystem"
			add_child(capture_system)
			_connect_capture_signals()
		else:
			push_error("Failed to load capture_system.gd")

func _connect_capture_signals() -> void:
	capture_system.capture_succeeded.connect(_on_capture_succeeded)
	capture_system.capture_failed.connect(_on_capture_failed)
	capture_system.corruption_battle_pass.connect(_on_capture_shake)
	capture_system.corruption_reduced.connect(_on_corruption_reduced)

func _on_capture_succeeded(monster: Node, method: int, bonus_data: Dictionary) -> void:
	battle_stats.captures_successful += 1

	# Validate monster node before accessing properties
	if not is_instance_valid(monster):
		push_warning("BattleManager: Monster invalid in capture success handler")
		capture_result.emit(null, true)
		return

	vfx_command.emit("screen_flash", {"color": Color.WHITE, "duration": 0.15})
	vfx_command.emit("capture_success", {"position": monster.global_position})
	audio_command.emit("play_sfx", {"sound": "capture_success"})
	audio_command.emit("play_jingle", {"jingle": "capture_fanfare"})

	# Use bonus_data for enhanced feedback if available
	var monster_name: String = monster.character_name if "character_name" in monster else "Monster"
	var capture_chance: float = bonus_data.get("capture_chance", 0.0)
	var method_name: String = bonus_data.get("method_name", "capture")
	ui_command.emit("capture_announcement", {"monster_name": monster_name, "method": method_name, "chance": capture_chance})
	EventBus.emit_debug("%s was captured via %s! (chance: %.0f%%)" % [monster_name, method_name, capture_chance * 100])

	if monster is Monster:
		_add_monster_to_rewards(monster as Monster)
	capture_result.emit(monster, true)

func _on_capture_failed(monster: Node, _method: int, reason: String) -> void:
	# Validate monster node before accessing properties
	if is_instance_valid(monster):
		camera_command.emit("shake", {"intensity": 10.0, "duration": 0.3})
		vfx_command.emit("capture_break", {"position": monster.global_position})
	else:
		camera_command.emit("shake", {"intensity": 8.0, "duration": 0.2})

	audio_command.emit("play_sfx", {"sound": "capture_fail"})
	ui_command.emit("show_message", {"text": reason})
	EventBus.emit_debug("Capture failed: %s" % reason)
	# Pass null if monster is invalid to signal listeners
	capture_result.emit(monster if is_instance_valid(monster) else null, false)

func _on_capture_shake(monster: Node, current: int, total: int) -> void:
	# Intensity increases with each shake (guard against division by zero)
	var shake_total := maxi(total, 1)
	var intensity := 4.0 + (float(current) / float(shake_total)) * 4.0
	camera_command.emit("shake", {"intensity": intensity, "duration": 0.3})

	# Validate monster node before accessing position
	if is_instance_valid(monster):
		vfx_command.emit("capture_shake", {"position": monster.global_position, "shake_number": current, "total_shakes": total})
	audio_command.emit("play_sfx", {"sound": "capture_struggle"})

func _on_corruption_reduced(monster: Node, old_val: float, new_val: float) -> void:
	var reduction := old_val - new_val

	# Validate monster node before accessing properties
	if not is_instance_valid(monster):
		push_warning("BattleManager: Monster invalid in corruption reduced handler")
		return

	vfx_command.emit("purify_effect", {"position": monster.global_position})
	ui_command.emit("show_message", {"text": "Corruption -%.0f%%" % reduction, "position": monster.global_position})
	var monster_name: String = monster.character_name if "character_name" in monster else "Monster"
	EventBus.emit_debug("%s corruption: %.0f%% -> %.0f%%" % [monster_name, old_val, new_val])

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

	var boss_name: String = boss.character_name if boss is CharacterBase else "Boss"
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

	# Calculate turn order based on speed (for display purposes)
	turn_order = turn_manager.calculate_turn_order(player_party + enemy_party)
	current_turn_index = 0

	# Clear queued actions for new round
	queued_party_actions.clear()
	party_lock_in_index = 0
	party_execution_index = 0
	enemy_attack_index = 0

	# UI: Show turn order bar
	ui_command.emit("show_turn_order", {"order": turn_order})

	print("[BATTLE_MANAGER] Emitting round_started signal for round %d with %d characters in turn_order" % [current_round, turn_order.size()])
	round_started.emit(current_round)
	EventBus.emit_debug("Round %d started - Lock-in Phase" % current_round)

	await get_tree().create_timer(turn_start_delay).timeout

	# Start with party lock-in phase
	_start_party_lock_in()

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
	var ai_decision: Dictionary = ai_controller.get_action(character, enemy_party, player_party)

	await get_tree().create_timer(0.3).timeout

	execute_action(character, ai_decision.action, ai_decision.target, ai_decision.get("skill", ""))

# =============================================================================
# LOCK-IN TURN SYSTEM
# =============================================================================

func _start_party_lock_in() -> void:
	"""Begin the party lock-in phase where all allies select actions before executing"""
	battle_state = Enums.BattleState.PARTY_LOCK_IN
	party_lock_in_index = 0
	queued_party_actions.clear()

	EventBus.emit_debug("=== PARTY LOCK-IN PHASE ===")
	ui_command.emit("show_message", {"text": "Select Actions!", "duration": 1.0})

	await get_tree().create_timer(0.5).timeout
	_prompt_next_party_member()

func _prompt_next_party_member() -> void:
	"""Prompt the next party member to select their action"""
	if _check_battle_end():
		return

	# Find next alive party member
	while party_lock_in_index < player_party.size():
		var character := player_party[party_lock_in_index]

		if character.is_dead():
			party_lock_in_index += 1
			continue

		# Process start-of-turn effects for this character
		var tick_results := character.tick_status_effects()
		character.tick_stat_modifiers()

		# Log status effect damage
		for result in tick_results:
			if result.has("damage"):
				EventBus.emit_debug("%s took %d damage from %s" % [
					character.character_name,
					result.damage,
					Enums.StatusEffect.keys()[result.effect]
				])

		# Check if character died from status effects
		if character.is_dead():
			party_lock_in_index += 1
			continue

		# Check if character can act (stunned, frozen, etc.)
		if not character.can_act():
			EventBus.emit_debug("%s cannot act due to status effect" % character.character_name)
			ui_command.emit("show_message", {"text": character.character_name + " is stunned!"})
			# Auto-defend for stunned characters
			queued_party_actions[character] = {
				"action": Enums.BattleAction.DEFEND,
				"target": character,
				"skill": ""
			}
			party_lock_in_index += 1
			await get_tree().create_timer(0.5).timeout
			continue

		# This character can select an action
		EventBus.turn_started.emit(character)
		turn_started_signal.emit(character)

		# Camera: Focus on character selecting
		camera_command.emit("focus", {"target": character, "duration": camera_focus_time})

		# Determine if player controls this character
		# - Protagonist: always player controlled
		# - Party monsters: player controlled UNLESS corruption >= threshold
		var is_player_controlled := character.is_protagonist
		var corruption_auto_attack := false

		if not is_player_controlled and character in player_party:
			# Check if monster has high corruption (auto-attacks on its own)
			if character is Monster:
				var monster: Monster = character as Monster
				if monster.corruption_level >= Constants.MONSTER_AUTO_ATTACK_CORRUPTION_THRESHOLD:
					corruption_auto_attack = true
					EventBus.emit_debug("[CORRUPTION] %s's corruption (%.0f%%) is too high - attacks on its own!" % [character.character_name, monster.corruption_level])
				else:
					# Player controls this party monster
					is_player_controlled = true
			else:
				# Non-monster party member (shouldn't happen but handle gracefully)
				is_player_controlled = true

		print("[BATTLE_MANAGER] _prompt_next_party_member: character=%s, is_protagonist=%s, is_player_controlled=%s" % [character.character_name, character.is_protagonist, is_player_controlled])

		if is_player_controlled:
			# Player selects action (protagonist OR party monster with low corruption)
			battle_state = Enums.BattleState.SELECTING_ACTION
			ui_command.emit("show_action_menu", {"entity": character, "is_monster": character is Monster})
			print("[BATTLE_MANAGER] Emitting waiting_for_player_input for %s" % character.character_name)
			waiting_for_player_input.emit(character)
		else:
			# AI-controlled: high corruption monster attacks on its own
			if corruption_auto_attack:
				ui_command.emit("show_message", {"text": "%s is consumed by corruption!" % character.character_name, "duration": 1.0})
			print("[BATTLE_MANAGER] Character is AI ally (corruption auto-attack) - queueing AI action")
			await get_tree().create_timer(0.3).timeout
			_queue_ally_ai_action(character)
		return

	# All party members have selected - move to execution phase
	_execute_party_actions()

func _queue_ally_ai_action(character: CharacterBase) -> void:
	"""AI ally selects and queues their action"""
	var ai_decision: Dictionary = ai_controller.get_action(character, player_party, enemy_party)

	queued_party_actions[character] = {
		"action": ai_decision.action,
		"target": ai_decision.target,
		"skill": ai_decision.get("skill", "")
	}

	EventBus.emit_debug("%s locked in: %s" % [character.character_name, Enums.BattleAction.keys()[ai_decision.action]])

	party_lock_in_index += 1
	await get_tree().create_timer(0.2).timeout
	_prompt_next_party_member()

func _queue_player_action(action: Enums.BattleAction, target: CharacterBase, skill: String) -> void:
	"""Queue the player's action during lock-in phase"""
	var character := player_party[party_lock_in_index]

	queued_party_actions[character] = {
		"action": action,
		"target": target,
		"skill": skill
	}

	EventBus.emit_debug("%s locked in: %s" % [character.character_name, Enums.BattleAction.keys()[action]])

	party_lock_in_index += 1

	await get_tree().create_timer(0.2).timeout
	_prompt_next_party_member()

func _execute_party_actions() -> void:
	"""Execute all queued party actions in order"""
	battle_state = Enums.BattleState.PARTY_EXECUTING
	party_execution_index = 0

	EventBus.emit_debug("=== PARTY EXECUTION PHASE ===")
	ui_command.emit("show_message", {"text": "Attack!", "duration": 0.8})

	await get_tree().create_timer(0.5).timeout
	_execute_next_party_action()

func _execute_next_party_action() -> void:
	"""Execute the next queued party action"""
	if _check_battle_end():
		return

	# Find next alive party member with a queued action
	var executing_characters: Array = []
	for character in player_party:
		if queued_party_actions.has(character) and character.is_alive():
			executing_characters.append(character)

	if party_execution_index >= executing_characters.size():
		# All party actions executed - move to enemy phase
		_start_enemy_phase()
		return

	var character := executing_characters[party_execution_index] as CharacterBase
	var queued := queued_party_actions[character] as Dictionary

	# Execute the queued action
	is_executing_action = true
	
	# Set current_target meta for animation system to know where to animate toward
	if queued.target:
		character.set_meta("current_target", queued.target)
	
	print("[BattleManager] Emitting action_animation_started for %s, action=%d, target=%s" % [character.character_name, queued.action, queued.target.character_name if queued.target else "none"])
	action_animation_started.emit(character, queued.action)

	var result: Dictionary = {}
	match queued.action:
		Enums.BattleAction.ATTACK:
			result = await _execute_attack(character, queued.target)
		Enums.BattleAction.SKILL:
			result = await _execute_skill(character, queued.target, queued.skill)
		Enums.BattleAction.DEFEND:
			result = _execute_defend(character, queued.target)
		Enums.BattleAction.ITEM:
			result = await _execute_item(character, queued.target, queued.skill)
		Enums.BattleAction.PURIFY:
			result = await _execute_purify(character, queued.target)
		Enums.BattleAction.FLEE:
			result = _execute_flee(character)

	EventBus.action_executed.emit(character, queued.action, result)

	camera_command.emit("return_to_battle", {"duration": camera_return_time})

	await get_tree().create_timer(action_recovery_time).timeout

	action_animation_finished.emit(character)
	is_executing_action = false

	if battle_state == Enums.BattleState.FLED:
		return

	party_execution_index += 1

	# Continue to next action
	await get_tree().create_timer(0.2).timeout
	_execute_next_party_action()

func _start_enemy_phase() -> void:
	"""Begin the enemy attack phase - enemies get attacks = alive party count"""
	if _check_battle_end():
		return

	battle_state = Enums.BattleState.ENEMY_EXECUTING

	# Calculate how many attack phases enemies get
	var alive_party_count := 0
	for p in player_party:
		if p.is_alive():
			alive_party_count += 1

	# Enemies get attack phases equal to alive party members
	enemy_attacks_remaining = alive_party_count
	enemy_attack_index = 0

	EventBus.emit_debug("=== ENEMY PHASE === (%d attacks)" % enemy_attacks_remaining)
	ui_command.emit("show_message", {"text": "Enemy Turn!", "duration": 0.8})

	await get_tree().create_timer(0.5).timeout
	_execute_next_enemy_attack()

func _execute_next_enemy_attack() -> void:
	"""Execute the next enemy attack"""
	if _check_battle_end():
		return

	if enemy_attacks_remaining <= 0:
		# All enemy attacks done - end round
		_end_round()
		return

	# Find alive enemies
	var alive_enemies: Array[CharacterBase] = []
	for e in enemy_party:
		if e.is_alive():
			alive_enemies.append(e)

	if alive_enemies.is_empty():
		_end_round()
		return

	# Select which enemy attacks (cycle through alive enemies)
	var attacker := alive_enemies[enemy_attack_index % alive_enemies.size()]

	# Check if this is a boss with custom attack patterns
	var is_boss := attacker in active_bosses

	# Process status effects for the attacker
	var tick_results := attacker.tick_status_effects()
	attacker.tick_stat_modifiers()

	for result in tick_results:
		if result.has("damage"):
			EventBus.emit_debug("%s took %d damage from %s" % [
				attacker.character_name,
				result.damage,
				Enums.StatusEffect.keys()[result.effect]
			])

	if attacker.is_dead():
		enemy_attacks_remaining -= 1
		enemy_attack_index += 1
		_execute_next_enemy_attack()
		return

	# Check if enemy can act
	if not attacker.can_act():
		EventBus.emit_debug("%s cannot act due to status effect" % attacker.character_name)
		ui_command.emit("show_message", {"text": attacker.character_name + " is stunned!"})
		enemy_attacks_remaining -= 1
		enemy_attack_index += 1
		await get_tree().create_timer(0.5).timeout
		_execute_next_enemy_attack()
		return

	EventBus.turn_started.emit(attacker)
	turn_started_signal.emit(attacker)

	# Camera focus on enemy
	camera_command.emit("focus", {"target": attacker, "duration": camera_focus_time})

	await get_tree().create_timer(0.3).timeout

	# AI decides action
	var ai_decision: Dictionary = ai_controller.get_action(attacker, enemy_party, player_party)

	# Execute enemy action
	is_executing_action = true
	
	# Set current_target meta for animation system
	if ai_decision.target:
		attacker.set_meta("current_target", ai_decision.target)
	
	action_animation_started.emit(attacker, ai_decision.action)

	var result: Dictionary = {}
	match ai_decision.action:
		Enums.BattleAction.ATTACK:
			result = await _execute_attack(attacker, ai_decision.target)
		Enums.BattleAction.SKILL:
			result = await _execute_skill(attacker, ai_decision.target, ai_decision.get("skill", ""))
		Enums.BattleAction.DEFEND:
			result = _execute_defend(attacker, ai_decision.target)
		_:
			result = await _execute_attack(attacker, ai_decision.target)

	EventBus.action_executed.emit(attacker, ai_decision.action, result)

	camera_command.emit("return_to_battle", {"duration": camera_return_time})

	await get_tree().create_timer(action_recovery_time).timeout

	action_animation_finished.emit(attacker)
	is_executing_action = false

	enemy_attacks_remaining -= 1
	enemy_attack_index += 1

	EventBus.turn_ended.emit(attacker)
	turn_ended_signal.emit(attacker)

	# Continue to next enemy attack
	await get_tree().create_timer(turn_end_delay).timeout
	_execute_next_enemy_attack()

# =============================================================================
# ACTION EXECUTION
# =============================================================================

func submit_player_action(action: Enums.BattleAction, target: CharacterBase = null, skill: String = "") -> void:
	if battle_state != Enums.BattleState.SELECTING_ACTION and battle_state != Enums.BattleState.SELECTING_TARGET:
		return

	if is_executing_action:
		return

	ui_command.emit("hide_action_menu", {})

	# Check if we're in lock-in phase
	if battle_state == Enums.BattleState.SELECTING_ACTION or battle_state == Enums.BattleState.PARTY_LOCK_IN:
		# Queue action for lock-in system
		_queue_player_action(action, target, skill)
	else:
		# Fallback to old system (shouldn't happen with new flow)
		var current_character := turn_order[current_turn_index]
		execute_action(current_character, action, target, skill)

func execute_action(character: CharacterBase, action: Enums.BattleAction, target: CharacterBase, skill: String = "") -> void:
	if is_executing_action:
		return

	is_executing_action = true
	battle_state = Enums.BattleState.EXECUTING_ACTION
	
	# Set current_target meta for animation system to know where to animate toward
	if target:
		character.set_meta("current_target", target)
	
	# Set current skill metadata for animation system (if using a skill)
	if action == Enums.BattleAction.SKILL and skill != "":
		var skill_data: SkillData = DataManager.get_skill(skill)
		if skill_data:
			character.set_meta("current_skill", skill_data)
	else:
		# Clear skill metadata for non-skill actions
		if character.has_meta("current_skill"):
			character.remove_meta("current_skill")
	
	action_animation_started.emit(character, action)

	var result: Dictionary = {}

	match action:
		Enums.BattleAction.ATTACK:
			result = await _execute_attack(character, target)
		Enums.BattleAction.SKILL:
			result = await _execute_skill(character, target, skill)
		Enums.BattleAction.DEFEND:
			result = _execute_defend(character, target)
		Enums.BattleAction.ITEM:
			result = await _execute_item(character, target, skill)  # skill = item_id
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
	var result: Dictionary = damage_calculator.calculate_damage(attacker, target, null)

	if result.is_miss:
		ui_command.emit("show_message", {"text": "MISS!", "position": target.global_position})
		EventBus.emit_debug("%s's attack missed %s!" % [attacker.character_name, target.character_name])
		return {"success": true, "is_miss": true, "target_name": target.character_name, "attacker_name": attacker.character_name}

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

	# Check if target is being defended by an ally
	var actual_target: CharacterBase = target
	var damage_to_apply: int = result.damage
	
	if target.has_meta("defended_by"):
		var defender: CharacterBase = target.get_meta("defended_by")
		if is_instance_valid(defender) and defender.is_defending:
			# Redirect damage to defender (50% damage reduction since they're defending)
			actual_target = defender
			damage_to_apply = int(result.damage * 0.5)
			
			# Clear the defend relationship after use
			target.remove_meta("defended_by")
			defender.remove_meta("defending_target")
			defender.set_defending(false)
			
			ui_command.emit("show_status_popup", {
				"target": defender,
				"status": "PROTECTED %s!" % target.character_name.to_upper(),
				"positive": true
			})
			EventBus.emit_debug("%s protected %s, taking %d damage instead!" % [defender.character_name, target.character_name, damage_to_apply])
	
	# Damage number
	vfx_command.emit("spawn_damage_number", {
		"position": actual_target.global_position,
		"amount": damage_to_apply,
		"is_critical": result.is_critical
	})

	# Apply damage to actual target (could be defender)
	actual_target.take_damage(damage_to_apply, attacker, result.is_critical)

	# Track stats
	if attacker in player_party:
		battle_stats.damage_dealt += damage_to_apply
	else:
		battle_stats.damage_received += damage_to_apply

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

	# Add target name to result for combat log
	result["target_name"] = target.character_name
	result["attacker_name"] = attacker.character_name
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
				var dmg_result: Dictionary = damage_calculator.calculate_damage(caster, t, skill_data)
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
				var heal_result: Dictionary = damage_calculator.calculate_healing(caster, t, skill_data)
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

	# Add skill name and attacker info for combat log
	result["skill_name"] = skill_data.display_name
	result["attacker_name"] = caster.character_name
	if targets.size() > 0:
		result["target_name"] = targets[0].character_name
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
		"life_steal", "life_steal_100", "life_steal_50":
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
		"force_target_self":
			# TAUNT - Force all enemies to target the caster for 2 turns
			for t in targets:
				t.set_meta("forced_target", caster)
				t.set_meta("forced_target_turns", 2)
			caster.set_meta("is_taunting", true)
			vfx_command.emit("taunt_effect", {"position": caster.global_position})
			ui_command.emit("show_status_popup", {
				"target": caster,
				"status": "TAUNTING",
				"positive": true
			})
			EventBus.emit_debug("%s is taunting all enemies!" % caster.character_name)
		"heal_ally_from_damage_150", "heal_ally_from_damage":
			# Siphon heal - damage dealt heals an ally (handled after damage in skill execution)
			# This is tracked via meta and processed after damage
			caster.set_meta("siphon_heal_pending", true)
			caster.set_meta("siphon_heal_multiplier", 1.5 if "150" in effect_id else 1.0)
		_:
			EventBus.emit_debug("Unknown special effect: %s" % effect_id)

func _execute_defend(character: CharacterBase, target: CharacterBase = null) -> Dictionary:
	# If no target specified, defend self
	var defend_target: CharacterBase = target if target != null else character
	
	# Check if target is already being defended by someone else
	if defend_target != character and defend_target.has_meta("defended_by"):
		var existing_defender: CharacterBase = defend_target.get_meta("defended_by")
		if is_instance_valid(existing_defender) and existing_defender.is_defending:
			# Target is already defended - defender can't double up
			ui_command.emit("show_message", {"text": "%s is already being defended!" % defend_target.character_name})
			return {"success": false, "reason": "already_defended"}
	
	character.set_defending(true)
	
	# If defending an ally, mark the relationship
	if defend_target != character:
		defend_target.set_meta("defended_by", character)
		character.set_meta("defending_target", defend_target)
		
		vfx_command.emit("defend_effect", {"position": defend_target.global_position})
		audio_command.emit("play_sfx", {"sound": "defend"})
		
		ui_command.emit("show_status_popup", {
			"target": character,
			"status": "DEFENDING %s" % defend_target.character_name.to_upper(),
			"positive": true
		})
		
		EventBus.emit_debug("%s is defending %s" % [character.character_name, defend_target.character_name])
		return {
			"success": true, 
			"defense_boost": character.base_defense * 0.5,
			"defending_ally": true,
			"target_name": defend_target.character_name
		}
	else:
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
	# Check if this is a capture orb item first
	var item_data: ItemData = InventorySystem.get_item_data(item_id)
	if item_data and item_data.is_capture_item():
		# Delegate to capture system
		if not target is Monster:
			ui_command.emit("show_message", {"text": "Can only capture monsters!"})
			return {"success": false, "reason": "Target is not a monster"}

		var capture_tier: int = item_data.get_capture_tier()
		EventBus.emit_debug("%s throws %s at %s!" % [user.character_name, item_data.display_name, target.character_name])

		# Consume the orb before capture attempt
		InventorySystem.remove_item(item_id, 1)

		# Execute the capture
		return await execute_orb_capture(user, target, capture_tier)

	# Use item through inventory system (non-capture items)
	var use_target: CharacterBase = target if target else user
	var result: Dictionary = InventorySystem.use_item(item_id, use_target)

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
	await capture_system.attempt_capture(monster, purifier, Enums.CaptureMethod.PURIFY)

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

	# Use CaptureSystem with SOULBIND method (orb-based capture)
	var tier_enum: Enums.SoulVesselTier = orb_tier as Enums.SoulVesselTier
	await capture_system.attempt_capture(monster, caster, Enums.CaptureMethod.SOULBIND, tier_enum)

	return {"success": true, "delegated": true}

## Execute bargain capture attempt
func execute_bargain_capture(caster: CharacterBase, target: CharacterBase) -> Dictionary:
	if not target is Monster:
		return {"success": false, "reason": "Target is not a monster"}

	var monster: Monster = target as Monster

	battle_state = Enums.BattleState.PURIFICATION
	capture_attempt_started.emit(target)

	await capture_system.attempt_capture(monster, caster, Enums.CaptureMethod.BARGAIN)

	return {"success": true, "delegated": true}

## Execute force capture attempt
func execute_force_capture(caster: CharacterBase, target: CharacterBase) -> Dictionary:
	if not target is Monster:
		return {"success": false, "reason": "Target is not a monster"}

	var monster: Monster = target as Monster

	# Validate dominate conditions (DOMINATE replaces FORCE)
	var check: Dictionary = capture_system.can_use_method(monster, caster, Enums.CaptureMethod.DOMINATE)
	if not check.available:
		ui_command.emit("show_message", {"text": check.reason})
		return {"success": false, "reason": check.reason}

	battle_state = Enums.BattleState.PURIFICATION
	capture_attempt_started.emit(target)

	await capture_system.attempt_capture(monster, caster, Enums.CaptureMethod.DOMINATE)

	return {"success": true, "delegated": true}

## Get capture chance preview for UI
func get_capture_chance_preview(caster: CharacterBase, target: CharacterBase, method: int, orb_tier: int = 0) -> Dictionary:
	if not target is Monster:
		return {"available": false, "chance": 0.0, "reason": "Not a monster"}

	var capture_method: Enums.CaptureMethod = method as Enums.CaptureMethod
	var check: Dictionary = capture_system.can_use_method(target, caster, capture_method)

	if capture_method == Enums.CaptureMethod.SOULBIND:
		var tier: Enums.SoulVesselTier = orb_tier as Enums.SoulVesselTier
		check.capture_chance = capture_system.calculate_soulbind_chance(target, caster, tier)
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
		# Pass "fled" flag so handlers know this isn't a defeat
		EventBus.battle_ended.emit(false, {"fled": true})
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
	
	# Clear all defend relationships at end of round
	_clear_all_defend_relationships()
	
	# Decrement taunt/forced target turns
	_decrement_forced_target_turns()

	if not _check_battle_end():
		_start_round()

func _decrement_forced_target_turns() -> void:
	"""Decrement forced target (taunt) duration at end of round"""
	for character in turn_order:
		if character.has_meta("forced_target_turns"):
			var turns: int = character.get_meta("forced_target_turns") - 1
			if turns <= 0:
				character.remove_meta("forced_target")
				character.remove_meta("forced_target_turns")
				EventBus.emit_debug("%s is no longer taunted" % character.character_name)
			else:
				character.set_meta("forced_target_turns", turns)

func _clear_all_defend_relationships() -> void:
	"""Clear all defend meta data at end of round"""
	for character in turn_order:
		if character.has_meta("defended_by"):
			character.remove_meta("defended_by")
		if character.has_meta("defending_target"):
			character.remove_meta("defending_target")

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

	# Distribute experience to all alive party members (players and allied monsters)
	var alive_members: Array = player_party.filter(func(p): return p.is_alive())
	var exp_per_member: int = int(total_rewards.experience) / maxi(1, alive_members.size())

	for member in alive_members:
		if member is PlayerCharacter:
			member.add_experience(exp_per_member)
		elif member is Monster and not member.is_corrupted:
			# Allied/purified monsters also gain experience
			member.add_experience(exp_per_member)

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
