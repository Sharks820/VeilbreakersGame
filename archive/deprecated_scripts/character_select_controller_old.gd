class_name CharacterSelectController
extends Control
## CharacterSelectController: AAA-quality hero selection screen with VERA integration.
## Features large hero display, class showcase, recommended monsters, and tutorial setup.

signal character_selected(hero_id: String)
signal selection_cancelled

# =============================================================================
# CONSTANTS
# =============================================================================

const HERO_IDS: Array[String] = ["bastion", "rend", "marrow", "mirage"]

# Class colors for visual identity
const CLASS_COLORS: Dictionary = {
	"VEILGUARD": Color(0.4, 0.5, 0.7),  # Steel blue
	"BLOODHUNTER": Color(0.8, 0.2, 0.2),  # Blood red
	"SOULWEAVER": Color(0.5, 0.3, 0.7),  # Soul purple
	"VOIDWALKER": Color(0.3, 0.7, 0.9)  # Ethereal cyan
}

# Path and Brand colors now use centralized systems:
# - PathSystem.get_path_color() for path colors
# - BrandSystem.get_brand_color() for brand colors

# =============================================================================
# STATE
# =============================================================================

var hero_cards: Array[Control] = []
var selected_hero_index: int = 0
var hero_data_cache: Dictionary = {}
var monster_data_cache: Dictionary = {}
var _selection_locked: bool = false  # True after user clicks to confirm selection
var _hovered_index: int = -1  # Currently hovered card (for visual feedback only)

# Main UI elements
var background: TextureRect = null
var hero_portrait: TextureRect = null
var hero_name_label: Label = null
var hero_class_label: Label = null
var hero_title_label: Label = null
var hero_description: RichTextLabel = null
var path_label: Label = null
var brand_label: Label = null
var synergy_label: RichTextLabel = null
var stats_grid: GridContainer = null
var monster_showcase: HBoxContainer = null
var vera_panel: PanelContainer = null
var vera_portrait: TextureRect = null
var vera_dialogue: RichTextLabel = null
var confirm_button: Button = null
var back_button: Button = null

# Animation tweens
var _selection_tween: Tween = null
var _vera_tween: Tween = null
var _vera_flash_tween: Tween = null  # Separate tween for VERA portrait flash effect

# Breathing animation state (using _process for frame-perfect animation)
var _breathing_enabled: bool = false
var _breathing_time: float = 0.0
var _vera_breathing_enabled: bool = false
var _vera_breathing_time: float = 0.0

# =============================================================================
# LIFECYCLE
# =============================================================================


func _ready() -> void:
	_load_all_data()
	_build_ui()
	_setup_animations()
	_select_hero(0)

	# Initial VERA greeting
	_show_vera_dialogue("Welcome, Hunter. I am VERA - your Virtual Entity for Reconnaissance and Analysis. Choose your champion wisely. Each walks a different Path, and the monsters you capture will resonate with that choice.")

func _process(delta: float) -> void:
	# Hero portrait breathing animation - SMOOTH sine wave for AAA quality
	if _breathing_enabled and hero_portrait and is_instance_valid(hero_portrait):
		_breathing_time += delta
		# Sine wave: 2.5% amplitude, 3.5 second full cycle (slower = more natural)
		# Using smoother easing for AAA feel
		var breath_raw: float = sin(_breathing_time * TAU / 3.5)
		# Apply ease-in-out curve for more organic breathing
		var breath: float = (breath_raw * 0.5 + 0.5)  # Normalize to 0-1
		breath = breath * breath * (3.0 - 2.0 * breath)  # Smoothstep for organic feel
		var target_scale: float = 1.0 + breath * 0.025  # 1.0 to 1.025 (subtle)
		hero_portrait.scale = Vector2(target_scale, target_scale)

	# VERA portrait breathing animation - SMOOTH sine wave
	if _vera_breathing_enabled and vera_portrait and is_instance_valid(vera_portrait):
		_vera_breathing_time += delta
		# Sine wave: 4% amplitude, 4.5 second full cycle
		var breath_raw: float = sin(_vera_breathing_time * TAU / 4.5)
		var breath: float = (breath_raw * 0.5 + 0.5)
		breath = breath * breath * (3.0 - 2.0 * breath)  # Smoothstep
		var target_scale: float = 1.0 + breath * 0.04  # 1.0 to 1.04
		vera_portrait.scale = Vector2(target_scale, target_scale)

func _load_all_data() -> void:
	## Load all hero and monster data
	# Load heroes
	for hero_id in HERO_IDS:
		var path := "res://data/heroes/%s.tres" % hero_id
		if ResourceLoader.exists(path):
			var data := load(path) as HeroData
			if data:
				hero_data_cache[hero_id] = data

	# Load monsters for showcase - includes all starter monsters for all heroes
	var monster_ids := [
		# IRON brand (Bastion starters)
		"chainbound",
		"skitter_teeth",
		"the_bulwark",
		"ironjaw",  # BLOODIRON hybrid
		# SAVAGE brand (Rend starters)
		"mawling",
		"ravener",
		"needlefang",  # VENOMSTRIKE - fast assassin
		# LEECH/DREAD brand (Marrow starters)
		"gluttony_polyp",
		"bloodshade",  # NIGHTLEECH hybrid
		"hollow",
		"sporecaller",
		# SURGE/DREAD brand (Mirage starters)
		"flicker",
		"crackling",
		"voltgeist",  # TERRORFLUX hybrid
		"the_weeping"
	]
	for monster_id in monster_ids:
		var path := "res://data/monsters/%s.tres" % monster_id
		if ResourceLoader.exists(path):
			var data := load(path)
			if data:
				monster_data_cache[monster_id] = data


func _build_ui() -> void:
	## Build the complete AAA-quality UI
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# === BACKGROUND ===
	_create_background()

	# === MAIN LAYOUT ===
	var main_container := MarginContainer.new()
	main_container.name = "MainContainer"
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.add_theme_constant_override("margin_left", 40)
	main_container.add_theme_constant_override("margin_right", 40)
	main_container.add_theme_constant_override("margin_top", 30)
	main_container.add_theme_constant_override("margin_bottom", 30)
	add_child(main_container)

	var vbox := UIStyleFactory.create_vbox(15)
	main_container.add_child(vbox)

	# === TITLE BAR ===
	_create_title_bar(vbox)

	# === MAIN CONTENT (Hero + Info + Monsters) ===
	var content_hbox := UIStyleFactory.create_hbox(25)
	UIStyleFactory.expand_vertical(content_hbox)
	vbox.add_child(content_hbox)

	# Left: Hero selection cards
	var cards_panel := _create_hero_cards_panel()
	cards_panel.custom_minimum_size.x = 260
	content_hbox.add_child(cards_panel)

	# Center: Large hero display
	var hero_display := _create_hero_display()
	hero_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_hbox.add_child(hero_display)

	# Right: Info + Monsters panel
	var info_panel := _create_info_panel()
	info_panel.custom_minimum_size.x = 420
	content_hbox.add_child(info_panel)

	# === VERA PANEL (Bottom) ===
	_create_vera_panel(vbox)

	# === BUTTON BAR ===
	_create_button_bar(vbox)


func _create_background() -> void:
	## Create atmospheric dark background
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.04, 0.04, 0.06, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Vignette overlay
	var vignette := ColorRect.new()
	vignette.name = "Vignette"
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0, 0, 0, 0)
	add_child(vignette)

	# Add subtle gradient shader effect (simulated with multiple rects)
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


func _create_title_bar(parent: Control) -> void:
	## Create the title bar with game logo feel
	var title_container := UIStyleFactory.create_hbox(20)
	parent.add_child(title_container)

	# Decorative line left
	var line_left := ColorRect.new()
	line_left.custom_minimum_size = Vector2(100, 2)
	line_left.color = Color(0.6, 0.5, 0.3, 0.5)
	UIStyleFactory.expand_horizontal(line_left)
	line_left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_container.add_child(line_left)

	# Title
	var title := UIStyleFactory.create_centered_label("CHOOSE YOUR CHAMPION", 38, Color(0.9, 0.8, 0.6))
	title_container.add_child(title)

	# Decorative line right
	var line_right := ColorRect.new()
	line_right.custom_minimum_size = Vector2(100, 2)
	line_right.color = Color(0.6, 0.5, 0.3, 0.5)
	UIStyleFactory.expand_horizontal(line_right)
	line_right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_container.add_child(line_right)


func _create_hero_cards_panel() -> PanelContainer:
	## Create the left panel with hero selection cards
	var panel := UIStyleFactory.create_styled_panel(UIStyleFactory.create_char_select_panel(15))
	panel.name = "HeroCardsPanel"

	var vbox := UIStyleFactory.create_vbox(10)
	panel.add_child(vbox)

	# Section header
	var header := UIStyleFactory.create_centered_label("CHAMPIONS", 14, Color(0.6, 0.55, 0.5))
	vbox.add_child(header)

	var sep := UIStyleFactory.create_separator()
	sep.modulate = Color(0.4, 0.35, 0.45, 0.5)
	vbox.add_child(sep)

	# Create hero cards
	for i in range(HERO_IDS.size()):
		var card := _create_hero_card(HERO_IDS[i], i)
		vbox.add_child(card)
		hero_cards.append(card)

	return panel


func _create_hero_card(hero_id: String, index: int) -> PanelContainer:
	## Create a single hero selection card
	var data: HeroData = hero_data_cache.get(hero_id)
	var class_color: Color = CLASS_COLORS.get(data.hero_class, Color.WHITE) if data else Color.WHITE

	var card := UIStyleFactory.create_styled_panel(UIStyleFactory.create_hero_card_style(class_color) if data else StyleBoxFlat.new())
	card.name = "HeroCard_%s" % hero_id
	card.custom_minimum_size = Vector2(230, 110)
	card.focus_mode = Control.FOCUS_ALL

	if not data:
		return card

	var hbox := UIStyleFactory.create_hbox(12)
	card.add_child(hbox)

	# Portrait frame
	var portrait_frame := UIStyleFactory.create_styled_panel(UIStyleFactory.create_hero_portrait_frame(class_color))
	portrait_frame.custom_minimum_size = Vector2(75, 75)
	hbox.add_child(portrait_frame)

	# Portrait image
	var portrait := UIStyleFactory.create_portrait(Vector2(71, 71))
	if data.sprite_path != "" and ResourceLoader.exists(data.sprite_path):
		portrait.texture = load(data.sprite_path)
	portrait_frame.add_child(portrait)

	# Info column
	var info := UIStyleFactory.create_vbox(3)
	UIStyleFactory.expand_horizontal(info)
	hbox.add_child(info)

	# Name
	var name_label := UIStyleFactory.create_label(data.display_name.to_upper(), 18, Color(0.95, 0.9, 0.85))
	info.add_child(name_label)

	# Class
	var class_label := UIStyleFactory.create_label(data.hero_class if data.hero_class != "" else data.role.to_upper(), 13, class_color)
	info.add_child(class_label)

	# Path indicator - use PathSystem for centralized colors
	var path_label := UIStyleFactory.create_label(Enums.get_path_name(data.primary_path), 11, PathSystem.get_path_color(data.primary_path))
	info.add_child(path_label)

	# Connect signals
	card.gui_input.connect(_on_card_input.bind(index))
	card.mouse_entered.connect(_on_card_hover.bind(index))
	card.mouse_exited.connect(_on_card_unhover.bind(index))
	card.focus_entered.connect(_on_card_focus.bind(index))

	return card


func _create_hero_display() -> Control:
	## Create the center panel with large hero display
	var container := Control.new()
	container.name = "HeroDisplay"

	# Dark backdrop
	var backdrop := UIStyleFactory.create_styled_panel(UIStyleFactory.create_hero_display_backdrop())
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(backdrop)

	# Hero portrait (large)
	hero_portrait = TextureRect.new()
	hero_portrait.name = "HeroPortrait"
	hero_portrait.set_anchors_preset(Control.PRESET_CENTER)
	hero_portrait.offset_left = -200
	hero_portrait.offset_right = 200
	hero_portrait.offset_top = -250
	hero_portrait.offset_bottom = 200
	hero_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# CRITICAL: Use LINEAR filtering for smooth scaling animations
	# Point filtering causes visible pixel stepping when scaling by small amounts
	hero_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# Pivot at exact center of the rect (400x450) for smooth scale animations
	# This ensures breathing animation scales uniformly from center
	hero_portrait.pivot_offset = Vector2(200, 225)  # Center: width/2, height/2
	container.add_child(hero_portrait)

	# Name overlay at bottom
	var name_panel := UIStyleFactory.create_styled_panel(UIStyleFactory.create_hero_name_overlay())
	name_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	name_panel.offset_top = -140
	container.add_child(name_panel)

	var name_vbox := UIStyleFactory.create_vbox(5)
	name_panel.add_child(name_vbox)

	# Hero name
	hero_name_label = UIStyleFactory.create_centered_label("", 42, Color(1.0, 0.95, 0.85))
	name_vbox.add_child(hero_name_label)

	# Hero class
	hero_class_label = UIStyleFactory.create_centered_label("", 22, Color.WHITE)
	name_vbox.add_child(hero_class_label)

	# Hero title
	hero_title_label = UIStyleFactory.create_centered_label("", 16, Color(0.6, 0.55, 0.5))
	name_vbox.add_child(hero_title_label)

	return container


func _create_info_panel() -> PanelContainer:
	## Create the right panel with stats, path/brand info, and monster showcase
	var panel := UIStyleFactory.create_styled_panel(UIStyleFactory.create_char_select_panel(20))
	panel.name = "InfoPanel"

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var vbox := UIStyleFactory.create_vbox(18)
	UIStyleFactory.expand_horizontal(vbox)
	scroll.add_child(vbox)

	# === PATH & BRAND SECTION ===
	var alignment_section := _create_section_header("PATH & BRAND ALIGNMENT")
	vbox.add_child(alignment_section)

	var alignment_hbox := UIStyleFactory.create_hbox(30)
	alignment_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(alignment_hbox)

	# Path display
	var path_vbox := UIStyleFactory.create_vbox(4)
	alignment_hbox.add_child(path_vbox)

	var path_title := UIStyleFactory.create_centered_label("PATH", 11, Color(0.5, 0.45, 0.4))
	path_vbox.add_child(path_title)

	path_label = UIStyleFactory.create_centered_label("", 18, Color.WHITE)
	path_vbox.add_child(path_label)

	# Arrow
	var arrow := UIStyleFactory.create_label("→", 28, Color(0.4, 0.35, 0.3))
	alignment_hbox.add_child(arrow)

	# Brand display
	var brand_vbox := UIStyleFactory.create_vbox(4)
	alignment_hbox.add_child(brand_vbox)

	var brand_title := UIStyleFactory.create_centered_label("ALIGNED BRAND", 11, Color(0.5, 0.45, 0.4))
	brand_vbox.add_child(brand_title)

	brand_label = UIStyleFactory.create_centered_label("", 18, Color.WHITE)
	brand_vbox.add_child(brand_label)

	# === DESCRIPTION SECTION ===
	var desc_section := _create_section_header("BACKGROUND")
	vbox.add_child(desc_section)

	hero_description = RichTextLabel.new()
	hero_description.bbcode_enabled = true
	hero_description.fit_content = true
	hero_description.custom_minimum_size.y = 60
	hero_description.add_theme_font_size_override("normal_font_size", 13)
	hero_description.add_theme_color_override("default_color", Color(0.7, 0.65, 0.6))
	vbox.add_child(hero_description)

	# === STATS SECTION ===
	var stats_section := _create_section_header("BASE STATS")
	vbox.add_child(stats_section)

	stats_grid = GridContainer.new()
	stats_grid.columns = 4
	stats_grid.add_theme_constant_override("h_separation", 20)
	stats_grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(stats_grid)

	# === STARTER MONSTER SECTION ===
	var monsters_section := _create_section_header("YOUR STARTER MONSTER")
	vbox.add_child(monsters_section)

	synergy_label = RichTextLabel.new()
	synergy_label.bbcode_enabled = true
	synergy_label.fit_content = true
	synergy_label.custom_minimum_size.y = 40
	synergy_label.add_theme_font_size_override("normal_font_size", 12)
	synergy_label.add_theme_color_override("default_color", Color(0.65, 0.6, 0.55))
	vbox.add_child(synergy_label)

	monster_showcase = UIStyleFactory.create_hbox(15)
	monster_showcase.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(monster_showcase)

	return panel


func _create_section_header(title: String) -> VBoxContainer:
	## Create a styled section header
	var container := UIStyleFactory.create_vbox(8)

	var label := UIStyleFactory.create_label(title, 13, Color(0.55, 0.5, 0.45))
	container.add_child(label)

	var sep := UIStyleFactory.create_separator()
	sep.modulate = Color(0.35, 0.3, 0.4, 0.6)
	container.add_child(sep)

	return container


func _create_monster_card(monster_id: String) -> PanelContainer:
	## Create a small monster showcase card
	var card := UIStyleFactory.create_styled_panel(UIStyleFactory.create_monster_card_style())
	card.custom_minimum_size = Vector2(110, 130)

	var monster_data = monster_data_cache.get(monster_id)

	var vbox := UIStyleFactory.create_vbox(5)
	card.add_child(vbox)

	# Monster sprite
	var sprite_container := CenterContainer.new()
	sprite_container.custom_minimum_size.y = 70
	vbox.add_child(sprite_container)

	var sprite := UIStyleFactory.create_icon(Vector2(60, 60))
	# Use LINEAR filtering for smooth scaling/animations
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var sprite_path := "res://assets/sprites/monsters/%s.png" % monster_id
	if ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
	sprite_container.add_child(sprite)

	# Monster name
	var name_label := UIStyleFactory.create_centered_label(
		monster_id.capitalize().replace("_", " "), 11, Color(0.85, 0.8, 0.75)
	)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)

	# Brand indicator
	if monster_data and monster_data.has_method("get") or monster_data is Resource:
		var brand_name := ""
		if "primary_brand" in monster_data:
			brand_name = Enums.get_brand_name(monster_data.primary_brand)
		elif "brand" in monster_data:
			brand_name = Enums.get_brand_name(monster_data.brand)

		if brand_name != "":
			var brand_indicator := UIStyleFactory.create_centered_label(brand_name, 9, Color(0.6, 0.55, 0.5))
			vbox.add_child(brand_indicator)

	return card


func _create_vera_panel(parent: Control) -> void:
	## Create the VERA introduction panel at the bottom - dynamic and engaging
	vera_panel = UIStyleFactory.create_styled_panel(UIStyleFactory.create_vera_panel_style())
	vera_panel.name = "VERAPanel"
	vera_panel.custom_minimum_size.y = 120
	parent.add_child(vera_panel)

	var hbox := UIStyleFactory.create_hbox(25)
	vera_panel.add_child(hbox)

	# VERA portrait - larger with animated glow
	var portrait_frame := UIStyleFactory.create_styled_panel(UIStyleFactory.create_vera_portrait_frame())
	portrait_frame.name = "PortraitFrame"
	portrait_frame.custom_minimum_size = Vector2(90, 90)
	hbox.add_child(portrait_frame)

	vera_portrait = UIStyleFactory.create_portrait(Vector2(84, 84))
	vera_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	vera_portrait.pivot_offset = Vector2(42, 42)  # Center pivot for animations
	# CRITICAL: Use LINEAR filtering for smooth breathing animation
	vera_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if ResourceLoader.exists("res://assets/characters/vera/vera_interface.png"):
		vera_portrait.texture = load("res://assets/characters/vera/vera_interface.png")
	portrait_frame.add_child(vera_portrait)

	# Start portrait pulse animation
	_start_vera_portrait_animation()

	# VERA dialogue section
	var dialogue_vbox := UIStyleFactory.create_vbox(8)
	UIStyleFactory.expand_horizontal(dialogue_vbox)
	hbox.add_child(dialogue_vbox)

	# VERA name with glowing effect
	var vera_name := UIStyleFactory.create_label("⬡ V.E.R.A. ⬡", 16, Color(0.7, 0.5, 0.8))
	vera_name.name = "VERAName"
	vera_name.add_theme_color_override("font_outline_color", Color(0.3, 0.2, 0.4))
	vera_name.add_theme_constant_override("outline_size", 2)
	dialogue_vbox.add_child(vera_name)

	vera_dialogue = RichTextLabel.new()
	vera_dialogue.bbcode_enabled = true
	vera_dialogue.fit_content = true
	UIStyleFactory.expand_horizontal(vera_dialogue)
	vera_dialogue.custom_minimum_size.y = 60
	vera_dialogue.add_theme_font_size_override("normal_font_size", 14)
	vera_dialogue.add_theme_color_override("default_color", Color(0.82, 0.78, 0.72))
	dialogue_vbox.add_child(vera_dialogue)

func _start_vera_portrait_animation() -> void:
	"""Start smooth _process-based breathing animation on VERA portrait"""
	if not vera_portrait or not is_instance_valid(vera_portrait):
		return

	# Reset scale to base before starting breathing animation
	# This ensures clean transition without visual jumping
	vera_portrait.scale = Vector2.ONE
	_vera_breathing_time = 0.0
	_vera_breathing_enabled = true

func _create_button_bar(parent: Control) -> void:
	## Create the bottom button bar
	var button_container := UIStyleFactory.create_hbox(20)
	parent.add_child(button_container)

	# Back button
	back_button = _create_styled_button("BACK", Color(0.4, 0.35, 0.35), 150)
	back_button.pressed.connect(_on_back_pressed)
	button_container.add_child(back_button)

	# Spacer
	var spacer := Control.new()
	UIStyleFactory.expand_horizontal(spacer)
	button_container.add_child(spacer)

	# Confirm button
	confirm_button = _create_styled_button("BEGIN JOURNEY", Color(0.3, 0.5, 0.4), 220)
	confirm_button.pressed.connect(_on_confirm_pressed)
	button_container.add_child(confirm_button)


func _create_styled_button(text: String, color: Color, min_width: int = 150) -> Button:
	## Create a styled button
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(min_width, 55)
	UIStyleFactory.apply_color_button_style(button, color)
	return button


# =============================================================================
# HERO SELECTION
# =============================================================================


func _select_hero(index: int) -> void:
	## Select a hero and update all displays
	if index < 0 or index >= HERO_IDS.size():
		return

	selected_hero_index = index
	var hero_id := HERO_IDS[index]
	var data: HeroData = hero_data_cache.get(hero_id)

	if not data:
		push_warning("No data for hero: %s" % hero_id)
		return

	_update_card_highlights()
	_animate_hero_change(data)
	_update_info_panel(data)
	_update_monster_showcase(data)
	_update_vera_dialogue(data)


func _update_card_highlights() -> void:
	## Update visual state of all hero cards
	for i in range(hero_cards.size()):
		var card := hero_cards[i] as PanelContainer
		if not card:
			continue

		var hero_id := HERO_IDS[i]
		var data: HeroData = hero_data_cache.get(hero_id)
		var class_color: Color = CLASS_COLORS.get(data.hero_class if data else "", Color.WHITE)
		
		# Apply selected or normal style based on selection state
		var style: StyleBoxFlat
		if i == selected_hero_index:
			style = UIStyleFactory.create_hero_card_selected(class_color)
		else:
			style = UIStyleFactory.create_hero_card_normal(class_color)
		card.add_theme_stylebox_override("panel", style)


func _animate_hero_change(data: HeroData) -> void:
	## Animate the hero portrait change - AAA QUALITY with smooth transitions
	if _selection_tween and _selection_tween.is_valid():
		_selection_tween.kill()

	# Stop breathing animation during hero change to avoid conflicts
	_stop_breathing_animation()

	_selection_tween = create_tween()
	_selection_tween.set_ease(Tween.EASE_OUT)

	# Fade out with subtle scale down
	_selection_tween.set_parallel(true)
	_selection_tween.tween_property(hero_portrait, "modulate:a", 0.0, 0.15)
	_selection_tween.tween_property(hero_portrait, "scale", Vector2(0.95, 0.95), 0.15)
	_selection_tween.set_parallel(false)

	# Change content
	_selection_tween.tween_callback(
		func():
			# Load portrait
			if data.battle_sprite_path != "" and ResourceLoader.exists(data.battle_sprite_path):
				hero_portrait.texture = load(data.battle_sprite_path)
			elif data.sprite_path != "" and ResourceLoader.exists(data.sprite_path):
				hero_portrait.texture = load(data.sprite_path)

			# CRITICAL FIX: Set pivot FIRST at scale 1.0 to prevent visual jumping
			# The pivot determines the center point for scale transforms
			# Changing pivot while scaled != 1.0 causes position shifts
			hero_portrait.scale = Vector2.ONE  # Reset to 1.0 before pivot change

			if hero_portrait.texture:
				var tex_size: Vector2 = hero_portrait.texture.get_size()
				# Scale down to fit in container (400x450 area)
				var scale_factor: float = minf(400.0 / tex_size.x, 450.0 / tex_size.y)
				var display_size: Vector2 = tex_size * scale_factor
				# Set pivot to center of displayed size
				hero_portrait.pivot_offset = display_size / 2.0
			else:
				# Fallback pivot for missing textures
				hero_portrait.pivot_offset = Vector2(200, 225)

			# NOW set the starting scale for fade-in animation (after pivot is correct)
			hero_portrait.scale = Vector2(0.9, 0.9)

			# Update labels
			hero_name_label.text = data.display_name.to_upper()

			var hero_class_name := (
				data.hero_class if data.hero_class != "" else data.role.to_upper()
			)
			hero_class_label.text = hero_class_name
			var class_color: Color = CLASS_COLORS.get(hero_class_name, Color.WHITE)
			hero_class_label.add_theme_color_override("font_color", class_color)

			hero_title_label.text = '"' + data.title + '"'
	)

	# Fade in with smooth elastic pop - AAA quality entrance
	_selection_tween.set_parallel(true)
	_selection_tween.tween_property(hero_portrait, "modulate:a", 1.0, 0.2)
	(
		_selection_tween
		. tween_property(hero_portrait, "scale", Vector2(1.05, 1.05), 0.18)
		. set_ease(Tween.EASE_OUT)
		. set_trans(Tween.TRANS_BACK)
	)
	_selection_tween.set_parallel(false)

	# Settle to base scale with slight overshoot for polish
	_selection_tween.tween_property(hero_portrait, "scale", Vector2(0.98, 0.98), 0.08)
	_selection_tween.tween_property(hero_portrait, "scale", Vector2.ONE, 0.06)

	# Small delay before breathing starts for clean transition
	_selection_tween.tween_interval(0.1)
	_selection_tween.tween_callback(_start_breathing_animation)


func _update_info_panel(data: HeroData) -> void:
	## Update the info panel with hero data
	# Path & Brand - use centralized color systems
	var path_color: Color = PathSystem.get_path_color(data.primary_path)
	path_label.text = Enums.get_path_name(data.primary_path)
	path_label.add_theme_color_override("font_color", path_color)

	var brand_color: Color = BrandSystem.get_brand_color(data.primary_brand)
	brand_label.text = Enums.get_brand_name(data.primary_brand)
	brand_label.add_theme_color_override("font_color", brand_color)

	# Description
	hero_description.text = data.description

	# Stats
	for child in stats_grid.get_children():
		child.queue_free()

	var stats := [
		["HP", data.base_hp, Color(0.4, 0.9, 0.4)],
		["MP", data.base_mp, Color(0.4, 0.6, 1.0)],
		["ATK", data.base_attack, Color(1.0, 0.5, 0.4)],
		["DEF", data.base_defense, Color(0.5, 0.7, 1.0)],
		["MAG", data.base_magic, Color(0.8, 0.5, 1.0)],
		["RES", data.base_resistance, Color(0.6, 0.8, 0.9)],
		["SPD", data.base_speed, Color(0.5, 1.0, 0.7)],
		["LCK", data.base_luck, Color(1.0, 0.9, 0.4)]
	]

	for stat_info in stats:
		var stat_name: String = stat_info[0]
		var stat_value: int = stat_info[1]
		var stat_color: Color = stat_info[2]

		var name_lbl := UIStyleFactory.create_label(stat_name, 12, Color(0.55, 0.5, 0.45))
		stats_grid.add_child(name_lbl)

		var value_lbl := UIStyleFactory.create_label(str(stat_value), 14, stat_color)
		stats_grid.add_child(value_lbl)

	# Synergy explanation
	synergy_label.text = (
		data.synergy_explanation
		if data.synergy_explanation != ""
		else "Monsters of aligned brands gain bonus effectiveness when fighting alongside this hero."
	)


func _update_monster_showcase(data: HeroData) -> void:
	## Update the monster showcase with recommended monsters
	# Clear existing
	for child in monster_showcase.get_children():
		child.queue_free()

	# Add recommended monsters
	for monster_id in data.recommended_monsters:
		var card := _create_monster_card(monster_id)
		monster_showcase.add_child(card)


func _update_vera_dialogue(data: HeroData) -> void:
	## Update VERA's dialogue based on selected hero
	var dialogues := {
		"bastion":
		"[color=#9999bb]Bastion walks the IRONBOUND path.[/color] A living fortress. Monsters of the IRON brand will find their defensive capabilities amplified under their command. The Veil's corruption breaks against such resolve.",
		"rend":
		"[color=#cc6666]Rend follows the FANGBORN path.[/color] Pure predatory instinct. SAVAGE brand monsters will hunt with terrifying efficiency alongside this one. Blood calls to blood.",
		"marrow":
		"[color=#9966aa]Marrow treads the VOIDTOUCHED path.[/color] They understand the exchange of life force. LEECH brand monsters will drain with greater potency, their stolen vitality flowing to heal allies.",
		"mirage":
		"[color=#66aacc]Mirage dances the UNCHAINED path.[/color] Reality bends around them. SURGE and DREAD brand monsters will find their speed and terror effects magnified. What is real becomes... negotiable."
	}

	var hero_id := HERO_IDS[selected_hero_index]
	_show_vera_dialogue(dialogues.get(hero_id, "Choose wisely, Hunter."))


func _show_vera_dialogue(text: String) -> void:
	## Show VERA dialogue with dynamic typing effect and portrait reaction
	if not vera_dialogue:
		push_warning("_show_vera_dialogue called before vera_dialogue was created")
		return
	
	if _vera_tween and _vera_tween.is_valid():
		_vera_tween.kill()

	# Flash the portrait when speaking - kill previous flash to prevent conflicts
	if vera_portrait:
		if _vera_flash_tween and _vera_flash_tween.is_valid():
			_vera_flash_tween.kill()
		_vera_flash_tween = create_tween()
		_vera_flash_tween.tween_property(vera_portrait, "modulate", Color(1.3, 1.1, 1.4), 0.15)
		_vera_flash_tween.tween_property(vera_portrait, "modulate", Color(1.0, 1.0, 1.0), 0.3)
	
	# Slide in effect for text
	vera_dialogue.modulate.a = 0
	vera_dialogue.text = ""
	vera_dialogue.visible_characters = 0
	vera_dialogue.text = text

	_vera_tween = create_tween()
	_vera_tween.set_parallel(false)
	# Fade in
	_vera_tween.tween_property(vera_dialogue, "modulate:a", 1.0, 0.2)
	# Type out text (faster for better UX)
	_vera_tween.tween_property(
		vera_dialogue, "visible_characters", text.length(), text.length() * 0.015
	)


# =============================================================================
# ANIMATIONS
# =============================================================================


func _setup_animations() -> void:
	## Setup idle animations
	_start_breathing_animation()


func _start_breathing_animation() -> void:
	"""Start smooth _process-based breathing animation on hero portrait"""
	if not hero_portrait or not is_instance_valid(hero_portrait):
		return

	# CRITICAL FIX: Ensure scale is exactly 1.0 before starting breathing
	# This prevents glitches when transitioning from hero change animation
	hero_portrait.scale = Vector2.ONE

	# Reset breathing time to 0 for a clean sine wave start
	# Starting at 0 means we begin at the midpoint of the breath cycle (natural)
	_breathing_time = 0.0
	_breathing_enabled = true

func _stop_breathing_animation() -> void:
	"""Stop breathing animation and reset scale"""
	_breathing_enabled = false

	# Reset scale to base
	if hero_portrait and is_instance_valid(hero_portrait):
		hero_portrait.scale = Vector2.ONE

# =============================================================================
# INPUT HANDLING
# =============================================================================


func _on_card_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Click locks in the selection
		_selection_locked = true
		_select_hero(index)
		if index < hero_cards.size():
			hero_cards[index].grab_focus()


func _on_card_hover(index: int) -> void:
	# Only change selection on hover if not locked
	if not _selection_locked:
		_hovered_index = index
		_select_hero(index)
	else:
		# Just update visual hover state without changing selection
		_hovered_index = index
		_update_card_hover_visual(index)


func _on_card_focus(index: int) -> void:
	# Keyboard focus should always select (and lock)
	_selection_locked = true
	_select_hero(index)


func _on_card_unhover(index: int) -> void:
	## Handle mouse exiting a card
	if _hovered_index == index:
		_hovered_index = -1
		_update_card_hover_visual(-1)


func _update_card_hover_visual(hovered_index: int) -> void:
	## Update hover visual without changing selection
	for i in range(hero_cards.size()):
		var card := hero_cards[i] as PanelContainer
		if not card:
			continue

		# Skip selected card - it has its own highlight
		if i == selected_hero_index:
			continue

		var hero_id := HERO_IDS[i]
		var data: HeroData = hero_data_cache.get(hero_id)
		var class_color: Color = CLASS_COLORS.get(data.hero_class if data else "", Color.WHITE)
		
		# Apply hovered or normal style based on hover state
		var style: StyleBoxFlat
		if i == hovered_index:
			style = UIStyleFactory.create_hero_card_hovered(class_color)
		else:
			style = UIStyleFactory.create_hero_card_normal(class_color)
		card.add_theme_stylebox_override("panel", style)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		var new_index := (selected_hero_index - 1 + HERO_IDS.size()) % HERO_IDS.size()
		_select_hero(new_index)
		if new_index < hero_cards.size():
			hero_cards[new_index].grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		var new_index := (selected_hero_index + 1) % HERO_IDS.size()
		_select_hero(new_index)
		if new_index < hero_cards.size():
			hero_cards[new_index].grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_on_confirm_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()


# =============================================================================
# BUTTON HANDLERS
# =============================================================================

var _confirmation_popup: PanelContainer = null


func _on_confirm_pressed() -> void:
	var hero_id := HERO_IDS[selected_hero_index]
	var data: HeroData = hero_data_cache.get(hero_id)
	var hero_name := data.display_name if data else hero_id.capitalize()

	# Show confirmation popup
	_show_confirmation_popup(hero_name, hero_id)


func _show_confirmation_popup(hero_name: String, hero_id: String) -> void:
	## Show confirmation dialog before starting the game
	# Remove existing popup if any
	if _confirmation_popup and is_instance_valid(_confirmation_popup):
		_confirmation_popup.queue_free()

	# Create popup overlay - use Control instead of ColorRect for proper child centering
	var overlay := Control.new()
	overlay.name = "ConfirmOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# Add dark background
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.6)
	overlay.add_child(bg)

	# Use CenterContainer to properly center the popup
	var center := CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	# Create popup panel
	_confirmation_popup = UIStyleFactory.create_styled_panel(UIStyleFactory.create_confirmation_popup_style())
	_confirmation_popup.name = "ConfirmationPopup"
	_confirmation_popup.custom_minimum_size = Vector2(500, 240)
	center.add_child(_confirmation_popup)

	var vbox := UIStyleFactory.create_vbox(20)
	_confirmation_popup.add_child(vbox)

	# Title
	var title := UIStyleFactory.create_centered_label("CONFIRM SELECTION", 24, Color(0.9, 0.8, 0.6))
	vbox.add_child(title)

	# Message
	var message := UIStyleFactory.create_centered_label(
		"Are you sure you want to choose\n%s as your champion?" % hero_name, 16, Color(0.8, 0.75, 0.7)
	)
	vbox.add_child(message)

	# Button container
	var button_hbox := UIStyleFactory.create_hbox(30)
	button_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(button_hbox)

	# Cancel button
	var cancel_btn := _create_styled_button("CANCEL", Color(0.5, 0.35, 0.35), 140)
	cancel_btn.pressed.connect(_on_confirmation_cancel.bind(overlay))
	button_hbox.add_child(cancel_btn)

	# Confirm button
	var confirm_btn := _create_styled_button("CONFIRM", Color(0.35, 0.5, 0.4), 140)
	confirm_btn.pressed.connect(_on_confirmation_confirm.bind(hero_id, overlay))
	button_hbox.add_child(confirm_btn)

	# Focus confirm button
	confirm_btn.grab_focus()

	# Animate popup entrance
	_confirmation_popup.modulate.a = 0.0
	_confirmation_popup.scale = Vector2(0.8, 0.8)
	# Set pivot to center of the popup for proper scale animation
	_confirmation_popup.pivot_offset = _confirmation_popup.custom_minimum_size / 2

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_confirmation_popup, "modulate:a", 1.0, 0.2)
	(
		tween
		. tween_property(_confirmation_popup, "scale", Vector2.ONE, 0.25)
		. set_ease(Tween.EASE_OUT)
		. set_trans(Tween.TRANS_BACK)
	)


func _on_confirmation_cancel(overlay: Control) -> void:
	## Cancel the confirmation and close popup
	if overlay and is_instance_valid(overlay):
		overlay.queue_free()
	_confirmation_popup = null
	confirm_button.grab_focus()


func _on_confirmation_confirm(hero_id: String, overlay: Control) -> void:
	## Confirm selection and start the game
	print("[CHARACTER_SELECT] Confirmed hero: %s" % hero_id)

	# Close popup
	if overlay and is_instance_valid(overlay):
		overlay.queue_free()
	_confirmation_popup = null

	# Store selection
	GameManager.set_selected_hero(hero_id)

	# Initialize player character
	var player := GameManager.initialize_player_character()
	if player:
		print("[CHARACTER_SELECT] Player character created: %s" % player.character_name)
		# Add 4 starting monsters based on hero's path/brand alignment
		var starter_monsters := _get_starter_monsters_for_hero(hero_id)
		for monster_id in starter_monsters:
			GameManager.add_monster_to_collection(monster_id, 5)  # Level 5 starters
			print("[CHARACTER_SELECT] Added starter monster: %s" % monster_id)


		# Set tutorial flag for first battle
		GameManager.set_story_flag("tutorial_battle_pending", true)
		GameManager.set_story_flag("vera_introduced", true)

		character_selected.emit(hero_id)

		# Go to tutorial battle
		SceneManager.change_scene("res://scenes/test/test_battle.tscn")
	else:
		push_error("[CHARACTER_SELECT] Failed to create player character!")


func _on_back_pressed() -> void:
	selection_cancelled.emit()
	SceneManager.goto_main_menu()


func _get_starter_monsters_for_hero(hero_id: String) -> Array[String]:
	## Returns 4 starter monsters appropriate for the hero's path and brand alignment
	match hero_id:
		"bastion":
			# IRONBOUND path / IRON brand - Defensive monsters
			# chainbound (IRON), skitter_teeth (IRON), the_bulwark (IRON), ironjaw (BLOODIRON hybrid)
			return ["chainbound", "skitter_teeth", "the_bulwark", "ironjaw"]
		"rend":
			# FANGBORN path / SAVAGE brand - Aggressive attack monsters
			# mawling (SAVAGE), ravener (SAVAGE), ironjaw (BLOODIRON hybrid), needlefang (VENOMSTRIKE - fast assassin)
			return ["mawling", "ravener", "ironjaw", "needlefang"]
		"marrow":
			# VOIDTOUCHED path / LEECH brand - Life-drain and support monsters
			# gluttony_polyp (LEECH), bloodshade (NIGHTLEECH), hollow (DREAD - void), sporecaller (VENOM - debuffer)
			return ["gluttony_polyp", "bloodshade", "hollow", "sporecaller"]
		"mirage":
			# UNCHAINED path / SURGE+DREAD brands - Speed and terror monsters
			# flicker (SURGE), crackling (SURGE), voltgeist (TERRORFLUX), the_weeping (DREAD)
			return ["flicker", "crackling", "voltgeist", "the_weeping"]
		_:
			# Fallback - balanced starter set
			push_warning("[CHARACTER_SELECT] Unknown hero_id: %s, using fallback starters" % hero_id)
			return ["mawling", "chainbound", "crackling", "hollow"]


# =============================================================================
# CLEANUP
# =============================================================================


func _exit_tree() -> void:
	# Stop all breathing animations and reset states
	_stop_breathing_animation()
	_vera_breathing_enabled = false

	# Reset VERA portrait scale to prevent any residual state
	if vera_portrait and is_instance_valid(vera_portrait):
		vera_portrait.scale = Vector2.ONE

	# Kill remaining tweens to prevent orphaned callbacks
	if _selection_tween and _selection_tween.is_valid():
		_selection_tween.kill()
	if _vera_tween and _vera_tween.is_valid():
		_vera_tween.kill()
	if _vera_flash_tween and _vera_flash_tween.is_valid():
		_vera_flash_tween.kill()
