class_name HeroInfoPanel
extends PanelContainer
## Right panel displaying hero stats, path/brand, description, and monster showcase.

# =============================================================================
# STATE
# =============================================================================

var path_label: Label = null
var brand_label: Label = null
var hero_description: RichTextLabel = null
var stats_grid: GridContainer = null
var monster_showcase: MonsterShowcasePanel = null

var _scroll_container: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# =============================================================================
# LIFECYCLE
# =============================================================================


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	name = "InfoPanel"
	add_theme_stylebox_override("panel", UIStyleFactory.create_char_select_panel(20))

	_scroll_container = ScrollContainer.new()
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll_container)

	_content_vbox = UIStyleFactory.create_vbox(18)
	UIStyleFactory.expand_horizontal(_content_vbox)
	_scroll_container.add_child(_content_vbox)

	# === PATH & BRAND SECTION ===
	_build_alignment_section()

	# === DESCRIPTION SECTION ===
	_build_description_section()

	# === STATS SECTION ===
	_build_stats_section()

	# === MONSTER SHOWCASE ===
	_build_monster_section()


func _build_alignment_section() -> void:
	var header := _create_section_header("PATH & BRAND ALIGNMENT")
	_content_vbox.add_child(header)

	var alignment_hbox := UIStyleFactory.create_hbox(30)
	alignment_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_content_vbox.add_child(alignment_hbox)

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


func _build_description_section() -> void:
	var header := _create_section_header("BACKGROUND")
	_content_vbox.add_child(header)

	hero_description = RichTextLabel.new()
	hero_description.bbcode_enabled = true
	hero_description.fit_content = true
	hero_description.custom_minimum_size.y = 60
	hero_description.add_theme_font_size_override("normal_font_size", 13)
	hero_description.add_theme_color_override("default_color", Color(0.7, 0.65, 0.6))
	_content_vbox.add_child(hero_description)


func _build_stats_section() -> void:
	var header := _create_section_header("BASE STATS")
	_content_vbox.add_child(header)

	stats_grid = GridContainer.new()
	stats_grid.columns = 4
	stats_grid.add_theme_constant_override("h_separation", 20)
	stats_grid.add_theme_constant_override("v_separation", 8)
	_content_vbox.add_child(stats_grid)


func _build_monster_section() -> void:
	monster_showcase = MonsterShowcasePanel.new()
	_content_vbox.add_child(monster_showcase)


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
	if monster_showcase:
		monster_showcase.set_monster_cache(cache)


func display_hero_info(hero_data: HeroData) -> void:
	if not hero_data:
		return

	_update_path_brand(hero_data)
	_update_description(hero_data)
	_update_stats(hero_data)
	_update_monsters(hero_data)

	# Scroll to top
	if _scroll_container:
		_scroll_container.scroll_vertical = 0


func _update_path_brand(hero_data: HeroData) -> void:
	# Path
	var path_color: Color = PathSystem.get_path_color(hero_data.primary_path)
	path_label.text = Enums.get_path_name(hero_data.primary_path)
	path_label.add_theme_color_override("font_color", path_color)

	# Brand
	var brand_color: Color = BrandSystem.get_brand_color(hero_data.primary_brand)
	brand_label.text = Enums.get_brand_name(hero_data.primary_brand)
	brand_label.add_theme_color_override("font_color", brand_color)


func _update_description(hero_data: HeroData) -> void:
	hero_description.text = hero_data.description


func _update_stats(hero_data: HeroData) -> void:
	# Clear existing
	NodeHelpers.clear_children(stats_grid)

	# Stat definitions with colors
	var stats: Array = [
		["HP", hero_data.base_hp, Color(0.4, 0.9, 0.4)],
		["MP", hero_data.base_mp, Color(0.4, 0.6, 1.0)],
		["ATK", hero_data.base_attack, Color(1.0, 0.5, 0.4)],
		["DEF", hero_data.base_defense, Color(0.5, 0.7, 1.0)],
		["MAG", hero_data.base_magic, Color(0.8, 0.5, 1.0)],
		["RES", hero_data.base_resistance, Color(0.6, 0.8, 0.9)],
		["SPD", hero_data.base_speed, Color(0.5, 1.0, 0.7)],
		["LCK", hero_data.base_luck, Color(1.0, 0.9, 0.4)]
	]

	for stat_info in stats:
		var stat_name: String = stat_info[0]
		var stat_value: int = stat_info[1]
		var stat_color: Color = stat_info[2]

		# Stat name
		var name_lbl := UIStyleFactory.create_label(stat_name, 12, Color(0.55, 0.5, 0.45))
		stats_grid.add_child(name_lbl)

		# Stat value with color
		var value_lbl := UIStyleFactory.create_label(str(stat_value), 14, stat_color)
		stats_grid.add_child(value_lbl)

	# Animate stats in
	_animate_stats_entrance()


func _animate_stats_entrance() -> void:
	var children := stats_grid.get_children()
	for i in range(children.size()):
		var child := children[i] as Control
		if not child:
			continue

		child.modulate.a = 0.0

		var tween := create_tween()
		tween.tween_interval(i * 0.03)  # 30ms stagger
		tween.tween_property(child, "modulate:a", 1.0, 0.15)


func _update_monsters(hero_data: HeroData) -> void:
	if not monster_showcase:
		return

	var synergy_text: String = hero_data.synergy_explanation if hero_data.synergy_explanation != "" \
		else "Monsters of aligned brands gain bonus effectiveness when fighting alongside this hero."

	monster_showcase.display_monsters(hero_data.recommended_monsters, synergy_text)
