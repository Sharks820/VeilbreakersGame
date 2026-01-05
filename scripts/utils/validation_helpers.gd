class_name ValidationHelpers
extends RefCounted
## ValidationHelpers: Centralized validation and type-checking functions.
## Eliminates 300+ duplicate null checks, type checks, and validation patterns.

# =============================================================================
# NODE VALIDATION
# =============================================================================


## Check if a node reference is valid (not null and exists in tree)
static func is_valid_node(node: Variant) -> bool:
	return node != null and node is Node and is_instance_valid(node)


## Check if any node in array is valid
static func has_valid_node(nodes: Array) -> bool:
	for node in nodes:
		if is_valid_node(node):
			return true
	return false


## Filter array to only valid nodes
static func filter_valid_nodes(nodes: Array) -> Array:
	return nodes.filter(func(n): return is_valid_node(n))


# =============================================================================
# SKILL VALIDATION
# =============================================================================


## Check if skill reference is valid SkillData
static func is_valid_skill(skill: Variant) -> bool:
	return skill != null and skill is SkillData


## Get skill brand type safely (returns NONE if invalid)
static func get_skill_brand_safe(skill: Variant) -> Enums.Brand:
	if not is_valid_skill(skill):
		return Enums.Brand.NONE
	if not "brand_type" in skill:
		return Enums.Brand.NONE
	if skill.brand_type == Enums.Brand.NONE:
		return Enums.Brand.NONE
	return skill.brand_type


## Check if skill has valid brand type
static func skill_has_brand(skill: Variant) -> bool:
	return get_skill_brand_safe(skill) != Enums.Brand.NONE


# =============================================================================
# CHARACTER TYPE CHECKS
# =============================================================================


## Check if character is a Monster
static func is_monster(character: Variant) -> bool:
	return character is Monster


## Check if character is a PlayerCharacter (hero)
static func is_player(character: Variant) -> bool:
	return character is PlayerCharacter


## Check if character is a boss monster
static func is_boss(character: Variant) -> bool:
	return character is Monster and character.is_boss()


## Check if character can be purified
static func can_purify(character: Variant) -> bool:
	return character is Monster and character.can_be_purified()


## Check if character is alive
static func is_alive(character: Variant) -> bool:
	if not is_valid_node(character):
		return false
	if character.has_method("is_alive"):
		return character.is_alive()
	return false


## Filter array to only alive characters
static func filter_alive(characters: Array) -> Array:
	return characters.filter(func(c): return is_alive(c))


## Filter array to only monsters
static func filter_monsters(characters: Array) -> Array:
	return characters.filter(func(c): return is_monster(c))


## Filter array to only players
static func filter_players(characters: Array) -> Array:
	return characters.filter(func(c): return is_player(c))


# =============================================================================
# PROPERTY ACCESS
# =============================================================================


## Safely get brand from character (returns NONE if no brand property)
static func get_brand_safe(
	character: Variant, default: Enums.Brand = Enums.Brand.NONE
) -> Enums.Brand:
	if character == null:
		return default
	if "brand" in character:
		return character.brand
	return default


## Safely get path from character (returns NONE if no path property)
static func get_path_safe(character: Variant, default: Enums.Path = Enums.Path.NONE) -> Enums.Path:
	if character == null:
		return default
	if "path" in character:
		return character.path
	return default


## Safely get character name
static func get_name_safe(character: Variant, default: String = "Unknown") -> String:
	if character == null:
		return default
	if "character_name" in character:
		return character.character_name
	if "display_name" in character:
		return character.display_name
	return default


# =============================================================================
# ARRAY SAFETY
# =============================================================================


## Safely access array element (returns default if out of bounds)
static func safe_array_get(array: Array, index: int, default: Variant = null) -> Variant:
	if index < 0 or index >= array.size():
		return default
	return array[index]


## Check if array has valid first element
static func has_first(array: Array) -> bool:
	return array.size() > 0


## Get first element or default
static func first_or_default(array: Array, default: Variant = null) -> Variant:
	return array[0] if array.size() > 0 else default


## Check if first arg is valid int (common debug pattern)
static func is_first_arg_int(args: Array) -> bool:
	return args.size() > 0 and args[0] is String and args[0].is_valid_int()


# =============================================================================
# DICTIONARY SAFETY
# =============================================================================


## Safely get dictionary value with type check
static func safe_dict_get(dict: Variant, key: String, default: Variant = null) -> Variant:
	if not dict is Dictionary:
		return default
	return dict.get(key, default)


## Check if item (Object or Dictionary) has property with value
static func has_property_value(item: Variant, property: String, value: Variant) -> bool:
	if item is Object:
		return property in item and item.get(property) == value
	elif item is Dictionary:
		return item.get(property) == value
	return false


# =============================================================================
# HP THRESHOLD CHECKS
# =============================================================================


## Check if character HP is below threshold (0.0 to 1.0)
static func hp_below_threshold(character: Variant, threshold: float) -> bool:
	if not is_valid_node(character):
		return false
	if not character.has_method("get_hp_percent"):
		if "current_hp" in character and "max_hp" in character and character.max_hp > 0:
			return float(character.current_hp) / float(character.max_hp) < threshold
		return false
	return character.get_hp_percent() < threshold


## Check if character is at very low HP (<30%)
static func is_very_low_hp(character: Variant) -> bool:
	return hp_below_threshold(character, Constants.HP_THRESHOLD_30)


## Check if character is at low HP (<50%)
static func is_low_hp(character: Variant) -> bool:
	return hp_below_threshold(character, Constants.HP_THRESHOLD_50)


## Check if character is at critical HP (<10%)
static func is_critical_hp(character: Variant) -> bool:
	return hp_below_threshold(character, Constants.HP_THRESHOLD_10)


# =============================================================================
# STATUS EFFECT CHECKS
# =============================================================================


## Check if character has specific status effect
static func has_status(character: Variant, effect: Enums.StatusEffect) -> bool:
	if not is_valid_node(character):
		return false
	if character.has_method("has_status_effect"):
		return character.has_status_effect(effect)
	return false


## Check if character can act (not stunned, frozen, etc.)
static func can_act(character: Variant) -> bool:
	if not is_valid_node(character):
		return false
	if character.has_method("can_act"):
		return character.can_act()
	return true


# =============================================================================
# BATTLE VALIDATION
# =============================================================================


## Validate target for attack (valid, alive, in battle)
static func is_valid_target(target: Variant) -> bool:
	return is_valid_node(target) and is_alive(target)


## Validate array of targets
static func get_valid_targets(targets: Array) -> Array:
	return targets.filter(func(t): return is_valid_target(t))


## Check if battle is still ongoing (both sides have living members)
static func is_battle_active(players: Array, enemies: Array) -> bool:
	return filter_alive(players).size() > 0 and filter_alive(enemies).size() > 0


# =============================================================================
# TWEEN VALIDATION
# =============================================================================


## Check if tween is valid and running
static func is_tween_active(tween: Variant) -> bool:
	return tween != null and tween is Tween and tween.is_valid() and tween.is_running()


## Kill tween safely if it exists
static func kill_tween_safe(tween: Variant) -> void:
	if tween != null and tween is Tween and tween.is_valid():
		tween.kill()


# =============================================================================
# INPUT VALIDATION
# =============================================================================


## Check if event is cancel input (Escape or Right-click)
static func is_cancel_input(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_cancel"):
		return true
	if (
		event is InputEventMouseButton
		and event.pressed
		and event.button_index == MOUSE_BUTTON_RIGHT
	):
		return true
	return false


## Check if event is accept input (Enter/Space or Left-click)
static func is_accept_input(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_accept"):
		return true
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		return true
	return false


## Check if mouse button pressed
static func is_mouse_pressed(event: InputEvent, button: MouseButton) -> bool:
	return event is InputEventMouseButton and event.pressed and event.button_index == button


## Check if mouse button released
static func is_mouse_released(event: InputEvent, button: MouseButton) -> bool:
	return event is InputEventMouseButton and not event.pressed and event.button_index == button
