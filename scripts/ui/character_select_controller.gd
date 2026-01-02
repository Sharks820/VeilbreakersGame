class_name CharacterSelectController
extends Control
## CharacterSelectController: AAA-quality hero selection screen with animated displays.
## Shows all 4 heroes with their Path/Brand alignment, stats, and specialties.

signal character_selected(hero_id: String)
signal selection_cancelled

# =============================================================================
# CONSTANTS
# =============================================================================

const HERO_IDS: Array[String] = ["bastion", "marrow", "rend", "mirage"]

# Path to Brand alignment mapping
const PATH_BRAND_MAP: Dictionary = {
	Enums.Path.IRONBOUND: Enums.Brand.IRON,
	Enums.Path.FANGBORN: Enums.Brand.SAVAGE,
	Enums.Path.VOIDTOUCHED: Enums.Brand.LEECH,
	Enums.Path.UNCHAINED: Enums.Brand.SURGE
}

# Role icons/colors
const ROLE_COLORS: Dictionary = {
	"Tank": Color(0.5, 0.6, 0.8),      # Steel blue
	"DPS": Color(0.9, 0.3, 0.3),       # Red
	"Healer": Color(0.4, 0.8, 0.5),    # Green
	"Illusionist": Color(0.6, 0.3, 0.8) # Purple
}

# =============================================================================
# NODE REFERENCES
# =============================================================================

var hero_cards: Array[PanelContainer] = []
var selected_hero_index: int = 0
var hero_data_cache: Dictionary = {}  # hero_id -> HeroData

# Main display elements
var main_display: Control = null
var hero_sprite: TextureRect = null
var hero_name_label: Label = null
var hero_title_label: Label = null
var hero_description: RichTextLabel = null
var stats_container: GridContainer = null
var skills_container: VBoxContainer = null
var path_brand_display: HBoxContainer = null

# Buttons
var confirm_button: Button = null
var back_button: Button = null

# Animation state
var _breathing_tween: Tween = null
var _selection_tween: Tween = null

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_load_hero_data()
	_build_ui()
	_setup_animations()
	_select_hero(0)
	
	# Grab focus on first card
	if not hero_cards.is_empty():
		hero_cards[0].grab_focus()

func _load_hero_data() -> void:
	"""Load all hero data resources"""
	for hero_id in HERO_IDS:
		var path := "res://data/heroes/%s.tres" % hero_id
		if ResourceLoader.exists(path):
			var data := load(path) as HeroData
			if data:
				hero_data_cache[hero_id] = data
				print("[CHARACTER_SELECT] Loaded hero: %s" % hero_id)
			else:
				push_warning("[CHARACTER_SELECT] Failed to load hero data: %s" % hero_id)
		else:
			push_warning("[CHARACTER_SELECT] Hero data not found: %s" % path)

func _build_ui() -> void:
	"""Build the entire character select UI programmatically"""
	# Set up main control
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Dark background
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.05, 0.05, 0.08, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Title
	var title := Label.new()
	title.name = "Title"
	title.text = "CHOOSE YOUR CHAMPION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 30
	title.offset_bottom = 90
	add_child(title)
	
	# Main content container (horizontal split)
	var main_hbox := HBoxContainer.new()
	main_hbox.name = "MainContent"
	main_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_hbox.offset_top = 100
	main_hbox.offset_bottom = -80
	main_hbox.offset_left = 40
	main_hbox.offset_right = -40
	main_hbox.add_theme_constant_override("separation", 30)
	add_child(main_hbox)
	
	# Left side: Hero cards (vertical list)
	var cards_panel := _create_hero_cards_panel()
	cards_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	cards_panel.custom_minimum_size.x = 280
	main_hbox.add_child(cards_panel)
	
	# Center: Large hero display
	main_display = _create_main_display()
	main_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(main_display)
	
	# Right side: Stats and skills
	var info_panel := _create_info_panel()
	info_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	info_panel.custom_minimum_size.x = 350
	main_hbox.add_child(info_panel)
	
	# Bottom buttons
	var button_container := HBoxContainer.new()
	button_container.name = "ButtonContainer"
	button_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	button_container.offset_top = -70
	button_container.offset_left = 40
	button_container.offset_right = -40
	button_container.alignment = BoxContainer.ALIGNMENT_END
	button_container.add_theme_constant_override("separation", 20)
	add_child(button_container)
	
	# Back button
	back_button = _create_styled_button("Back", Color(0.5, 0.4, 0.4))
	back_button.pressed.connect(_on_back_pressed)
	button_container.add_child(back_button)
	
	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_container.add_child(spacer)
	
	# Confirm button
	confirm_button = _create_styled_button("Begin Journey", Color(0.3, 0.6, 0.4))
	confirm_button.custom_minimum_size.x = 200
	confirm_button.pressed.connect(_on_confirm_pressed)
	button_container.add_child(confirm_button)

func _create_hero_cards_panel() -> PanelContainer:
	"""Create the left panel with hero selection cards"""
	var panel := PanelContainer.new()
	panel.name = "HeroCardsPanel"
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	style.border_color = Color(0.3, 0.25, 0.35)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	
	# Section title
	var section_title := Label.new()
	section_title.text = "HEROES"
	section_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section_title.add_theme_font_size_override("font_size", 16)
	section_title.add_theme_color_override("font_color", Color(0.7, 0.65, 0.6))
	vbox.add_child(section_title)
	
	# Create a card for each hero
	for i in range(HERO_IDS.size()):
		var hero_id := HERO_IDS[i]
		var card := _create_hero_card(hero_id, i)
		vbox.add_child(card)
		hero_cards.append(card)
	
	return panel

func _create_hero_card(hero_id: String, index: int) -> PanelContainer:
	"""Create a single hero selection card"""
	var card := PanelContainer.new()
	card.name = "HeroCard_%s" % hero_id
	card.custom_minimum_size = Vector2(250, 100)
	card.focus_mode = Control.FOCUS_ALL
	
	# Get hero data
	var data: HeroData = hero_data_cache.get(hero_id)
	if not data:
		return card
	
	# Style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_color = ROLE_COLORS.get(data.role, Color.WHITE).darkened(0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)
	
	# Content
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	card.add_child(hbox)
	
	# Portrait placeholder
	var portrait_container := PanelContainer.new()
	portrait_container.custom_minimum_size = Vector2(70, 70)
	var portrait_style := StyleBoxFlat.new()
	portrait_style.bg_color = Color(0.15, 0.12, 0.18)
	portrait_style.border_color = ROLE_COLORS.get(data.role, Color.WHITE)
	portrait_style.set_border_width_all(2)
	portrait_style.set_corner_radius_all(4)
	portrait_container.add_theme_stylebox_override("panel", portrait_style)
	hbox.add_child(portrait_container)
	
	# Try to load portrait
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(66, 66)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if data.portrait_path != "" and ResourceLoader.exists(data.portrait_path):
		portrait.texture = load(data.portrait_path)
	elif data.sprite_path != "" and ResourceLoader.exists(data.sprite_path):
		portrait.texture = load(data.sprite_path)
	portrait_container.add_child(portrait)
	
	# Info
	var info_vbox := VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	# Name
	var name_label := Label.new()
	name_label.text = data.display_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.85))
	info_vbox.add_child(name_label)
	
	# Title
	var title_label := Label.new()
	title_label.text = data.title
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.6))
	info_vbox.add_child(title_label)
	
	# Role badge
	var role_label := Label.new()
	role_label.text = data.role.to_upper()
	role_label.add_theme_font_size_override("font_size", 11)
	role_label.add_theme_color_override("font_color", ROLE_COLORS.get(data.role, Color.WHITE))
	info_vbox.add_child(role_label)
	
	# Connect signals
	card.gui_input.connect(_on_card_input.bind(index))
	card.mouse_entered.connect(_on_card_hover.bind(index))
	card.focus_entered.connect(_on_card_focus.bind(index))
	
	return card

func _create_main_display() -> Control:
	"""Create the center panel with large hero display"""
	var container := Control.new()
	container.name = "MainDisplay"
	
	# Large hero sprite
	hero_sprite = TextureRect.new()
	hero_sprite.name = "HeroSprite"
	hero_sprite.set_anchors_preset(Control.PRESET_CENTER)
	hero_sprite.custom_minimum_size = Vector2(400, 500)
	hero_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_sprite.pivot_offset = Vector2(200, 250)
	container.add_child(hero_sprite)
	
	# Name and title overlay at bottom
	var name_container := VBoxContainer.new()
	name_container.name = "NameContainer"
	name_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	name_container.offset_top = -120
	name_container.add_theme_constant_override("separation", 5)
	container.add_child(name_container)
	
	hero_name_label = Label.new()
	hero_name_label.name = "HeroName"
	hero_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_name_label.add_theme_font_size_override("font_size", 36)
	hero_name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	name_container.add_child(hero_name_label)
	
	hero_title_label = Label.new()
	hero_title_label.name = "HeroTitle"
	hero_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_title_label.add_theme_font_size_override("font_size", 18)
	hero_title_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
	name_container.add_child(hero_title_label)
	
	return container

func _create_info_panel() -> PanelContainer:
	"""Create the right panel with stats, skills, and path/brand info"""
	var panel := PanelContainer.new()
	panel.name = "InfoPanel"
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	style.border_color = Color(0.3, 0.25, 0.35)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	
	# Path & Brand alignment section
	var alignment_section := _create_section("PATH & BRAND ALIGNMENT")
	vbox.add_child(alignment_section)
	
	path_brand_display = HBoxContainer.new()
	path_brand_display.name = "PathBrandDisplay"
	path_brand_display.add_theme_constant_override("separation", 20)
	path_brand_display.alignment = BoxContainer.ALIGNMENT_CENTER
	alignment_section.add_child(path_brand_display)
	
	# Description section
	var desc_section := _create_section("BACKGROUND")
	vbox.add_child(desc_section)
	
	hero_description = RichTextLabel.new()
	hero_description.name = "HeroDescription"
	hero_description.bbcode_enabled = true
	hero_description.fit_content = true
	hero_description.custom_minimum_size.y = 80
	hero_description.add_theme_font_size_override("normal_font_size", 13)
	hero_description.add_theme_color_override("default_color", Color(0.75, 0.7, 0.65))
	desc_section.add_child(hero_description)
	
	# Stats section
	var stats_section := _create_section("BASE STATS")
	vbox.add_child(stats_section)
	
	stats_container = GridContainer.new()
	stats_container.name = "StatsContainer"
	stats_container.columns = 4
	stats_container.add_theme_constant_override("h_separation", 15)
	stats_container.add_theme_constant_override("v_separation", 8)
	stats_section.add_child(stats_container)
	
	# Skills section
	var skills_section := _create_section("COMBAT STYLE")
	vbox.add_child(skills_section)
	
	skills_container = VBoxContainer.new()
	skills_container.name = "SkillsContainer"
	skills_container.add_theme_constant_override("separation", 8)
	skills_section.add_child(skills_container)
	
	return panel

func _create_section(title: String) -> VBoxContainer:
	"""Create a titled section container"""
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 10)
	
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	section.add_child(title_label)
	
	var separator := HSeparator.new()
	separator.modulate = Color(0.4, 0.35, 0.45, 0.5)
	section.add_child(separator)
	
	return section

func _create_styled_button(text: String, color: Color) -> Button:
	"""Create a styled button"""
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(140, 50)
	
	var normal := StyleBoxFlat.new()
	normal.bg_color = color.darkened(0.3)
	normal.border_color = color
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	
	var hover := StyleBoxFlat.new()
	hover.bg_color = color.darkened(0.1)
	hover.border_color = color.lightened(0.2)
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(6)
	hover.shadow_color = color
	hover.shadow_color.a = 0.4
	hover.shadow_size = 6
	
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color.WHITE)
	
	return button

# =============================================================================
# HERO SELECTION
# =============================================================================

func _select_hero(index: int) -> void:
	"""Select a hero and update the display"""
	if index < 0 or index >= HERO_IDS.size():
		return
	
	selected_hero_index = index
	var hero_id := HERO_IDS[index]
	var data: HeroData = hero_data_cache.get(hero_id)
	
	if not data:
		return
	
	# Update card highlights
	_update_card_highlights()
	
	# Update main display with animation
	_animate_hero_change(data)
	
	# Update info panel
	_update_info_panel(data)

func _update_card_highlights() -> void:
	"""Update visual state of all hero cards"""
	for i in range(hero_cards.size()):
		var card := hero_cards[i]
		var style := card.get_theme_stylebox("panel") as StyleBoxFlat
		if not style:
			continue
		
		var hero_id := HERO_IDS[i]
		var data: HeroData = hero_data_cache.get(hero_id)
		var role_color: Color = ROLE_COLORS.get(data.role if data else "DPS", Color.WHITE)
		
		if i == selected_hero_index:
			# Selected - bright border and glow
			style.border_color = role_color
			style.set_border_width_all(3)
			style.shadow_color = role_color
			style.shadow_color.a = 0.5
			style.shadow_size = 8
			style.bg_color = Color(0.15, 0.12, 0.18, 0.98)
		else:
			# Not selected - dim
			style.border_color = role_color.darkened(0.5)
			style.set_border_width_all(2)
			style.shadow_size = 0
			style.bg_color = Color(0.1, 0.1, 0.15, 0.95)

func _animate_hero_change(data: HeroData) -> void:
	"""Animate the hero sprite change"""
	if _selection_tween and _selection_tween.is_valid():
		_selection_tween.kill()
	
	_selection_tween = create_tween()
	
	# Fade out current
	_selection_tween.tween_property(hero_sprite, "modulate:a", 0.0, 0.15)
	
	# Change sprite
	_selection_tween.tween_callback(func():
		if data.battle_sprite_path != "" and ResourceLoader.exists(data.battle_sprite_path):
			hero_sprite.texture = load(data.battle_sprite_path)
		elif data.sprite_path != "" and ResourceLoader.exists(data.sprite_path):
			hero_sprite.texture = load(data.sprite_path)
		
		hero_name_label.text = data.display_name
		hero_title_label.text = data.title
	)
	
	# Fade in with scale pop
	_selection_tween.tween_property(hero_sprite, "modulate:a", 1.0, 0.2)
	_selection_tween.parallel().tween_property(hero_sprite, "scale", Vector2(1.05, 1.05), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_selection_tween.tween_property(hero_sprite, "scale", Vector2(1.0, 1.0), 0.1)

func _update_info_panel(data: HeroData) -> void:
	"""Update the info panel with hero data"""
	# Path & Brand display
	for child in path_brand_display.get_children():
		child.queue_free()
	
	# Path info
	var path_vbox := VBoxContainer.new()
	path_vbox.add_theme_constant_override("separation", 4)
	path_brand_display.add_child(path_vbox)
	
	var path_title := Label.new()
	path_title.text = "PATH"
	path_title.add_theme_font_size_override("font_size", 11)
	path_title.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	path_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	path_vbox.add_child(path_title)
	
	var path_name := Label.new()
	path_name.text = Enums.get_path_name(data.primary_path)
	path_name.add_theme_font_size_override("font_size", 16)
	path_name.add_theme_color_override("font_color", _get_path_color(data.primary_path))
	path_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	path_vbox.add_child(path_name)
	
	# Arrow
	var arrow := Label.new()
	arrow.text = "→"
	arrow.add_theme_font_size_override("font_size", 24)
	arrow.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	path_brand_display.add_child(arrow)
	
	# Brand info
	var brand_vbox := VBoxContainer.new()
	brand_vbox.add_theme_constant_override("separation", 4)
	path_brand_display.add_child(brand_vbox)
	
	var brand_title := Label.new()
	brand_title.text = "ALIGNED BRAND"
	brand_title.add_theme_font_size_override("font_size", 11)
	brand_title.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	brand_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand_vbox.add_child(brand_title)
	
	var brand_name := Label.new()
	brand_name.text = Enums.get_brand_name(data.primary_brand)
	brand_name.add_theme_font_size_override("font_size", 16)
	brand_name.add_theme_color_override("font_color", _get_brand_color(data.primary_brand))
	brand_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand_vbox.add_child(brand_name)
	
	# Description
	hero_description.text = data.description
	
	# Stats
	for child in stats_container.get_children():
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
		
		var name_label := Label.new()
		name_label.text = stat_name
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
		stats_container.add_child(name_label)
		
		var value_label := Label.new()
		value_label.text = str(stat_value)
		value_label.add_theme_font_size_override("font_size", 14)
		value_label.add_theme_color_override("font_color", stat_color)
		stats_container.add_child(value_label)
	
	# Combat style
	for child in skills_container.get_children():
		child.queue_free()
	
	var combat_label := Label.new()
	combat_label.text = data.combat_description
	combat_label.add_theme_font_size_override("font_size", 13)
	combat_label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.65))
	combat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skills_container.add_child(combat_label)
	
	# Starting skills
	var skills_title := Label.new()
	skills_title.text = "\nStarting Skills:"
	skills_title.add_theme_font_size_override("font_size", 12)
	skills_title.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
	skills_container.add_child(skills_title)
	
	for skill_id in data.innate_skills:
		var skill_label := Label.new()
		skill_label.text = "• " + skill_id.capitalize().replace("_", " ")
		skill_label.add_theme_font_size_override("font_size", 12)
		skill_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.7))
		skills_container.add_child(skill_label)

func _get_path_color(path: Enums.Path) -> Color:
	match path:
		Enums.Path.IRONBOUND: return Color(0.6, 0.65, 0.75)
		Enums.Path.FANGBORN: return Color(0.85, 0.4, 0.3)
		Enums.Path.VOIDTOUCHED: return Color(0.6, 0.3, 0.7)
		Enums.Path.UNCHAINED: return Color(0.9, 0.8, 0.3)
		_: return Color(0.7, 0.7, 0.7)

func _get_brand_color(brand: Enums.Brand) -> Color:
	match brand:
		Enums.Brand.SAVAGE: return Color(1.0, 0.4, 0.3)
		Enums.Brand.IRON: return Color(0.6, 0.7, 0.8)
		Enums.Brand.VENOM: return Color(0.4, 0.9, 0.3)
		Enums.Brand.SURGE: return Color(0.3, 0.8, 1.0)
		Enums.Brand.DREAD: return Color(0.6, 0.3, 0.8)
		Enums.Brand.LEECH: return Color(0.8, 0.2, 0.4)
		_: return Color(0.5, 0.5, 0.5)

# =============================================================================
# ANIMATIONS
# =============================================================================

func _setup_animations() -> void:
	"""Setup idle breathing animation for hero sprite"""
	_start_breathing_animation()

func _start_breathing_animation() -> void:
	if _breathing_tween and _breathing_tween.is_valid():
		_breathing_tween.kill()
	
	_breathing_tween = create_tween().set_loops()
	_breathing_tween.tween_property(hero_sprite, "scale", Vector2(1.02, 1.02), 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_breathing_tween.tween_property(hero_sprite, "scale", Vector2(1.0, 1.0), 2.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

# =============================================================================
# INPUT HANDLING
# =============================================================================

func _on_card_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_hero(index)
		hero_cards[index].grab_focus()

func _on_card_hover(index: int) -> void:
	_select_hero(index)

func _on_card_focus(index: int) -> void:
	_select_hero(index)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_up"):
		var new_index := (selected_hero_index - 1 + HERO_IDS.size()) % HERO_IDS.size()
		_select_hero(new_index)
		hero_cards[new_index].grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		var new_index := (selected_hero_index + 1) % HERO_IDS.size()
		_select_hero(new_index)
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

func _on_confirm_pressed() -> void:
	var hero_id := HERO_IDS[selected_hero_index]
	print("[CHARACTER_SELECT] Selected hero: %s" % hero_id)
	
	# Store selection in GameManager
	GameManager.set_selected_hero(hero_id)
	
	# Initialize the player character
	var player := GameManager.initialize_player_character()
	if player:
		print("[CHARACTER_SELECT] Player character created: %s" % player.character_name)
		
		# Emit signal for any listeners
		character_selected.emit(hero_id)
		
		# Transition to test battle (or overworld when ready)
		# For now, go to test_battle.tscn
		SceneManager.goto_scene("res://scenes/test/test_battle.tscn")
	else:
		push_error("[CHARACTER_SELECT] Failed to create player character!")

func _on_back_pressed() -> void:
	selection_cancelled.emit()
	# Return to main menu
	SceneManager.goto_main_menu()

# =============================================================================
# CLEANUP
# =============================================================================

func _exit_tree() -> void:
	if _breathing_tween and _breathing_tween.is_valid():
		_breathing_tween.kill()
	if _selection_tween and _selection_tween.is_valid():
		_selection_tween.kill()
