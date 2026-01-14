class_name HeroCardsPanel
extends PanelContainer
## Left panel containing hero selection cards.
## Handles selection, hover, and keyboard focus.

# =============================================================================
# SIGNALS
# =============================================================================

signal hero_hovered(index: int)
signal hero_selected(index: int)
signal hero_clicked(index: int)  # For locking selection on click

# =============================================================================
# CONSTANTS
# =============================================================================

# DRAMATIC class colors - MAXIMUM SATURATION for visual impact
const CLASS_COLORS: Dictionary = {
	"VEILGUARD": Color(0.3, 0.5, 0.95),     # Electric blue - intense
	"BLOODHUNTER": Color(0.95, 0.15, 0.15), # Blood red - maximum
	"SOULWEAVER": Color(0.7, 0.3, 0.9),     # Mystic purple - vivid
	"VOIDWALKER": Color(0.2, 0.85, 0.95)    # Cyan void - bright
}

# =============================================================================
# STATE
# =============================================================================

var hero_cards: Array[Control] = []
var selected_index: int = 0
var hovered_index: int = -1
var _hero_data_cache: Dictionary = {}
var _hero_ids: Array[String] = []

# DRAMATIC: Animated selection indicator
var _selection_glow_tween: Tween = null
var _selection_indicator: Control = null
var _indicator_corners: Array[ColorRect] = []
var _current_indicator_card: PanelContainer = null  # Track which card has the indicator
var _selection_locked: bool = false  # True after user clicks - indicator stops following mouse

# PERFORMANCE: Track hover tweens to prevent accumulation
var _hover_tweens: Dictionary = {}  # index -> Tween

# =============================================================================
# LIFECYCLE
# =============================================================================


func _ready() -> void:
	_build_base_ui()


func _build_base_ui() -> void:
	add_theme_stylebox_override("panel", UIStyleFactory.create_char_select_panel(15))


# =============================================================================
# PUBLIC API
# =============================================================================


func setup(hero_ids: Array[String], hero_data_cache: Dictionary) -> void:
	_hero_ids = hero_ids
	_hero_data_cache = hero_data_cache
	_build_cards()


func select_hero(index: int) -> void:
	if index < 0 or index >= hero_cards.size():
		return

	selected_index = index
	_update_card_visuals()
	hero_selected.emit(index)


func get_selected_hero_id() -> String:
	if selected_index >= 0 and selected_index < _hero_ids.size():
		return _hero_ids[selected_index]
	return ""


func focus_card(index: int) -> void:
	if index >= 0 and index < hero_cards.size():
		hero_cards[index].grab_focus()


# =============================================================================
# UI BUILDING
# =============================================================================


func _build_cards() -> void:
	# Clear existing
	for child in get_children():
		child.queue_free()
	hero_cards.clear()

	var vbox := UIStyleFactory.create_vbox(10)
	add_child(vbox)

	# Header
	var header := UIStyleFactory.create_centered_label("CHAMPIONS", 14, Color(0.6, 0.55, 0.5))
	vbox.add_child(header)

	var sep := UIStyleFactory.create_separator()
	sep.modulate = Color(0.4, 0.35, 0.45, 0.5)
	vbox.add_child(sep)

	# Create cards
	for i in range(_hero_ids.size()):
		var hero_id := _hero_ids[i]
		var card := _create_hero_card(hero_id, i)
		vbox.add_child(card)
		hero_cards.append(card)

		# Staggered entrance
		_animate_card_entrance(card, i)


func _create_hero_card(hero_id: String, index: int) -> PanelContainer:
	var data: HeroData = _hero_data_cache.get(hero_id)
	var class_color: Color = CLASS_COLORS.get(data.hero_class, Color.WHITE) if data else Color.WHITE

	# Use DRAMATIC normal style as initial state
	var card := UIStyleFactory.create_styled_panel(
		UIStyleFactory.create_dramatic_hero_card_normal(class_color) if data else StyleBoxFlat.new()
	)
	card.name = "HeroCard_%s" % hero_id
	card.custom_minimum_size = Vector2(250, 120)  # Larger cards for more presence
	card.focus_mode = Control.FOCUS_ALL
	card.pivot_offset = Vector2(125, 60)  # Center pivot for animations

	if not data:
		return card

	var hbox := UIStyleFactory.create_hbox(14)
	card.add_child(hbox)

	# DRAMATIC portrait frame with glowing border
	var portrait_frame := UIStyleFactory.create_styled_panel(
		UIStyleFactory.create_dramatic_portrait_frame(class_color)
	)
	portrait_frame.custom_minimum_size = Vector2(80, 80)
	hbox.add_child(portrait_frame)

	# Portrait image
	var portrait := UIStyleFactory.create_portrait(Vector2(71, 71))
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if data.sprite_path != "" and ResourceLoader.exists(data.sprite_path):
		portrait.texture = load(data.sprite_path)
	portrait_frame.add_child(portrait)

	# Info column
	var info := UIStyleFactory.create_vbox(3)
	UIStyleFactory.expand_horizontal(info)
	hbox.add_child(info)

	# Name
	var name_label := UIStyleFactory.create_label(
		data.display_name.to_upper(), 18, Color(0.95, 0.9, 0.85)
	)
	info.add_child(name_label)

	# Class
	var class_text := data.hero_class if data.hero_class != "" else data.role.to_upper()
	var class_label := UIStyleFactory.create_label(class_text, 13, class_color)
	info.add_child(class_label)

	# Path indicator
	var path_color := PathSystem.get_path_color(data.primary_path)
	var path_label := UIStyleFactory.create_label(
		Enums.get_path_name(data.primary_path), 11, path_color
	)
	info.add_child(path_label)

	# Connect signals
	card.gui_input.connect(_on_card_input.bind(index))
	card.mouse_entered.connect(_on_card_mouse_entered.bind(index))
	card.mouse_exited.connect(_on_card_mouse_exited.bind(index))
	card.focus_entered.connect(_on_card_focus_entered.bind(index))

	return card


func _animate_card_entrance(card: Control, index: int) -> void:
	# Start hidden and offset
	card.modulate.a = 0.0
	card.position.x = -30

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	var delay: float = index * 0.1

	tween.tween_interval(delay)
	tween.set_parallel(true)
	tween.tween_property(card, "modulate:a", 1.0, 0.25)
	tween.tween_property(card, "position:x", 0.0, 0.3)


# =============================================================================
# VISUAL UPDATES
# =============================================================================


func _update_card_visuals() -> void:
	# Determine which card should have the indicator:
	# - If locked (user clicked): show on selected_index
	# - If NOT locked: show on hovered card (mouse following), fallback to selected
	var indicator_target: int = selected_index
	if not _selection_locked and hovered_index >= 0:
		indicator_target = hovered_index

	for i in range(hero_cards.size()):
		var card := hero_cards[i] as PanelContainer
		if not card:
			continue

		var hero_id := _hero_ids[i]
		var data: HeroData = _hero_data_cache.get(hero_id)
		var class_color: Color = CLASS_COLORS.get(data.hero_class if data else "", Color.WHITE)

		# Use DRAMATIC styles for maximum visual impact
		var style: StyleBoxFlat
		if i == selected_index:
			style = UIStyleFactory.create_dramatic_hero_card_selected(class_color)
			_pulse_selected_card(card)
		elif i == hovered_index:
			style = UIStyleFactory.create_dramatic_hero_card_hovered(class_color)
		else:
			style = UIStyleFactory.create_dramatic_hero_card_normal(class_color)

		card.add_theme_stylebox_override("panel", style)

		# DRAMATIC: Show animated indicator on target card (follows mouse or locked)
		if i == indicator_target:
			var target_color: Color = CLASS_COLORS.get(data.hero_class if data else "", Color.WHITE)
			_start_selection_glow(card, target_color)


func _pulse_selected_card(card: PanelContainer) -> void:
	# Brief scale pulse when selected
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	tween.tween_property(card, "scale", Vector2(1.03, 1.03), 0.1)
	tween.tween_property(card, "scale", Vector2.ONE, 0.15)


# =============================================================================
# INPUT HANDLERS
# =============================================================================


func _on_card_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_selection_locked = true  # Lock indicator to selected card on click
		select_hero(index)
		hero_clicked.emit(index)
		hero_cards[index].grab_focus()


func _on_card_mouse_entered(index: int) -> void:
	hovered_index = index
	hero_hovered.emit(index)

	# Hover scale animation - PERFORMANCE: Kill old tween first
	if index != selected_index:
		_kill_hover_tween(index)
		var card := hero_cards[index]
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(card, "scale", Vector2(1.02, 1.02), 0.1)
		_hover_tweens[index] = tween

	_update_card_visuals()


func _on_card_mouse_exited(index: int) -> void:
	if hovered_index == index:
		hovered_index = -1

		# Return to normal scale if not selected - PERFORMANCE: Kill old tween first
		if index != selected_index:
			_kill_hover_tween(index)
			var card := hero_cards[index]
			var tween := create_tween()
			tween.tween_property(card, "scale", Vector2.ONE, 0.1)
			_hover_tweens[index] = tween

		_update_card_visuals()


func _kill_hover_tween(index: int) -> void:
	if _hover_tweens.has(index):
		var old_tween: Tween = _hover_tweens[index]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
		_hover_tweens.erase(index)


func _on_card_focus_entered(index: int) -> void:
	select_hero(index)
	hero_clicked.emit(index)


# =============================================================================
# DRAMATIC SELECTION INDICATOR - CONTINUOUS ANIMATION
# =============================================================================


func _start_selection_glow(card: PanelContainer, class_color: Color) -> void:
	## Start continuous pulsing glow animation on the target card
	## FIXED: Indicator now appears BEHIND card as shadow glow (z_index = -1)
	if not card or not is_instance_valid(card):
		return

	# FIX: Only recreate indicator if the target card actually changed
	if _current_indicator_card == card and _selection_indicator and is_instance_valid(_selection_indicator):
		return  # Indicator is already on this card, don't recreate

	_stop_selection_glow()

	# FIX: Use minimum size if actual size not ready yet (pre-layout)
	var bracket_size: Vector2 = card.size
	if bracket_size.x < 10 or bracket_size.y < 10:
		bracket_size = card.custom_minimum_size  # Fallback to minimum size

	# Create the selection indicator container as a SIBLING, not child
	# This allows us to put it BEHIND the card using z_index
	_selection_indicator = Control.new()
	_selection_indicator.name = "SelectionIndicator"
	_selection_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_selection_indicator.z_index = -1  # BEHIND all cards for true shadow glow effect
	_selection_indicator.size = bracket_size

	# Add to this panel (HeroCardsPanel) and position to overlay the card
	add_child(_selection_indicator)

	# Position indicator to overlay the target card using global coords
	# We need to update position when card moves, but for now set initial position
	_update_indicator_position(card)
	_current_indicator_card = card  # Track which card has the indicator

	# Create animated corner brackets - Persona 5 style
	_create_corner_brackets(bracket_size, class_color)

	# Start the continuous glow pulse animation
	_start_glow_pulse(class_color)


func _update_indicator_position(card: PanelContainer) -> void:
	## Update indicator position to overlay the target card
	if not _selection_indicator or not is_instance_valid(_selection_indicator):
		return
	if not card or not is_instance_valid(card):
		return

	# Get card's position relative to this panel
	var card_rect: Rect2 = card.get_global_rect()
	var panel_rect: Rect2 = get_global_rect()
	_selection_indicator.global_position = card_rect.position


func _stop_selection_glow() -> void:
	## Stop and clean up selection animation
	if _selection_glow_tween and _selection_glow_tween.is_valid():
		_selection_glow_tween.kill()
	_selection_glow_tween = null

	_indicator_corners.clear()

	if _selection_indicator and is_instance_valid(_selection_indicator):
		_selection_indicator.queue_free()
	_selection_indicator = null
	_current_indicator_card = null  # Clear tracking


func _create_corner_brackets(card_size: Vector2, class_color: Color) -> void:
	## Create animated corner bracket indicators
	if not _selection_indicator:
		return

	_indicator_corners.clear()

	var bracket_length: float = 20.0
	var bracket_thickness: float = 3.0
	var corner_offset: float = -4.0  # Offset outside the card

	# Bright version of class color
	var bracket_color := class_color.lightened(0.3)
	bracket_color.a = 0.9

	# Four corners: TL, TR, BL, BR - each has 2 lines (horizontal + vertical)
	var corners: Array[Dictionary] = [
		# Top-Left
		{"pos": Vector2(corner_offset, corner_offset), "h_size": Vector2(bracket_length, bracket_thickness), "v_size": Vector2(bracket_thickness, bracket_length)},
		# Top-Right
		{"pos": Vector2(card_size.x - bracket_length - corner_offset, corner_offset), "h_size": Vector2(bracket_length, bracket_thickness), "v_size": Vector2(bracket_thickness, bracket_length), "v_offset": Vector2(bracket_length - bracket_thickness, 0)},
		# Bottom-Left
		{"pos": Vector2(corner_offset, card_size.y - bracket_length - corner_offset), "h_size": Vector2(bracket_length, bracket_thickness), "v_size": Vector2(bracket_thickness, bracket_length), "h_offset": Vector2(0, bracket_length - bracket_thickness)},
		# Bottom-Right
		{"pos": Vector2(card_size.x - bracket_length - corner_offset, card_size.y - bracket_length - corner_offset), "h_size": Vector2(bracket_length, bracket_thickness), "v_size": Vector2(bracket_thickness, bracket_length), "h_offset": Vector2(0, bracket_length - bracket_thickness), "v_offset": Vector2(bracket_length - bracket_thickness, 0)}
	]

	for corner in corners:
		# Horizontal line
		var h_line := ColorRect.new()
		h_line.color = bracket_color
		h_line.size = corner["h_size"]
		h_line.position = corner["pos"] + corner.get("h_offset", Vector2.ZERO)
		h_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_selection_indicator.add_child(h_line)
		_indicator_corners.append(h_line)

		# Vertical line
		var v_line := ColorRect.new()
		v_line.color = bracket_color
		v_line.size = corner["v_size"]
		v_line.position = corner["pos"] + corner.get("v_offset", Vector2.ZERO)
		v_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_selection_indicator.add_child(v_line)
		_indicator_corners.append(v_line)


func _start_glow_pulse(class_color: Color) -> void:
	## Continuous pulsing glow animation - loops forever
	if _indicator_corners.is_empty():
		return

	var bright_color := class_color.lightened(0.5)
	bright_color.a = 1.0
	var dim_color := class_color.lightened(0.2)
	dim_color.a = 0.5

	_selection_glow_tween = create_tween()
	_selection_glow_tween.set_loops()  # Infinite loop
	_selection_glow_tween.set_ease(Tween.EASE_IN_OUT)
	_selection_glow_tween.set_trans(Tween.TRANS_SINE)

	# Pulse bright
	for corner in _indicator_corners:
		_selection_glow_tween.parallel().tween_property(corner, "color", bright_color, 0.6)

	# Pulse dim
	for corner in _indicator_corners:
		_selection_glow_tween.parallel().tween_property(corner, "color", dim_color, 0.6)


func _exit_tree() -> void:
	_stop_selection_glow()
	# Clean up hover tweens
	for tween in _hover_tweens.values():
		if tween and tween.is_valid():
			tween.kill()
	_hover_tweens.clear()
