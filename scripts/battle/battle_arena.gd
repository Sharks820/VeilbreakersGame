extends Node2D
## BattleArena: Visual representation of battle with character placement and effects.
## Now integrated with full animation systems for AAA-quality combat.

# =============================================================================
# NODE REFERENCES - Core Systems
# =============================================================================

@onready var player_positions: Node2D = $BattleField/PlayerPositions
@onready var enemy_positions: Node2D = $BattleField/EnemyPositions
@onready var players_container: Node2D = $BattleField/CharacterContainer/Players
@onready var enemies_container: Node2D = $BattleField/CharacterContainer/Enemies
@onready var vfx_container: Node2D = $EffectsLayer/VFXContainer
@onready var damage_numbers_container: Node2D = $EffectsLayer/DamageNumbers
@onready var battle_manager: BattleManager = $Systems/BattleManager
@onready var turn_manager: TurnManager = $Systems/TurnManager
@onready var damage_calculator: DamageCalculator = $Systems/DamageCalculator
@onready var ui_layer: CanvasLayer = $UILayer

# =============================================================================
# NODE REFERENCES - Animation Systems (NEW)
# =============================================================================

@onready var battle_camera: BattleCameraController = $BattleCamera
@onready var vfx_manager: VFXManager = $AnimationSystems/VFXManager
@onready var damage_number_spawner: DamageNumberSpawner = $AnimationSystems/DamageNumberSpawner
@onready var screen_effects: ScreenEffectsManager = $ScreenEffectsLayer/ScreenEffectsManager
@onready var battle_sequencer: BattleSequencer = $Systems/BattleSequencer

# =============================================================================
# STATE
# =============================================================================

var player_sprites: Array[Node2D] = []
var enemy_sprites: Array[Node2D] = []
var battle_ui: Control = null
var is_battle_active: bool = false

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_connect_signals()
	_setup_background()
	_setup_battle_ui()
	_setup_battle_manager()
	_setup_animation_systems()
	_setup_screen_effects()
	EventBus.emit_debug("BattleArena ready with animation systems")

func _setup_background() -> void:
	"""Load a battle background"""
	var bg_sprite: Sprite2D = get_node_or_null("Background/BackgroundSprite")
	if bg_sprite:
		var bg_texture := load("res://assets/environments/battles/corrupted_grove.png")
		if bg_texture:
			bg_sprite.texture = bg_texture
			bg_sprite.centered = false
			bg_sprite.position = Vector2.ZERO
			# Scale to fill 1920x1080
			var tex_size = bg_texture.get_size()
			bg_sprite.scale = Vector2(1920.0 / tex_size.x, 1080.0 / tex_size.y)

func _connect_signals() -> void:
	# Core battle events
	EventBus.battle_started.connect(_on_battle_started)
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.healing_done.connect(_on_healing_done)
	EventBus.action_executed.connect(_on_action_executed)

	# Connect Battle Sequencer command signals to animation systems
	if battle_sequencer:
		battle_sequencer.camera_command.connect(_on_camera_command)
		battle_sequencer.vfx_command.connect(_on_vfx_command)
		battle_sequencer.ui_command.connect(_on_ui_command)
		battle_sequencer.audio_command.connect(_on_audio_command)
		battle_sequencer.turn_started.connect(_on_sequencer_turn_started)
		battle_sequencer.action_execution_started.connect(_on_action_execution_started)

func _setup_animation_systems() -> void:
	"""Initialize and configure animation systems"""
	# Configure VFX Manager
	if vfx_manager:
		vfx_manager.effect_spawned.connect(_on_vfx_spawned)
		vfx_manager.effect_completed.connect(_on_vfx_completed)

	# Configure Damage Number Spawner
	if damage_number_spawner:
		damage_number_spawner.number_spawned.connect(_on_damage_number_spawned)

	# Configure Battle Camera
	if battle_camera:
		battle_camera.shake_completed.connect(_on_camera_shake_completed)
		battle_camera.focus_completed.connect(_on_camera_focus_completed)
		# Set battle bounds
		battle_camera.set_battle_bounds(Rect2(0, 0, 1920, 1080))

	EventBus.emit_debug("Animation systems initialized")

func _setup_screen_effects() -> void:
	"""Configure screen effects manager with node references"""
	if screen_effects:
		# Assign the effect rects (they're child nodes)
		screen_effects.flash_rect = screen_effects.get_node_or_null("FlashRect")
		screen_effects.vignette_rect = screen_effects.get_node_or_null("VignetteRect")
		screen_effects.fade_rect = screen_effects.get_node_or_null("FadeRect")
		screen_effects.letterbox_top = screen_effects.get_node_or_null("LetterboxTop")
		screen_effects.letterbox_bottom = screen_effects.get_node_or_null("LetterboxBottom")

func _setup_battle_ui() -> void:
	# Load and instantiate battle UI
	EventBus.emit_debug("Setting up battle UI...")

	# Check if UILayer exists
	if ui_layer == null:
		push_error("UILayer is NULL! Creating one dynamically.")
		ui_layer = CanvasLayer.new()
		ui_layer.name = "UILayer"
		add_child(ui_layer)

	# Configure UILayer for proper rendering
	ui_layer.layer = 100
	ui_layer.visible = true
	ui_layer.follow_viewport_enabled = false

	var ui_scene := load("res://scenes/battle/battle_ui.tscn")
	if ui_scene:
		battle_ui = ui_scene.instantiate()
		ui_layer.add_child(battle_ui)

		# Force proper sizing for CanvasLayer context
		battle_ui.position = Vector2.ZERO
		battle_ui.size = Vector2(1920, 1080)  # Use project resolution
		battle_ui.visible = true

		battle_ui.set_battle_manager(battle_manager)
		EventBus.emit_debug("Battle UI loaded and added to layer %d, size: %s" % [ui_layer.layer, battle_ui.size])
	else:
		push_error("Failed to load battle_ui.tscn!")
		EventBus.emit_debug("ERROR: Failed to load battle_ui.tscn")

func _setup_battle_manager() -> void:
	# Connect battle manager signals
	battle_manager.battle_initialized.connect(_on_battle_initialized)
	battle_manager.action_animation_started.connect(_on_action_animation_started)
	battle_manager.battle_victory.connect(_on_battle_victory)
	battle_manager.battle_defeat.connect(_on_battle_defeat)

	# Link subsystems
	battle_manager.turn_manager = turn_manager
	battle_manager.damage_calculator = damage_calculator

# =============================================================================
# BATTLE INITIALIZATION
# =============================================================================

func initialize_battle(players: Array[CharacterBase], enemies: Array[CharacterBase]) -> void:
	is_battle_active = true

	# Place characters on the battlefield
	_place_characters(players, player_positions, players_container, player_sprites)
	_place_characters(enemies, enemy_positions, enemies_container, enemy_sprites)

	# Create sidebars
	_create_party_sidebar(players)
	_create_enemy_sidebar(enemies)

	# Start battle logic
	battle_manager.start_battle(players, enemies)

	EventBus.emit_debug("Battle initialized with %d players vs %d enemies" % [players.size(), enemies.size()])

func _create_party_sidebar(players: Array[CharacterBase]) -> void:
	"""Create party sidebar with HP/MP bars on battle_ui"""
	if not battle_ui:
		return

	var sidebar := PanelContainer.new()
	sidebar.name = "PartySidebar"
	sidebar.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	sidebar.position = Vector2(10, 70)
	sidebar.custom_minimum_size = Vector2(170, 0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14, 0.92)
	style.border_color = Color(0.25, 0.4, 0.35, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	sidebar.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	sidebar.add_child(vbox)

	# Header
	var header := Label.new()
	header.text = "Party"
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(0.5, 0.85, 0.65, 1.0))
	vbox.add_child(header)

	# Add each party member
	for player in players:
		var slot := _create_party_slot(player)
		vbox.add_child(slot)

	battle_ui.add_child(sidebar)

func _create_party_slot(character: CharacterBase) -> PanelContainer:
	"""Create individual party member slot with portrait and HP/MP bars"""
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(154, 50)

	var slot_style := StyleBoxFlat.new()
	slot_style.bg_color = Color(0.12, 0.15, 0.18, 0.9)
	slot_style.border_color = Color(0.3, 0.45, 0.4, 1.0)
	slot_style.set_border_width_all(1)
	slot_style.set_corner_radius_all(3)
	slot_style.content_margin_left = 4
	slot_style.content_margin_right = 4
	slot_style.content_margin_top = 4
	slot_style.content_margin_bottom = 4
	slot.add_theme_stylebox_override("panel", slot_style)

	# Horizontal layout: portrait | name+bars
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	slot.add_child(hbox)

	# Portrait
	var portrait := _create_portrait(character, 40)
	hbox.add_child(portrait)

	# Name and bars column
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = character.character_name
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.85, 1.0))
	vbox.add_child(name_lbl)

	# HP Bar
	var hp_bar := ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(90, 10)
	hp_bar.max_value = maxf(character.get_max_hp(), 1.0)
	hp_bar.value = character.current_hp
	hp_bar.show_percentage = false
	_style_hp_bar(hp_bar)
	vbox.add_child(hp_bar)

	# Store reference on character for updates
	character.set_meta("sidebar_hp_bar", hp_bar)

	# MP Bar (if character has MP)
	if character.base_max_mp > 0:
		var mp_bar := ProgressBar.new()
		mp_bar.custom_minimum_size = Vector2(90, 6)
		mp_bar.max_value = maxf(character.get_max_mp(), 1.0)
		mp_bar.value = character.current_mp
		mp_bar.show_percentage = false
		_style_mp_bar(mp_bar)
		vbox.add_child(mp_bar)

		# Store reference on character for updates
		character.set_meta("sidebar_mp_bar", mp_bar)

	return slot

func _create_portrait(character: CharacterBase, size: int) -> Control:
	"""Create a portrait thumbnail for sidebar"""
	var container := PanelContainer.new()
	container.custom_minimum_size = Vector2(size, size)

	# Portrait frame style
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.08, 0.08, 0.1, 1.0)
	frame_style.border_color = Color(0.4, 0.5, 0.45, 1.0)
	frame_style.set_border_width_all(1)
	frame_style.set_corner_radius_all(2)
	container.add_theme_stylebox_override("panel", frame_style)

	# Load sprite texture
	var sprite_path := _get_character_sprite_path(character)
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		var tex := load(sprite_path)
		if tex:
			var tex_rect := TextureRect.new()
			tex_rect.texture = tex
			tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.custom_minimum_size = Vector2(size - 4, size - 4)
			container.add_child(tex_rect)

	return container

func _style_hp_bar(bar: ProgressBar) -> void:
	"""Style HP bar with green fill"""
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.1, 0.1, 1.0)
	bg.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg)

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.2, 0.75, 0.3, 1.0)
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", fill)

func _style_mp_bar(bar: ProgressBar) -> void:
	"""Style MP bar with blue fill"""
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.15, 1.0)
	bg.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg)

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.3, 0.5, 0.9, 1.0)
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", fill)

func _create_enemy_sidebar(enemies: Array[CharacterBase]) -> void:
	"""Create enemy sidebar with HP bars - matches party sidebar but RED"""
	if not battle_ui:
		return

	var sidebar := PanelContainer.new()
	sidebar.name = "EnemySidebar"
	sidebar.anchor_left = 1.0
	sidebar.anchor_right = 1.0
	sidebar.anchor_top = 0.0
	sidebar.anchor_bottom = 0.0
	sidebar.offset_left = -180.0
	sidebar.offset_right = -10.0
	sidebar.offset_top = 70.0
	sidebar.custom_minimum_size = Vector2(170, 0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.08, 0.08, 0.92)
	style.border_color = Color(0.5, 0.25, 0.25, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	sidebar.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	sidebar.add_child(vbox)

	# Header
	var header := Label.new()
	header.text = "Enemies"
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4, 1.0))
	vbox.add_child(header)

	# Add each enemy
	for enemy in enemies:
		var slot := _create_enemy_slot(enemy)
		vbox.add_child(slot)

	battle_ui.add_child(sidebar)

func _create_enemy_slot(character: CharacterBase) -> PanelContainer:
	"""Create individual enemy slot with portrait and HP bar - RED style"""
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(154, 50)

	var slot_style := StyleBoxFlat.new()
	slot_style.bg_color = Color(0.18, 0.12, 0.12, 0.9)
	slot_style.border_color = Color(0.5, 0.3, 0.3, 1.0)
	slot_style.set_border_width_all(1)
	slot_style.set_corner_radius_all(3)
	slot_style.content_margin_left = 4
	slot_style.content_margin_right = 4
	slot_style.content_margin_top = 4
	slot_style.content_margin_bottom = 4
	slot.add_theme_stylebox_override("panel", slot_style)

	# Horizontal layout: portrait | name+bars
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	slot.add_child(hbox)

	# Portrait with red frame
	var portrait := _create_enemy_portrait(character, 40)
	hbox.add_child(portrait)

	# Name and bars column
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = character.character_name
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.85, 1.0))
	vbox.add_child(name_lbl)

	# HP Bar (red)
	var hp_bar := ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(90, 10)
	hp_bar.max_value = maxf(character.get_max_hp(), 1.0)
	hp_bar.value = character.current_hp
	hp_bar.show_percentage = false
	_style_enemy_hp_bar(hp_bar)
	vbox.add_child(hp_bar)

	# Store reference on character for updates
	character.set_meta("sidebar_hp_bar", hp_bar)

	return slot

func _create_enemy_portrait(character: CharacterBase, size: int) -> Control:
	"""Create a portrait thumbnail for enemy sidebar (red frame)"""
	var container := PanelContainer.new()
	container.custom_minimum_size = Vector2(size, size)

	# Red portrait frame style
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.1, 0.06, 0.06, 1.0)
	frame_style.border_color = Color(0.6, 0.3, 0.3, 1.0)
	frame_style.set_border_width_all(1)
	frame_style.set_corner_radius_all(2)
	container.add_theme_stylebox_override("panel", frame_style)

	# Load sprite texture
	var sprite_path := _get_character_sprite_path(character)
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		var tex := load(sprite_path)
		if tex:
			var tex_rect := TextureRect.new()
			tex_rect.texture = tex
			tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.custom_minimum_size = Vector2(size - 4, size - 4)
			container.add_child(tex_rect)

	return container

func _style_enemy_hp_bar(bar: ProgressBar) -> void:
	"""Style enemy HP bar with red fill"""
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.08, 0.08, 1.0)
	bg.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg)

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.85, 0.25, 0.2, 1.0)
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", fill)

func _place_characters(characters: Array[CharacterBase], positions_node: Node2D, container: Node2D, sprite_array: Array[Node2D]) -> void:
	sprite_array.clear()
	var markers := positions_node.get_children()
	var is_player_party := positions_node == player_positions

	EventBus.emit_debug("Placing %d characters with %d markers (is_player_party: %s)" % [characters.size(), markers.size(), is_player_party])

	# Get calculated positions based on party composition
	var calculated_positions: Array[Vector2] = _calculate_formation_positions(characters, positions_node, is_player_party)

	for i in range(characters.size()):
		var character := characters[i]
		var target_pos := calculated_positions[i] if i < calculated_positions.size() else positions_node.global_position

		# Create visual representation
		var sprite := _create_character_sprite(character)
		container.add_child(sprite)
		sprite.global_position = target_pos
		sprite_array.append(sprite)

		# Store reference for animations
		character.set_meta("battle_sprite", sprite)
		character.battle_position = target_pos

func _calculate_formation_positions(characters: Array[CharacterBase], positions_node: Node2D, is_player_party: bool) -> Array[Vector2]:
	"""Calculate intelligent formation positions based on party size"""
	var positions: Array[Vector2] = []
	var base_pos := positions_node.global_position
	var markers := positions_node.get_children()
	var party_size := characters.size()

	if not is_player_party:
		# Enemies use standard marker positions (less formal formation)
		for i in range(party_size):
			if i < markers.size():
				positions.append(markers[i].global_position)
			else:
				# Fallback position with offset
				positions.append(base_pos + Vector2(i * 80, (i % 2) * 100 - 50))
		return positions

	# Player party - intelligent arrow formation
	# Player FURTHER BACK behind point monster (same Y, much further back X)
	# Point monster at front apex, wing monsters flanking

	match party_size:
		1:
			# Player only - single position centered
			positions.append(base_pos + Vector2(60, 0))
		2:
			# Player + 1 monster - player far behind monster
			positions.append(base_pos + Vector2(-120, 0))  # Player far back (same Y as monster)
			positions.append(base_pos + Vector2(140, 0))   # Monster in front
		3:
			# Player + 2 monsters - player far back, 2 monsters in line in front
			positions.append(base_pos + Vector2(-120, 0))  # Player far back center
			positions.append(base_pos + Vector2(140, -70)) # Monster 1 upper
			positions.append(base_pos + Vector2(140, 70))  # Monster 2 lower
		4:
			# Player + 3 monsters - full arrow formation
			# Player far behind point monster, wings flanking
			positions.append(base_pos + Vector2(-120, 0))  # Player (far behind point, same Y)
			positions.append(base_pos + Vector2(220, 0))   # Point monster (front apex)
			positions.append(base_pos + Vector2(80, -90))  # Upper wing
			positions.append(base_pos + Vector2(80, 90))   # Lower wing
		_:
			# Fallback for unexpected sizes
			for i in range(party_size):
				if i < markers.size():
					positions.append(markers[i].global_position)
				else:
					positions.append(base_pos + Vector2(i * 60, 0))

	return positions

func _create_character_sprite(character: CharacterBase) -> Node2D:
	var container := Node2D.new()
	container.name = character.character_name
	container.z_index = 10

	var sprite_path := _get_character_sprite_path(character)
	var sprite_loaded := false

	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		var tex := load(sprite_path)
		if tex:
			var sprite := Sprite2D.new()
			sprite.texture = tex
			sprite.name = "CharacterSprite"

			# Scale and position based on character type
			match character.character_type:
				Enums.CharacterType.PLAYER:
					sprite.scale = Vector2(0.08, 0.08)
					sprite.position = Vector2(0, -60)
				Enums.CharacterType.MONSTER:
					if character is Monster and character.is_corrupted:
						# Enemy monsters - same size as players
						sprite.scale = Vector2(0.08, 0.08)
						sprite.position = Vector2(0, -60)
					else:
						# Allied monsters
						sprite.scale = Vector2(0.08, 0.08)
						sprite.position = Vector2(0, -60)
				Enums.CharacterType.BOSS:
					sprite.scale = Vector2(0.10, 0.10)
					sprite.position = Vector2(0, -75)
				_:
					sprite.scale = Vector2(0.08, 0.08)
					sprite.position = Vector2(0, -60)

			# Flip sprite to face enemies (allies face right, enemies face left)
			if character is Monster and character.is_corrupted:
				sprite.flip_h = false
			else:
				sprite.flip_h = true

			container.add_child(sprite)
			sprite_loaded = true

	# Fallback to colored rectangle if no sprite
	if not sprite_loaded:
		var sprite := ColorRect.new()
		match character.character_type:
			Enums.CharacterType.PLAYER:
				sprite.size = Vector2(100, 150)
				sprite.position = Vector2(-50, -150)
				sprite.color = Color(0.2, 0.6, 1.0, 0.9)
			Enums.CharacterType.MONSTER:
				sprite.size = Vector2(50, 75)
				sprite.position = Vector2(-25, -75)
				sprite.color = Color(0.8, 0.2, 0.2, 0.9)
			Enums.CharacterType.BOSS:
				sprite.size = Vector2(80, 120)
				sprite.position = Vector2(-40, -120)
				sprite.color = Color(0.6, 0.1, 0.6, 0.9)
			_:
				sprite.size = Vector2(50, 75)
				sprite.position = Vector2(-25, -75)
				sprite.color = Color(0.5, 0.5, 0.5, 0.9)
		container.add_child(sprite)

	# Name label - position based on sprite size
	var label := Label.new()
	label.text = character.character_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	container.add_child(label)

	# HP bar above character - size and position based on character type
	var hp_bar := ProgressBar.new()
	hp_bar.max_value = character.get_max_hp()
	hp_bar.value = character.current_hp
	hp_bar.show_percentage = false
	hp_bar.name = "HPBar"

	# Style the HP bar to be visible
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.2, 0.8, 0.3, 1.0)  # Green fill
	fill_style.corner_radius_top_left = 2
	fill_style.corner_radius_top_right = 2
	fill_style.corner_radius_bottom_left = 2
	fill_style.corner_radius_bottom_right = 2
	hp_bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.1, 0.1, 0.9)  # Dark background
	bg_style.border_color = Color(0.3, 0.25, 0.2, 1.0)  # Border
	bg_style.border_width_top = 1
	bg_style.border_width_bottom = 1
	bg_style.border_width_left = 1
	bg_style.border_width_right = 1
	bg_style.corner_radius_top_left = 2
	bg_style.corner_radius_top_right = 2
	bg_style.corner_radius_bottom_left = 2
	bg_style.corner_radius_bottom_right = 2
	hp_bar.add_theme_stylebox_override("background", bg_style)

	container.add_child(hp_bar)

	# Adjust label and HP bar based on character type
	match character.character_type:
		Enums.CharacterType.PLAYER:
			label.position = Vector2(-50, -175)
			hp_bar.size = Vector2(100, 12)
			hp_bar.position = Vector2(-50, -160)
		Enums.CharacterType.MONSTER:
			label.position = Vector2(-35, -100)
			hp_bar.size = Vector2(70, 10)
			hp_bar.position = Vector2(-35, -88)
		Enums.CharacterType.BOSS:
			label.position = Vector2(-50, -145)
			hp_bar.size = Vector2(100, 12)
			hp_bar.position = Vector2(-50, -132)
		_:
			label.position = Vector2(-35, -100)
			hp_bar.size = Vector2(70, 10)
			hp_bar.position = Vector2(-35, -88)

	return container

# =============================================================================
# ANIMATIONS
# =============================================================================

func _on_action_animation_started(character: CharacterBase, action: int) -> void:
	var sprite: Node2D = character.get_meta("battle_sprite", null)
	if not sprite:
		return

	var original_pos := sprite.position
	var tween := create_tween()

	match action:
		Enums.BattleAction.ATTACK:
			var direction := 1.0 if character in battle_manager.player_party else -1.0
			tween.tween_property(sprite, "position:x", original_pos.x + (80 * direction), 0.15)
			tween.tween_property(sprite, "position:x", original_pos.x, 0.15)

		Enums.BattleAction.SKILL:
			# Glow effect for skills
			tween.tween_property(sprite, "modulate", Color(1.2, 1.2, 1.5), 0.2)
			tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)

		Enums.BattleAction.DEFEND:
			tween.tween_property(sprite, "modulate", Color(0.5, 0.7, 1.0), 0.1)
			tween.tween_property(sprite, "modulate", Color.WHITE, 0.4)

		Enums.BattleAction.PURIFY:
			# Holy light effect
			tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 0.8), 0.3)
			tween.tween_property(sprite, "modulate", Color.WHITE, 0.5)

func _play_hit_animation(sprite: Node2D) -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3), 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

	# Shake effect
	var original_pos := sprite.position
	tween.parallel().tween_property(sprite, "position:x", original_pos.x + 5, 0.02)
	tween.tween_property(sprite, "position:x", original_pos.x - 5, 0.04)
	tween.tween_property(sprite, "position:x", original_pos.x, 0.04)

func _play_heal_animation(sprite: Node2D) -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(0.5, 1.5, 0.5), 0.2)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)

func _play_death_animation(sprite: Node2D) -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.3, 0.5)
	tween.parallel().tween_property(sprite, "position:y", sprite.position.y + 20, 0.5)

# =============================================================================
# DAMAGE NUMBERS
# =============================================================================

func _spawn_damage_number(pos: Vector2, amount: int, is_critical: bool, is_heal: bool = false) -> void:
	var label := Label.new()
	label.text = str(amount) if not is_heal else "+" + str(amount)
	label.global_position = pos + Vector2(randf_range(-20, 20), 0)
	label.z_index = 100

	# Styling
	var font_size := 32 if is_critical else 24
	label.add_theme_font_size_override("font_size", font_size)

	var color := Color.WHITE
	if is_heal:
		color = Color.LIME_GREEN
	elif is_critical:
		color = Color.YELLOW
	else:
		color = Color.WHITE
	label.add_theme_color_override("font_color", color)

	damage_numbers_container.add_child(label)

	# Animate
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", pos.y - 60, Constants.DAMAGE_NUMBER_DURATION)
	tween.tween_property(label, "modulate:a", 0.0, Constants.DAMAGE_NUMBER_DURATION)
	tween.chain().tween_callback(label.queue_free)

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_battle_started(enemy_data: Array) -> void:
	# Guard against being called twice (battle_manager also emits this signal)
	if is_battle_active:
		return

	# Create enemy characters from data if provided
	if enemy_data.is_empty():
		return

	var enemies: Array[CharacterBase] = []
	for data in enemy_data:
		EventBus.emit_debug("  Processing enemy data type: %s" % [typeof(data)])
		if data is Monster:
			enemies.append(data)
			EventBus.emit_debug("    -> Added Monster: %s" % [data.character_name])
		elif data is Dictionary:
			enemies.append(Monster.create_from_data(data))
		# Limit to 2 enemy monsters
		if enemies.size() >= 2:
			break

	# Get full party (1 player + up to 3 allied monsters = 4 max)
	var players: Array[CharacterBase] = []
	for i in range(mini(4, GameManager.player_party.size())):
		var member = GameManager.player_party[i]
		if member is CharacterBase:
			players.append(member)

	if not players.is_empty() and not enemies.is_empty():
		initialize_battle(players, enemies)

func _on_battle_initialized() -> void:
	EventBus.emit_debug("Battle arena: Battle initialized")

func _on_damage_dealt(source: Node, target: Node, amount: int, is_critical: bool) -> void:
	if not target is CharacterBase:
		return

	var character: CharacterBase = target
	var sprite: Node2D = character.get_meta("battle_sprite", null)
	if not sprite:
		return

	# Update HP bar on sprite
	var hp_bar: ProgressBar = sprite.get_node_or_null("HPBar")
	if hp_bar:
		hp_bar.value = character.current_hp

	# Update sidebar HP bar
	var sidebar_hp_bar: ProgressBar = character.get_meta("sidebar_hp_bar", null)
	if sidebar_hp_bar and is_instance_valid(sidebar_hp_bar):
		sidebar_hp_bar.value = character.current_hp

	# Update screen effects with health percent for vignette
	if screen_effects and character in battle_manager.player_party:
		var hp_percent = float(character.current_hp) / float(character.get_max_hp())
		screen_effects.set_health_percent(hp_percent)

	# Get brand for color coding
	var brand := ""
	if source and source.has_method("get_brand"):
		brand = source.get_brand()

	# Spawn damage number (using advanced system)
	_spawn_advanced_damage_number({
		"position": sprite.global_position + Vector2(0, -80),
		"amount": amount,
		"is_critical": is_critical,
		"brand": brand
	})

	# Play hit animation
	_play_hit_animation(sprite)

	# Apply knockback using the KnockbackAnimator
	var knockback_direction := Vector2.LEFT
	if source and source is Node2D and source.has_meta("battle_sprite"):
		var source_sprite: Node2D = source.get_meta("battle_sprite")
		knockback_direction = (sprite.global_position - source_sprite.global_position).normalized()

	KnockbackAnimator.apply_knockback(sprite, knockback_direction, 1.0, is_critical)

	# Camera shake on hit
	if battle_camera:
		if is_critical:
			battle_camera.shake_preset("critical")
			battle_camera.impact_freeze(0.05)
		else:
			battle_camera.shake_preset("light")

	# Screen effects on player damage
	if screen_effects and character in battle_manager.player_party:
		if is_critical:
			screen_effects.on_player_crit_hit()
		else:
			var damage_percent = float(amount) / float(character.get_max_hp())
			screen_effects.on_player_hit(damage_percent)

	# Check for death
	if character.is_dead():
		_play_death_animation(sprite)
		if screen_effects:
			screen_effects.on_enemy_death()

func _on_healing_done(_source: Node, target: Node, amount: int) -> void:
	if not target is CharacterBase:
		return

	var character: CharacterBase = target
	var sprite: Node2D = character.get_meta("battle_sprite", null)
	if not sprite:
		return

	# Update HP bar on sprite
	var hp_bar: ProgressBar = sprite.get_node_or_null("HPBar")
	if hp_bar:
		hp_bar.value = character.current_hp

	# Update sidebar HP bar
	var sidebar_hp_bar: ProgressBar = character.get_meta("sidebar_hp_bar", null)
	if sidebar_hp_bar and is_instance_valid(sidebar_hp_bar):
		sidebar_hp_bar.value = character.current_hp

	# Update sidebar MP bar (if exists)
	var sidebar_mp_bar: ProgressBar = character.get_meta("sidebar_mp_bar", null)
	if sidebar_mp_bar and is_instance_valid(sidebar_mp_bar):
		sidebar_mp_bar.value = character.current_mp

	# Update screen effects with health percent for vignette
	if screen_effects and character in battle_manager.player_party:
		var hp_percent = float(character.current_hp) / float(character.get_max_hp())
		screen_effects.set_health_percent(hp_percent)

	# Spawn heal number (using advanced system)
	_spawn_advanced_damage_number({
		"position": sprite.global_position + Vector2(0, -80),
		"amount": amount,
		"is_heal": true
	})

	# Spawn heal VFX
	if vfx_manager:
		vfx_manager.spawn_heal_effect({"position": sprite.global_position})

	# Screen flash for heal
	if screen_effects:
		screen_effects.flash_heal()

	# Play heal animation
	_play_heal_animation(sprite)

func _on_action_executed(character: Node, action: int, _results: Dictionary) -> void:
	"""Update sidebar bars after any action (especially for MP after skill use)"""
	if not character is CharacterBase:
		return

	var char_base: CharacterBase = character

	# Update sidebar MP bar (skills consume MP)
	var sidebar_mp_bar: ProgressBar = char_base.get_meta("sidebar_mp_bar", null)
	if sidebar_mp_bar and is_instance_valid(sidebar_mp_bar):
		sidebar_mp_bar.value = char_base.current_mp

	# Also update HP bar in case action affected HP (e.g., HP cost skills)
	var sidebar_hp_bar: ProgressBar = char_base.get_meta("sidebar_hp_bar", null)
	if sidebar_hp_bar and is_instance_valid(sidebar_hp_bar):
		sidebar_hp_bar.value = char_base.current_hp

func _on_battle_victory(rewards: Dictionary) -> void:
	is_battle_active = false
	EventBus.emit_debug("Victory! Rewards: %s" % str(rewards))

	# Play victory animations
	for sprite in player_sprites:
		var tween := create_tween()
		tween.tween_property(sprite, "position:y", sprite.position.y - 20, 0.2)
		tween.tween_property(sprite, "position:y", sprite.position.y, 0.2)

func _on_battle_defeat() -> void:
	is_battle_active = false
	EventBus.emit_debug("Defeat!")

# =============================================================================
# SEQUENCER COMMAND HANDLERS - Route commands to animation systems
# =============================================================================

func _on_camera_command(command: String, data: Dictionary) -> void:
	"""Handle camera commands from the battle sequencer"""
	if not battle_camera:
		return

	match command:
		"battle_intro":
			battle_camera.release_focus(data.get("duration", 1.5))
		"focus":
			var target = data.get("target")
			var zoom = data.get("zoom", -1.0)
			var duration = data.get("duration", 0.3)
			if target:
				battle_camera.focus_on(target, zoom, duration)
		"focus_between":
			var from = data.get("from")
			var to = data.get("to")
			var bias = data.get("bias", 0.5)
			if from and to:
				battle_camera.focus_between(from, to, bias)
		"focus_group":
			var targets = data.get("targets", [])
			if targets.size() > 0:
				var typed_targets: Array[Node2D] = []
				for t in targets:
					if t is Node2D:
						typed_targets.append(t)
				battle_camera.focus_on_multiple(typed_targets)
		"return_to_battle":
			battle_camera.release_focus(data.get("duration", 0.3))
		"shake":
			var intensity = data.get("intensity", 8.0)
			var duration = data.get("duration", 0.2)
			battle_camera.shake(Vector2(intensity, intensity), duration)
		"impact_freeze":
			var duration = data.get("duration", 0.05)
			battle_camera.impact_freeze(duration)
		"boss_intro":
			var target = data.get("target")
			var duration = data.get("duration", 3.0)
			if target:
				battle_camera.play_boss_intro_camera(target, duration)
		"boss_phase_transition":
			var target = data.get("target")
			if target:
				battle_camera.focus_on(target, 1.2, 0.3)
				battle_camera.shake(Vector2(15, 15), 1.0)
		"victory_pan", "defeat_pan":
			battle_camera.release_focus(1.0)
		_:
			EventBus.emit_debug("Unknown camera command: %s" % command)

func _on_vfx_command(command: String, data: Dictionary) -> void:
	"""Handle VFX commands from the battle sequencer"""
	match command:
		"spawn_hit_effect":
			if vfx_manager:
				vfx_manager.spawn_hit_effect(data)
		"spawn_damage_number":
			_spawn_advanced_damage_number(data)
		"screen_flash":
			if screen_effects:
				var color = data.get("color", Color.WHITE)
				var duration = data.get("duration", 0.1)
				screen_effects.flash(color, duration)
		"heal_effect":
			if vfx_manager:
				vfx_manager.spawn_heal_effect(data)
		"death_effect":
			if vfx_manager:
				vfx_manager.spawn_death_effect(data)
		"defend_effect":
			if vfx_manager:
				vfx_manager.spawn_defend_effect(data)
		"skill_charge":
			if vfx_manager:
				vfx_manager.spawn_skill_charge(data)
		"buff_effect", "debuff_effect":
			if vfx_manager:
				vfx_manager.spawn_status_apply(data)
		"status_apply":
			if vfx_manager:
				vfx_manager.spawn_status_apply(data)
		"poison_tick", "burn_tick", "bleed_tick", "regen_tick":
			if vfx_manager:
				data["status"] = command.replace("_tick", "")
				vfx_manager.spawn_status_tick(data)
		"capture_projectile":
			if vfx_manager:
				vfx_manager.spawn_capture_projectile(data)
		"capture_beam":
			if vfx_manager:
				vfx_manager.spawn_capture_beam(data)
		"capture_shake":
			if vfx_manager:
				vfx_manager.spawn_capture_shake(data)
		"capture_success":
			if vfx_manager:
				vfx_manager.spawn_capture_success(data)
			if screen_effects:
				screen_effects.on_capture_success()
		"capture_break":
			if vfx_manager:
				vfx_manager.spawn_capture_break(data)
		"monster_summon", "monster_return":
			if vfx_manager:
				vfx_manager.spawn_summon_effect(data)
		"boss_death_explosion":
			if vfx_manager:
				vfx_manager.spawn_boss_death_explosion(data)
		"boss_rage_aura":
			if vfx_manager:
				vfx_manager.spawn_boss_rage_aura(data)
		_:
			EventBus.emit_debug("Unknown VFX command: %s" % command)

func _on_ui_command(command: String, data: Dictionary) -> void:
	"""Handle UI commands from the battle sequencer"""
	if not battle_ui:
		return

	match command:
		"show_turn_order":
			if battle_ui.has_method("update_turn_order"):
				battle_ui.update_turn_order(data.get("order", []))
		"show_action_menu":
			if battle_ui.has_method("show_action_menu"):
				battle_ui.show_action_menu()
		"hide_action_menu":
			if battle_ui.has_method("hide_action_menu"):
				battle_ui.hide_action_menu()
		"show_skill_name":
			if battle_ui.has_method("show_skill_announcement"):
				battle_ui.show_skill_announcement(data.get("name", ""), data.get("brand", "NEUTRAL"))
		"show_status_popup":
			if battle_ui.has_method("show_status_popup"):
				battle_ui.show_status_popup(data.get("target"), data.get("status", ""), data.get("positive", true))
		"show_message":
			if battle_ui.has_method("show_battle_message"):
				battle_ui.show_battle_message(data.get("text", ""))
		"capture_announcement":
			if battle_ui.has_method("show_capture_success"):
				battle_ui.show_capture_success(data.get("monster_name", ""))
		"phase_announcement":
			if battle_ui.has_method("show_phase_announcement"):
				battle_ui.show_phase_announcement(data.get("boss_name", ""), data.get("phase", 1), data.get("phase_name", ""))
		"show_victory_screen":
			if battle_ui.has_method("show_victory"):
				battle_ui.show_victory(data)
		"show_defeat_screen":
			if battle_ui.has_method("show_defeat"):
				battle_ui.show_defeat(data)
		"hide_ui":
			if battle_ui.has_method("hide_all"):
				battle_ui.hide_all()
		"show_ui":
			if battle_ui.has_method("show_all"):
				battle_ui.show_all()
		_:
			EventBus.emit_debug("Unknown UI command: %s" % command)

func _on_audio_command(command: String, data: Dictionary) -> void:
	"""Handle audio commands from the battle sequencer"""
	match command:
		"play_sfx":
			var sound = data.get("sound", "")
			AudioManager.play_sfx(sound) if AudioManager.has_method("play_sfx") else null
		"play_music":
			var track = data.get("track", "")
			AudioManager.play_music(track) if AudioManager.has_method("play_music") else null
		"play_jingle":
			var jingle = data.get("jingle", "")
			AudioManager.play_jingle(jingle) if AudioManager.has_method("play_jingle") else null
		"intensify_music":
			var phase = data.get("phase", 1)
			# Could add music intensity logic here
			pass
		_:
			EventBus.emit_debug("Unknown audio command: %s" % command)

func _on_sequencer_turn_started(entity: Node, turn_number: int) -> void:
	"""Handle turn started from sequencer"""
	EventBus.emit_debug("Turn %d started for %s" % [turn_number, entity.name if entity else "unknown"])

	# Register entity with camera
	if battle_camera and entity is Node2D:
		battle_camera.register_combatant(entity)

func _on_action_execution_started(action: Dictionary) -> void:
	"""Handle action execution started"""
	var source = action.get("source")
	EventBus.emit_debug("Action started: %s" % str(action.get("type", "unknown")))

# =============================================================================
# ANIMATION SYSTEM CALLBACKS
# =============================================================================

func _on_vfx_spawned(effect_name: String, instance: Node) -> void:
	EventBus.emit_debug("VFX spawned: %s" % effect_name)

func _on_vfx_completed(effect_name: String) -> void:
	pass  # Effect completed, could trigger follow-up

func _on_damage_number_spawned(number_node: Node) -> void:
	pass  # Damage number visible

func _on_camera_shake_completed() -> void:
	pass  # Camera shake done

func _on_camera_focus_completed() -> void:
	pass  # Camera focus transition done

# =============================================================================
# ADVANCED DAMAGE NUMBERS
# =============================================================================

func _spawn_advanced_damage_number(data: Dictionary) -> void:
	"""Spawn damage number using the advanced system or fallback"""
	var position = data.get("position", Vector2.ZERO)
	var amount = data.get("amount", 0)
	var is_critical = data.get("is_critical", false)
	var is_heal = data.get("is_heal", false)
	var brand = data.get("brand", "")

	if damage_number_spawner:
		if is_heal:
			damage_number_spawner.spawn_heal(position, amount)
		else:
			damage_number_spawner.spawn_damage(position, amount, is_critical, brand)
	else:
		_spawn_damage_number(position, amount, is_critical, is_heal)

# =============================================================================
# CAMERA EFFECTS (Legacy - kept for compatibility)
# =============================================================================

func shake_camera(intensity: float = 5.0, duration: float = 0.2) -> void:
	"""Legacy camera shake - now routes to battle camera"""
	if battle_camera:
		battle_camera.shake(Vector2(intensity, intensity), duration)
	else:
		# Fallback for when battle camera isn't available
		_legacy_shake_camera(intensity, duration)

func _legacy_shake_camera(intensity: float, duration: float) -> void:
	"""Original camera shake implementation as fallback"""
	var camera_node: Camera2D = get_node_or_null("BattleCamera") as Camera2D
	if not camera_node:
		return
	var original_offset: Vector2 = camera_node.offset
	var tween := create_tween()

	for i in range(int(duration / 0.05)):
		var shake_offset := Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(camera_node, "offset", original_offset + shake_offset, 0.05)

	tween.tween_property(camera_node, "offset", original_offset, 0.05)


func _get_character_sprite_path(character: CharacterBase) -> String:
	# Check if it's a monster with a sprite
	if character is Monster:
		var monster := character as Monster
		var monster_path := "res://assets/sprites/monsters/%s.png" % monster.monster_id
		if ResourceLoader.exists(monster_path):
			return monster_path

	# Check for hero portraits
	var hero_path := "res://assets/characters/heroes/%s.png" % character.character_name.to_lower()
	if ResourceLoader.exists(hero_path):
		return hero_path

	# Default - no sprite found
	return ""

# =============================================================================
# CLEANUP
# =============================================================================

func cleanup_battle() -> void:
	# Clear character sprites
	for sprite in player_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	player_sprites.clear()

	for sprite in enemy_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	enemy_sprites.clear()

	# Clear damage numbers
	for child in damage_numbers_container.get_children():
		child.queue_free()

	is_battle_active = false

# =============================================================================
# UTILITY
# =============================================================================

func get_battle_manager() -> BattleManager:
	return battle_manager

func get_turn_manager() -> TurnManager:
	return turn_manager
