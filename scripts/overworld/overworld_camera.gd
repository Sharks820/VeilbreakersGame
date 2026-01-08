extends Camera2D
class_name OverworldCamera
## OverworldCamera: Smooth follow camera for overworld exploration.
## Features smooth follow, bounds limiting, and zoom controls.

# =============================================================================
# EXPORTS
# =============================================================================

@export_group("Follow Settings")
@export var follow_target: Node2D = null
@export var follow_smoothing: float = 5.0
@export var look_ahead_amount: float = 50.0
@export var look_ahead_smoothing: float = 3.0

@export_group("Zoom Settings")
@export var default_zoom: float = 1.0
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var zoom_speed: float = 0.1
@export var zoom_smoothing: float = 5.0

@export_group("Bounds")
@export var use_bounds: bool = false
@export var bounds_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(10000, 10000))

@export_group("Shake")
@export var max_shake_offset: float = 16.0
@export var shake_decay: float = 5.0

# =============================================================================
# STATE
# =============================================================================

var target_position: Vector2 = Vector2.ZERO
var target_zoom: float = 1.0
var current_look_ahead: Vector2 = Vector2.ZERO
var shake_intensity: float = 0.0
var shake_offset: Vector2 = Vector2.ZERO

# Last movement direction for look-ahead
var last_movement: Vector2 = Vector2.ZERO

# =============================================================================
# LIFECYCLE
# =============================================================================


func _ready() -> void:
	target_zoom = default_zoom
	zoom = Vector2(default_zoom, default_zoom)

	if follow_target:
		global_position = follow_target.global_position
		target_position = global_position


func _process(delta: float) -> void:
	if not follow_target:
		return

	_update_follow(delta)
	_update_look_ahead(delta)
	_update_zoom(delta)
	_update_shake(delta)
	_apply_bounds()


# =============================================================================
# FOLLOW SYSTEM
# =============================================================================


func _update_follow(delta: float) -> void:
	target_position = follow_target.global_position + current_look_ahead
	global_position = global_position.lerp(target_position, follow_smoothing * delta)


func _update_look_ahead(delta: float) -> void:
	# Get movement from CharacterBody2D velocity if available
	if follow_target is CharacterBody2D:
		var velocity: Vector2 = follow_target.velocity
		if velocity.length() > 10.0:
			last_movement = velocity.normalized()

	var target_look_ahead := last_movement * look_ahead_amount
	current_look_ahead = current_look_ahead.lerp(target_look_ahead, look_ahead_smoothing * delta)


func set_follow_target(target: Node2D) -> void:
	follow_target = target
	if target:
		global_position = target.global_position
		target_position = global_position


# =============================================================================
# ZOOM SYSTEM
# =============================================================================


func _update_zoom(delta: float) -> void:
	var current_zoom := zoom.x
	var smoothed_zoom := lerpf(current_zoom, target_zoom, zoom_smoothing * delta)
	zoom = Vector2(smoothed_zoom, smoothed_zoom)


func zoom_in() -> void:
	target_zoom = minf(target_zoom + zoom_speed, max_zoom)


func zoom_out() -> void:
	target_zoom = maxf(target_zoom - zoom_speed, min_zoom)


func set_zoom_level(level: float) -> void:
	target_zoom = clampf(level, min_zoom, max_zoom)


func reset_zoom() -> void:
	target_zoom = default_zoom


# =============================================================================
# BOUNDS
# =============================================================================


func _apply_bounds() -> void:
	if not use_bounds:
		return

	var viewport_size := get_viewport_rect().size / zoom.x
	var half_size := viewport_size / 2.0

	global_position.x = clampf(
		global_position.x,
		bounds_rect.position.x + half_size.x,
		bounds_rect.end.x - half_size.x
	)
	global_position.y = clampf(
		global_position.y,
		bounds_rect.position.y + half_size.y,
		bounds_rect.end.y - half_size.y
	)


func set_bounds(rect: Rect2) -> void:
	bounds_rect = rect
	use_bounds = true


func clear_bounds() -> void:
	use_bounds = false


# =============================================================================
# CAMERA SHAKE
# =============================================================================


func _update_shake(delta: float) -> void:
	if shake_intensity <= 0:
		shake_offset = Vector2.ZERO
		return

	# Random shake offset
	shake_offset = Vector2(
		randf_range(-1.0, 1.0) * shake_intensity * max_shake_offset,
		randf_range(-1.0, 1.0) * shake_intensity * max_shake_offset
	)

	offset = shake_offset
	shake_intensity = maxf(0.0, shake_intensity - shake_decay * delta)


func shake(intensity: float = 1.0) -> void:
	shake_intensity = clampf(intensity, 0.0, 1.0)


func stop_shake() -> void:
	shake_intensity = 0.0
	shake_offset = Vector2.ZERO
	offset = Vector2.ZERO


# =============================================================================
# TRANSITIONS
# =============================================================================


func focus_on_position(pos: Vector2, duration: float = 0.5) -> void:
	## Temporarily focus camera on a position
	var tween := create_tween()
	tween.tween_property(self, "global_position", pos, duration).set_ease(Tween.EASE_OUT)


func transition_to_target(new_target: Node2D, duration: float = 1.0) -> void:
	## Smoothly transition to a new follow target
	var tween := create_tween()
	tween.tween_property(self, "global_position", new_target.global_position, duration).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func(): follow_target = new_target)


# =============================================================================
# INPUT
# =============================================================================


func _input(event: InputEvent) -> void:
	# Optional zoom controls with mouse wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()
