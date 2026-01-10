class_name CharacterSelectController
extends Control
## CharacterSelectController: Orchestrates the modular character select screen.
## Coordinates communication between child panels via signals.

signal character_selected(hero_id: String)
signal selection_cancelled

# =============================================================================
# CONSTANTS
# =============================================================================

const HERO_IDS: Array[String] = ["bastion", "rend", "marrow", "mirage"]

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

# =============================================================================
# LIFECYCLE
# =============================================================================


func _ready() -> void:
	_load_all_data()
	_build_ui()
	_connect_signals()
	_select_hero(0)


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

	# === MAIN CONTENT ===
	var content_hbox := UIStyleFactory.create_hbox(25)
	UIStyleFactory.expand_vertical(content_hbox)
	vbox.add_child(content_hbox)

	# Left: Hero selection cards
	hero_cards_panel = HeroCardsPanel.new()
	hero_cards_panel.custom_minimum_size.x = 260
	hero_cards_panel.setup(HERO_IDS, hero_data_cache)
	content_hbox.add_child(hero_cards_panel)

	# Center: Large hero display
	hero_display_panel = HeroDisplayPanel.new()
	hero_display_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_hbox.add_child(hero_display_panel)

	# Right: Info panel
	info_panel = HeroInfoPanel.new()
	info_panel.custom_minimum_size.x = 420
	info_panel.set_monster_cache(monster_data_cache)
	content_hbox.add_child(info_panel)

	# === VERA PANEL (Bottom) ===
	vera_panel = CharacterSelectVERAPanel.new()
	vbox.add_child(vera_panel)

	# === BUTTON BAR ===
	button_bar = CharacterSelectButtonBar.new()
	vbox.add_child(button_bar)

	# === CONFIRMATION POPUP (hidden initially) ===
	confirmation_popup = CharacterSelectConfirmationPopup.new()
	add_child(confirmation_popup)


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


func _create_title_bar(parent: Control) -> void:
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
	var title := UIStyleFactory.create_centered_label(
		"CHOOSE YOUR CHAMPION", 38, Color(0.9, 0.8, 0.6)
	)
	title_container.add_child(title)

	# Decorative line right
	var line_right := ColorRect.new()
	line_right.custom_minimum_size = Vector2(100, 2)
	line_right.color = Color(0.6, 0.5, 0.3, 0.5)
	UIStyleFactory.expand_horizontal(line_right)
	line_right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_container.add_child(line_right)


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
