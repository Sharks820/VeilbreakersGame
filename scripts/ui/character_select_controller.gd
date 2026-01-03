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
	"VEILGUARD": Color(0.4, 0.5, 0.7),      # Steel blue
	"BLOODHUNTER": Color(0.8, 0.2, 0.2),    # Blood red
	"SOULWEAVER": Color(0.5, 0.3, 0.7),     # Soul purple
	"VOIDWALKER": Color(0.3, 0.7, 0.9)      # Ethereal cyan
}

# Path colors
const PATH_COLORS: Dictionary = {
	0: Color(0.6, 0.65, 0.75),  # IRONBOUND - Steel
	1: Color(0.85, 0.4, 0.3),   # FANGBORN - Blood
	2: Color(0.6, 0.3, 0.7),    # VOIDTOUCHED - Void
	3: Color(0.9, 0.8, 0.3)     # UNCHAINED - Lightning
}

# Brand colors
const BRAND_COLORS: Dictionary = {
	0: Color(1.0, 0.4, 0.3),    # SAVAGE - Red
	1: Color(0.6, 0.7, 0.8),    # IRON - Steel
	2: Color(0.4, 0.9, 0.3),    # VENOM - Green
	3: Color(0.3, 0.8, 1.0),    # SURGE - Blue
	4: Color(0.6, 0.3, 0.8),    # DREAD - Purple
	5: Color(0.8, 0.2, 0.4)     # LEECH - Dark red
}

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

# Breathing animation state (using _process for smooth per-frame animation)
var _breathing_time: float = 0.0
var _breathing_enabled: bool = false

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
	# Smooth breathing animation using sine wave - no frame skipping
	if _breathing_enabled and hero_portrait:
		_breathing_time += delta
		# Gentle sine wave: 1.5 Hz frequency, 2% amplitude
		var breath: float = sin(_breathing_time * 1.5) * 0.02
		hero_portrait.scale = Vector2(1.0 + breath, 1.0 + breath)

func _load_all_data() -> void:
	"""Load all hero and monster data"""
	# Load heroes
	for hero_id in HERO_IDS:
		var path := "res://data/heroes/%s.tres" % hero_id
		if ResourceLoader.exists(path):
			var data := load(path) as HeroData
			if data:
				hero_data_cache[hero_id] = data
	
	# Load monsters for showcase
	var monster_ids := ["chainbound", "ironjaw", "the_bulwark", "ravener", "mawling", 
					   "bloodshade", "the_weeping", "hollow", "gluttony_polyp", 
					   "flicker", "voltgeist", "crackling"]
	for monster_id in monster_ids:
		var path := "res://data/monsters/%s.tres" % monster_id
		if ResourceLoader.exists(path):
			var data := load(path)
			if data:
				monster_data_cache[monster_id] = data

func _build_ui() -> void:
	"""Build the complete AAA-quality UI"""
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
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	main_container.add_child(vbox)
	
	# === TITLE BAR ===
	_create_title_bar(vbox)
	
	# === MAIN CONTENT (Hero + Info + Monsters) ===
	var content_hbox := HBoxContainer.new()
	content_hbox.add_theme_constant_override("separation", 25)
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
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
	"""Create atmospheric dark background"""
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
	"""Create the title bar with game logo feel"""
	var title_container := HBoxContainer.new()
	title_container.add_theme_constant_override("separation", 20)
	parent.add_child(title_container)
	
	# Decorative line left
	var line_left := ColorRect.new()
	line_left.custom_minimum_size = Vector2(100, 2)
	line_left.color = Color(0.6, 0.5, 0.3, 0.5)
	line_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_container.add_child(line_left)
	
	# Title
	var title := Label.new()
	title.text = "CHOOSE YOUR CHAMPION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	title_container.add_child(title)
	
	# Decorative line right
	var line_right := ColorRect.new()
	line_right.custom_minimum_size = Vector2(100, 2)
	line_right.color = Color(0.6, 0.5, 0.3, 0.5)
	line_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_container.add_child(line_right)

func _create_hero_cards_panel() -> PanelContainer:
	"""Create the left panel with hero selection cards"""
	var panel := PanelContainer.new()
	panel.name = "HeroCardsPanel"
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.09, 0.95)
	style.border_color = Color(0.25, 0.2, 0.3, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	# Section header
	var header := Label.new()
	header.text = "CHAMPIONS"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	vbox.add_child(header)
	
	var sep := HSeparator.new()
	sep.modulate = Color(0.4, 0.35, 0.45, 0.5)
	vbox.add_child(sep)
	
	# Create hero cards
	for i in range(HERO_IDS.size()):
		var card := _create_hero_card(HERO_IDS[i], i)
		vbox.add_child(card)
		hero_cards.append(card)
	
	return panel

func _create_hero_card(hero_id: String, index: int) -> PanelContainer:
	"""Create a single hero selection card"""
	var card := PanelContainer.new()
	card.name = "HeroCard_%s" % hero_id
	card.custom_minimum_size = Vector2(230, 110)
	card.focus_mode = Control.FOCUS_ALL
	
	var data: HeroData = hero_data_cache.get(hero_id)
	if not data:
		return card
	
	var class_color: Color = CLASS_COLORS.get(data.hero_class, Color.WHITE)
	
	# Card style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.border_color = class_color.darkened(0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", style)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	card.add_child(hbox)
	
	# Portrait frame
	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(75, 75)
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.1, 0.08, 0.14)
	frame_style.border_color = class_color
	frame_style.set_border_width_all(2)
	frame_style.set_corner_radius_all(6)
	portrait_frame.add_theme_stylebox_override("panel", frame_style)
	hbox.add_child(portrait_frame)
	
	# Portrait image
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(71, 71)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if data.sprite_path != "" and ResourceLoader.exists(data.sprite_path):
		portrait.texture = load(data.sprite_path)
	portrait_frame.add_child(portrait)
	
	# Info column
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 3)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)
	
	# Name
	var name_label := Label.new()
	name_label.text = data.display_name.to_upper()
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.85))
	info.add_child(name_label)
	
	# Class
	var class_label := Label.new()
	class_label.text = data.hero_class if data.hero_class != "" else data.role.to_upper()
	class_label.add_theme_font_size_override("font_size", 13)
	class_label.add_theme_color_override("font_color", class_color)
	info.add_child(class_label)
	
	# Path indicator
	var path_label := Label.new()
	path_label.text = Enums.get_path_name(data.primary_path)
	path_label.add_theme_font_size_override("font_size", 11)
	path_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	info.add_child(path_label)
	
	# Connect signals
	card.gui_input.connect(_on_card_input.bind(index))
	card.mouse_entered.connect(_on_card_hover.bind(index))
	card.mouse_exited.connect(_on_card_unhover.bind(index))
	card.focus_entered.connect(_on_card_focus.bind(index))
	
	return card

func _create_hero_display() -> Control:
	"""Create the center panel with large hero display"""
	var container := Control.new()
	container.name = "HeroDisplay"
	
	# Dark backdrop
	var backdrop := PanelContainer.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	var backdrop_style := StyleBoxFlat.new()
	backdrop_style.bg_color = Color(0.05, 0.05, 0.08, 0.7)
	backdrop_style.set_corner_radius_all(16)
	backdrop.add_theme_stylebox_override("panel", backdrop_style)
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
	hero_portrait.pivot_offset = Vector2(200, 225)
	container.add_child(hero_portrait)
	
	# Name overlay at bottom
	var name_panel := PanelContainer.new()
	name_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	name_panel.offset_top = -140
	var name_style := StyleBoxFlat.new()
	name_style.bg_color = Color(0.02, 0.02, 0.04, 0.9)
	name_style.content_margin_left = 20
	name_style.content_margin_right = 20
	name_style.content_margin_top = 15
	name_style.content_margin_bottom = 15
	name_panel.add_theme_stylebox_override("panel", name_style)
	container.add_child(name_panel)
	
	var name_vbox := VBoxContainer.new()
	name_vbox.add_theme_constant_override("separation", 5)
	name_panel.add_child(name_vbox)
	
	# Hero name
	hero_name_label = Label.new()
	hero_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_name_label.add_theme_font_size_override("font_size", 42)
	hero_name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	name_vbox.add_child(hero_name_label)
	
	# Hero class
	hero_class_label = Label.new()
	hero_class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_class_label.add_theme_font_size_override("font_size", 22)
	name_vbox.add_child(hero_class_label)
	
	# Hero title
	hero_title_label = Label.new()
	hero_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_title_label.add_theme_font_size_override("font_size", 16)
	hero_title_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	name_vbox.add_child(hero_title_label)
	
	return container

func _create_info_panel() -> PanelContainer:
	"""Create the right panel with stats, path/brand info, and monster showcase"""
	var panel := PanelContainer.new()
	panel.name = "InfoPanel"
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.09, 0.95)
	style.border_color = Color(0.25, 0.2, 0.3, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	
	# === PATH & BRAND SECTION ===
	var alignment_section := _create_section_header("PATH & BRAND ALIGNMENT")
	vbox.add_child(alignment_section)
	
	var alignment_hbox := HBoxContainer.new()
	alignment_hbox.add_theme_constant_override("separation", 30)
	alignment_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(alignment_hbox)
	
	# Path display
	var path_vbox := VBoxContainer.new()
	path_vbox.add_theme_constant_override("separation", 4)
	alignment_hbox.add_child(path_vbox)
	
	var path_title := Label.new()
	path_title.text = "PATH"
	path_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	path_title.add_theme_font_size_override("font_size", 11)
	path_title.add_theme_color_override("font_color", Color(0.5, 0.45, 0.4))
	path_vbox.add_child(path_title)
	
	path_label = Label.new()
	path_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	path_label.add_theme_font_size_override("font_size", 18)
	path_vbox.add_child(path_label)
	
	# Arrow
	var arrow := Label.new()
	arrow.text = "→"
	arrow.add_theme_font_size_override("font_size", 28)
	arrow.add_theme_color_override("font_color", Color(0.4, 0.35, 0.3))
	alignment_hbox.add_child(arrow)
	
	# Brand display
	var brand_vbox := VBoxContainer.new()
	brand_vbox.add_theme_constant_override("separation", 4)
	alignment_hbox.add_child(brand_vbox)
	
	var brand_title := Label.new()
	brand_title.text = "ALIGNED BRAND"
	brand_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand_title.add_theme_font_size_override("font_size", 11)
	brand_title.add_theme_color_override("font_color", Color(0.5, 0.45, 0.4))
	brand_vbox.add_child(brand_title)
	
	brand_label = Label.new()
	brand_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand_label.add_theme_font_size_override("font_size", 18)
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
	
	monster_showcase = HBoxContainer.new()
	monster_showcase.add_theme_constant_override("separation", 15)
	monster_showcase.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(monster_showcase)
	
	return panel

func _create_section_header(title: String) -> VBoxContainer:
	"""Create a styled section header"""
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)
	
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.55, 0.5, 0.45))
	container.add_child(label)
	
	var sep := HSeparator.new()
	sep.modulate = Color(0.35, 0.3, 0.4, 0.6)
	container.add_child(sep)
	
	return container

func _create_monster_card(monster_id: String) -> PanelContainer:
	"""Create a small monster showcase card"""
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(110, 130)
	
	var monster_data = monster_data_cache.get(monster_id)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	style.border_color = Color(0.3, 0.25, 0.35, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	card.add_child(vbox)
	
	# Monster sprite
	var sprite_container := CenterContainer.new()
	sprite_container.custom_minimum_size.y = 70
	vbox.add_child(sprite_container)
	
	var sprite := TextureRect.new()
	sprite.custom_minimum_size = Vector2(60, 60)
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var sprite_path := "res://assets/sprites/monsters/%s.png" % monster_id
	if ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
	sprite_container.add_child(sprite)
	
	# Monster name
	var name_label := Label.new()
	name_label.text = monster_id.capitalize().replace("_", " ")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.75))
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
			var brand_indicator := Label.new()
			brand_indicator.text = brand_name
			brand_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			brand_indicator.add_theme_font_size_override("font_size", 9)
			brand_indicator.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
			vbox.add_child(brand_indicator)
	
	return card

func _create_vera_panel(parent: Control) -> void:
	"""Create the VERA introduction panel at the bottom - dynamic and engaging"""
	vera_panel = PanelContainer.new()
	vera_panel.name = "VERAPanel"
	vera_panel.custom_minimum_size.y = 120
	
	# Dark panel with glowing purple border
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.02, 0.06, 0.98)
	style.border_color = Color(0.5, 0.3, 0.6, 0.9)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.4, 0.2, 0.5, 0.4)
	style.shadow_size = 10
	style.content_margin_left = 25
	style.content_margin_right = 25
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	vera_panel.add_theme_stylebox_override("panel", style)
	parent.add_child(vera_panel)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 25)
	vera_panel.add_child(hbox)
	
	# VERA portrait - larger with animated glow
	var portrait_frame := PanelContainer.new()
	portrait_frame.name = "PortraitFrame"
	portrait_frame.custom_minimum_size = Vector2(90, 90)
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.06, 0.04, 0.1)
	frame_style.border_color = Color(0.6, 0.4, 0.7)
	frame_style.set_border_width_all(3)
	frame_style.set_corner_radius_all(45)  # Circular
	frame_style.shadow_color = Color(0.5, 0.3, 0.6, 0.5)
	frame_style.shadow_size = 8
	portrait_frame.add_theme_stylebox_override("panel", frame_style)
	hbox.add_child(portrait_frame)
	
	vera_portrait = TextureRect.new()
	vera_portrait.custom_minimum_size = Vector2(84, 84)
	vera_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	vera_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vera_portrait.pivot_offset = Vector2(42, 42)  # Center pivot for animations
	if ResourceLoader.exists("res://assets/characters/vera/vera_interface.png"):
		vera_portrait.texture = load("res://assets/characters/vera/vera_interface.png")
	portrait_frame.add_child(vera_portrait)
	
	# Start portrait pulse animation
	_start_vera_portrait_animation()
	
	# VERA dialogue section
	var dialogue_vbox := VBoxContainer.new()
	dialogue_vbox.add_theme_constant_override("separation", 8)
	dialogue_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(dialogue_vbox)
	
	# VERA name with glowing effect
	var vera_name := Label.new()
	vera_name.name = "VERAName"
	vera_name.text = "⬡ V.E.R.A. ⬡"
	vera_name.add_theme_font_size_override("font_size", 16)
	vera_name.add_theme_color_override("font_color", Color(0.7, 0.5, 0.8))
	vera_name.add_theme_color_override("font_outline_color", Color(0.3, 0.2, 0.4))
	vera_name.add_theme_constant_override("outline_size", 2)
	dialogue_vbox.add_child(vera_name)
	
	vera_dialogue = RichTextLabel.new()
	vera_dialogue.bbcode_enabled = true
	vera_dialogue.fit_content = true
	vera_dialogue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vera_dialogue.custom_minimum_size.y = 60
	vera_dialogue.add_theme_font_size_override("normal_font_size", 14)
	vera_dialogue.add_theme_color_override("default_color", Color(0.82, 0.78, 0.72))
	dialogue_vbox.add_child(vera_dialogue)

var _vera_portrait_tween: Tween = null

func _start_vera_portrait_animation() -> void:
	"""Animate VERA portrait with subtle pulse and glow"""
	if _vera_portrait_tween and _vera_portrait_tween.is_valid():
		_vera_portrait_tween.kill()
	
	if not vera_portrait:
		return
	
	# Subtle breathing/pulse effect - larger scale range for smoother visual
	_vera_portrait_tween = create_tween().set_loops()
	_vera_portrait_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)  # Smoother processing
	_vera_portrait_tween.tween_property(vera_portrait, "scale", Vector2(1.05, 1.05), 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_vera_portrait_tween.tween_property(vera_portrait, "scale", Vector2(1.0, 1.0), 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _create_button_bar(parent: Control) -> void:
	"""Create the bottom button bar"""
	var button_container := HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 20)
	parent.add_child(button_container)
	
	# Back button
	back_button = _create_styled_button("BACK", Color(0.4, 0.35, 0.35), 150)
	back_button.pressed.connect(_on_back_pressed)
	button_container.add_child(back_button)
	
	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_container.add_child(spacer)
	
	# Confirm button
	confirm_button = _create_styled_button("BEGIN JOURNEY", Color(0.3, 0.5, 0.4), 220)
	confirm_button.pressed.connect(_on_confirm_pressed)
	button_container.add_child(confirm_button)

func _create_styled_button(text: String, color: Color, min_width: int = 150) -> Button:
	"""Create a styled button"""
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(min_width, 55)
	
	var normal := StyleBoxFlat.new()
	normal.bg_color = color.darkened(0.3)
	normal.border_color = color
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)
	
	var hover := StyleBoxFlat.new()
	hover.bg_color = color.darkened(0.1)
	hover.border_color = color.lightened(0.2)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(8)
	hover.shadow_color = color
	hover.shadow_color.a = 0.4
	hover.shadow_size = 8
	
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = color
	pressed.border_color = color.lightened(0.3)
	pressed.set_border_width_all(2)
	pressed.set_corner_radius_all(8)
	
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color.WHITE)
	
	return button

# =============================================================================
# HERO SELECTION
# =============================================================================

func _select_hero(index: int) -> void:
	"""Select a hero and update all displays"""
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
	"""Update visual state of all hero cards"""
	for i in range(hero_cards.size()):
		var card := hero_cards[i] as PanelContainer
		if not card:
			continue
		
		var hero_id := HERO_IDS[i]
		var data: HeroData = hero_data_cache.get(hero_id)
		var class_color: Color = CLASS_COLORS.get(data.hero_class if data else "", Color.WHITE)
		
		var style := card.get_theme_stylebox("panel") as StyleBoxFlat
		if not style:
			continue
		
		if i == selected_hero_index:
			style.border_color = class_color
			style.set_border_width_all(3)
			style.shadow_color = class_color
			style.shadow_color.a = 0.5
			style.shadow_size = 10
			style.bg_color = Color(0.12, 0.1, 0.16, 0.98)
		else:
			style.border_color = class_color.darkened(0.5)
			style.set_border_width_all(2)
			style.shadow_size = 0
			style.bg_color = Color(0.08, 0.08, 0.12, 0.95)

func _animate_hero_change(data: HeroData) -> void:
	"""Animate the hero portrait change"""
	if _selection_tween and _selection_tween.is_valid():
		_selection_tween.kill()
	
	_selection_tween = create_tween()
	
	# Fade out
	_selection_tween.tween_property(hero_portrait, "modulate:a", 0.0, 0.12)
	
	# Change content
	_selection_tween.tween_callback(func():
		# Load portrait
		if data.battle_sprite_path != "" and ResourceLoader.exists(data.battle_sprite_path):
			hero_portrait.texture = load(data.battle_sprite_path)
		elif data.sprite_path != "" and ResourceLoader.exists(data.sprite_path):
			hero_portrait.texture = load(data.sprite_path)
		
		# Update labels
		hero_name_label.text = data.display_name.to_upper()
		
		var hero_class_name := data.hero_class if data.hero_class != "" else data.role.to_upper()
		hero_class_label.text = hero_class_name
		var class_color: Color = CLASS_COLORS.get(hero_class_name, Color.WHITE)
		hero_class_label.add_theme_color_override("font_color", class_color)
		
		hero_title_label.text = "\"" + data.title + "\""
	)
	
	# Fade in with pop
	_selection_tween.tween_property(hero_portrait, "modulate:a", 1.0, 0.18)
	_selection_tween.parallel().tween_property(hero_portrait, "scale", Vector2(1.08, 1.08), 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_selection_tween.tween_property(hero_portrait, "scale", Vector2(1.0, 1.0), 0.08)

func _update_info_panel(data: HeroData) -> void:
	"""Update the info panel with hero data"""
	# Path & Brand
	var path_color: Color = PATH_COLORS.get(data.primary_path, Color.WHITE)
	path_label.text = Enums.get_path_name(data.primary_path)
	path_label.add_theme_color_override("font_color", path_color)
	
	var brand_color: Color = BRAND_COLORS.get(data.primary_brand, Color.WHITE)
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
		
		var name_lbl := Label.new()
		name_lbl.text = stat_name
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", Color(0.55, 0.5, 0.45))
		stats_grid.add_child(name_lbl)
		
		var value_lbl := Label.new()
		value_lbl.text = str(stat_value)
		value_lbl.add_theme_font_size_override("font_size", 14)
		value_lbl.add_theme_color_override("font_color", stat_color)
		stats_grid.add_child(value_lbl)
	
	# Synergy explanation
	synergy_label.text = data.synergy_explanation if data.synergy_explanation != "" else "Monsters of aligned brands gain bonus effectiveness when fighting alongside this hero."

func _update_monster_showcase(data: HeroData) -> void:
	"""Update the monster showcase with recommended monsters"""
	# Clear existing
	for child in monster_showcase.get_children():
		child.queue_free()
	
	# Add recommended monsters
	for monster_id in data.recommended_monsters:
		var card := _create_monster_card(monster_id)
		monster_showcase.add_child(card)

func _update_vera_dialogue(data: HeroData) -> void:
	"""Update VERA's dialogue based on selected hero"""
	var dialogues := {
		"bastion": "[color=#9999bb]Bastion walks the IRONBOUND path.[/color] A living fortress. Monsters of the IRON brand will find their defensive capabilities amplified under their command. The Veil's corruption breaks against such resolve.",
		"rend": "[color=#cc6666]Rend follows the FANGBORN path.[/color] Pure predatory instinct. SAVAGE brand monsters will hunt with terrifying efficiency alongside this one. Blood calls to blood.",
		"marrow": "[color=#9966aa]Marrow treads the VOIDTOUCHED path.[/color] They understand the exchange of life force. LEECH brand monsters will drain with greater potency, their stolen vitality flowing to heal allies.",
		"mirage": "[color=#66aacc]Mirage dances the UNCHAINED path.[/color] Reality bends around them. SURGE and DREAD brand monsters will find their speed and terror effects magnified. What is real becomes... negotiable."
	}
	
	var hero_id := HERO_IDS[selected_hero_index]
	_show_vera_dialogue(dialogues.get(hero_id, "Choose wisely, Hunter."))

func _show_vera_dialogue(text: String) -> void:
	"""Show VERA dialogue with dynamic typing effect and portrait reaction"""
	if _vera_tween and _vera_tween.is_valid():
		_vera_tween.kill()
	
	# Flash the portrait when speaking
	if vera_portrait:
		var flash_tween := create_tween()
		flash_tween.tween_property(vera_portrait, "modulate", Color(1.3, 1.1, 1.4), 0.15)
		flash_tween.tween_property(vera_portrait, "modulate", Color(1.0, 1.0, 1.0), 0.3)
	
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
	_vera_tween.tween_property(vera_dialogue, "visible_characters", text.length(), text.length() * 0.015)

# =============================================================================
# ANIMATIONS
# =============================================================================

func _setup_animations() -> void:
	"""Setup idle animations"""
	_start_breathing_animation()

func _start_breathing_animation() -> void:
	if not hero_portrait:
		return
	
	# Enable smooth per-frame breathing animation via _process()
	# This avoids the frame-skipping issues that tweens cause on small scale changes
	_breathing_time = 0.0
	_breathing_enabled = true
	hero_portrait.scale = Vector2(1.0, 1.0)

func _stop_breathing_animation() -> void:
	_breathing_enabled = false
	if hero_portrait:
		hero_portrait.scale = Vector2(1.0, 1.0)

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
	"""Handle mouse exiting a card"""
	if _hovered_index == index:
		_hovered_index = -1
		_update_card_hover_visual(-1)

func _update_card_hover_visual(hovered_index: int) -> void:
	"""Update hover visual without changing selection"""
	for i in range(hero_cards.size()):
		var card := hero_cards[i] as PanelContainer
		if not card:
			continue
		
		var style := card.get_theme_stylebox("panel") as StyleBoxFlat
		if not style:
			continue
		
		# If this is the hovered card (but not selected), show subtle hover effect
		if i == hovered_index and i != selected_hero_index:
			style.bg_color = Color(0.1, 0.09, 0.14, 0.98)  # Slightly brighter
		elif i != selected_hero_index:
			style.bg_color = Color(0.08, 0.08, 0.12, 0.95)  # Normal

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
	"""Show confirmation dialog before starting the game"""
	# Remove existing popup if any
	if _confirmation_popup and is_instance_valid(_confirmation_popup):
		_confirmation_popup.queue_free()
	
	# Create popup overlay
	var overlay := ColorRect.new()
	overlay.name = "ConfirmOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	add_child(overlay)
	
	# Create popup panel
	_confirmation_popup = PanelContainer.new()
	_confirmation_popup.name = "ConfirmationPopup"
	_confirmation_popup.set_anchors_preset(Control.PRESET_CENTER)
	_confirmation_popup.offset_left = -250
	_confirmation_popup.offset_right = 250
	_confirmation_popup.offset_top = -120
	_confirmation_popup.offset_bottom = 120
	
	var popup_style := StyleBoxFlat.new()
	popup_style.bg_color = Color(0.06, 0.06, 0.09, 0.98)
	popup_style.border_color = Color(0.5, 0.4, 0.6, 0.9)
	popup_style.set_border_width_all(3)
	popup_style.set_corner_radius_all(12)
	popup_style.shadow_color = Color(0.3, 0.2, 0.4, 0.6)
	popup_style.shadow_size = 20
	popup_style.content_margin_left = 30
	popup_style.content_margin_right = 30
	popup_style.content_margin_top = 25
	popup_style.content_margin_bottom = 25
	_confirmation_popup.add_theme_stylebox_override("panel", popup_style)
	overlay.add_child(_confirmation_popup)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	_confirmation_popup.add_child(vbox)
	
	# Title
	var title := Label.new()
	title.text = "CONFIRM SELECTION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	vbox.add_child(title)
	
	# Message
	var message := Label.new()
	message.text = "Are you sure you want to choose\n%s as your champion?" % hero_name
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 16)
	message.add_theme_color_override("font_color", Color(0.8, 0.75, 0.7))
	vbox.add_child(message)
	
	# Button container
	var button_hbox := HBoxContainer.new()
	button_hbox.add_theme_constant_override("separation", 30)
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
	_confirmation_popup.pivot_offset = _confirmation_popup.size / 2
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_confirmation_popup, "modulate:a", 1.0, 0.2)
	tween.tween_property(_confirmation_popup, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_confirmation_cancel(overlay: Control) -> void:
	"""Cancel the confirmation and close popup"""
	if overlay and is_instance_valid(overlay):
		overlay.queue_free()
	_confirmation_popup = null
	confirm_button.grab_focus()

func _on_confirmation_confirm(hero_id: String, overlay: Control) -> void:
	"""Confirm selection and start the game"""
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

# =============================================================================
# CLEANUP
# =============================================================================

func _exit_tree() -> void:
	# Stop breathing animation (now handled via _process, not tween)
	_stop_breathing_animation()
	if _selection_tween and _selection_tween.is_valid():
		_selection_tween.kill()
	if _vera_tween and _vera_tween.is_valid():
		_vera_tween.kill()
