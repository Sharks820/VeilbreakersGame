# =============================================================================
# VEILBREAKERS Knockback Animator
# Handles knockback effects when characters take damage
# Integrates with battle system for visual combat feedback
# =============================================================================

class_name KnockbackAnimator
extends RefCounted

# -----------------------------------------------------------------------------
# CONSTANTS
# -----------------------------------------------------------------------------
const NORMAL_KNOCKBACK_DISTANCE := 12.0
const CRITICAL_KNOCKBACK_DISTANCE := 24.0
const HEAVY_KNOCKBACK_DISTANCE := 36.0

const KNOCKBACK_DURATION := 0.08
const RETURN_DURATION := 0.15
const RECOIL_OVERSHOOT := 0.3  # How much to overshoot on return (bounce effect)

# -----------------------------------------------------------------------------
# STATIC METHODS - Can be called from anywhere
# -----------------------------------------------------------------------------

static func apply_knockback(target: Node2D, direction: Vector2 = Vector2.LEFT, intensity: float = 1.0, is_critical: bool = false) -> Tween:
	"""Apply knockback to a character sprite with smooth return animation.

	Args:
		target: The Node2D to knockback (usually a sprite)
		direction: Direction of knockback (normalized or will be normalized)
		intensity: Multiplier for knockback distance (1.0 = normal)
		is_critical: If true, uses larger knockback distance

	Returns:
		The Tween controlling the animation (can be awaited)
	"""
	if not is_instance_valid(target):
		return null

	# Calculate knockback distance
	var base_distance := CRITICAL_KNOCKBACK_DISTANCE if is_critical else NORMAL_KNOCKBACK_DISTANCE
	var knockback_distance := base_distance * intensity

	# Normalize direction
	var knockback_dir := direction.normalized() if direction.length() > 0 else Vector2.LEFT

	# Store original position
	var original_pos := target.position
	var knockback_pos := original_pos + (knockback_dir * knockback_distance)

	# Create knockback tween
	var tween := target.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	# Phase 1: Quick knockback
	tween.tween_property(target, "position", knockback_pos, KNOCKBACK_DURATION)

	# Phase 2: Return with slight overshoot (bounce)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(target, "position", original_pos, RETURN_DURATION)

	return tween


static func apply_knockback_from_attacker(target: Node2D, attacker: Node2D, intensity: float = 1.0, is_critical: bool = false) -> Tween:
	"""Apply knockback away from an attacker's position.

	Args:
		target: The Node2D to knockback
		attacker: The attacking Node2D (knockback goes away from this)
		intensity: Multiplier for knockback distance
		is_critical: If true, uses larger knockback distance

	Returns:
		The Tween controlling the animation
	"""
	if not is_instance_valid(target) or not is_instance_valid(attacker):
		return null

	# Calculate direction away from attacker
	var direction := (target.global_position - attacker.global_position).normalized()

	# If positions overlap, default to left
	if direction.length() < 0.1:
		direction = Vector2.LEFT

	return apply_knockback(target, direction, intensity, is_critical)


static func apply_heavy_knockback(target: Node2D, direction: Vector2 = Vector2.LEFT) -> Tween:
	"""Apply heavy knockback (for boss attacks, finishers, etc.)

	Args:
		target: The Node2D to knockback
		direction: Direction of knockback

	Returns:
		The Tween controlling the animation
	"""
	if not is_instance_valid(target):
		return null

	var knockback_dir := direction.normalized() if direction.length() > 0 else Vector2.LEFT
	var original_pos := target.position
	var knockback_pos := original_pos + (knockback_dir * HEAVY_KNOCKBACK_DISTANCE)

	var tween := target.create_tween()

	# Phase 1: Violent knockback
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.tween_property(target, "position", knockback_pos, 0.1)

	# Phase 2: Slow recovery
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "position", original_pos, 0.3)

	return tween


static func apply_flinch(target: Node2D, direction: Vector2 = Vector2.LEFT) -> Tween:
	"""Apply a small flinch/recoil (for blocked attacks, light hits)

	Args:
		target: The Node2D to flinch
		direction: Direction of flinch

	Returns:
		The Tween controlling the animation
	"""
	if not is_instance_valid(target):
		return null

	var flinch_dir := direction.normalized() if direction.length() > 0 else Vector2.LEFT
	var original_pos := target.position
	var flinch_pos := original_pos + (flinch_dir * 4.0)

	var tween := target.create_tween()

	# Quick flinch and return
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(target, "position", flinch_pos, 0.04)
	tween.tween_property(target, "position", original_pos, 0.08)

	return tween


static func apply_shake(target: Node2D, intensity: float = 3.0, duration: float = 0.2) -> Tween:
	"""Apply a shake effect (for status effects, charging, etc.)

	Args:
		target: The Node2D to shake
		intensity: How far the shake moves (pixels)
		duration: How long to shake

	Returns:
		The Tween controlling the animation
	"""
	if not is_instance_valid(target):
		return null

	var original_pos := target.position
	var shake_count := int(duration / 0.03)  # Shake every 30ms

	var tween := target.create_tween()

	for i in range(shake_count):
		var offset := Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(target, "position", original_pos + offset, 0.015)
		tween.tween_property(target, "position", original_pos, 0.015)

	# Ensure return to original
	tween.tween_property(target, "position", original_pos, 0.01)

	return tween


static func apply_death_fall(target: Node2D, direction: Vector2 = Vector2.LEFT) -> Tween:
	"""Apply a dramatic death fall animation.

	Args:
		target: The Node2D to animate
		direction: Direction of fall

	Returns:
		The Tween controlling the animation
	"""
	if not is_instance_valid(target):
		return null

	var fall_dir := direction.normalized() if direction.length() > 0 else Vector2.LEFT
	var original_pos := target.position
	var fall_pos := original_pos + (fall_dir * 20.0) + Vector2(0, 10)  # Slight downward

	var tween := target.create_tween()
	tween.set_parallel(true)

	# Fall with rotation
	tween.tween_property(target, "position", fall_pos, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Rotate as falling
	var fall_rotation := deg_to_rad(45.0) if fall_dir.x < 0 else deg_to_rad(-45.0)
	tween.tween_property(target, "rotation", fall_rotation, 0.5).set_ease(Tween.EASE_IN)

	# Fade out
	tween.tween_property(target, "modulate:a", 0.5, 0.5)

	return tween
