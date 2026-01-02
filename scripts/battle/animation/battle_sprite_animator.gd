# =============================================================================
# VEILBREAKERS Battle Sprite Animator
# Adds life to static sprites through procedural "puppet" animation
# Ready to upgrade to real sprite sheets when available
# =============================================================================

class_name BattleSpriteAnimator
extends Node

## Emitted when a key animation moment occurs (for damage timing, VFX, etc.)
signal animation_event(event_name: String, data: Dictionary)
signal animation_finished(anim_name: String)

# =============================================================================
# CONFIGURATION
# =============================================================================

## The sprite node to animate
var sprite: Node2D = null

## Original transform values (for resetting)
var _original_position: Vector2 = Vector2.ZERO
var _original_scale: Vector2 = Vector2.ONE
var _original_rotation: float = 0.0
var _original_modulate: Color = Color.WHITE

## Animation state
var _current_animation: String = ""
var _is_animating: bool = false
var _is_enemy: bool = false

## Idle breathing
var _breathing_enabled: bool = true
var _breathing_time: float = 0.0
var _breathing_speed: float = 2.0
var _breathing_amount: float = 0.015

## Active tweens (for cleanup)
var _active_tweens: Array[Tween] = []

# =============================================================================
# ANIMATION PRESETS - Procedural "puppet" animations for static sprites
# =============================================================================

const ANIM_IDLE := {
	"breathing": true,
	"bob_amount": 3.0,
	"bob_speed": 1.5,
}

const ANIM_ATTACK := {
	"phases": [
		{"name": "anticipate", "duration": 0.2, "offset": Vector2(-15, 5), "scale": Vector2(0.95, 1.05), "rotation": -5.0},
		{"name": "lunge", "duration": 0.1, "offset": Vector2(60, -10), "scale": Vector2(1.1, 0.95), "rotation": 8.0, "event": "hit"},
		{"name": "impact", "duration": 0.05, "flash": Color(1.5, 1.5, 1.5), "shake": 8.0},
		{"name": "recover", "duration": 0.25, "offset": Vector2.ZERO, "scale": Vector2.ONE, "rotation": 0.0},
	]
}

const ANIM_ATTACK_HEAVY := {
	"phases": [
		{"name": "windup", "duration": 0.35, "offset": Vector2(-25, 8), "scale": Vector2(0.9, 1.1), "rotation": -10.0},
		{"name": "charge", "duration": 0.15, "glow": 1.5, "shake": 3.0},
		{"name": "strike", "duration": 0.08, "offset": Vector2(80, -15), "scale": Vector2(1.15, 0.9), "rotation": 15.0, "event": "hit"},
		{"name": "impact", "duration": 0.08, "flash": Color(2.0, 1.8, 1.5), "shake": 15.0, "freeze": 0.05},
		{"name": "recover", "duration": 0.35, "offset": Vector2.ZERO, "scale": Vector2.ONE, "rotation": 0.0},
	]
}

const ANIM_SKILL := {
	"phases": [
		{"name": "cast_start", "duration": 0.2, "offset": Vector2(0, -10), "scale": Vector2(1.0, 1.05), "glow": 0.5},
		{"name": "channel", "duration": 0.3, "scale": Vector2(1.05, 1.05), "glow": 2.0, "shake": 3.0},
		{"name": "release", "duration": 0.15, "offset": Vector2(30, 0), "scale": Vector2(1.1, 0.95), "glow": 3.0, "event": "cast"},
		{"name": "impact", "duration": 0.1, "flash": Color(1.8, 1.8, 2.0), "shake": 10.0, "event": "hit"},
		{"name": "recover", "duration": 0.25, "offset": Vector2.ZERO, "scale": Vector2.ONE, "glow": 0.0},
	]
}

const ANIM_HURT := {
	"phases": [
		{"name": "impact", "duration": 0.05, "flash": Color(1.0, 0.3, 0.3), "shake": 10.0},
		{"name": "recoil", "duration": 0.15, "offset": Vector2(-25, 0), "scale": Vector2(0.95, 1.05), "rotation": -5.0},
		{"name": "recover", "duration": 0.2, "offset": Vector2.ZERO, "scale": Vector2.ONE, "rotation": 0.0},
	]
}

const ANIM_HURT_CRITICAL := {
	"phases": [
		{"name": "impact", "duration": 0.08, "flash": Color(1.0, 0.2, 0.2), "shake": 15.0, "freeze": 0.05},
		{"name": "stagger", "duration": 0.25, "offset": Vector2(-40, 5), "scale": Vector2(0.9, 1.1), "rotation": -10.0},
		{"name": "recover", "duration": 0.3, "offset": Vector2.ZERO, "scale": Vector2.ONE, "rotation": 0.0},
	]
}

const ANIM_DEATH := {
	"phases": [
		{"name": "hit", "duration": 0.1, "flash": Color(1.0, 0.3, 0.3), "shake": 12.0, "event": "death_hit"},
		{"name": "stagger", "duration": 0.3, "offset": Vector2(-30, 0), "scale": Vector2(0.95, 1.05), "rotation": -15.0},
		{"name": "fall", "duration": 0.4, "offset": Vector2(-50, 30), "scale": Vector2(1.0, 0.8), "rotation": -45.0, "alpha": 0.7},
		{"name": "ground", "duration": 0.3, "offset": Vector2(-60, 50), "scale": Vector2(1.1, 0.6), "rotation": -90.0, "alpha": 0.0, "event": "death_complete"},
	]
}

const ANIM_DEFEND := {
	"phases": [
		{"name": "brace", "duration": 0.1, "offset": Vector2(-5, 0), "scale": Vector2(0.95, 1.02)},
		{"name": "shield", "duration": 0.15, "glow": 1.0, "tint": Color(0.7, 0.85, 1.0)},
		{"name": "hold", "duration": 0.0, "glow": 0.5, "tint": Color(0.8, 0.9, 1.0)},  # Stays in this state
	]
}

const ANIM_PURIFY := {
	"phases": [
		{"name": "raise", "duration": 0.2, "offset": Vector2(0, -10), "scale": Vector2(1.0, 1.05), "tint": Color(1.1, 1.1, 0.9)},
		{"name": "channel", "duration": 0.4, "offset": Vector2(0, -20), "scale": Vector2(1.02, 1.08), "glow": 2.0, "event": "purify_start"},
		{"name": "beam", "duration": 0.3, "glow": 3.0, "flash": Color(1.5, 1.5, 1.2), "event": "purify_beam"},
		{"name": "complete", "duration": 0.25, "offset": Vector2.ZERO, "scale": Vector2.ONE, "glow": 0.0},
	]
}

const ANIM_FLEE := {
	"phases": [
		{"name": "startle", "duration": 0.1, "offset": Vector2(10, 0), "scale": Vector2(1.1, 0.95)},
		{"name": "turn", "duration": 0.1, "rotation": -30.0},
		{"name": "run", "duration": 0.3, "offset": Vector2(-200, 0), "scale": Vector2(0.8, 1.0), "alpha": 0.0},
	]
}

const ANIM_SPAWN := {
	"phases": [
		{"name": "appear", "duration": 0.0, "scale": Vector2(0.0, 0.0), "alpha": 0.0},
		{"name": "grow", "duration": 0.4, "scale": Vector2(1.1, 1.1), "alpha": 1.0, "ease": "back_out"},
		{"name": "settle", "duration": 0.15, "scale": Vector2.ONE, "event": "spawn_complete"},
	]
}

const ANIM_VICTORY := {
	"phases": [
		{"name": "jump_up", "duration": 0.2, "offset": Vector2(0, -30), "scale": Vector2(0.95, 1.1)},
		{"name": "land", "duration": 0.15, "offset": Vector2(0, 5), "scale": Vector2(1.1, 0.9)},
		{"name": "pose", "duration": 0.2, "offset": Vector2.ZERO, "scale": Vector2(1.05, 1.05), "glow": 1.0},
		{"name": "settle", "duration": 0.2, "scale": Vector2.ONE, "glow": 0.0},
	]
}

# =============================================================================
# INITIALIZATION
# =============================================================================

func setup(target_sprite: Node2D, is_enemy_sprite: bool = false) -> void:
	"""Initialize the animator with a sprite to control"""
	sprite = target_sprite
	_is_enemy = is_enemy_sprite
	
	if sprite:
		_original_position = sprite.position
		_original_scale = sprite.scale
		_original_rotation = sprite.rotation_degrees
		_original_modulate = sprite.modulate

func _process(delta: float) -> void:
	if not sprite or not _breathing_enabled or _is_animating:
		return
	
	# Idle breathing animation
	_breathing_time += delta * _breathing_speed
	var breath_offset := sin(_breathing_time * TAU) * _breathing_amount
	sprite.scale = _original_scale * Vector2(1.0, 1.0 + breath_offset)
	
	# Subtle bob
	var bob_offset := sin(_breathing_time * TAU * 0.5) * 2.0
	sprite.position.y = _original_position.y + bob_offset

# =============================================================================
# PUBLIC ANIMATION API
# =============================================================================

func play_idle() -> void:
	"""Return to idle state with breathing"""
	_stop_all_tweens()
	_is_animating = false
	_breathing_enabled = true
	_current_animation = "idle"
	_reset_to_original()

func play_attack(is_heavy: bool = false) -> void:
	"""Play attack animation"""
	var config: Dictionary = ANIM_ATTACK_HEAVY if is_heavy else ANIM_ATTACK
	await _play_phased_animation("attack", config)

func play_skill() -> void:
	"""Play skill/magic animation"""
	await _play_phased_animation("skill", ANIM_SKILL)

func play_hurt(is_critical: bool = false) -> void:
	"""Play hurt reaction"""
	var config: Dictionary = ANIM_HURT_CRITICAL if is_critical else ANIM_HURT
	await _play_phased_animation("hurt", config)

func play_death() -> void:
	"""Play death animation - does NOT return to idle"""
	_breathing_enabled = false
	await _play_phased_animation("death", ANIM_DEATH, false)

func play_defend() -> void:
	"""Play defend stance"""
	await _play_phased_animation("defend", ANIM_DEFEND, false)

func play_purify() -> void:
	"""Play purify/capture animation"""
	await _play_phased_animation("purify", ANIM_PURIFY)

func play_flee() -> void:
	"""Play flee animation"""
	await _play_phased_animation("flee", ANIM_FLEE, false)

func play_spawn() -> void:
	"""Play spawn/summon animation"""
	await _play_phased_animation("spawn", ANIM_SPAWN)

func play_victory() -> void:
	"""Play victory celebration"""
	await _play_phased_animation("victory", ANIM_VICTORY)

# =============================================================================
# ANIMATION ENGINE
# =============================================================================

func _play_phased_animation(anim_name: String, config: Dictionary, return_to_idle: bool = true) -> void:
	"""Execute a multi-phase animation sequence"""
	_stop_all_tweens()
	_breathing_enabled = false
	_is_animating = true
	_current_animation = anim_name
	
	var phases: Array = config.get("phases", [])
	var dir := -1.0 if _is_enemy else 1.0  # Flip direction for enemies
	
	for phase in phases:
		var duration: float = phase.get("duration", 0.2)
		if duration <= 0:
			# Instant state change
			_apply_phase_instant(phase, dir)
			continue
		
		# Create tween for this phase
		var tween := create_tween()
		_active_tweens.append(tween)
		tween.set_parallel(true)
		
		# Position offset
		if phase.has("offset"):
			var offset: Vector2 = phase["offset"]
			offset.x *= dir
			tween.tween_property(sprite, "position", _original_position + offset, duration)
		
		# Scale
		if phase.has("scale"):
			var target_scale: Vector2 = phase["scale"]
			tween.tween_property(sprite, "scale", _original_scale * target_scale, duration)
		
		# Rotation
		if phase.has("rotation"):
			var rot: float = phase["rotation"] * dir
			tween.tween_property(sprite, "rotation_degrees", _original_rotation + rot, duration)
		
		# Alpha
		if phase.has("alpha"):
			var target_mod := sprite.modulate
			target_mod.a = phase["alpha"]
			tween.tween_property(sprite, "modulate", target_mod, duration)
		
		# Tint
		if phase.has("tint"):
			tween.tween_property(sprite, "modulate", phase["tint"], duration)
		
		# Flash (instant white flash)
		if phase.has("flash"):
			_apply_flash(phase["flash"], 0.1)
		
		# Glow (modulate brightness)
		if phase.has("glow"):
			var intensity: float = phase["glow"]
			var glow_color := Color(1.0 + intensity * 0.2, 1.0 + intensity * 0.2, 1.0 + intensity * 0.15, 1.0)
			tween.tween_property(sprite, "modulate", glow_color, duration * 0.5)
		
		# Shake
		if phase.has("shake"):
			_apply_shake(phase["shake"], duration)
		
		# Freeze frame (hitstop)
		if phase.has("freeze"):
			await get_tree().create_timer(phase["freeze"]).timeout
		
		# Emit event
		if phase.has("event"):
			animation_event.emit(phase["event"], {"phase": phase.get("name", ""), "animation": anim_name})
		
		# Wait for phase to complete
		await get_tree().create_timer(duration).timeout
	
	_is_animating = false
	animation_finished.emit(anim_name)
	
	if return_to_idle:
		play_idle()

func _apply_phase_instant(phase: Dictionary, dir: float) -> void:
	"""Apply phase properties instantly (for duration=0 phases)"""
	if phase.has("offset"):
		var offset: Vector2 = phase["offset"]
		offset.x *= dir
		sprite.position = _original_position + offset
	if phase.has("scale"):
		sprite.scale = _original_scale * phase["scale"]
	if phase.has("rotation"):
		sprite.rotation_degrees = _original_rotation + phase["rotation"] * dir
	if phase.has("alpha"):
		sprite.modulate.a = phase["alpha"]

func _apply_flash(color: Color, duration: float) -> void:
	"""Quick flash effect"""
	var original := sprite.modulate
	sprite.modulate = color
	
	var tween := create_tween()
	_active_tweens.append(tween)
	tween.tween_property(sprite, "modulate", original, duration)

func _apply_shake(intensity: float, duration: float) -> void:
	"""Shake effect"""
	var original_pos := sprite.position
	var shake_count := int(duration / 0.03)
	
	var tween := create_tween()
	_active_tweens.append(tween)
	
	for i in range(shake_count):
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity * 0.5, intensity * 0.5))
		tween.tween_property(sprite, "position", original_pos + offset, 0.015)
		tween.tween_property(sprite, "position", original_pos, 0.015)

func _reset_to_original() -> void:
	"""Reset sprite to original transform"""
	if not sprite:
		return
	sprite.position = _original_position
	sprite.scale = _original_scale
	sprite.rotation_degrees = _original_rotation
	sprite.modulate = _original_modulate

func _stop_all_tweens() -> void:
	"""Kill all active tweens"""
	for tween in _active_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_active_tweens.clear()

# =============================================================================
# UTILITY
# =============================================================================

func is_animating() -> bool:
	return _is_animating

func get_current_animation() -> String:
	return _current_animation

func set_breathing(enabled: bool) -> void:
	_breathing_enabled = enabled

func set_enemy(is_enemy: bool) -> void:
	_is_enemy = is_enemy
