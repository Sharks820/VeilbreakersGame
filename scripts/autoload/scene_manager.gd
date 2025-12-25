extends Node
## SceneManager: Handles scene transitions with loading screens and fade effects.

# =============================================================================
# STATE
# =============================================================================

var current_scene: Node = null
var current_scene_path: String = ""
var is_transitioning: bool = false

var _transition_canvas: CanvasLayer
var _fade_rect: ColorRect
var _loading_container: Control
var _progress_bar: ProgressBar
var _loading_label: Label

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_transition_ui()

	# Get initial scene
	await get_tree().process_frame
	current_scene = get_tree().current_scene
	if current_scene:
		current_scene_path = current_scene.scene_file_path

	EventBus.emit_debug("SceneManager initialized")

func _setup_transition_ui() -> void:
	# Create canvas layer for transitions
	_transition_canvas = CanvasLayer.new()
	_transition_canvas.layer = 100
	add_child(_transition_canvas)

	# Fade rectangle
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.modulate.a = 0.0
	_transition_canvas.add_child(_fade_rect)

	# Loading container
	_loading_container = Control.new()
	_loading_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loading_container.visible = false
	_transition_canvas.add_child(_loading_container)

	# Loading background
	var loading_bg := ColorRect.new()
	loading_bg.color = Color(0.1, 0.1, 0.15, 1.0)
	loading_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loading_container.add_child(loading_bg)

	# Center container for loading elements
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loading_container.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)

	# Loading label
	_loading_label = Label.new()
	_loading_label.text = "Loading..."
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_loading_label)

	# Progress bar
	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(400, 24)
	_progress_bar.show_percentage = false
	vbox.add_child(_progress_bar)

# =============================================================================
# SCENE TRANSITIONS
# =============================================================================

func change_scene(scene_path: String, fade_duration: float = Constants.SCENE_TRANSITION_DURATION) -> void:
	if is_transitioning:
		push_warning("Scene transition already in progress")
		return

	is_transitioning = true
	var from_scene := current_scene_path

	EventBus.scene_transition_started.emit(from_scene, scene_path)

	# Fade out
	await _fade_out(fade_duration)

	# Load and switch scene
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Failed to change scene: %s" % scene_path)
		await _fade_in(fade_duration)
		is_transitioning = false
		return

	# Wait for scene to be ready
	await get_tree().process_frame

	# Update references
	current_scene = get_tree().current_scene
	current_scene_path = scene_path

	# Fade in
	await _fade_in(fade_duration)

	is_transitioning = false
	EventBus.scene_transition_completed.emit(scene_path)

func change_scene_with_loading(scene_path: String, loading_text: String = "Loading...") -> void:
	if is_transitioning:
		push_warning("Scene transition already in progress")
		return

	is_transitioning = true
	var from_scene := current_scene_path

	EventBus.scene_transition_started.emit(from_scene, scene_path)

	# Fade out
	await _fade_out(Constants.SCENE_TRANSITION_DURATION)

	# Show loading screen
	_loading_label.text = loading_text
	_loading_container.visible = true
	_progress_bar.value = 0

	# Fade in loading screen
	_fade_rect.modulate.a = 0.0

	# Start threaded loading
	ResourceLoader.load_threaded_request(scene_path)

	# Monitor loading progress
	while true:
		var progress: Array = []
		var status := ResourceLoader.load_threaded_get_status(scene_path, progress)

		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_progress_bar.value = progress[0] * 100
			await get_tree().process_frame
		elif status == ResourceLoader.THREAD_LOAD_LOADED:
			_progress_bar.value = 100
			break
		else:
			push_error("Failed to load scene: %s" % scene_path)
			_loading_container.visible = false
			await _fade_in(Constants.SCENE_TRANSITION_DURATION)
			is_transitioning = false
			return

	# Get loaded scene
	var packed_scene: PackedScene = ResourceLoader.load_threaded_get(scene_path)

	# Switch scene
	if current_scene:
		current_scene.queue_free()

	current_scene = packed_scene.instantiate()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene
	current_scene_path = scene_path

	# Small delay for scene initialization
	await get_tree().create_timer(0.2).timeout

	# Hide loading screen
	_loading_container.visible = false

	# Fade in
	await _fade_in(Constants.SCENE_TRANSITION_DURATION)

	is_transitioning = false
	EventBus.scene_transition_completed.emit(scene_path)

# =============================================================================
# FADE EFFECTS
# =============================================================================

func _fade_out(duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, duration)
	await tween.finished

func _fade_in(duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 0.0, duration)
	await tween.finished

func fade_to_black(duration: float = 0.5) -> void:
	await _fade_out(duration)

func fade_from_black(duration: float = 0.5) -> void:
	await _fade_in(duration)

func flash(color: Color = Color.WHITE, duration: float = 0.1) -> void:
	_fade_rect.color = color
	_fade_rect.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 0.0, duration)
	await tween.finished
	_fade_rect.color = Color.BLACK

func flash_damage(duration: float = 0.1) -> void:
	await flash(Color(1.0, 0.2, 0.2, 0.5), duration)

func flash_heal(duration: float = 0.2) -> void:
	await flash(Color(0.2, 1.0, 0.2, 0.3), duration)

# =============================================================================
# SCENE QUERIES
# =============================================================================

func get_current_scene_name() -> String:
	if current_scene_path.is_empty():
		return ""
	return current_scene_path.get_file().get_basename()

func is_scene(scene_name: String) -> bool:
	return get_current_scene_name() == scene_name

func is_main_menu() -> bool:
	return is_scene("main_menu")

func is_overworld() -> bool:
	return is_scene("overworld")

func is_battle() -> bool:
	return is_scene("battle_arena")

# =============================================================================
# NAVIGATION HELPERS
# =============================================================================

func go_to_main_menu() -> void:
	await change_scene("res://scenes/main/main_menu.tscn")
	GameManager.change_state(Enums.GameState.MAIN_MENU)

## Alias for go_to_main_menu (backwards compatibility)
func goto_main_menu() -> void:
	await go_to_main_menu()

func go_to_overworld() -> void:
	await change_scene_with_loading("res://scenes/overworld/overworld.tscn")
	GameManager.change_state(Enums.GameState.OVERWORLD)

func go_to_battle(enemy_data: Array = []) -> void:
	await change_scene("res://scenes/battle/battle_arena.tscn")
	GameManager.change_state(Enums.GameState.BATTLE)
	EventBus.battle_started.emit(enemy_data)

# =============================================================================
# RELOAD
# =============================================================================

func reload_current_scene() -> void:
	if current_scene_path.is_empty():
		push_error("No current scene to reload")
		return

	await change_scene(current_scene_path)

# =============================================================================
# UTILITY
# =============================================================================

func get_scene_tree_as_text() -> String:
	if not current_scene:
		return "No current scene"

	var result := ""
	result = _build_tree_text(current_scene, result, 0)
	return result

func _build_tree_text(node: Node, result: String, depth: int) -> String:
	result += "  ".repeat(depth) + node.name + " (" + node.get_class() + ")\n"
	for child in node.get_children():
		result = _build_tree_text(child, result, depth + 1)
	return result
