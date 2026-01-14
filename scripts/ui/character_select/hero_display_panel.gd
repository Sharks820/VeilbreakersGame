class_name HeroDisplayPanel
extends Control
## Center panel displaying the large hero portrait.
## Uses tween-based breathing animation for smooth, stutter-free idle animation.

# =============================================================================
# CONSTANTS
# =============================================================================

const CLASS_COLORS: Dictionary = {
	"VEILGUARD": Color(0.4, 0.5, 0.7),
	"BLOODHUNTER": Color(0.8, 0.2, 0.2),
	"SOULWEAVER": Color(0.5, 0.3, 0.7),
	"VOIDWALKER": Color(0.3, 0.7, 0.9)
}

# Breathing animation parameters
const BREATHING_MIN_SCALE := 1.0
const BREATHING_MAX_SCALE := 1.025  # 2.5% amplitude - subtle but visible
const BREATHING_CYCLE_TIME := 3.5  # Seconds per full breath cycle

# =============================================================================
# STATE
# =============================================================================

var hero_portrait: TextureRect = null
var hero_name_label: Label = null
var hero_class_label: Label = null
var hero_title_label: Label = null

var _breathing_tween: Tween = null
var _transition_tween: Tween = null
var _current_hero_data: HeroData = null

# =============================================================================
# LIFECYCLE
# =============================================================================


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	name = "HeroDisplay"

	# Dark backdrop
	var backdrop := UIStyleFactory.create_styled_panel(UIStyleFactory.create_hero_display_backdrop())
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	# Hero portrait (large, centered)
	hero_portrait = TextureRect.new()
	hero_portrait.name = "HeroPortrait"
	hero_portrait.set_anchors_preset(Control.PRESET_CENTER)
	hero_portrait.offset_left = -200
	hero_portrait.offset_right = 200
	hero_portrait.offset_top = -250
	hero_portrait.offset_bottom = 200
	hero_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# CRITICAL: LINEAR filtering prevents pixel stepping during scale animations
	hero_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# Center pivot for smooth breathing animation
	hero_portrait.pivot_offset = Vector2(200, 225)
	add_child(hero_portrait)

	# Name overlay at bottom
	var name_panel := UIStyleFactory.create_styled_panel(UIStyleFactory.create_hero_name_overlay())
	name_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	name_panel.offset_top = -140
	add_child(name_panel)

	var name_vbox := UIStyleFactory.create_vbox(5)
	name_panel.add_child(name_vbox)

	# Hero name (large)
	hero_name_label = UIStyleFactory.create_centered_label("", 42, Color(1.0, 0.95, 0.85))
	name_vbox.add_child(hero_name_label)

	# Hero class
	hero_class_label = UIStyleFactory.create_centered_label("", 22, Color.WHITE)
	name_vbox.add_child(hero_class_label)

	# Hero title (italic feel)
	hero_title_label = UIStyleFactory.create_centered_label("", 16, Color(0.6, 0.55, 0.5))
	name_vbox.add_child(hero_title_label)


# =============================================================================
# PUBLIC API
# =============================================================================


func display_hero(hero_data: HeroData) -> void:
	if not hero_data:
		return

	_current_hero_data = hero_data
	_animate_hero_change(hero_data)


func get_current_hero() -> HeroData:
	return _current_hero_data


# =============================================================================
# BREATHING ANIMATION - TWEEN BASED (NO STUTTER)
# =============================================================================


func _start_breathing_animation() -> void:
	_stop_breathing_animation()

	if not hero_portrait or not is_instance_valid(hero_portrait):
		return

	# Ensure starting from base scale
	hero_portrait.scale = Vector2.ONE

	# Use AnimationEffects utility for smooth, looping breathing
	# This uses TRANS_SINE + EASE_IN_OUT for organic feel
	_breathing_tween = AnimationEffects.breathing_loop(
		hero_portrait,
		BREATHING_MIN_SCALE,
		BREATHING_MAX_SCALE,
		BREATHING_CYCLE_TIME
	)


func _stop_breathing_animation() -> void:
	if _breathing_tween and _breathing_tween.is_valid():
		_breathing_tween.kill()
	_breathing_tween = null

	# Reset to base scale
	if hero_portrait and is_instance_valid(hero_portrait):
		hero_portrait.scale = Vector2.ONE


# =============================================================================
# HERO TRANSITION ANIMATION - AAA QUALITY
# =============================================================================


func _animate_hero_change(hero_data: HeroData) -> void:
	# 1. Stop breathing to avoid conflicts
	_stop_breathing_animation()

	# 2. Kill any existing transition
	if _transition_tween and _transition_tween.is_valid():
		_transition_tween.kill()

	_transition_tween = create_tween()
	_transition_tween.set_ease(Tween.EASE_OUT)

	# 3. Fade out with subtle scale down
	_transition_tween.set_parallel(true)
	_transition_tween.tween_property(hero_portrait, "modulate:a", 0.0, 0.15)
	_transition_tween.tween_property(hero_portrait, "scale", Vector2(0.95, 0.95), 0.15)
	_transition_tween.set_parallel(false)

	# 4. Change content (callback)
	_transition_tween.tween_callback(_set_hero_content.bind(hero_data))

	# 5. Fade in with smooth scale up (NO TRANS_BACK - causes overshoot glitches)
	_transition_tween.set_parallel(true)
	_transition_tween.tween_property(hero_portrait, "modulate:a", 1.0, 0.25)
	_transition_tween.tween_property(hero_portrait, "scale", Vector2.ONE, 0.25) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_transition_tween.set_parallel(false)

	# 6. Small delay then restart breathing (NO settle bounce - causes glitches)
	_transition_tween.tween_interval(0.05)
	_transition_tween.tween_callback(_start_breathing_animation)


func _set_hero_content(hero_data: HeroData) -> void:
	# CRITICAL: Reset scale to 1.0 BEFORE changing pivot
	# Changing pivot while scaled != 1.0 causes visual jumping
	hero_portrait.scale = Vector2.ONE

	# Load portrait texture
	var texture_loaded := false
	if hero_data.battle_sprite_path != "" and ResourceLoader.exists(hero_data.battle_sprite_path):
		hero_portrait.texture = load(hero_data.battle_sprite_path)
		texture_loaded = true
	elif hero_data.sprite_path != "" and ResourceLoader.exists(hero_data.sprite_path):
		hero_portrait.texture = load(hero_data.sprite_path)
		texture_loaded = true

	# FIXED: Always use fixed pivot based on TextureRect bounds (400x450)
	# The TextureRect offsets define a 400x450 area centered at (0,0)
	# Dynamic pivot calculation caused glitchy breathing when texture size didn't match
	# Center of 400x450 = (200, 225) - this ensures smooth scale animation from center
	hero_portrait.pivot_offset = Vector2(200, 225)

	# Set starting scale for fade-in animation (AFTER pivot is set)
	hero_portrait.scale = Vector2(0.9, 0.9)

	# Update labels
	hero_name_label.text = hero_data.display_name.to_upper()

	var hero_class_name := hero_data.hero_class if hero_data.hero_class != "" else hero_data.role.to_upper()
	hero_class_label.text = hero_class_name
	var class_color: Color = CLASS_COLORS.get(hero_class_name, Color.WHITE)
	hero_class_label.add_theme_color_override("font_color", class_color)

	hero_title_label.text = '"%s"' % hero_data.title


# =============================================================================
# CLEANUP
# =============================================================================


func _exit_tree() -> void:
	_stop_breathing_animation()

	if _transition_tween and _transition_tween.is_valid():
		_transition_tween.kill()
