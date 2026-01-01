class_name StatusEffectManager
extends Node
## StatusEffectManager: Manages status effect data and application.

# =============================================================================
# STATUS EFFECT DATA
# =============================================================================

const EFFECT_DATA := {
	Enums.StatusEffect.POISON: {
		"name": "Poison",
		"description": "Deals 5% max HP damage per turn",
		"icon": "status_poison",
		"color": Color.PURPLE,
		"max_stacks": 3,
		"default_duration": 3,
		"is_debuff": true,
		"can_stack": true
	},
	Enums.StatusEffect.BURN: {
		"name": "Burn",
		"description": "Deals 8% max HP damage per turn",
		"icon": "status_burn",
		"color": Color.ORANGE_RED,
		"max_stacks": 1,
		"default_duration": 2,
		"is_debuff": true,
		"can_stack": false
	},
	Enums.StatusEffect.FREEZE: {
		"name": "Freeze",
		"description": "Cannot act for 1 turn",
		"icon": "status_freeze",
		"color": Color.CYAN,
		"max_stacks": 1,
		"default_duration": 1,
		"is_debuff": true,
		"can_stack": false
	},
	Enums.StatusEffect.PARALYSIS: {
		"name": "Paralysis",
		"description": "50% chance to be unable to act",
		"icon": "status_paralysis",
		"color": Color.YELLOW,
		"max_stacks": 1,
		"default_duration": 2,
		"is_debuff": true,
		"can_stack": false
	},
	Enums.StatusEffect.SLEEP: {
		"name": "Sleep",
		"description": "Cannot act, wakes when damaged",
		"icon": "status_sleep",
		"color": Color.DARK_BLUE,
		"max_stacks": 1,
		"default_duration": 3,
		"is_debuff": true,
		"can_stack": false
	},
	Enums.StatusEffect.CONFUSION: {
		"name": "Confusion",
		"description": "May attack allies",
		"icon": "status_confusion",
		"color": Color.MAGENTA,
		"max_stacks": 1,
		"default_duration": 2,
		"is_debuff": true,
		"can_stack": false
	},
	Enums.StatusEffect.BLIND: {
		"name": "Blind",
		"description": "Greatly reduced accuracy",
		"icon": "status_blind",
		"color": Color.DARK_GRAY,
		"max_stacks": 1,
		"default_duration": 3,
		"is_debuff": true,
		"can_stack": false
	},
	Enums.StatusEffect.SILENCE: {
		"name": "Silence",
		"description": "Cannot use skills",
		"icon": "status_silence",
		"color": Color.SLATE_GRAY,
		"max_stacks": 1,
		"default_duration": 2,
		"is_debuff": true,
		"can_stack": false
	},
	Enums.StatusEffect.BLEED: {
		"name": "Bleed",
		"description": "Deals 3% max HP damage per turn",
		"icon": "status_bleed",
		"color": Color.DARK_RED,
		"max_stacks": 5,
		"default_duration": 4,
		"is_debuff": true,
		"can_stack": true
	},
	Enums.StatusEffect.REGEN: {
		"name": "Regeneration",
		"description": "Heals 5% max HP per turn",
		"icon": "status_regen",
		"color": Color.LIME_GREEN,
		"max_stacks": 3,
		"default_duration": 3,
		"is_debuff": false,
		"can_stack": true
	},
	Enums.StatusEffect.SHIELD: {
		"name": "Shield",
		"description": "Absorbs damage",
		"icon": "status_shield",
		"color": Color.ROYAL_BLUE,
		"max_stacks": 1,
		"default_duration": 3,
		"is_debuff": false,
		"can_stack": false
	},
	Enums.StatusEffect.ATTACK_UP: {
		"name": "Attack Up",
		"description": "Increased attack power by 25%",
		"icon": "status_atk_up",
		"color": Color.RED,
		"max_stacks": 1,
		"default_duration": 3,
		"is_debuff": false,
		"can_stack": false
	},
	Enums.StatusEffect.ATTACK_DOWN: {
		"name": "Attack Down",
		"description": "Decreased attack power by 25%",
		"icon": "status_atk_down",
		"color": Color.DARK_RED,
		"max_stacks": 1,
		"default_duration": 3,
		"is_debuff": true,
		"can_stack": false
	},
	Enums.StatusEffect.DEFENSE_UP: {
		"name": "Defense Up",
		"description": "Increased defense by 25%",
		"icon": "status_def_up",
		"color": Color.DODGER_BLUE,
		"max_stacks": 1,
		"default_duration": 3,
		"is_debuff": false,
		"can_stack": false
	},
	Enums.StatusEffect.DEFENSE_DOWN: {
		"name": "Defense Down",
		"description": "Decreased defense by 25%",
		"icon": "status_def_down",
		"color": Color.DARK_BLUE,
		"max_stacks": 1,
		"default_duration": 3,
		"is_debuff": true,
		"can_stack": false
	},
	Enums.StatusEffect.SPEED_UP: {
		"name": "Speed Up",
		"description": "Increased speed by 25%",
		"icon": "status_spd_up",
		"color": Color.YELLOW_GREEN,
		"max_stacks": 1,
		"default_duration": 3,
		"is_debuff": false,
		"can_stack": false
	},
	Enums.StatusEffect.SPEED_DOWN: {
		"name": "Speed Down",
		"description": "Decreased speed by 25%",
		"icon": "status_spd_down",
		"color": Color.OLIVE,
		"max_stacks": 1,
		"default_duration": 3,
		"is_debuff": true,
		"can_stack": false
	},
	Enums.StatusEffect.CORRUPTED: {
		"name": "Corrupted",
		"description": "Veil corruption is spreading",
		"icon": "status_corrupted",
		"color": Color.DARK_VIOLET,
		"max_stacks": 1,
		"default_duration": 5,
		"is_debuff": true,
		"can_stack": false
	},
	Enums.StatusEffect.PURIFYING: {
		"name": "Purifying",
		"description": "Being cleansed of corruption",
		"icon": "status_purifying",
		"color": Color.GOLD,
		"max_stacks": 1,
		"default_duration": 1,
		"is_debuff": false,
		"can_stack": false
	}
}

# =============================================================================
# APPLICATION
# =============================================================================

func apply_effect(target: CharacterBase, effect: Enums.StatusEffect, duration: int = -1, source: Node = null) -> bool:
	if not EFFECT_DATA.has(effect):
		return false

	var effect_info: Dictionary = EFFECT_DATA[effect]
	var actual_duration: int = duration if duration > 0 else effect_info.default_duration

	# Check for immunity (some effects cancel each other)
	if _check_immunity(target, effect):
		return false

	target.add_status_effect(effect, actual_duration, source)

	# Apply stat modifiers for buff/debuff effects
	_apply_effect_modifiers(target, effect)

	return true

func remove_effect(target: CharacterBase, effect: Enums.StatusEffect) -> void:
	if target.has_status_effect(effect):
		_remove_effect_modifiers(target, effect)
		target.remove_status_effect(effect)

func _check_immunity(target: CharacterBase, effect: Enums.StatusEffect) -> bool:
	# v5.0 Brand-based immunities
	var target_brand: Enums.Brand = target.brand if "brand" in target else Enums.Brand.NONE
	
	# SURGE brand resists electric/burn effects (lightning speed)
	if effect == Enums.StatusEffect.BURN and target_brand == Enums.Brand.SURGE:
		return true
	# IRON brand resists freeze (unyielding defense)
	if effect == Enums.StatusEffect.FREEZE and target_brand == Enums.Brand.IRON:
		return true
	# LEECH brand is immune to corruption (life drain sustains)
	if effect == Enums.StatusEffect.CORRUPTED and target_brand == Enums.Brand.LEECH:
		return true
	# VENOM brand is immune to poison (precision poison masters)
	if effect == Enums.StatusEffect.POISON and target_brand == Enums.Brand.VENOM:
		return true
	
	# Legacy: Element-based immunities (deprecated, kept for backwards compatibility)
	if "elements" in target and target.elements is Array:
		# Fire immunity prevents burn
		if effect == Enums.StatusEffect.BURN and Enums.Element.FIRE in target.elements:
			return true
		# Ice immunity prevents freeze
		if effect == Enums.StatusEffect.FREEZE and Enums.Element.ICE in target.elements:
			return true
		# Light immunity prevents certain debuffs
		if effect == Enums.StatusEffect.CORRUPTED and Enums.Element.HOLY in target.elements:
			return true

	return false

func _apply_effect_modifiers(target: CharacterBase, effect: Enums.StatusEffect) -> void:
	match effect:
		Enums.StatusEffect.ATTACK_UP:
			target.add_stat_modifier(Enums.Stat.ATTACK, target.base_attack * 0.25, 999, "status_atk_up")
		Enums.StatusEffect.ATTACK_DOWN:
			target.add_stat_modifier(Enums.Stat.ATTACK, -target.base_attack * 0.25, 999, "status_atk_down")
		Enums.StatusEffect.DEFENSE_UP:
			target.add_stat_modifier(Enums.Stat.DEFENSE, target.base_defense * 0.25, 999, "status_def_up")
		Enums.StatusEffect.DEFENSE_DOWN:
			target.add_stat_modifier(Enums.Stat.DEFENSE, -target.base_defense * 0.25, 999, "status_def_down")
		Enums.StatusEffect.SPEED_UP:
			target.add_stat_modifier(Enums.Stat.SPEED, target.base_speed * 0.25, 999, "status_spd_up")
		Enums.StatusEffect.SPEED_DOWN:
			target.add_stat_modifier(Enums.Stat.SPEED, -target.base_speed * 0.25, 999, "status_spd_down")

func _remove_effect_modifiers(target: CharacterBase, effect: Enums.StatusEffect) -> void:
	# Clear modifiers with matching source
	var source_name := ""
	match effect:
		Enums.StatusEffect.ATTACK_UP:
			source_name = "status_atk_up"
		Enums.StatusEffect.ATTACK_DOWN:
			source_name = "status_atk_down"
		Enums.StatusEffect.DEFENSE_UP:
			source_name = "status_def_up"
		Enums.StatusEffect.DEFENSE_DOWN:
			source_name = "status_def_down"
		Enums.StatusEffect.SPEED_UP:
			source_name = "status_spd_up"
		Enums.StatusEffect.SPEED_DOWN:
			source_name = "status_spd_down"

	# Remove the stat modifiers added by this effect
	if source_name != "":
		target.remove_stat_modifiers_by_source(source_name)

# =============================================================================
# CLEANSING
# =============================================================================

func cleanse_debuffs(target: CharacterBase, count: int = -1) -> int:
	## Remove debuffs from target. Returns number of debuffs removed.
	var removed := 0
	var to_remove: Array[Enums.StatusEffect] = []

	for effect in target.status_effects.keys():
		if EFFECT_DATA.has(effect) and EFFECT_DATA[effect].is_debuff:
			to_remove.append(effect)
			removed += 1
			if count > 0 and removed >= count:
				break

	for effect in to_remove:
		remove_effect(target, effect)

	return removed

func dispel_buffs(target: CharacterBase, count: int = -1) -> int:
	## Remove buffs from target. Returns number of buffs removed.
	var removed := 0
	var to_remove: Array[Enums.StatusEffect] = []

	for effect in target.status_effects.keys():
		if EFFECT_DATA.has(effect) and not EFFECT_DATA[effect].is_debuff:
			to_remove.append(effect)
			removed += 1
			if count > 0 and removed >= count:
				break

	for effect in to_remove:
		remove_effect(target, effect)

	return removed

# =============================================================================
# QUERIES
# =============================================================================

func get_effect_name(effect: Enums.StatusEffect) -> String:
	if EFFECT_DATA.has(effect):
		return EFFECT_DATA[effect].name
	return "Unknown"

func get_effect_description(effect: Enums.StatusEffect) -> String:
	if EFFECT_DATA.has(effect):
		return EFFECT_DATA[effect].description
	return ""

func get_effect_color(effect: Enums.StatusEffect) -> Color:
	if EFFECT_DATA.has(effect):
		return EFFECT_DATA[effect].color
	return Color.WHITE

func get_effect_icon(effect: Enums.StatusEffect) -> String:
	if EFFECT_DATA.has(effect):
		return EFFECT_DATA[effect].icon
	return ""

func is_debuff(effect: Enums.StatusEffect) -> bool:
	if EFFECT_DATA.has(effect):
		return EFFECT_DATA[effect].is_debuff
	return false

func get_active_debuffs(target: CharacterBase) -> Array[Enums.StatusEffect]:
	var debuffs: Array[Enums.StatusEffect] = []
	for effect in target.status_effects.keys():
		if is_debuff(effect):
			debuffs.append(effect)
	return debuffs

func get_active_buffs(target: CharacterBase) -> Array[Enums.StatusEffect]:
	var buffs: Array[Enums.StatusEffect] = []
	for effect in target.status_effects.keys():
		if not is_debuff(effect):
			buffs.append(effect)
	return buffs
