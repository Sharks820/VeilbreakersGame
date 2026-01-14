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

# Idle animation parameters - MODULATE GLOW PULSE (not scale - scale causes artifacts)
const IDLE_MIN_BRIGHTNESS := 1.0
const IDLE_MAX_BRIGHTNESS := 1.08  # 8% brighter at peak - subtle warm glow
const IDLE_CYCLE_TIME := 3.0  # Seconds per full glow cycle

# =============================================================================
# STATE
# =============================================================================

var hero_portrait: TextureRect = null
var hero_name_label: Label = null
var hero_class_label: Label = null
var hero_title_label: Label = null

var _idle_glow_tween: Tween = null
var _transition_tween: Tween = null
var _current_hero_data: HeroData = null

# =============================================================================
# LIFECYCLE
# =============================================================================


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	name = "HeroDisplay"

	# DRAMATIC deep void backdrop with purple edge glow
	var backdrop := UIStyleFactory.create_styled_panel(UIStyleFactory.create_dramatic_hero_display_backdrop())
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	# Hero portrait - FILL the backdrop properly
	# Hero sprites are ~1792x2368 (portrait orientation, aspect ~0.757)
	# Backdrop is ~1230x850 (landscape) so we size based on HEIGHT with padding
	hero_portrait = TextureRect.new()
	hero_portrait.name = "HeroPortrait"
	hero_portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Generous padding from edges so portrait doesn't touch frame
	hero_portrait.offset_left = 100
	hero_portrait.offset_right = -100
	hero_portrait.offset_top = 20
	hero_portrait.offset_bottom = -130  # More bottom space for name overlay
	hero_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# CRITICAL: LINEAR filtering prevents pixel stepping during scale animations
	hero_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(hero_portrait)

	# DRAMATIC gold-accented name overlay at bottom
	var name_panel := UIStyleFactory.create_styled_panel(UIStyleFactory.create_dramatic_hero_name_overlay())
	name_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	name_panel.offset_top = -150
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
# IDLE GLOW ANIMATION - MODULATE PULSE (NO SCALE - SCALE CAUSES ARTIFACTS)
# =============================================================================


func _start_idle_animation() -> void:
	_stop_idle_animation()

	if not hero_portrait or not is_instance_valid(hero_portrait):
		return

	# Ensure starting from base modulate
	hero_portrait.modulate = Color.WHITE

	# Create smooth modulate glow pulse (NO SCALE - scale causes stuttering/artifacts)
	# This pulses brightness subtly for a warm, living feel
	_idle_glow_tween = create_tween().set_loops()
	_idle_glow_tween.set_trans(Tween.TRANS_SINE)
	_idle_glow_tween.set_ease(Tween.EASE_IN_OUT)

	var bright := Color(IDLE_MAX_BRIGHTNESS, IDLE_MAX_BRIGHTNESS, IDLE_MAX_BRIGHTNESS, 1.0)
	var normal := Color(IDLE_MIN_BRIGHTNESS, IDLE_MIN_BRIGHTNESS, IDLE_MIN_BRIGHTNESS, 1.0)

	_idle_glow_tween.tween_property(hero_portrait, "modulate", bright, IDLE_CYCLE_TIME * 0.5)
	_idle_glow_tween.tween_property(hero_portrait, "modulate", normal, IDLE_CYCLE_TIME * 0.5)


func _stop_idle_animation() -> void:
	if _idle_glow_tween and _idle_glow_tween.is_valid():
		_idle_glow_tween.kill()
	_idle_glow_tween = null

	# Reset to base modulate
	if hero_portrait and is_instance_valid(hero_portrait):
		hero_portrait.modulate = Color.WHITE


# =============================================================================
# HERO TRANSITION ANIMATION - AAA QUALITY
# =============================================================================


func _animate_hero_change(hero_data: HeroData) -> void:
	# 1. Stop idle animation to avoid conflicts
	_stop_idle_animation()

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

	# 6. Small delay then restart idle animation (NO settle bounce - causes glitches)
	_transition_tween.tween_interval(0.05)
	_transition_tween.tween_callback(_start_idle_animation)


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

	# Calculate pivot at center of the TextureRect's actual size
	# With FULL_RECT anchoring, size is dynamic based on parent
	# Use size/2 for center pivot - ensures smooth scale animations
	var portrait_size: Vector2 = hero_portrait.size
	if portrait_size.x <= 0 or portrait_size.y <= 0:
		# Fallback if size not yet calculated
		portrait_size = Vector2(1030, 700)  # Approximate based on padding
	hero_portrait.pivot_offset = portrait_size / 2.0

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
	_stop_idle_animation()

	if _transition_tween and _transition_tween.is_valid():
		_transition_tween.kill()
