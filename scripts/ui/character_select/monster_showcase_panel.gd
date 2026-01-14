class_name MonsterShowcasePanel
extends VBoxContainer
## Displays starter monsters for the selected hero.
## Shows monster cards with sprites, names, and brand indicators.
## Uses 2x2 grid layout to fit 4 monsters in available space.

# =============================================================================
# CONSTANTS
# =============================================================================

# Card sizing for 2x2 grid layout - fits in 360px panel width
const CARD_SIZE := Vector2(85, 105)
const SPRITE_SIZE := Vector2(55, 55)
const GRID_COLUMNS := 2
const GRID_H_SPACING := 10
const GRID_V_SPACING := 8

# =============================================================================
# STATE
# =============================================================================

var _monster_container: GridContainer = null
var _synergy_label: RichTextLabel = null
var _monster_data_cache: Dictionary = {}
var _idle_tweens: Array[Tween] = []  # Track tweens for cleanup
var _hover_tweens: Dictionary = {}  # Card -> Tween for hover animation tracking

# =============================================================================
# LIFECYCLE
# =============================================================================


func _ready() -> void:
	_build_ui()


func _exit_tree() -> void:
	# Clean up all idle tweens to prevent leaks
	for tween in _idle_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_idle_tweens.clear()

	# Clean up hover tweens
	for card: PanelContainer in _hover_tweens.keys():
		var tween: Tween = _hover_tweens[card]
		if tween and tween.is_valid():
			tween.kill()
	_hover_tweens.clear()


func _build_ui() -> void:
	add_theme_constant_override("separation", 12)

	# Section header
	var header := _create_section_header("YOUR STARTER MONSTERS")
	add_child(header)

	# Synergy explanation
	_synergy_label = RichTextLabel.new()
	_synergy_label.bbcode_enabled = true
	_synergy_label.fit_content = true
	_synergy_label.custom_minimum_size.y = 40
	_synergy_label.add_theme_font_size_override("normal_font_size", 12)
	_synergy_label.add_theme_color_override("default_color", Color(0.65, 0.6, 0.55))
	add_child(_synergy_label)

	# Monster card container - 2x2 grid layout
	_monster_container = GridContainer.new()
	_monster_container.columns = GRID_COLUMNS
	_monster_container.add_theme_constant_override("h_separation", GRID_H_SPACING)
	_monster_container.add_theme_constant_override("v_separation", GRID_V_SPACING)
	_monster_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(_monster_container)


func _create_section_header(title: String) -> VBoxContainer:
	var container := UIStyleFactory.create_vbox(8)

	var label := UIStyleFactory.create_label(title, 13, Color(0.55, 0.5, 0.45))
	container.add_child(label)

	var sep := UIStyleFactory.create_separator()
	sep.modulate = Color(0.35, 0.3, 0.4, 0.6)
	container.add_child(sep)

	return container


# =============================================================================
# PUBLIC API
# =============================================================================


func set_monster_cache(cache: Dictionary) -> void:
	_monster_data_cache = cache


func display_monsters(monster_ids: Array, synergy_text: String = "") -> void:
	# Kill any existing idle tweens
	for tween in _idle_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_idle_tweens.clear()

	# Clear existing
	NodeHelpers.clear_children(_monster_container)

	# Update synergy text
	if synergy_text != "":
		_synergy_label.text = synergy_text
	else:
		_synergy_label.text = "These monsters gain bonus effectiveness when fighting alongside your hero."

	# Add monster cards with staggered entrance
	for i in range(monster_ids.size()):
		var monster_id: String = monster_ids[i]
		var card := _create_monster_card(monster_id)
		_monster_container.add_child(card)

		# Staggered entrance animation
		_animate_card_entrance(card, i)


func _animate_card_entrance(card: Control, index: int) -> void:
	# Start state
	card.modulate.a = 0.0
	card.scale = Vector2(0.8, 0.8)
	card.pivot_offset = card.custom_minimum_size / 2

	# Animate with stagger
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	var delay: float = index * 0.08  # 80ms stagger

	tween.tween_interval(delay)
	tween.set_parallel(true)
	tween.tween_property(card, "modulate:a", 1.0, 0.2)
	tween.tween_property(card, "scale", Vector2.ONE, 0.25)


func _create_monster_card(monster_id: String) -> PanelContainer:
	var card := UIStyleFactory.create_styled_panel(UIStyleFactory.create_monster_card_style())
	card.custom_minimum_size = CARD_SIZE

	var monster_data = _monster_data_cache.get(monster_id)

	var vbox := UIStyleFactory.create_vbox(3)
	card.add_child(vbox)

	# Monster sprite container - compact for grid
	var sprite_container := CenterContainer.new()
	sprite_container.custom_minimum_size.y = SPRITE_SIZE.y + 8
	vbox.add_child(sprite_container)

	# Monster sprite
	var sprite := UIStyleFactory.create_icon(SPRITE_SIZE)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var sprite_path := "res://assets/sprites/monsters/%s.png" % monster_id
	if ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
	sprite_container.add_child(sprite)

	# Add subtle idle animation to sprite
	_add_idle_animation(sprite)

	# Monster name - smaller font for compact cards
	var display_name := monster_id.capitalize().replace("_", " ")
	var name_label := UIStyleFactory.create_centered_label(display_name, 10, Color(0.85, 0.8, 0.75))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)

	# Brand indicator - smaller for compact layout
	var brand_name := _get_monster_brand_name(monster_data)
	if brand_name != "":
		var brand_color := _get_brand_color_from_name(brand_name)
		var brand_indicator := UIStyleFactory.create_centered_label(brand_name, 8, brand_color)
		vbox.add_child(brand_indicator)

	# Hover effects
	card.mouse_entered.connect(_on_card_hover.bind(card))
	card.mouse_exited.connect(_on_card_unhover.bind(card))

	return card


func _add_idle_animation(sprite: TextureRect) -> void:
	# Subtle floating animation
	sprite.pivot_offset = sprite.custom_minimum_size / 2

	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	# Float up and down slightly
	tween.tween_property(sprite, "position:y", -3.0, 1.5)
	tween.tween_property(sprite, "position:y", 0.0, 1.5)

	# Track for cleanup
	_idle_tweens.append(tween)


func _get_monster_brand_name(monster_data) -> String:
	if not monster_data:
		return ""

	if monster_data is Resource:
		if "primary_brand" in monster_data:
			return Enums.get_brand_name(monster_data.primary_brand)
		elif "brand" in monster_data:
			return Enums.get_brand_name(monster_data.brand)

	return ""


func _get_brand_color_from_name(brand_name: String) -> Color:
	# Convert name back to enum for color lookup
	var brand_upper := brand_name.to_upper()
	for i in range(Enums.Brand.size()):
		if Enums.get_brand_name(i as Enums.Brand).to_upper() == brand_upper:
			return BrandSystem.get_brand_color(i as Enums.Brand)
	return Color(0.6, 0.55, 0.5)


# =============================================================================
# HOVER EFFECTS
# =============================================================================


func _kill_card_hover_tween(card: PanelContainer) -> void:
	if _hover_tweens.has(card):
		var old_tween: Tween = _hover_tweens[card]
		if old_tween and old_tween.is_valid():
			old_tween.kill()
		_hover_tweens.erase(card)


func _on_card_hover(card: PanelContainer) -> void:
	_kill_card_hover_tween(card)

	var tween := create_tween()
	_hover_tweens[card] = tween
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_parallel(true)

	card.pivot_offset = card.size / 2
	tween.tween_property(card, "scale", Vector2(1.05, 1.05), 0.12)
	tween.tween_property(card, "modulate", Color(1.1, 1.08, 1.05), 0.12)


func _on_card_unhover(card: PanelContainer) -> void:
	_kill_card_hover_tween(card)

	var tween := create_tween()
	_hover_tweens[card] = tween
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)

	tween.tween_property(card, "scale", Vector2.ONE, 0.1)
	tween.tween_property(card, "modulate", Color.WHITE, 0.1)
