class_name Helpers
extends RefCounted
## Helpers: Utility functions used across the game.

# =============================================================================
# MATH HELPERS
# =============================================================================

static func lerp_clamp(from: float, to: float, weight: float) -> float:
	return clampf(lerpf(from, to, weight), min(from, to), max(from, to))

static func inverse_lerp_clamped(from: float, to: float, value: float) -> float:
	return clampf(inverse_lerp(from, to, value), 0.0, 1.0)

static func remap(value: float, from_min: float, from_max: float, to_min: float, to_max: float) -> float:
	var normalized := inverse_lerp(from_min, from_max, value)
	return lerpf(to_min, to_max, normalized)

static func approach(current: float, target: float, delta: float) -> float:
	if current < target:
		return minf(current + delta, target)
	elif current > target:
		return maxf(current - delta, target)
	return target

static func wrap_index(index: int, array_size: int) -> int:
	return posmod(index, array_size)

# =============================================================================
# RANDOM HELPERS
# =============================================================================

static func random_chance(probability: float) -> bool:
	return randf() < probability

static func random_range_int(min_val: int, max_val: int) -> int:
	return randi_range(min_val, max_val)

static func pick_random(array: Array) -> Variant:
	if array.is_empty():
		return null
	return array[randi() % array.size()]

static func pick_weighted(options: Array, weights: Array[float]) -> Variant:
	if options.is_empty() or weights.is_empty():
		return null
	if options.size() != weights.size():
		push_error("Options and weights arrays must be same size")
		return options[0]

	var total_weight := 0.0
	for w in weights:
		total_weight += w

	var roll := randf() * total_weight
	var cumulative := 0.0

	for i in range(options.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return options[i]

	return options[-1]

static func shuffle(array: Array) -> Array:
	var result := array.duplicate()
	result.shuffle()
	return result

# =============================================================================
# STRING HELPERS
# =============================================================================

static func format_number(number: int) -> String:
	var result := ""
	var num_str := str(absi(number))
	var length := num_str.length()

	for i in range(length):
		if i > 0 and (length - i) % 3 == 0:
			result += ","
		result += num_str[i]

	if number < 0:
		result = "-" + result

	return result

static func format_time(seconds: float) -> String:
	var total := int(seconds)
	var hours := total / 3600
	var minutes := (total % 3600) / 60
	var secs := total % 60

	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, secs]
	else:
		return "%d:%02d" % [minutes, secs]

static func format_percentage(value: float, decimals: int = 1) -> String:
	return "%.*f%%" % [decimals, value * 100]

static func truncate(text: String, max_length: int, suffix: String = "...") -> String:
	if text.length() <= max_length:
		return text
	return text.substr(0, max_length - suffix.length()) + suffix

static func capitalize_first(text: String) -> String:
	if text.is_empty():
		return text
	return text[0].to_upper() + text.substr(1)

# =============================================================================
# ARRAY HELPERS
# =============================================================================

static func find_by_property(array: Array, property: String, value: Variant) -> Variant:
	for item in array:
		if item is Object and item.get(property) == value:
			return item
		elif item is Dictionary and item.get(property) == value:
			return item
	return null

static func filter_by_property(array: Array, property: String, value: Variant) -> Array:
	var result := []
	for item in array:
		if item is Object and item.get(property) == value:
			result.append(item)
		elif item is Dictionary and item.get(property) == value:
			result.append(item)
	return result

static func map_property(array: Array, property: String) -> Array:
	var result := []
	for item in array:
		if item is Object:
			result.append(item.get(property))
		elif item is Dictionary:
			result.append(item.get(property))
	return result

static func sum(array: Array) -> float:
	var total := 0.0
	for item in array:
		if item is int or item is float:
			total += item
	return total

static func average(array: Array) -> float:
	if array.is_empty():
		return 0.0
	return sum(array) / array.size()

# =============================================================================
# COLOR HELPERS
# =============================================================================

static func lerp_color(from: Color, to: Color, weight: float) -> Color:
	return from.lerp(to, weight)

static func hex_to_color(hex: String) -> Color:
	return Color.from_string(hex, Color.WHITE)

static func get_rarity_color(rarity: Enums.Rarity) -> Color:
	match rarity:
		Enums.Rarity.COMMON:
			return Color.WHITE
		Enums.Rarity.UNCOMMON:
			return Color.GREEN
		Enums.Rarity.RARE:
			return Color.DODGER_BLUE
		Enums.Rarity.EPIC:
			return Color.DARK_VIOLET
		Enums.Rarity.LEGENDARY:
			return Color.GOLD
	return Color.WHITE

static func get_element_color(element: Enums.Element) -> Color:
	match element:
		Enums.Element.FIRE:
			return Color.ORANGE_RED
		Enums.Element.ICE:
			return Color.DEEP_SKY_BLUE
		Enums.Element.LIGHTNING:
			return Color.YELLOW
		Enums.Element.EARTH:
			return Color.SADDLE_BROWN
		Enums.Element.WIND:
			return Color.PALE_GREEN
		Enums.Element.WATER:
			return Color.ROYAL_BLUE
		Enums.Element.LIGHT:
			return Color.GOLD
		Enums.Element.DARK:
			return Color.DARK_SLATE_GRAY
		Enums.Element.HOLY:
			return Color.WHITE
		Enums.Element.VOID:
			return Color.PURPLE
	return Color.WHITE

# =============================================================================
# VECTOR HELPERS
# =============================================================================

static func direction_to(from: Vector2, to: Vector2) -> Vector2:
	return (to - from).normalized()

static func distance_to(from: Vector2, to: Vector2) -> float:
	return from.distance_to(to)

static func is_within_range(from: Vector2, to: Vector2, range_val: float) -> bool:
	return from.distance_squared_to(to) <= range_val * range_val

static func random_point_in_circle(center: Vector2, radius: float) -> Vector2:
	var angle := randf() * TAU
	var r := sqrt(randf()) * radius
	return center + Vector2(cos(angle), sin(angle)) * r

# =============================================================================
# TWEEN HELPERS
# =============================================================================

static func create_bounce_tween(node: Node, property: String, target: Variant, duration: float = 0.3) -> Tween:
	var tween := node.create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, property, target, duration)
	return tween

static func create_elastic_tween(node: Node, property: String, target: Variant, duration: float = 0.5) -> Tween:
	var tween := node.create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, property, target, duration)
	return tween

# =============================================================================
# VALIDATION HELPERS
# =============================================================================

static func is_valid_node(node: Variant) -> bool:
	return node != null and node is Node and is_instance_valid(node)

static func is_valid_resource(resource: Variant) -> bool:
	return resource != null and resource is Resource
