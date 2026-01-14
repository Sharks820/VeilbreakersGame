class_name CharacterSelectController
extends Control
## CharacterSelectController: Orchestrates the modular character select screen.
## Coordinates communication between child panels via signals.
## AAA-quality with atmospheric particles, animated vignette, and glowing effects.

signal character_selected(hero_id: String)
signal selection_cancelled

# =============================================================================
# CONSTANTS
# =============================================================================

const HERO_IDS: Array[String] = ["bastion", "rend", "marrow", "mirage"]

# AAA Atmospheric settings
const PARTICLE_COUNT := 15  # Floating dust/ember particles (reduced from 50 for performance)
const VIGNETTE_PULSE_MIN := 0.6
const VIGNETTE_PULSE_MAX := 0.85
const VIGNETTE_PULSE_DURATION := 4.0  # Seconds per cycle
const TITLE_GLOW_MIN := 0.3
const TITLE_GLOW_MAX := 0.7

# Monster IDs for showcase (all starters across all heroes)
const MONSTER_IDS: Array[String] = [
	"chainbound", "skitter_teeth", "the_bulwark", "ironjaw",
	"mawling", "ravener", "needlefang",
	"gluttony_polyp", "bloodshade", "hollow", "sporecaller",
	"flicker", "crackling", "voltgeist", "the_weeping"
]

# =============================================================================
# STATE
# =============================================================================

var hero_data_cache: Dictionary = {}
var monster_data_cache: Dictionary = {}
var selected_hero_index: int = 0
var _selection_locked: bool = false

# Child panels
var hero_cards_panel: HeroCardsPanel = null
var hero_display_panel: HeroDisplayPanel = null
var info_panel: HeroInfoPanel = null
var vera_panel: CharacterSelectVERAPanel = null
var button_bar: CharacterSelectButtonBar = null
var confirmation_popup: CharacterSelectConfirmationPopup = null

# AAA Atmospheric effects
var _vignette_overlay: ColorRect = null
var _vignette_tween: Tween = null
var _title_label: Label = null
var _title_glow: Label = null
var _title_glow_tween: Tween = null
var _particles_container: Control = null
var _dust_particles: Array[ColorRect] = []
var _particle_tweens: Array[Tween] = []
var _line_left: ColorRect = null
var _line_right: ColorRect = null
var _line_pulse_tween: Tween = null

# Hero-change transition tweens (tracked for cleanup)
var _particle_color_tweens: Array[Tween] = []
var _glow_change_tween: Tween = null
var _line_change_tweens: Array[Tween] = []

# DRAMATIC selection effects
var _screen_flash: ColorRect = null
var _burst_container: Control = null

# =============================================================================
# LIFECYCLE
# =============================================================================


func _ready() -> void:
	_load_all_data()
	_build_ui()
	_connect_signals()
	_start_atmospheric_effects()
	call_deferred("_select_hero", 0)


func _exit_tree() -> void:
	# Clean up all atmospheric tweens to prevent memory leaks
	if _vignette_tween and _vignette_tween.is_valid():
		_vignette_tween.kill()
	if _title_glow_tween and _title_glow_tween.is_valid():
		_title_glow_tween.kill()
	if _line_pulse_tween and _line_pulse_tween.is_valid():
		_line_pulse_tween.kill()
	for tween in _particle_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_particle_tweens.clear()

	# Clean up hero-change transition tweens
	for tween in _particle_color_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_particle_color_tweens.clear()

	if _glow_change_tween and _glow_change_tween.is_valid():
		_glow_change_tween.kill()

	for tween in _line_change_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_line_change_tweens.clear()


func _load_all_data() -> void:
	# Load hero data
	for hero_id in HERO_IDS:
		var path := "res://data/heroes/%s.tres" % hero_id
		if ResourceLoader.exists(path):
			var data := load(path) as HeroData
			if data:
				hero_data_cache[hero_id] = data

	# Load monster data
	for monster_id in MONSTER_IDS:
		var path := "res://data/monsters/%s.tres" % monster_id
		if ResourceLoader.exists(path):
			var data := load(path)
			if data:
				monster_data_cache[monster_id] = data


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# === BACKGROUND ===
	_create_background()

	# =========================================================================
	# AAA HERO-CENTRIC LAYOUT
	# Hero dominates 65% center, cards on left edge, info slides right
	# =========================================================================

	# === TITLE BAR (Top, full width, minimal height) ===
	var title_container := Control.new()
	title_container.name = "TitleContainer"
	title_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_container.custom_minimum_size.y = 80
	title_container.offset_bottom = 80
	add_child(title_container)
	_create_title_bar_redesigned(title_container)

	# === HERO DISPLAY (DOMINANT CENTER - 65% of screen) ===
	# This is the star of the show - massive hero portrait
	hero_display_panel = HeroDisplayPanel.new()
	hero_display_panel.name = "HeroDisplayDominant"
	hero_display_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Push slightly left to leave room for info panel
	hero_display_panel.offset_left = 310  # Space for cards (295px + 15px gap)
	hero_display_panel.offset_right = -380  # Space for info
	hero_display_panel.offset_top = 90  # Below title
	hero_display_panel.offset_bottom = -140  # Above button bar
	add_child(hero_display_panel)

	# === HERO CARDS (Left edge - vertical strip, sleek) ===
	var cards_container := Control.new()
	cards_container.name = "CardsContainer"
	cards_container.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	cards_container.offset_right = 295  # Wide enough for 250px cards + 30px padding + 15px margin
	cards_container.offset_top = 90
	cards_container.offset_bottom = -200  # Make room for VERA below
	add_child(cards_container)

	# Dark backdrop for cards
	var cards_backdrop := UIStyleFactory.create_styled_panel(UIStyleFactory.create_hero_display_backdrop())
	cards_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	cards_backdrop.modulate.a = 0.6
	cards_container.add_child(cards_backdrop)

	hero_cards_panel = HeroCardsPanel.new()
	hero_cards_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	hero_cards_panel.offset_left = 15
	hero_cards_panel.offset_right = -15
	hero_cards_panel.offset_top = 20
	hero_cards_panel.offset_bottom = -20
	cards_container.add_child(hero_cards_panel)
	hero_cards_panel.setup(HERO_IDS, hero_data_cache)

	# === INFO PANEL (Right edge - sleek overlay) ===
	var info_container := Control.new()
	info_container.name = "InfoContainer"
	info_container.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	info_container.offset_left = -360  # Slightly narrower
	info_container.offset_top = 90
	info_container.offset_bottom = -140
	add_child(info_container)

	# Dark backdrop for info
	var info_backdrop := UIStyleFactory.create_styled_panel(UIStyleFactory.create_hero_display_backdrop())
	info_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	info_backdrop.modulate.a = 0.7
	info_container.add_child(info_backdrop)

	info_panel = HeroInfoPanel.new()
	info_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	info_panel.offset_left = 15
	info_panel.offset_right = -15
	info_panel.offset_top = 15
	info_panel.offset_bottom = -15
	info_panel.set_monster_cache(monster_data_cache)
	info_container.add_child(info_panel)

	# === VERA PANEL (Bottom left - companion style) ===
	# Positioned below main content (which ends at y=940 from offset_bottom=-140)
	# Height: 150px for proper dialogue display
	var vera_container := Control.new()
	vera_container.name = "VERAContainer"
	vera_container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	vera_container.offset_left = 20
	vera_container.offset_right = 500  # Wider for dialogue text
	vera_container.offset_top = -200   # 1080-200=880 to 1080-15=1065 = 185px height (VERA needs 180 minimum)
	vera_container.offset_bottom = -15
	add_child(vera_container)

	vera_panel = CharacterSelectVERAPanel.new()
	vera_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	vera_container.add_child(vera_panel)

	# === BUTTON BAR (Bottom right - action buttons) ===
	# Vertically centered within the bottom zone (915-1065)
	# Height: 80px, centered gives top=955, bottom=1035 but we use offset math
	var button_container := Control.new()
	button_container.name = "ButtonContainer"
	button_container.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button_container.offset_left = -420   # Wider for larger buttons
	button_container.offset_right = -20
	button_container.offset_top = -100    # Taller for more prominent buttons
	button_container.offset_bottom = -20  # Slightly raised from very bottom
	add_child(button_container)

	button_bar = CharacterSelectButtonBar.new()
	button_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	button_container.add_child(button_bar)

	# === CONFIRMATION POPUP (hidden initially) ===
	confirmation_popup = CharacterSelectConfirmationPopup.new()
	add_child(confirmation_popup)

	# === DRAMATIC: Screen flash overlay (on TOP of everything) ===
	_screen_flash = ColorRect.new()
	_screen_flash.name = "ScreenFlash"
	_screen_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_flash.color = Color(1.0, 1.0, 1.0, 0.0)  # Starts invisible
	add_child(_screen_flash)

	# === DRAMATIC: Particle burst container (on TOP) ===
	_burst_container = Control.new()
	_burst_container.name = "BurstContainer"
	_burst_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_burst_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_burst_container)


func _create_background() -> void:
	# Dark atmospheric background
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.04, 0.04, 0.06, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Gradient overlays for atmosphere
	var gradient_top := ColorRect.new()
	gradient_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	gradient_top.custom_minimum_size.y = 150
	gradient_top.color = Color(0.08, 0.06, 0.12, 0.6)
	add_child(gradient_top)

	var gradient_bottom := ColorRect.new()
	gradient_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	gradient_bottom.custom_minimum_size.y = 200
	gradient_bottom.color = Color(0.02, 0.02, 0.04, 0.8)
	add_child(gradient_bottom)

	# === AAA: Floating dust particles container ===
	_particles_container = Control.new()
	_particles_container.name = "ParticlesContainer"
	_particles_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_particles_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_particles_container)
	_create_dust_particles()

	# === AAA: Animated vignette overlay ===
	_vignette_overlay = ColorRect.new()
	_vignette_overlay.name = "VignetteOverlay"
	_vignette_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Create radial gradient effect with shader-like appearance
	_vignette_overlay.color = Color(0.0, 0.0, 0.0, VIGNETTE_PULSE_MIN)
	add_child(_vignette_overlay)


func _create_dust_particles() -> void:
	## Create floating dust/ember particles for atmosphere
	for i in range(PARTICLE_COUNT):
		var particle := ColorRect.new()
		particle.custom_minimum_size = Vector2(randf_range(2, 5), randf_range(2, 5))
		particle.size = particle.custom_minimum_size

		# Random warm ember colors
		var hue := randf_range(0.05, 0.12)  # Orange to gold range
		var sat := randf_range(0.3, 0.7)
		var val := randf_range(0.5, 0.9)
		particle.color = Color.from_hsv(hue, sat, val, randf_range(0.1, 0.4))

		# Random starting position
		particle.position = Vector2(
			randf_range(0, 1920),
			randf_range(0, 1080)
		)

		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_particles_container.add_child(particle)
		_dust_particles.append(particle)


func _create_title_bar_redesigned(parent: Control) -> void:
	## AAA-quality title bar with anchor-based positioning for precise control
	## Uses sleek minimal design with animated decorative elements

	# === Left decorative line (animated) ===
	_line_left = ColorRect.new()
	_line_left.name = "LineLeft"
	_line_left.anchor_left = 0.0
	_line_left.anchor_right = 0.35  # 35% of title bar width
	_line_left.anchor_top = 0.5
	_line_left.anchor_bottom = 0.5
	_line_left.offset_left = 50
	_line_left.offset_right = -30
	_line_left.offset_top = -1
	_line_left.offset_bottom = 1
	_line_left.color = Color(0.6, 0.5, 0.3, 0.5)
	parent.add_child(_line_left)

	# === Title wrapper (center) ===
	var title_wrapper := Control.new()
	title_wrapper.name = "TitleWrapper"
	title_wrapper.anchor_left = 0.35
	title_wrapper.anchor_right = 0.65  # 30% width for title
	title_wrapper.anchor_top = 0.0
	title_wrapper.anchor_bottom = 1.0
	title_wrapper.offset_left = 0
	title_wrapper.offset_right = 0
	parent.add_child(title_wrapper)

	# Main title text - crisp and readable (SINGLE label to avoid doubling)
	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "CHOOSE YOUR CHAMPION"
	_title_label.add_theme_font_size_override("font_size", 40)
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
	# Add outline for glow effect instead of separate glow layer
	_title_label.add_theme_color_override("font_outline_color", Color(1.0, 0.85, 0.4, 0.6))
	_title_label.add_theme_constant_override("outline_size", 4)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_wrapper.add_child(_title_label)

	# Set _title_glow reference to same label for animation compatibility
	_title_glow = _title_label

	# === Right decorative line (animated) ===
	_line_right = ColorRect.new()
	_line_right.name = "LineRight"
	_line_right.anchor_left = 0.65
	_line_right.anchor_right = 1.0
	_line_right.anchor_top = 0.5
	_line_right.anchor_bottom = 0.5
	_line_right.offset_left = 30
	_line_right.offset_right = -50
	_line_right.offset_top = -1
	_line_right.offset_bottom = 1
	_line_right.color = Color(0.6, 0.5, 0.3, 0.5)
	parent.add_child(_line_right)


func _create_title_bar(parent: Control) -> void:
	## LEGACY - kept for reference, use _create_title_bar_redesigned instead
	var title_container := UIStyleFactory.create_hbox(20)
	parent.add_child(title_container)

	# Decorative line left (with glow capability)
	_line_left = ColorRect.new()
	_line_left.custom_minimum_size = Vector2(100, 2)
	_line_left.color = Color(0.6, 0.5, 0.3, 0.5)
	UIStyleFactory.expand_horizontal(_line_left)
	_line_left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_container.add_child(_line_left)

	# === AAA: Title with glow layer ===
	var title_wrapper := Control.new()
	title_wrapper.custom_minimum_size = Vector2(500, 60)
	title_container.add_child(title_wrapper)

	# Glow layer (behind main text)
	_title_glow = Label.new()
	_title_glow.text = "CHOOSE YOUR CHAMPION"
	_title_glow.add_theme_font_size_override("font_size", 42)
	_title_glow.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, TITLE_GLOW_MIN))
	_title_glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_glow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_wrapper.add_child(_title_glow)

	# Main title text
	_title_label = Label.new()
	_title_label.text = "CHOOSE YOUR CHAMPION"
	_title_label.add_theme_font_size_override("font_size", 38)
	_title_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_wrapper.add_child(_title_label)

	# Decorative line right (with glow capability)
	_line_right = ColorRect.new()
	_line_right.custom_minimum_size = Vector2(100, 2)
	_line_right.color = Color(0.6, 0.5, 0.3, 0.5)
	UIStyleFactory.expand_horizontal(_line_right)
	_line_right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_container.add_child(_line_right)


func _connect_signals() -> void:
	# Hero cards panel
	hero_cards_panel.hero_hovered.connect(_on_hero_hovered)
	hero_cards_panel.hero_clicked.connect(_on_hero_clicked)
	hero_cards_panel.hero_selected.connect(_on_hero_selected)

	# Button bar
	button_bar.back_pressed.connect(_on_back_pressed)
	button_bar.confirm_pressed.connect(_on_confirm_pressed)

	# Confirmation popup
	confirmation_popup.confirmed.connect(_on_hero_confirmed)
	confirmation_popup.cancelled.connect(_on_confirmation_cancelled)


# =============================================================================
# HERO SELECTION
# =============================================================================


func _select_hero(index: int) -> void:
	if index < 0 or index >= HERO_IDS.size():
		return

	selected_hero_index = index
	var hero_id := HERO_IDS[index]
	var hero_data: HeroData = hero_data_cache.get(hero_id)

	if not hero_data:
		push_warning("No data for hero: %s" % hero_id)
		return

	# Update all panels
	hero_display_panel.display_hero(hero_data)
	info_panel.display_hero_info(hero_data)
	vera_panel.update_for_hero(hero_id)

	# AAA: Update atmospheric particle colors to match hero theme
	_update_particle_colors_for_hero(hero_id)

	# AAA: Update title glow color to match hero
	_update_title_glow_for_hero(hero_id)


func _get_selected_hero_id() -> String:
	if selected_hero_index >= 0 and selected_hero_index < HERO_IDS.size():
		return HERO_IDS[selected_hero_index]
	return ""


# =============================================================================
# SIGNAL HANDLERS - HERO CARDS
# =============================================================================


func _on_hero_hovered(index: int) -> void:
	# Only change selection on hover if not locked
	if not _selection_locked:
		_select_hero(index)


func _on_hero_clicked(index: int) -> void:
	# Lock selection on click
	_selection_locked = true
	_select_hero(index)

	# === DRAMATIC EFFECTS ON CLICK ===
	var hero_id := HERO_IDS[index] if index < HERO_IDS.size() else "bastion"
	_trigger_screen_flash(hero_id)
	_trigger_particle_burst(hero_id)


func _on_hero_selected(index: int) -> void:
	_select_hero(index)


# =============================================================================
# SIGNAL HANDLERS - BUTTONS
# =============================================================================


func _on_back_pressed() -> void:
	selection_cancelled.emit()
	SceneManager.goto_main_menu()


func _on_confirm_pressed() -> void:
	var hero_id := _get_selected_hero_id()
	var hero_data: HeroData = hero_data_cache.get(hero_id)
	var hero_name := hero_data.display_name if hero_data else hero_id.capitalize()

	confirmation_popup.show_popup(hero_name, hero_id)


func _on_confirmation_cancelled() -> void:
	button_bar.focus_confirm()


func _on_hero_confirmed(hero_id: String) -> void:
	print("[CHARACTER_SELECT] Confirmed hero: %s" % hero_id)

	# Store selection
	GameManager.set_selected_hero(hero_id)

	# Initialize player character
	var player := GameManager.initialize_player_character()
	if player:
		print("[CHARACTER_SELECT] Player character created: %s" % player.character_name)

		# Add starter monsters
		var starter_monsters := _get_starter_monsters_for_hero(hero_id)
		for monster_id in starter_monsters:
			GameManager.add_monster_to_collection(monster_id, 5)
			print("[CHARACTER_SELECT] Added starter monster: %s" % monster_id)

		# Set tutorial flags
		GameManager.set_story_flag("tutorial_battle_pending", true)
		GameManager.set_story_flag("vera_introduced", true)

		character_selected.emit(hero_id)

		# Go to tutorial battle
		SceneManager.change_scene("res://scenes/test/test_battle.tscn")
	else:
		push_error("[CHARACTER_SELECT] Failed to create player character!")


func _get_starter_monsters_for_hero(hero_id: String) -> Array[String]:
	match hero_id:
		"bastion":
			return ["chainbound", "skitter_teeth", "the_bulwark", "ironjaw"]
		"rend":
			return ["mawling", "ravener", "ironjaw", "needlefang"]
		"marrow":
			return ["gluttony_polyp", "bloodshade", "hollow", "sporecaller"]
		"mirage":
			return ["flicker", "crackling", "voltgeist", "the_weeping"]
		_:
			push_warning("[CHARACTER_SELECT] Unknown hero_id: %s" % hero_id)
			return ["mawling", "chainbound", "crackling", "hollow"]


# =============================================================================
# INPUT HANDLING
# =============================================================================


func _input(event: InputEvent) -> void:
	# Don't process input if popup is visible
	if confirmation_popup.visible:
		return

	if event.is_action_pressed("ui_up"):
		var new_index := (selected_hero_index - 1 + HERO_IDS.size()) % HERO_IDS.size()
		_selection_locked = true
		hero_cards_panel.select_hero(new_index)
		hero_cards_panel.focus_card(new_index)
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("ui_down"):
		var new_index := (selected_hero_index + 1) % HERO_IDS.size()
		_selection_locked = true
		hero_cards_panel.select_hero(new_index)
		hero_cards_panel.focus_card(new_index)
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("ui_accept"):
		_on_confirm_pressed()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()


# =============================================================================
# AAA ATMOSPHERIC EFFECTS SYSTEM
# =============================================================================


## Hero-specific particle color palettes
const HERO_PARTICLE_COLORS: Dictionary = {
	"bastion": [Color(0.4, 0.5, 0.7, 0.4), Color(0.5, 0.6, 0.8, 0.3), Color(0.3, 0.4, 0.6, 0.35)],  # Steel blue
	"rend": [Color(0.8, 0.2, 0.2, 0.4), Color(0.9, 0.3, 0.1, 0.35), Color(0.7, 0.1, 0.1, 0.3)],    # Blood red
	"marrow": [Color(0.5, 0.3, 0.7, 0.4), Color(0.6, 0.4, 0.8, 0.35), Color(0.4, 0.2, 0.6, 0.3)],  # Spirit purple
	"mirage": [Color(0.3, 0.7, 0.9, 0.4), Color(0.2, 0.6, 0.8, 0.35), Color(0.4, 0.8, 1.0, 0.3)]   # Void cyan
}

## Hero-specific accent colors for title glow and UI highlights
const HERO_ACCENT_COLORS: Dictionary = {
	"bastion": Color(0.6, 0.7, 0.9, 1.0),   # Steel blue glow
	"rend": Color(0.95, 0.3, 0.2, 1.0),      # Blood red glow
	"marrow": Color(0.7, 0.5, 0.9, 1.0),     # Spirit purple glow
	"mirage": Color(0.4, 0.85, 1.0, 1.0)     # Void cyan glow
}

## Hero-specific line colors for decorative accents
const HERO_LINE_COLORS: Dictionary = {
	"bastion": Color(0.5, 0.6, 0.8, 0.7),
	"rend": Color(0.8, 0.3, 0.2, 0.7),
	"marrow": Color(0.6, 0.4, 0.8, 0.7),
	"mirage": Color(0.3, 0.7, 0.9, 0.7)
}


func _start_atmospheric_effects() -> void:
	## Initialize all AAA atmospheric animations
	_start_vignette_pulse()
	_start_title_glow_pulse()
	_start_line_pulse()
	_start_particle_animations()


func _start_vignette_pulse() -> void:
	## Animated vignette that slowly pulses for atmosphere
	if not _vignette_overlay:
		return

	if _vignette_tween and _vignette_tween.is_valid():
		_vignette_tween.kill()

	_vignette_tween = create_tween()
	_vignette_tween.set_loops()  # Infinite loop

	# Pulse from min to max alpha and back
	_vignette_tween.tween_property(
		_vignette_overlay, "color:a",
		VIGNETTE_PULSE_MAX,
		VIGNETTE_PULSE_DURATION / 2.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_vignette_tween.tween_property(
		_vignette_overlay, "color:a",
		VIGNETTE_PULSE_MIN,
		VIGNETTE_PULSE_DURATION / 2.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _start_title_glow_pulse() -> void:
	## Animated title glow that pulses for magical effect
	if not _title_glow:
		return

	if _title_glow_tween and _title_glow_tween.is_valid():
		_title_glow_tween.kill()

	_title_glow_tween = create_tween()
	_title_glow_tween.set_loops()

	# Slower pulse for title glow - more subtle
	_title_glow_tween.tween_property(
		_title_glow, "modulate:a",
		TITLE_GLOW_MAX,
		1.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_title_glow_tween.tween_property(
		_title_glow, "modulate:a",
		TITLE_GLOW_MIN,
		1.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _start_line_pulse() -> void:
	## Animated decorative lines that pulse in sync with title
	if not _line_left or not _line_right:
		return

	if _line_pulse_tween and _line_pulse_tween.is_valid():
		_line_pulse_tween.kill()

	_line_pulse_tween = create_tween()
	_line_pulse_tween.set_loops()
	_line_pulse_tween.set_parallel(true)

	# Pulse both lines together
	_line_pulse_tween.tween_property(_line_left, "color:a", 0.8, 1.5).set_trans(Tween.TRANS_SINE)
	_line_pulse_tween.tween_property(_line_right, "color:a", 0.8, 1.5).set_trans(Tween.TRANS_SINE)
	_line_pulse_tween.set_parallel(false)
	_line_pulse_tween.tween_property(_line_left, "color:a", 0.4, 1.5).set_trans(Tween.TRANS_SINE)
	_line_pulse_tween.set_parallel(true)
	_line_pulse_tween.tween_property(_line_right, "color:a", 0.4, 1.5).set_trans(Tween.TRANS_SINE)


func _start_particle_animations() -> void:
	## Animate all dust particles with floating motion
	for i in range(_dust_particles.size()):
		var particle: ColorRect = _dust_particles[i]
		if not is_instance_valid(particle):
			continue

		_animate_single_particle(particle, i)


func _animate_single_particle(particle: ColorRect, index: int) -> void:
	## Animate a single particle with unique floating pattern
	var tween := create_tween()
	tween.set_loops()
	_particle_tweens.append(tween)

	# Random float parameters for variety
	var float_duration: float = randf_range(8.0, 15.0)
	var horizontal_drift: float = randf_range(-100, 100)
	var vertical_rise: float = randf_range(-200, -400)  # Always rise

	# Get screen bounds
	var screen_width: float = 1920.0
	var screen_height: float = 1080.0

	# Starting position
	var start_pos := particle.position
	var end_pos := Vector2(
		start_pos.x + horizontal_drift,
		start_pos.y + vertical_rise
	)

	# Wrap around screen edges
	if end_pos.y < -50:
		end_pos.y = screen_height + 50
	if end_pos.x < -50:
		end_pos.x = screen_width + randf_range(0, 200)
	if end_pos.x > screen_width + 50:
		end_pos.x = randf_range(-200, 0)

	# Float upward with slight horizontal sway
	tween.tween_property(particle, "position", end_pos, float_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Fade in and out during float
	tween.set_parallel(true)
	var original_alpha: float = particle.color.a
	tween.tween_property(particle, "color:a", original_alpha * 1.5, float_duration * 0.3)
	tween.chain().tween_property(particle, "color:a", original_alpha * 0.5, float_duration * 0.4)
	tween.chain().tween_property(particle, "color:a", original_alpha, float_duration * 0.3)

	# Reset position when animation completes (will loop)
	tween.set_parallel(false)
	tween.tween_callback(func():
		particle.position = Vector2(
			randf_range(0, screen_width),
			screen_height + randf_range(20, 100)
		)
	)


func _update_particle_colors_for_hero(hero_id: String) -> void:
	## Update particle colors to match the selected hero's theme
	var colors: Array = HERO_PARTICLE_COLORS.get(hero_id, HERO_PARTICLE_COLORS["bastion"])

	# Kill existing particle color tweens before creating new ones
	for tween in _particle_color_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_particle_color_tweens.clear()

	for particle in _dust_particles:
		if not is_instance_valid(particle):
			continue

		# Randomly select from the hero's color palette
		var new_color: Color = colors[randi() % colors.size()]
		# Vary the alpha slightly for depth
		new_color.a = randf_range(0.15, 0.4)

		# Smooth color transition - tracked for cleanup
		var color_tween := create_tween()
		color_tween.tween_property(particle, "color", new_color, 0.5) \
			.set_trans(Tween.TRANS_SINE)
		_particle_color_tweens.append(color_tween)


func _update_title_glow_for_hero(hero_id: String) -> void:
	## Update title glow and decorative lines to match hero's theme color
	var accent_color: Color = HERO_ACCENT_COLORS.get(hero_id, Color(1.0, 0.85, 0.4))
	var line_color: Color = HERO_LINE_COLORS.get(hero_id, Color(0.6, 0.5, 0.3, 0.7))

	# Kill existing glow/line change tweens before creating new ones
	if _glow_change_tween and _glow_change_tween.is_valid():
		_glow_change_tween.kill()
	for tween in _line_change_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_line_change_tweens.clear()

	# Animate title glow color change - tracked for cleanup
	if _title_glow and is_instance_valid(_title_glow):
		_glow_change_tween = create_tween()
		_glow_change_tween.tween_property(_title_glow, "modulate", accent_color, 0.4) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Animate decorative line colors - tracked for cleanup
	if _line_left and is_instance_valid(_line_left):
		var line_tween := create_tween()
		line_tween.tween_property(_line_left, "color", line_color, 0.4) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_line_change_tweens.append(line_tween)

	if _line_right and is_instance_valid(_line_right):
		var line_tween := create_tween()
		line_tween.tween_property(_line_right, "color", line_color, 0.4) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_line_change_tweens.append(line_tween)


# =============================================================================
# DRAMATIC SELECTION EFFECTS - AAA QUALITY
# =============================================================================


func _trigger_screen_flash(hero_id: String) -> void:
	## DRAMATIC screen flash on hero click - Persona 5 style
	if not _screen_flash or not is_instance_valid(_screen_flash):
		return

	# Get hero accent color for themed flash
	var flash_color: Color = HERO_ACCENT_COLORS.get(hero_id, Color(1.0, 0.85, 0.4))
	# Bright, saturated version of hero color
	flash_color = flash_color.lightened(0.5)
	flash_color.a = 0.6  # Strong but not blinding

	# Instant flash then rapid fade
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)

	# INSTANT: Set to flash color immediately
	_screen_flash.color = flash_color

	# RAPID FADE: 0.2s fade to invisible
	tween.tween_property(_screen_flash, "color:a", 0.0, 0.2)


func _trigger_particle_burst(hero_id: String) -> void:
	## DRAMATIC particle burst on hero click - radiating particles from center
	if not _burst_container or not is_instance_valid(_burst_container):
		return

	# Get hero colors for burst
	var colors: Array = HERO_PARTICLE_COLORS.get(hero_id, HERO_PARTICLE_COLORS["bastion"])

	# Center point of screen
	var center := get_viewport_rect().size / 2.0
	var burst_count := 24  # Number of particles in burst

	for i in range(burst_count):
		# Create burst particle
		var particle := ColorRect.new()
		particle.size = Vector2(randf_range(4, 12), randf_range(4, 12))
		particle.position = center - particle.size / 2.0
		particle.pivot_offset = particle.size / 2.0
		particle.rotation = randf() * TAU

		# Random hero color with high alpha
		var color: Color = colors[randi() % colors.size()]
		color.a = randf_range(0.6, 1.0)
		particle.color = color

		_burst_container.add_child(particle)

		# Calculate burst direction (radial from center)
		var angle: float = (TAU / burst_count) * i + randf_range(-0.2, 0.2)
		var distance: float = randf_range(300, 600)
		var target_pos := center + Vector2(cos(angle), sin(angle)) * distance

		# Animate: shoot outward with fade
		var tween := create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_EXPO)

		# Movement
		tween.tween_property(particle, "position", target_pos - particle.size / 2.0, randf_range(0.4, 0.7))

		# Scale down
		tween.tween_property(particle, "scale", Vector2(0.1, 0.1), randf_range(0.5, 0.8))

		# Fade out
		tween.tween_property(particle, "color:a", 0.0, randf_range(0.4, 0.6))

		# Rotation for extra flair
		tween.tween_property(particle, "rotation", particle.rotation + randf_range(-TAU, TAU), 0.6)

		# Clean up after animation
		tween.set_parallel(false)
		tween.tween_callback(particle.queue_free)
