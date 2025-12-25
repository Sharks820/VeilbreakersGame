class_name AIController
extends Node
## AIController: Controls enemy AI decision-making in battle.

# =============================================================================
# AI DECISION MAKING
# =============================================================================

func get_action(character: CharacterBase, allies: Array, enemies: Array) -> Dictionary:
	if character is Monster:
		var monster: Monster = character as Monster
		return monster.get_ai_action(allies, enemies)

	# Default AI for non-monster enemies
	return _default_ai(character, allies, enemies)

func _default_ai(character: CharacterBase, allies: Array, enemies: Array) -> Dictionary:
	var valid_targets: Array[CharacterBase] = []
	for enemy in enemies:
		if enemy is CharacterBase and enemy.is_alive():
			valid_targets.append(enemy)

	if valid_targets.is_empty():
		return {"action": Enums.BattleAction.DEFEND, "target": null, "skill": ""}

	# Simple AI: attack weakest target
	var target := _select_target_by_hp(valid_targets, true)

	return {
		"action": Enums.BattleAction.ATTACK,
		"target": target,
		"skill": ""
	}

# =============================================================================
# TARGET SELECTION
# =============================================================================

func _select_target_by_hp(targets: Array[CharacterBase], lowest: bool = true) -> CharacterBase:
	if targets.is_empty():
		return null

	var selected := targets[0]
	for target in targets:
		if lowest:
			if target.current_hp < selected.current_hp:
				selected = target
		else:
			if target.current_hp > selected.current_hp:
				selected = target

	return selected

func _select_target_by_threat(targets: Array[CharacterBase], allies: Array) -> CharacterBase:
	## Select target based on threat level (damage dealers first)
	if targets.is_empty():
		return null

	var highest_threat: CharacterBase = targets[0]
	var highest_threat_value := 0.0

	for target in targets:
		var threat := _calculate_threat(target, allies)
		if threat > highest_threat_value:
			highest_threat_value = threat
			highest_threat = target

	return highest_threat

func _calculate_threat(target: CharacterBase, _allies: Array) -> float:
	## Calculate threat score based on attack power and role
	var threat := 0.0

	# Attack stat contributes to threat
	threat += target.get_stat(Enums.Stat.ATTACK) * 2.0

	# Magic stat for casters
	threat += target.get_stat(Enums.Stat.MAGIC) * 1.5

	# Low HP targets are less threatening
	var hp_percent := target.get_hp_percent()
	threat *= hp_percent

	# Healers are high priority
	# TODO: Check for healer role or healing skills

	return threat

func _select_random_target(targets: Array[CharacterBase]) -> CharacterBase:
	if targets.is_empty():
		return null
	return targets[randi() % targets.size()]

# =============================================================================
# SKILL SELECTION
# =============================================================================

func _select_best_skill(character: CharacterBase, targets: Array[CharacterBase], allies: Array) -> Dictionary:
	## Select the best skill to use based on situation
	if character.known_skills.is_empty():
		return {"skill": "", "target": null}

	var best_skill := ""
	var best_target: CharacterBase = null
	var best_score := 0.0

	for skill_id in character.known_skills:
		if not character.can_use_skill(skill_id):
			continue

		var skill_data := _get_skill_evaluation(skill_id, character, targets, allies)
		if skill_data.score > best_score:
			best_score = skill_data.score
			best_skill = skill_id
			best_target = skill_data.target

	return {"skill": best_skill, "target": best_target}

func _get_skill_evaluation(skill_id: String, _caster: CharacterBase, targets: Array[CharacterBase], allies: Array) -> Dictionary:
	## Evaluate a skill's usefulness in current situation
	var score := 0.0
	var target: CharacterBase = null

	# TODO: Load skill data and evaluate based on type
	# For now, return basic evaluation

	match skill_id:
		"heal":
			# Find ally with lowest HP
			var lowest_ally: CharacterBase = null
			var lowest_percent := 1.0
			for ally in allies:
				if ally is CharacterBase and ally.is_alive():
					var hp_percent := ally.get_hp_percent()
					if hp_percent < lowest_percent:
						lowest_percent = hp_percent
						lowest_ally = ally

			if lowest_ally and lowest_percent < 0.5:
				score = (1.0 - lowest_percent) * 100
				target = lowest_ally
		_:
			# Damage skill - target lowest HP enemy
			if not targets.is_empty():
				target = _select_target_by_hp(targets, true)
				score = 50.0

	return {"score": score, "target": target}

# =============================================================================
# BEHAVIOR PATTERNS
# =============================================================================

func get_behavior_for_hp_phase(character: CharacterBase) -> String:
	## Returns behavior pattern based on HP percentage
	var hp_percent := character.get_hp_percent()

	if hp_percent > 0.75:
		return "normal"
	elif hp_percent > 0.5:
		return "cautious"
	elif hp_percent > 0.25:
		return "desperate"
	else:
		return "enraged"

func should_use_item(character: CharacterBase) -> bool:
	## Determine if AI should use a healing item
	var hp_percent := character.get_hp_percent()
	return hp_percent < 0.3 and randf() > 0.5

func should_defend(character: CharacterBase) -> bool:
	## Determine if AI should defend
	var hp_percent := character.get_hp_percent()
	return hp_percent < 0.2 and randf() > 0.7

func should_flee(character: CharacterBase, enemies: Array) -> bool:
	## Determine if AI should attempt to flee (for non-boss enemies)
	if character is Monster and character.is_boss():
		return false

	var hp_percent := character.get_hp_percent()

	# Count alive allies
	var alive_allies := 0
	# This would need ally reference

	# Flee if very low HP and outnumbered
	if hp_percent < 0.15:
		return randf() > 0.6

	return false
