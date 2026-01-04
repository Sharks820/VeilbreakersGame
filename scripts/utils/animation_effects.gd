class_name AnimationEffects
extends RefCounted
## AnimationEffects: Centralized animation utility functions.
## Eliminates duplication of tween/flash/shake effects across UI and battle systems.

# =============================================================================
# STANDARD TIMING CONSTANTS
# =============================================================================

const DURATION_INSTANT := 0.05
const DURATION_FAST := 0.1
const DURATION_NORMAL := 0.2
const DURATION_SLOW := 0.3
const DURATION_SCENE := 0.5

# =============================================================================
# FLASH EFFECTS
# =============================================================================

## Apply a quick flash effect to a sprite/node
## Returns the tween for chaining or awaiting
static func apply_flash(sprite: Node2D, color: Color, duration: float = 0.1) -> Tween:
	if not is_instance_valid(sprite):
		return null
	var original := sprite.modulate
	sprite.modulate = color
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "modulate", original, duration)
	return tween

## Apply a hit flash (red tint)
static func apply_hit_flash(sprite: Node2D, duration: float = 0.1) -> Tween:
	return apply_flash(sprite, Color(1.0, 0.3, 0.3, 1.0), duration)

## Apply a critical hit flash (brighter red)
static func apply_critical_flash(sprite: Node2D, duration: float = 0.15) -> Tween:
	return apply_flash(sprite, Color(1.0, 0.2, 0.2, 1.5), duration)

## Apply a heal flash (green tint)
static func apply_heal_flash(sprite: Node2D, duration: float = 0.15) -> Tween:
	return apply_flash(sprite, Color(0.5, 1.5, 0.5, 1.0), duration)

## Apply a buff flash (gold tint)
static func apply_buff_flash(sprite: Node2D, duration: float = 0.15) -> Tween:
	return apply_flash(sprite, Color(1.5, 1.3, 0.8, 1.0), duration)

## Apply a debuff flash (purple tint)
static func apply_debuff_flash(sprite: Node2D, duration: float = 0.15) -> Tween:
	return apply_flash(sprite, Color(0.8, 0.5, 1.0, 1.0), duration)

# =============================================================================
# GLOW EFFECTS
# =============================================================================

## Apply a glow effect (modulate brightness pulse)
static func apply_glow(sprite: Node2D, color: Color, intensity: float, duration: float) -> Tween:
	if not is_instance_valid(sprite):
		return null
	var glow_color := Color(
		color.r * (1.0 + intensity * 0.3),
		color.g * (1.0 + intensity * 0.3),
		color.b * (1.0 + intensity * 0.3),
		color.a
	)
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "modulate", glow_color, duration * 0.5)
	tween.tween_property(sprite, "modulate", Color.WHITE, duration * 0.5)
	return tween

## Apply a brand-colored glow
static func apply_brand_glow(sprite: Node2D, brand: Enums.Brand, intensity: float = 1.5, duration: float = 0.3) -> Tween:
	var color := Helpers.get_brand_glow_color(brand)
	return apply_glow(sprite, color, intensity, duration)

# =============================================================================
# SHAKE EFFECTS
# =============================================================================

## Apply a shake effect to a node
static func apply_shake(node: Node2D, amount: Vector2, duration: float) -> Tween:
	if not is_instance_valid(node):
		return null
	var original_pos := node.position
	var shake_count := maxi(1, int(duration / 0.03))
	var tween := node.create_tween()

	for i in range(shake_count):
		var offset := Vector2(
			randf_range(-amount.x, amount.x),
			randf_range(-amount.y, amount.y)
		)
		tween.tween_property(node, "position", original_pos + offset, 0.015)
		tween.tween_property(node, "position", original_pos, 0.015)

	# Ensure we end at original position
	tween.tween_property(node, "position", original_pos, 0.01)
	return tween

## Apply a simple shake (equal X and Y intensity)
static func apply_simple_shake(node: Node2D, intensity: float, duration: float) -> Tween:
	return apply_shake(node, Vector2(intensity, intensity * 0.5), duration)

## Apply a hit shake (standard damage reaction)
static func apply_hit_shake(node: Node2D, is_critical: bool = false) -> Tween:
	if is_critical:
		return apply_shake(node, Vector2(15.0, 8.0), 0.25)
	else:
		return apply_shake(node, Vector2(8.0, 4.0), 0.15)

# =============================================================================
# SCALE EFFECTS
# =============================================================================

## Scale pop effect (grow then shrink back)
static func scale_pop(node: Node2D, target_scale: Vector2, duration: float = 0.2) -> Tween:
	if not is_instance_valid(node):
		return null
	var original := node.scale
	var tween := node.create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", target_scale, duration * 0.4)
	tween.tween_property(node, "scale", original, duration * 0.6)
	return tween

## Scale from a starting scale to end scale
static func scale_to(node: Node2D, from_scale: Vector2, to_scale: Vector2, duration: float) -> Tween:
	if not is_instance_valid(node):
		return null
	node.scale = from_scale
	var tween := node.create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", to_scale, duration)
	return tween

## Bounce effect (scale down then up)
static func bounce(node: Node2D, squash_amount: float = 0.1, duration: float = 0.2) -> Tween:
	if not is_instance_valid(node):
		return null
	var original := node.scale
	var squash := Vector2(original.x * (1.0 + squash_amount), original.y * (1.0 - squash_amount))
	var stretch := Vector2(original.x * (1.0 - squash_amount * 0.5), original.y * (1.0 + squash_amount * 0.5))

	var tween := node.create_tween()
	tween.tween_property(node, "scale", squash, duration * 0.3)
	tween.tween_property(node, "scale", stretch, duration * 0.3)
	tween.tween_property(node, "scale", original, duration * 0.4).set_ease(Tween.EASE_OUT)
	return tween

# =============================================================================
# FADE EFFECTS
# =============================================================================

## Fade in a Control or Node2D
static func fade_in(node: CanvasItem, duration: float = 0.25, start_alpha: float = 0.0) -> Tween:
	if not is_instance_valid(node):
		return null
	node.modulate.a = start_alpha
	var tween := node.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "modulate:a", 1.0, duration)
	return tween

## Fade out a Control or Node2D
static func fade_out(node: CanvasItem, duration: float = 0.25) -> Tween:
	if not is_instance_valid(node):
		return null
	var tween := node.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(node, "modulate:a", 0.0, duration)
	return tween

## Crossfade (fade out one, fade in another)
static func crossfade(out_node: CanvasItem, in_node: CanvasItem, duration: float = 0.3) -> Tween:
	if not is_instance_valid(out_node) or not is_instance_valid(in_node):
		return null
	in_node.modulate.a = 0.0
	var tween := out_node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(out_node, "modulate:a", 0.0, duration)
	tween.tween_property(in_node, "modulate:a", 1.0, duration)
	return tween

# =============================================================================
# SLIDE EFFECTS
# =============================================================================

## Slide in from a direction
static func slide_in(node: Control, direction: Vector2, distance: float, duration: float = 0.3) -> Tween:
	if not is_instance_valid(node):
		return null
	var target_pos := node.position
	node.position = target_pos + direction * distance
	var tween := node.create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position", target_pos, duration)
	return tween

## Slide out in a direction
static func slide_out(node: Control, direction: Vector2, distance: float, duration: float = 0.25) -> Tween:
	if not is_instance_valid(node):
		return null
	var target_pos := node.position + direction * distance
	var tween := node.create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(node, "position", target_pos, duration)
	return tween

# =============================================================================
# BUTTON HOVER EFFECTS
# =============================================================================

## Standard button hover animation
static func button_hover(button: Control, scale_target: float = 1.05, duration: float = 0.15) -> Tween:
	if not is_instance_valid(button):
		return null
	var tween := button.create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(scale_target, scale_target), duration)
	tween.tween_property(button, "modulate", Color(1.2, 1.1, 1.1, 1.0), duration)
	return tween

## Standard button unhover animation
static func button_unhover(button: Control, duration: float = 0.15) -> Tween:
	if not is_instance_valid(button):
		return null
	var tween := button.create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2.ONE, duration)
	tween.tween_property(button, "modulate", Color.WHITE, duration)
	return tween

## Button press animation (quick scale down)
static func button_press(button: Control, duration: float = 0.08) -> Tween:
	if not is_instance_valid(button):
		return null
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), duration)
	tween.tween_property(button, "scale", Vector2.ONE, duration)
	return tween

# =============================================================================
# BREATHING / IDLE ANIMATIONS
# =============================================================================

## Create a breathing loop (for idle animations)
## Returns a looping tween that must be stored and killed manually
static func breathing_loop(node: Node2D, min_scale: float = 1.0, max_scale: float = 1.02, cycle_time: float = 2.0) -> Tween:
	if not is_instance_valid(node):
		return null
	var tween := node.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "scale", Vector2(max_scale, max_scale), cycle_time * 0.5)
	tween.tween_property(node, "scale", Vector2(min_scale, min_scale), cycle_time * 0.5)
	return tween

## Create a pulse loop (modulate brightness)
static func pulse_loop(node: CanvasItem, min_alpha: float = 0.8, max_alpha: float = 1.0, cycle_time: float = 1.5) -> Tween:
	if not is_instance_valid(node):
		return null
	var tween := node.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "modulate:a", max_alpha, cycle_time * 0.5)
	tween.tween_property(node, "modulate:a", min_alpha, cycle_time * 0.5)
	return tween

# =============================================================================
# UTILITY
# =============================================================================

## Kill a tween safely
static func kill_tween(tween: Tween) -> void:
	if tween and tween.is_valid():
		tween.kill()

## Kill multiple tweens safely
static func kill_tweens(tweens: Array) -> void:
	for tween in tweens:
		kill_tween(tween)
	tweens.clear()
