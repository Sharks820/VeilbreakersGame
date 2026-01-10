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

const CLASS_COLORS: Dictionary = {
	"VEILGUARD": Color(0.4, 0.5, 0.7),
	"BLOODHUNTER": Color(0.8, 0.2, 0.2),
	"SOULWEAVER": Color(0.5, 0.3, 0.7),
	"VOIDWALKER": Color(0.3, 0.7, 0.9)
}

# =============================================================================
# STATE
# =============================================================================

var hero_cards: Array[Control] = []
var selected_index: int = 0
var hovered_index: int = -1
var _hero_data_cache: Dictionary = {}
var _hero_ids: Array[String] = []

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

	var card := UIStyleFactory.create_styled_panel(
		UIStyleFactory.create_hero_card_style(class_color) if data else StyleBoxFlat.new()
	)
	card.name = "HeroCard_%s" % hero_id
	card.custom_minimum_size = Vector2(230, 110)
	card.focus_mode = Control.FOCUS_ALL
	card.pivot_offset = Vector2(115, 55)  # Center pivot for animations

	if not data:
		return card

	var hbox := UIStyleFactory.create_hbox(12)
	card.add_child(hbox)

	# Portrait frame
	var portrait_frame := UIStyleFactory.create_styled_panel(
		UIStyleFactory.create_hero_portrait_frame(class_color)
	)
	portrait_frame.custom_minimum_size = Vector2(75, 75)
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
	for i in range(hero_cards.size()):
		var card := hero_cards[i] as PanelContainer
		if not card:
			continue

		var hero_id := _hero_ids[i]
		var data: HeroData = _hero_data_cache.get(hero_id)
		var class_color: Color = CLASS_COLORS.get(data.hero_class if data else "", Color.WHITE)

		var style: StyleBoxFlat
		if i == selected_index:
			style = UIStyleFactory.create_hero_card_selected(class_color)
			_pulse_selected_card(card)
		elif i == hovered_index:
			style = UIStyleFactory.create_hero_card_hovered(class_color)
		else:
			style = UIStyleFactory.create_hero_card_normal(class_color)

		card.add_theme_stylebox_override("panel", style)


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
		select_hero(index)
		hero_clicked.emit(index)
		hero_cards[index].grab_focus()


func _on_card_mouse_entered(index: int) -> void:
	hovered_index = index
	hero_hovered.emit(index)

	# Hover scale animation
	if index != selected_index:
		var card := hero_cards[index]
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(card, "scale", Vector2(1.02, 1.02), 0.1)

	_update_card_visuals()


func _on_card_mouse_exited(index: int) -> void:
	if hovered_index == index:
		hovered_index = -1

		# Return to normal scale if not selected
		if index != selected_index:
			var card := hero_cards[index]
			var tween := create_tween()
			tween.tween_property(card, "scale", Vector2.ONE, 0.1)

		_update_card_visuals()


func _on_card_focus_entered(index: int) -> void:
	select_hero(index)
	hero_clicked.emit(index)
