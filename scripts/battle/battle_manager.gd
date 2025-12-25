class_name BattleManager
extends Node
## BattleManager: Orchestrates the entire battle flow.

# =============================================================================
# SIGNALS
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

# References to subsystems
var turn_manager: TurnManager
var damage_calculator: DamageCalculator
var status_effect_manager: StatusEffectManager
var ai_controller: AIController
var purification_system: PurificationSystem

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

# =============================================================================
# BATTLE FLOW
# =============================================================================

func start_battle(players: Array, enemies: Array) -> void:
	player_party.clear()
	enemy_party.clear()

	# Convert to typed arrays
	for p in players:
		if p is CharacterBase:
			player_party.append(p)

	for e in enemies:
		if e is CharacterBase:
			enemy_party.append(e)

	current_round = 0
	current_turn_index = 0
	total_rewards = {"experience": 0, "currency": 0, "items": []}
	is_executing_action = false

	battle_state = Enums.BattleState.INITIALIZING

	# Connect signals for all participants
	for character in player_party + enemy_party:
		if not character.died.is_connected(_on_character_died):
			character.died.connect(_on_character_died.bind(character))

	EventBus.battle_started.emit(enemies)
	GameManager.change_state(Enums.GameState.BATTLE)
	GameManager.battle_count += 1

	battle_initialized.emit()
	EventBus.emit_debug("Battle started: %d players vs %d enemies" % [player_party.size(), enemy_party.size()])

	await get_tree().create_timer(0.5).timeout

	_start_round()

func _start_round() -> void:
	current_round += 1
	battle_state = Enums.BattleState.TURN_START

	# Calculate turn order based on speed
	turn_order = turn_manager.calculate_turn_order(player_party + enemy_party)
	current_turn_index = 0

	round_started.emit(current_round)
	EventBus.emit_debug("Round %d started" % current_round)

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

	# Check if character can act
	if not current_character.can_act():
		EventBus.emit_debug("%s cannot act due to status effect" % current_character.character_name)
		EventBus.turn_ended.emit(current_character)
		turn_ended_signal.emit(current_character)
		current_turn_index += 1
		await get_tree().create_timer(0.3).timeout
		_start_next_turn()
		return

	EventBus.turn_started.emit(current_character)
	turn_started_signal.emit(current_character)

	# Player or AI?
	if current_character in player_party:
		battle_state = Enums.BattleState.SELECTING_ACTION
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
			result = _execute_attack(character, target)
		Enums.BattleAction.SKILL:
			result = _execute_skill(character, target, skill)
		Enums.BattleAction.DEFEND:
			result = _execute_defend(character)
		Enums.BattleAction.ITEM:
			result = _execute_item(character, target, skill)  # skill = item_id
		Enums.BattleAction.PURIFY:
			result = await _execute_purify(character, target)
		Enums.BattleAction.FLEE:
			result = _execute_flee(character)

	EventBus.action_executed.emit(character, action, result)

	await get_tree().create_timer(Constants.BATTLE_ACTION_DELAY).timeout

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

	var result := damage_calculator.calculate_damage(attacker, target, null)

	if result.is_miss:
		EventBus.emit_debug("%s's attack missed!" % attacker.character_name)
		return {"success": true, "is_miss": true}

	target.take_damage(result.damage, attacker, result.is_critical)

	EventBus.emit_debug("%s dealt %d damage to %s%s" % [
		attacker.character_name,
		result.damage,
		target.character_name,
		" (CRITICAL!)" if result.is_critical else ""
	])

	return result

func _execute_skill(caster: CharacterBase, target: CharacterBase, skill_id: String) -> Dictionary:
	if not caster.can_use_skill(skill_id):
		return {"success": false, "reason": "Cannot use skill"}

	# TODO: Load skill data and execute properly
	# For now, treat as enhanced attack
	var result := damage_calculator.calculate_damage(caster, target, null)
	result.damage = int(result.damage * 1.5)

	if not result.is_miss and target:
		target.take_damage(result.damage, caster, result.is_critical)

	EventBus.emit_debug("%s used %s!" % [caster.character_name, skill_id])

	return result

func _execute_defend(character: CharacterBase) -> Dictionary:
	character.set_defending(true)
	EventBus.emit_debug("%s is defending" % character.character_name)
	return {"success": true, "defense_boost": character.base_defense * 0.5}

func _execute_item(user: CharacterBase, target: CharacterBase, item_id: String) -> Dictionary:
	# TODO: Implement item usage through inventory system
	EventBus.emit_debug("%s used item %s on %s" % [user.character_name, item_id, target.character_name if target else "self"])
	return {"success": false, "reason": "Not implemented"}

func _execute_purify(purifier: CharacterBase, target: CharacterBase) -> Dictionary:
	if not target is Monster:
		return {"success": false, "reason": "Target is not a monster"}

	var monster: Monster = target as Monster

	if not monster.can_be_purified():
		return {"success": false, "reason": "Monster cannot be purified"}

	battle_state = Enums.BattleState.PURIFICATION

	# Attempt purification
	var purifier_power := 1.0 + (purifier.get_stat(Enums.Stat.MAGIC) / 100.0)
	var result := monster.attempt_purification(purifier_power)

	if result.success:
		EventBus.emit_debug("%s was purified!" % monster.character_name)
		_add_monster_to_rewards(monster)
	else:
		EventBus.emit_debug("Failed to purify %s (%.1f%% chance)" % [monster.character_name, result.chance * 100])

	return result

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

	# Check for boss (can't flee from bosses)
	for enemy in enemy_party:
		if enemy is Monster and enemy.is_boss():
			flee_chance = 0.0
			break

	if randf() <= flee_chance:
		battle_state = Enums.BattleState.FLED
		GameManager.flee_count += 1
		EventBus.emit_debug("Successfully fled from battle!")
		battle_fled.emit()
		EventBus.battle_ended.emit(false, {})
		return {"success": true}

	EventBus.emit_debug("Failed to flee! (%.1f%% chance)" % [flee_chance * 100])
	return {"success": false, "chance": flee_chance}

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
		await get_tree().create_timer(0.2).timeout
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
	battle_victory.emit(total_rewards)
	EventBus.battle_ended.emit(true, total_rewards)

func _on_battle_defeat() -> void:
	battle_state = Enums.BattleState.DEFEAT
	GameManager.defeat_count += 1
	EventBus.emit_debug("Battle Defeat!")
	battle_defeat.emit()
	EventBus.battle_ended.emit(false, {})
	GameManager.change_state(Enums.GameState.GAME_OVER)

func _on_character_died(character: CharacterBase) -> void:
	EventBus.emit_debug("%s has been defeated!" % character.character_name)

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

func get_valid_targets(action: Enums.BattleAction, _skill: String = "") -> Array[CharacterBase]:
	var targets: Array[CharacterBase] = []

	match action:
		Enums.BattleAction.ATTACK, Enums.BattleAction.PURIFY:
			for enemy in enemy_party:
				if enemy.is_alive():
					targets.append(enemy)
		Enums.BattleAction.ITEM, Enums.BattleAction.SKILL:
			# TODO: Check skill target type
			for player in player_party:
				if player.is_alive():
					targets.append(player)
			for enemy in enemy_party:
				if enemy.is_alive():
					targets.append(enemy)
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
		"current_character": get_current_character().character_name if get_current_character() else "None"
	}
