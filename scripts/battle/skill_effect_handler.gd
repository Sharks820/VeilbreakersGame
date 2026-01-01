class_name SkillEffectHandler
extends Node
## Handles special_effects from skill data during battle execution

# Reference to battle manager for accessing battle state
var battle_manager: BattleManager

# Track one-time effects per battle
var used_once_per_battle: Dictionary = {}

# Track passive effects per character
var passive_effects: Dictionary = {}


func _init(manager: BattleManager = null) -> void:
	battle_manager = manager


func reset_battle() -> void:
	used_once_per_battle.clear()
	passive_effects.clear()


# =============================================================================
# MAIN PROCESSING
# =============================================================================

func process_pre_skill_effects(caster: CharacterBase, target: CharacterBase, skill: SkillData) -> Dictionary:
	"""Process effects that happen BEFORE the skill executes"""
	var result := {"can_execute": true, "modified_power": skill.base_power}

	for effect in skill.special_effects:
		match effect:
			"once_per_battle":
				var key := "%s_%s" % [caster.get_instance_id(), skill.skill_id]
				if used_once_per_battle.has(key):
					result.can_execute = false
					result.reason = "Already used this battle"
					return result
				used_once_per_battle[key] = true

			"requires_corpse":
				if not _has_corpse_available():
					result.can_execute = false
					result.reason = "No corpse available"
					return result

			"trigger_at_10_hp":
				var max_hp := maxf(float(caster.get_stat(Enums.Stat.MAX_HP)), 1.0)
				var hp_percent := caster.current_hp / max_hp
				if hp_percent > 0.1:
					result.can_execute = false
					result.reason = "HP not low enough"
					return result

	return result


func process_damage_modifiers(caster: CharacterBase, target: CharacterBase, skill: SkillData, base_damage: int) -> int:
	"""Modify damage based on special effects"""
	var damage := base_damage

	for effect in skill.special_effects:
		match effect:
			"bonus_damage_vs_bleed_25":
				if target.has_status_effect(Enums.StatusEffect.BLEED):
					damage = int(damage * 1.25)

			"bonus_damage_low_hp_50":
				var hp_percent := target.current_hp / float(target.get_stat(Enums.Stat.MAX_HP))
				if hp_percent < 0.5:
					damage = int(damage * 1.3)

			"bonus_per_same_species":
				if caster is Monster:
					var same_species_count := _count_same_species(caster)
					damage = int(damage * (1.0 + 0.15 * same_species_count))

			"bonus_damage_trainer_hurt":
				if _is_trainer_hurt(caster):
					damage = int(damage * 1.4)

			"bonus_vs_low_hp":
				var hp_percent := target.current_hp / float(target.get_stat(Enums.Stat.MAX_HP))
				if hp_percent < 0.3:
					damage = int(damage * 1.5)

			"bonus_vs_sorrow":
				if target.has_status_effect(Enums.StatusEffect.SORROW):
					damage = int(damage * 1.5)

			"bonus_vs_casting":
				if target.is_casting:
					damage = int(damage * 1.5)

			"ignore_defense":
				# This is handled in damage_calculator, mark for it
				pass

			"double_action_weak":
				damage = int(damage * 0.6)

	return damage


func process_post_damage_effects(caster: CharacterBase, target: CharacterBase, skill: SkillData, damage_dealt: int, target_died: bool) -> Dictionary:
	"""Process effects that happen AFTER damage is dealt"""
	var result := {"extra_actions": [], "healed": 0, "buffs": [], "debuffs": []}

	for effect in skill.special_effects:
		match effect:
			"lifesteal_50":
				var heal_amount := int(damage_dealt * 0.5)
				caster.heal(heal_amount, caster)
				result.healed += heal_amount

			"lifesteal_25":
				var heal_amount := int(damage_dealt * 0.25)
				caster.heal(heal_amount, caster)
				result.healed += heal_amount

			"extra_action_on_kill":
				if target_died:
					result.extra_actions.append({"type": "attack", "source": caster})

			"consume_corpse_heal":
				if _consume_corpse():
					var heal_amount := int(caster.get_stat(Enums.Stat.MAX_HP) * 0.3)
					caster.heal(heal_amount, caster)
					result.healed += heal_amount

			"evasion_boost_self_1_turn":
				caster.add_stat_modifier(Enums.Stat.SPEED, 0.3, 1, "Evasion Boost")
				result.buffs.append("evasion")

			"evasion_boost_self":
				caster.add_stat_modifier(Enums.Stat.SPEED, 0.2, 2, "Evasion Boost")
				result.buffs.append("evasion")

			"swap_to_back_row":
				result.extra_actions.append({"type": "swap_row", "character": caster})

			"drain_mp":
				var mp_drain := mini(10, target.current_mp)
				target.use_mp(mp_drain)
				caster.restore_mp(mp_drain)

			"drain_mp_small":
				var mp_drain := mini(5, target.current_mp)
				target.use_mp(mp_drain)
				caster.restore_mp(mp_drain)

	return result


func process_buff_effects(caster: CharacterBase, target: CharacterBase, skill: SkillData) -> Dictionary:
	"""Process special buff-related effects"""
	var result := {"success": true}

	for effect in skill.special_effects:
		match effect:
			"copy_target_defenses":
				if target:
					var def_val := target.get_stat(Enums.Stat.DEFENSE)
					var res_val := target.get_stat(Enums.Stat.RESISTANCE)
					caster.add_stat_modifier(Enums.Stat.DEFENSE, def_val / 100.0, 3, "Mimic")
					caster.add_stat_modifier(Enums.Stat.RESISTANCE, res_val / 100.0, 3, "Mimic")

			"guard_ally":
				if target:
					_set_guarding(caster, target)

			"taunt_all":
				_apply_taunt(caster)

			"redirect_damage_to_self":
				if target:
					_set_damage_redirect(caster, target)

			"reduce_redirected_25":
				caster.set_meta("reduce_redirected", 0.25)

			"intangible_1_turn":
				caster.add_status_effect(Enums.StatusEffect.UNTARGETABLE, 1, caster)

			"underground":
				caster.add_status_effect(Enums.StatusEffect.UNTARGETABLE, 1, caster)
				caster.set_meta("next_attack_bonus", 1.5)

			"increase_size":
				caster.set_meta("size_increased", true)

			"steal_buff":
				if target:
					var stolen := _steal_random_buff(target, caster)
					result["stolen_buff"] = stolen

			"auto_revive_once":
				caster.set_meta("auto_revive", true)

			"reflect_damage_30":
				caster.set_meta("damage_reflect", 0.3)

			"power_per_dead_ally":
				var dead_allies := _count_dead_allies(caster)
				var bonus := dead_allies * 0.1
				caster.add_stat_modifier(Enums.Stat.ATTACK, bonus, 99, "Endless Grief")
				caster.add_stat_modifier(Enums.Stat.MAGIC, bonus, 99, "Endless Grief")

	return result


func process_heal_effects(caster: CharacterBase, target: CharacterBase, skill: SkillData) -> Dictionary:
	"""Process special heal-related effects"""
	var result := {"success": true, "revived": []}

	for effect in skill.special_effects:
		match effect:
			"revive_ally":
				if target.is_dead():
					target.revive(0.25)
					result.revived.append(target)

			"revive_all_fallen":
				for ally in _get_allies(caster):
					if ally.is_dead():
						ally.revive(0.25)
						result.revived.append(ally)

			"cleanse_one_debuff":
				if target:
					target.remove_random_debuff()

			"cleanse_all_debuffs":
				if target:
					target.remove_all_debuffs()

			"heal_25_percent":
				var heal := int(caster.get_stat(Enums.Stat.MAX_HP) * 0.25)
				caster.heal(heal, caster)

			"heal_on_consume":
				var heal := int(caster.get_stat(Enums.Stat.MAX_HP) * 0.2)
				caster.heal(heal, caster)

	return result


func process_debuff_effects(caster: CharacterBase, target: CharacterBase, skill: SkillData) -> Dictionary:
	"""Process special debuff-related effects"""
	var result := {"success": true}

	for effect in skill.special_effects:
		match effect:
			"cannot_evade":
				target.set_meta("cannot_evade", true)

			"reveal_weaknesses":
				target.set_meta("weaknesses_revealed", true)

	return result


func process_utility_effects(caster: CharacterBase, target: CharacterBase, skill: SkillData) -> Dictionary:
	"""Process utility skill effects"""
	var result := {"success": true}

	for effect in skill.special_effects:
		match effect:
			"reposition_target":
				if target:
					# Mark target for repositioning (handled by battle UI)
					result["reposition"] = target

			"random_stat_change":
				_apply_random_stat_change(caster)

			"capture_corpse_essence":
				if _has_corpse_available():
					caster.set_meta("stored_souls", caster.get_meta("stored_souls", 0) + 1)
					_consume_corpse()

			"bonus_from_stored_souls":
				var souls: int = caster.get_meta("stored_souls", 0)
				result["bonus_multiplier"] = 1.0 + (souls * 0.2)

			"summon_mawling":
				result["summon"] = {"monster_id": "mawling", "level": caster.level}

			"split_damage_party":
				_enable_damage_split(caster)

	return result


func process_accuracy_effects(caster: CharacterBase, target: CharacterBase, skill: SkillData) -> Dictionary:
	"""Process accuracy-related effects"""
	var result := {"accuracy_bonus": 0.0, "guaranteed_hit": false}

	for effect in skill.special_effects:
		match effect:
			"guaranteed_hit":
				result.guaranteed_hit = true

			"guaranteed_hit_low_hp":
				var hp_percent := target.current_hp / float(target.get_stat(Enums.Stat.MAX_HP))
				if hp_percent < 0.3:
					result.guaranteed_hit = true

	return result


func process_target_selection(caster: CharacterBase, skill: SkillData, potential_targets: Array) -> Array:
	"""Modify target selection based on effects"""
	var targets := potential_targets.duplicate()

	for effect in skill.special_effects:
		match effect:
			"target_lowest_hp":
				targets.sort_custom(func(a, b): return a.current_hp < b.current_hp)
				return [targets[0]] if targets.size() > 0 else []

			"random_targets":
				targets.shuffle()

	return targets


func check_interruptable(skill: SkillData) -> bool:
	"""Check if a skill can be interrupted"""
	return "interruptable" in skill.special_effects


func process_interrupt(caster: CharacterBase, target: CharacterBase, skill: SkillData) -> Dictionary:
	"""Process interrupt effects"""
	var result := {"interrupted": false}

	for effect in skill.special_effects:
		match effect:
			"interrupt_casting":
				if target.is_casting:
					target.cancel_cast()
					result.interrupted = true

	return result


# =============================================================================
# PASSIVE EFFECTS (checked each turn)
# =============================================================================

func apply_passive_effects(character: CharacterBase) -> void:
	"""Apply passive skill effects at start of turn"""
	if not character is Monster:
		return

	var monster: Monster = character as Monster

	for skill_id in monster.get_known_skills():
		var skill := DataManager.get_skill(skill_id) if DataManager else null
		if not skill:
			continue

		for effect in skill.special_effects:
			match effect:
				"passive_evasion_30":
					if not character.has_meta("passive_evasion_applied"):
						character.set_meta("passive_evasion", 0.3)
						character.set_meta("passive_evasion_applied", true)

				"attack_per_ally_10":
					var allies := _count_alive_allies(character)
					var bonus := allies * 0.1
					if bonus > 0:
						character.add_stat_modifier(Enums.Stat.ATTACK, bonus, 1, "Pack Tactics")


func on_any_death(dead_character: CharacterBase) -> void:
	"""Called when any character dies - for passive triggers"""
	if not battle_manager:
		return

	var all_characters := battle_manager.player_party + battle_manager.enemy_party

	for character in all_characters:
		if character.is_dead():
			continue

		if not character is Monster:
			continue

		var monster: Monster = character as Monster
		for skill_id in monster.get_known_skills():
			var skill := DataManager.get_skill(skill_id) if DataManager else null
			if not skill:
				continue

			for effect in skill.special_effects:
				if effect == "trigger_on_any_death":
					# Apply harvest-like effect
					character.add_stat_modifier(Enums.Stat.DEFENSE, 0.1, 99, "Harvest")


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

func _has_corpse_available() -> bool:
	if not battle_manager:
		return false

	for enemy in battle_manager.enemy_party:
		if enemy.is_dead() and not enemy.get_meta("corpse_consumed", false):
			return true
	return false


func _consume_corpse() -> bool:
	if not battle_manager:
		return false

	for enemy in battle_manager.enemy_party:
		if enemy.is_dead() and not enemy.get_meta("corpse_consumed", false):
			enemy.set_meta("corpse_consumed", true)
			return true
	return false


func _count_same_species(monster: Monster) -> int:
	if not battle_manager:
		return 0

	var count := 0
	var my_id := monster.monster_id

	for ally in battle_manager.player_party:
		if ally == monster:
			continue
		if ally is Monster and ally.is_alive():
			if ally.monster_id == my_id:
				count += 1

	return count


func _is_trainer_hurt(monster: CharacterBase) -> bool:
	if not battle_manager:
		return false

	for player in battle_manager.player_party:
		if player is PlayerCharacter and player.is_alive():
			var hp_percent := player.current_hp / float(player.get_stat(Enums.Stat.MAX_HP))
			if hp_percent < 0.5:
				return true
	return false


func _count_dead_allies(character: CharacterBase) -> int:
	if not battle_manager:
		return 0

	var party: Array
	if character in battle_manager.player_party:
		party = battle_manager.player_party
	else:
		party = battle_manager.enemy_party

	var count := 0
	for ally in party:
		if ally != character and ally.is_dead():
			count += 1
	return count


func _count_alive_allies(character: CharacterBase) -> int:
	if not battle_manager:
		return 0

	var party: Array
	if character in battle_manager.player_party:
		party = battle_manager.player_party
	else:
		party = battle_manager.enemy_party

	var count := 0
	for ally in party:
		if ally != character and ally.is_alive():
			count += 1
	return count


func _get_allies(character: CharacterBase) -> Array:
	if not battle_manager:
		return []

	if character in battle_manager.player_party:
		return battle_manager.player_party
	return battle_manager.enemy_party


func _set_guarding(guardian: CharacterBase, protected: CharacterBase) -> void:
	protected.set_meta("guardian", guardian)
	guardian.set_meta("protecting", protected)


func _set_damage_redirect(redirector: CharacterBase, protected: CharacterBase) -> void:
	protected.set_meta("damage_redirect", redirector)


func _apply_taunt(taunter: CharacterBase) -> void:
	if not battle_manager:
		return

	var enemies: Array
	if taunter in battle_manager.player_party:
		enemies = battle_manager.enemy_party
	else:
		enemies = battle_manager.player_party

	for enemy in enemies:
		if enemy.is_alive():
			enemy.set_meta("taunted_by", taunter)


func _steal_random_buff(target: CharacterBase, thief: CharacterBase) -> String:
	var buffs := target.get_positive_modifiers()
	if buffs.is_empty():
		return ""

	var stolen: Dictionary = buffs[randi() % buffs.size()]
	target.remove_stat_modifier(stolen.stat, stolen.source)
	thief.add_stat_modifier(stolen.stat, stolen.amount, stolen.duration, "Stolen: " + stolen.source)
	return stolen.source


func _apply_random_stat_change(character: CharacterBase) -> void:
	var stats := [Enums.Stat.ATTACK, Enums.Stat.DEFENSE, Enums.Stat.MAGIC, Enums.Stat.SPEED]
	var stat: Enums.Stat = stats[randi() % stats.size()]
	var amount := randf_range(-0.2, 0.3)
	character.add_stat_modifier(stat, amount, 2, "Unstable Form")


func _enable_damage_split(character: CharacterBase) -> void:
	if not battle_manager:
		return

	var allies := _get_allies(character)
	for ally in allies:
		ally.set_meta("damage_split_group", character.get_instance_id())
