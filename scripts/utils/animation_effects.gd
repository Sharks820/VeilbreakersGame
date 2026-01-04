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

# =============================================================================
# POPUP ANIMATIONS (v0.98 - Consolidate 17+ duplicate patterns)
# =============================================================================

## Animate popup entrance (fade in + scale pop)
## Standard pattern used across battle_ui_controller, pause_menu, settings_menu, etc.
static func popup_entrance(popup: Control, duration: float = Constants.UI_POPUP_ENTER) -> Tween:
	if not is_instance_valid(popup):
		return null
	popup.visible = true
	popup.modulate.a = 0.0
	popup.scale = Vector2(0.8, 0.8)

	var tween := popup.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "modulate:a", 1.0, duration)
	tween.tween_property(popup, "scale", Vector2.ONE, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	return tween

## Animate popup exit (fade out + scale shrink)
static func popup_exit(popup: Control, duration: float = Constants.UI_POPUP_EXIT, destroy: bool = false) -> Tween:
	if not is_instance_valid(popup):
		return null

	var tween := popup.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "modulate:a", 0.0, duration)
	tween.tween_property(popup, "scale", Vector2(0.9, 0.9), duration)

	if destroy:
		tween.chain().tween_callback(popup.queue_free)
	else:
		tween.chain().tween_callback(func(): popup.visible = false)
	return tween

## Fade out and destroy node (common pattern for damage numbers, status popups)
static func fade_out_destroy(node: CanvasItem, duration: float = 0.2) -> Tween:
	if not is_instance_valid(node):
		return null
	var tween := node.create_tween()
	tween.tween_property(node, "modulate:a", 0.0, duration)
	tween.tween_callback(node.queue_free)
	return tween

## Floating text animation (rise + fade out + destroy)
## Used for damage numbers, status text, etc.
static func floating_text(node: CanvasItem, rise_distance: float = 40.0, duration: float = 1.0) -> Tween:
	if not is_instance_valid(node):
		return null

	var start_pos = node.position if node is Node2D else node.global_position
	var end_pos = start_pos - Vector2(0, rise_distance)

	var tween := node.create_tween()
	tween.set_parallel(true)

	# Rise and fade
	if node is Node2D:
		tween.tween_property(node, "position:y", end_pos.y, duration).set_ease(Tween.EASE_OUT)
	else:
		tween.tween_property(node, "global_position:y", end_pos.y, duration).set_ease(Tween.EASE_OUT)

	# Hold then fade
	tween.chain().tween_interval(duration * 0.6)
	tween.chain().tween_property(node, "modulate:a", 0.0, duration * 0.4)
	tween.chain().tween_callback(node.queue_free)
	return tween

# =============================================================================
# BUTTON CLICK BOUNCE (v0.98 - Consolidate 3+ duplicate patterns)
# =============================================================================

## Full button click animation (press down, bounce up, settle)
static func button_click_bounce(button: Control, duration: float = 0.26) -> Tween:
	if not is_instance_valid(button):
		return null
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2(0.9, 0.9), duration * 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), duration * 0.4).set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "scale", Vector2.ONE, duration * 0.3).set_trans(Tween.TRANS_CUBIC)
	return tween

# =============================================================================
# TURN ORDER ANIMATIONS
# =============================================================================

## Turn icon entrance animation (slide down + fade in)
static func turn_icon_entrance(icon: Control, index: int, slide_time: float = 0.3) -> Tween:
	if not is_instance_valid(icon):
		return null

	icon.modulate.a = 0.0
	icon.position.y -= 50

	var tween := icon.create_tween()
	tween.set_parallel(true)
	tween.tween_property(icon, "modulate:a", 1.0, slide_time).set_delay(index * 0.1)
	tween.tween_property(icon, "position:y", 0, slide_time).set_delay(index * 0.1).set_ease(Tween.EASE_OUT)
	return tween

## Turn icon exit animation (slide up + fade out)
static func turn_icon_exit(icon: Control, duration: float = 0.2) -> Tween:
	if not is_instance_valid(icon):
		return null

	var tween := icon.create_tween()
	tween.set_parallel(true)
	tween.tween_property(icon, "modulate:a", 0.0, duration)
	tween.tween_property(icon, "position:y", icon.position.y - 30, duration)
	tween.chain().tween_callback(icon.queue_free)
	return tween

# =============================================================================
# MENU ANIMATIONS
# =============================================================================

## Standard action menu show animation
static func action_menu_show(menu: Control, duration: float = 0.25) -> Tween:
	if not is_instance_valid(menu):
		return null

	menu.visible = true
	menu.modulate.a = 0.0
	menu.scale = Vector2(0.8, 0.8)

	var tween := menu.create_tween()
	tween.set_parallel(true)
	tween.tween_property(menu, "modulate:a", 1.0, duration)
	tween.tween_property(menu, "scale", Vector2.ONE, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	return tween

## Standard action menu hide animation
static func action_menu_hide(menu: Control, duration: float = 0.15) -> Tween:
	if not is_instance_valid(menu):
		return null

	var tween := menu.create_tween()
	tween.set_parallel(true)
	tween.tween_property(menu, "modulate:a", 0.0, duration)
	tween.tween_property(menu, "scale", Vector2(0.9, 0.9), duration)
	tween.chain().tween_callback(func(): menu.visible = false)
	return tween

# =============================================================================
# SKILL ANNOUNCEMENT
# =============================================================================

## Skill name dramatic entrance (pop in, hold, fade out)
static func skill_announcement(display: Control, hold_time: float = Constants.BATTLE_SKILL_ANNOUNCE) -> Tween:
	if not is_instance_valid(display):
		return null

	display.visible = true
	display.modulate.a = 0.0
	display.scale = Vector2(0.5, 0.5)

	var tween := display.create_tween()

	# Pop in
	tween.tween_property(display, "modulate:a", 1.0, 0.1)
	tween.parallel().tween_property(display, "scale", Vector2(1.2, 1.2), 0.15).set_ease(Tween.EASE_OUT)

	# Settle
	tween.tween_property(display, "scale", Vector2.ONE, 0.1)

	# Hold
	tween.tween_interval(hold_time)

	# Fade out
	tween.tween_property(display, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): display.visible = false)

	return tween

# =============================================================================
# MODULATE PULSE PATTERNS (v1.02 - Consolidate 60+ duplicate patterns)
# =============================================================================

## Quick white flash and back (hit confirmation, button press)
static func flash_white(node: CanvasItem, flash_duration: float = 0.03, return_duration: float = 0.05) -> Tween:
	if not is_instance_valid(node):
		return null
	var tween := node.create_tween()
	tween.tween_property(node, "modulate", Color(1.8, 1.8, 1.8, 1.0), flash_duration)
	tween.tween_property(node, "modulate", Color.WHITE, return_duration)
	return tween

## Flash to color and back (general purpose)
static func flash_color(node: CanvasItem, color: Color, return_duration: float = 0.15) -> Tween:
	if not is_instance_valid(node):
		return null
	var tween := node.create_tween()
	node.modulate = color
	tween.tween_property(node, "modulate", Color.WHITE, return_duration)
	return tween

## Pulse glow (brighten then return) - common for level up, unlock
static func pulse_glow(node: CanvasItem, glow_color: Color, duration: float = 0.4) -> Tween:
	if not is_instance_valid(node):
		return null
	var tween := node.create_tween()
	tween.tween_property(node, "modulate", glow_color, duration * 0.5)
	tween.tween_property(node, "modulate", Color.WHITE, duration * 0.5)
	return tween

## Double pulse (flash, return, flash again) - victory, special events
static func double_pulse(node: CanvasItem, color: Color, duration: float = 0.8) -> Tween:
	if not is_instance_valid(node):
		return null
	var tween := node.create_tween()
	tween.tween_property(node, "modulate", color, duration * 0.2)
	tween.tween_property(node, "modulate", Color.WHITE, duration * 0.3)
	tween.tween_property(node, "modulate", color.lerp(Color.WHITE, 0.5), duration * 0.2)
	tween.tween_property(node, "modulate", Color.WHITE, duration * 0.3)
	return tween

## Looping color pulse (for active turn, selection highlighting)
static func color_pulse_loop(node: CanvasItem, glow_color: Color, base_color: Color = Color.WHITE, cycle_time: float = 1.6) -> Tween:
	if not is_instance_valid(node):
		return null
	var tween := node.create_tween().set_loops()
	tween.tween_property(node, "modulate", glow_color, cycle_time * 0.5).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "modulate", base_color, cycle_time * 0.5).set_ease(Tween.EASE_IN_OUT)
	return tween

## Low HP pulse (red warning)
static func low_hp_pulse_loop(node: CanvasItem, pulse_speed: float = 1.0) -> Tween:
	if not is_instance_valid(node):
		return null
	var tween := node.create_tween().set_loops()
	tween.tween_property(node, "modulate", Color(1.4, 0.8, 0.8, 1.0), 0.5 / pulse_speed)
	tween.tween_property(node, "modulate", Color.WHITE, 0.5 / pulse_speed)
	return tween

## Corruption pulse (purple)
static func corruption_pulse_loop(node: CanvasItem) -> Tween:
	if not is_instance_valid(node):
		return null
	var tween := node.create_tween().set_loops()
	tween.tween_property(node, "modulate", Color(1.4, 1.0, 1.4, 1.0), 0.3)
	tween.tween_property(node, "modulate", Color.WHITE, 0.3)
	return tween

# =============================================================================
# DEATH ANIMATIONS (v1.02 - Consolidate 4+ duplicate patterns)
# =============================================================================

## Standard death animation (flash red, fade gray, fade out)
static func death_animation(sprite: CanvasItem, duration: float = 0.8) -> Tween:
	if not is_instance_valid(sprite):
		return null
	var tween := sprite.create_tween()
	# Initial flash
	tween.tween_property(sprite, "modulate", Color(2.0, 0.4, 0.4, 1.0), duration * 0.1)
	# Hold red
	tween.tween_property(sprite, "modulate", Color(1.5, 0.3, 0.3, 1.0), duration * 0.2)
	# Fade to gray
	tween.tween_property(sprite, "modulate", Color(0.4, 0.4, 0.4, 0.7), duration * 0.3)
	# Fade out
	tween.tween_property(sprite, "modulate", Color(0.2, 0.2, 0.2, 0.0), duration * 0.4)
	return tween

## Critical death animation (more dramatic)
static func critical_death_animation(sprite: CanvasItem, duration: float = 1.0) -> Tween:
	if not is_instance_valid(sprite):
		return null
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "modulate", Color(2.5, 2.2, 2.8, 1.0), duration * 0.05)
	tween.tween_property(sprite, "modulate", Color(1.5, 1.3, 1.8, 1.0), duration * 0.15)
	tween.tween_property(sprite, "modulate", Color(1.2, 1.0, 1.4, 1.0), duration * 0.15)
	tween.tween_property(sprite, "modulate", Color(0.3, 0.3, 0.3, 0.0), duration * 0.65)
	return tween

# =============================================================================
# BUTTON HOVER COLORS (v1.02 - Consolidate 25+ duplicate patterns)
# =============================================================================

## Standard warm hover glow
static func button_warm_hover(button: Control, duration: float = 0.12) -> Tween:
	if not is_instance_valid(button):
		return null
	var tween := button.create_tween()
	tween.tween_property(button, "modulate", Color(1.3, 1.1, 0.9, 1.0), duration)
	return tween

## Standard hover exit
static func button_unhover_modulate(button: Control, duration: float = 0.1) -> Tween:
	if not is_instance_valid(button):
		return null
	var tween := button.create_tween()
	tween.tween_property(button, "modulate", Color.WHITE, duration)
	return tween

## Flash highlight (for selection changes)
static func flash_highlight(node: CanvasItem, color: Color = Color(1.5, 1.5, 1.0, 1.0), duration: float = 0.45) -> Tween:
	if not is_instance_valid(node):
		return null
	var tween := node.create_tween()
	tween.tween_property(node, "modulate", color, duration * 0.33)
	tween.tween_property(node, "modulate", Color.WHITE, duration * 0.67)
	return tween

# =============================================================================
# COMMON COLOR CONSTANTS FOR MODULATE
# =============================================================================

const MOD_WHITE := Color(1.0, 1.0, 1.0, 1.0)
const MOD_BRIGHT := Color(1.8, 1.8, 1.8, 1.0)
const MOD_WARM := Color(1.3, 1.1, 0.9, 1.0)
const MOD_COOL := Color(0.9, 1.0, 1.2, 1.0)
const MOD_HIT_RED := Color(2.0, 0.4, 0.4, 1.0)
const MOD_HEAL_GREEN := Color(0.5, 1.5, 0.5, 1.0)
const MOD_MAGIC_PURPLE := Color(1.5, 1.3, 1.8, 1.0)
const MOD_GOLD := Color(1.5, 1.3, 0.8, 1.0)
const MOD_LOW_HP := Color(1.4, 0.8, 0.8, 1.0)
const MOD_CORRUPTION := Color(1.4, 1.0, 1.4, 1.0)
