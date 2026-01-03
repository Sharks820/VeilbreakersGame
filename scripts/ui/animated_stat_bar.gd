# =============================================================================
# AnimatedStatBar - AAA-quality HP/MP bar with animations and effects
# Features: Animated fill, damage preview, gradient colors, glow effects
# =============================================================================

class_name AnimatedStatBar
extends Control

# =============================================================================
# SIGNALS
# =============================================================================

signal value_changed(old_value: float, new_value: float)
signal depleted()
signal filled()

# =============================================================================
# EXPORTS
# =============================================================================

@export_group("Values")
@export var max_value: float = 100.0:
	set(v):
		max_value = maxf(1.0, v)
		_update_display()
@export var current_value: float = 100.0:
	set(v):
		var old := current_value
		current_value = clampf(v, 0.0, max_value)
		if old != current_value:
			_on_value_changed(old, current_value)

@export_group("Bar Type")
@export_enum("HP", "MP", "Corruption", "XP", "Custom") var bar_type: int = 0

@export_group("Appearance")
@export var bar_size: Vector2 = Vector2(120, 14)
@export var corner_radius: int = 3
@export var border_width: int = 1
@export var show_text: bool = true
@export var text_format: String = "{current}/{max}"

@export_group("Colors - HP")
@export var hp_full_color: Color = Color(0.2, 0.85, 0.35, 1.0)
@export var hp_mid_color: Color = Color(0.9, 0.75, 0.2, 1.0)
@export var hp_low_color: Color = Color(0.9, 0.25, 0.2, 1.0)
@export var hp_critical_threshold: float = 0.25

@export_group("Colors - MP")
@export var mp_color: Color = Color(0.3, 0.5, 0.95, 1.0)
@export var mp_empty_color: Color = Color(0.15, 0.2, 0.4, 1.0)

@export_group("Colors - Corruption")
@export var corruption_color: Color = Color(0.6, 0.15, 0.7, 1.0)
@export var corruption_glow_color: Color = Color(0.8, 0.3, 0.9, 0.6)

@export_group("Colors - Background")
@export var background_color: Color = Color(0.08, 0.06, 0.06, 0.95)
@export var border_color: Color = Color(0.25, 0.2, 0.18, 1.0)

@export_group("Animation")
@export var fill_animation_duration: float = 0.35
@export var damage_preview_duration: float = 0.6
@export var damage_preview_color: Color = Color(1.0, 0.3, 0.2, 0.7)
@export var heal_preview_color: Color = Color(0.3, 1.0, 0.4, 0.7)
@export var pulse_on_low_hp: bool = true
@export var pulse_speed: float = 2.5

@export_group("Effects")
@export var show_damage_flash: bool = true
@export var show_glow_on_change: bool = true
@export var glow_intensity: float = 0.4

# =============================================================================
# NODE REFERENCES
# =============================================================================

var _background: ColorRect
var _damage_preview: ColorRect
var _fill: ColorRect
var _glow: ColorRect
var _border: ReferenceRect
var _text_label: Label

# =============================================================================
# STATE
# =============================================================================

var _displayed_value: float = 100.0
var _preview_value: float = 100.0
var _fill_tween: Tween
var _preview_tween: Tween
var _glow_tween: Tween
var _pulse_tween: Tween
var _is_pulsing: bool = false

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_create_bar_structure()
	_update_display()

func _create_bar_structure() -> void:
	# Set control size
	custom_minimum_size = bar_size
	size = bar_size
	
	# Background
	_background = ColorRect.new()
	_background.name = "Background"
	_background.size = bar_size
	_background.color = background_color
	add_child(_background)
	
	# Damage/heal preview layer (shows where HP will go)
	_damage_preview = ColorRect.new()
	_damage_preview.name = "DamagePreview"
	_damage_preview.size = bar_size
	_damage_preview.color = damage_preview_color
	add_child(_damage_preview)
	
	# Main fill
	_fill = ColorRect.new()
	_fill.name = "Fill"
	_fill.size = bar_size
	add_child(_fill)
	
	# Glow overlay (for effects)
	_glow = ColorRect.new()
	_glow.name = "Glow"
	_glow.size = bar_size
	_glow.color = Color(1.0, 1.0, 1.0, 0.0)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_glow)
	
	# Text label
	if show_text:
		_text_label = Label.new()
		_text_label.name = "ValueLabel"
		_text_label.size = bar_size
		_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_text_label.add_theme_font_size_override("font_size", int(bar_size.y * 0.65))
		_text_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
		_text_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
		_text_label.add_theme_constant_override("outline_size", 1)
		add_child(_text_label)
	
	# Apply initial styling
	_apply_styling()

func _apply_styling() -> void:
	# Apply corner radius via clip (Godot 4.x approach)
	# For now, we use simple rectangles - can enhance with shaders later
	
	# Update fill color based on bar type
	_update_fill_color()

# =============================================================================
# VALUE MANAGEMENT
# =============================================================================

func set_value(new_value: float, animate: bool = true) -> void:
	"""Set the current value with optional animation"""
	var old := current_value
	current_value = clampf(new_value, 0.0, max_value)
	
	if animate:
		_animate_to_value(old, current_value)
	else:
		_displayed_value = current_value
		_preview_value = current_value
		_update_display()

func set_max_value(new_max: float, keep_percent: bool = false) -> void:
	"""Set max value, optionally keeping the same percentage"""
	var percent := current_value / max_value if max_value > 0 else 1.0
	max_value = maxf(1.0, new_max)
	if keep_percent:
		current_value = max_value * percent
	_update_display()

func get_percent() -> float:
	"""Get current value as percentage (0.0 - 1.0)"""
	return current_value / max_value if max_value > 0 else 0.0

func is_empty() -> bool:
	return current_value <= 0.0

func is_full() -> bool:
	return current_value >= max_value

# =============================================================================
# ANIMATION
# =============================================================================

func _on_value_changed(old_value: float, new_value: float) -> void:
	value_changed.emit(old_value, new_value)
	_animate_to_value(old_value, new_value)
	
	if new_value <= 0.0:
		depleted.emit()
	elif new_value >= max_value and old_value < max_value:
		filled.emit()

func _animate_to_value(from_value: float, to_value: float) -> void:
	var is_damage := to_value < from_value
	
	# Kill existing tweens
	if _fill_tween and _fill_tween.is_valid():
		_fill_tween.kill()
	if _preview_tween and _preview_tween.is_valid():
		_preview_tween.kill()
	
	if is_damage:
		# DAMAGE: Show preview at old value, animate fill down
		_preview_value = from_value
		_damage_preview.color = damage_preview_color
		_update_preview_display()
		
		# Animate fill immediately
		_fill_tween = create_tween()
		_fill_tween.tween_method(_set_displayed_value, _displayed_value, to_value, fill_animation_duration * 0.5)
		
		# Animate preview to catch up after delay
		_preview_tween = create_tween()
		_preview_tween.tween_interval(damage_preview_duration * 0.3)
		_preview_tween.tween_method(_set_preview_value, from_value, to_value, damage_preview_duration * 0.7)
		
		# Flash effect
		if show_damage_flash:
			_flash_bar(Color(1.0, 0.3, 0.2, 0.5))
		
		# Start pulsing if low HP
		if pulse_on_low_hp and bar_type == 0 and get_percent() <= hp_critical_threshold:
			_start_pulse()
	else:
		# HEAL: Show preview at new value, animate fill up
		_preview_value = to_value
		_damage_preview.color = heal_preview_color
		_update_preview_display()
		
		# Animate fill to catch up
		_fill_tween = create_tween()
		_fill_tween.tween_method(_set_displayed_value, _displayed_value, to_value, fill_animation_duration)
		
		# Preview fades as fill catches up
		_preview_tween = create_tween()
		_preview_tween.tween_interval(fill_animation_duration * 0.8)
		_preview_tween.tween_method(_set_preview_value, to_value, to_value, 0.1)
		
		# Glow effect
		if show_glow_on_change:
			_glow_bar(Color(0.3, 1.0, 0.4, glow_intensity))
		
		# Stop pulsing if healed above threshold
		if pulse_on_low_hp and bar_type == 0 and get_percent() > hp_critical_threshold:
			_stop_pulse()

func _set_displayed_value(value: float) -> void:
	_displayed_value = value
	_update_display()

func _set_preview_value(value: float) -> void:
	_preview_value = value
	_update_preview_display()

func _flash_bar(color: Color) -> void:
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
	
	_glow.color = color
	_glow_tween = create_tween()
	_glow_tween.tween_property(_glow, "color:a", 0.0, 0.25)

func _glow_bar(color: Color) -> void:
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
	
	_glow.color = color
	_glow_tween = create_tween()
	_glow_tween.tween_property(_glow, "color:a", 0.0, 0.4)

func _start_pulse() -> void:
	if _is_pulsing:
		return
	_is_pulsing = true
	
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_property(_fill, "modulate", Color(1.4, 0.8, 0.8, 1.0), 0.5 / pulse_speed)
	_pulse_tween.tween_property(_fill, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5 / pulse_speed)

func _stop_pulse() -> void:
	if not _is_pulsing:
		return
	_is_pulsing = false
	
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_fill.modulate = Color.WHITE

# =============================================================================
# DISPLAY UPDATE
# =============================================================================

func _update_display() -> void:
	if not _fill:
		return
	
	var percent := _displayed_value / max_value if max_value > 0 else 0.0
	_fill.size.x = bar_size.x * percent
	
	_update_fill_color()
	_update_text()

func _update_preview_display() -> void:
	if not _damage_preview:
		return
	
	var percent := _preview_value / max_value if max_value > 0 else 0.0
	_damage_preview.size.x = bar_size.x * percent

func _update_fill_color() -> void:
	if not _fill:
		return
	
	var percent := _displayed_value / max_value if max_value > 0 else 0.0
	
	match bar_type:
		0:  # HP - gradient from green to yellow to red
			if percent > 0.5:
				_fill.color = hp_full_color.lerp(hp_mid_color, (1.0 - percent) * 2.0)
			else:
				_fill.color = hp_mid_color.lerp(hp_low_color, (0.5 - percent) * 2.0)
		1:  # MP - solid blue with fade
			_fill.color = mp_color.lerp(mp_empty_color, 1.0 - percent)
		2:  # Corruption - purple with glow
			_fill.color = corruption_color
		3:  # XP - gold
			_fill.color = Color(0.9, 0.75, 0.2, 1.0)
		_:  # Custom
			_fill.color = hp_full_color

func _update_text() -> void:
	if not _text_label or not show_text:
		return
	
	var text := text_format
	text = text.replace("{current}", str(int(_displayed_value)))
	text = text.replace("{max}", str(int(max_value)))
	text = text.replace("{percent}", str(int(get_percent() * 100)))
	_text_label.text = text

# =============================================================================
# UTILITY
# =============================================================================

func shake(intensity: float = 3.0, duration: float = 0.15) -> void:
	"""Shake the bar (for damage feedback)"""
	var original_pos := position
	var tween := create_tween()
	
	for i in range(int(duration / 0.03)):
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity * 0.5, intensity * 0.5))
		tween.tween_property(self, "position", original_pos + offset, 0.03)
	
	tween.tween_property(self, "position", original_pos, 0.03)

func highlight(color: Color = Color.WHITE, duration: float = 0.3) -> void:
	"""Highlight the bar temporarily"""
	var original_border := border_color
	
	var style := _background.get_theme_stylebox("panel") if _background.has_theme_stylebox("panel") else null
	if style and style is StyleBoxFlat:
		var flat := style as StyleBoxFlat
		flat.border_color = color
		
		var tween := create_tween()
		tween.tween_callback(func(): flat.border_color = original_border).set_delay(duration)
