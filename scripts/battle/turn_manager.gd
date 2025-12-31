class_name TurnManager
extends Node
## TurnManager: Calculates and manages turn order in battle.

# =============================================================================
# TURN ORDER CALCULATION
# =============================================================================

func calculate_turn_order(participants: Array) -> Array[CharacterBase]:
	var order: Array[CharacterBase] = []

	# Filter alive participants
	for p in participants:
		if p is CharacterBase and p.is_alive():
			order.append(p)

	# Sort by speed (descending)
	order.sort_custom(_compare_speed)

	return order

func _compare_speed(a: CharacterBase, b: CharacterBase) -> bool:
	var speed_a := a.get_stat(Enums.Stat.SPEED)
	var speed_b := b.get_stat(Enums.Stat.SPEED)

	if speed_a == speed_b:
		# Tie-breaker: luck
		var luck_a := a.get_stat(Enums.Stat.LUCK)
		var luck_b := b.get_stat(Enums.Stat.LUCK)

		if luck_a == luck_b:
			# Final tie-breaker: deterministic by instance ID (stable sort)
			return a.get_instance_id() > b.get_instance_id()

		return luck_a > luck_b

	return speed_a > speed_b

# =============================================================================
# SPEED MANIPULATION
# =============================================================================

func insert_character_next(order: Array[CharacterBase], character: CharacterBase, after_index: int) -> Array[CharacterBase]:
	## Insert a character to act immediately after the specified index
	if character in order:
		order.erase(character)

	var insert_pos := mini(after_index + 1, order.size())
	order.insert(insert_pos, character)

	return order

func delay_character(order: Array[CharacterBase], character: CharacterBase, positions: int) -> Array[CharacterBase]:
	## Delay a character's turn by a number of positions
	if character not in order:
		return order

	var current_index := order.find(character)
	order.erase(character)

	var new_index := mini(current_index + positions, order.size())
	order.insert(new_index, character)

	return order

func advance_character(order: Array[CharacterBase], character: CharacterBase, positions: int) -> Array[CharacterBase]:
	## Advance a character's turn by a number of positions
	if character not in order:
		return order

	var current_index := order.find(character)
	order.erase(character)

	var new_index := maxi(0, current_index - positions)
	order.insert(new_index, character)

	return order

# =============================================================================
# QUERIES
# =============================================================================

func get_next_character(order: Array[CharacterBase], current_index: int) -> CharacterBase:
	var next_index := current_index + 1
	while next_index < order.size():
		if order[next_index].is_alive():
			return order[next_index]
		next_index += 1
	return null

func get_turns_until_character(order: Array[CharacterBase], character: CharacterBase, current_index: int) -> int:
	if character not in order:
		return -1

	var char_index := order.find(character)
	if char_index <= current_index:
		# Character already acted this round, count until next round
		return (order.size() - current_index) + char_index
	else:
		return char_index - current_index

func predict_next_round_order(participants: Array) -> Array[CharacterBase]:
	## Predict the turn order for the next round (accounts for potential speed changes)
	return calculate_turn_order(participants)

# =============================================================================
# ACTION TIMING
# =============================================================================

func calculate_action_speed(character: CharacterBase, action: Enums.BattleAction) -> float:
	## Calculate the speed value for a specific action (for ATB-style systems)
	var base_speed := character.get_stat(Enums.Stat.SPEED)

	# Action speed modifiers
	var action_modifier := 1.0
	match action:
		Enums.BattleAction.ATTACK:
			action_modifier = 1.0
		Enums.BattleAction.SKILL:
			action_modifier = 0.8  # Skills are slightly slower
		Enums.BattleAction.DEFEND:
			action_modifier = 1.5  # Defend is fast
		Enums.BattleAction.ITEM:
			action_modifier = 1.2
		Enums.BattleAction.FLEE:
			action_modifier = 1.3
		Enums.BattleAction.PURIFY:
			action_modifier = 0.5  # Purification is slow

	return base_speed * action_modifier

# =============================================================================
# DEBUG
# =============================================================================

func get_turn_order_debug(order: Array[CharacterBase]) -> String:
	var result := "Turn Order:\n"
	for i in range(order.size()):
		var char := order[i]
		result += "  %d. %s (SPD: %.0f)\n" % [i + 1, char.character_name, char.get_stat(Enums.Stat.SPEED)]
	return result
