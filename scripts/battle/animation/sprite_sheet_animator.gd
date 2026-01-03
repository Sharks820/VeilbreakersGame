# =============================================================================
# VEILBREAKERS Sprite Sheet Animator
# Advanced animation system using multiple sprite sheets per monster
# Supports idle, attack, special, hurt, death animations with particles
# Uses MonsterSpriteConfig for frame mappings
# =============================================================================

class_name SpriteSheetAnimator
extends Node

## Emitted when animation reaches key frames (for damage timing, VFX sync)
signal animation_event(event_name: String, data: Dictionary)
signal animation_finished(anim_name: String)
signal hit_frame_reached()

# =============================================================================
# EXPORTS
# =============================================================================

@export_group("Sprite Configuration")
@export var sprite: Sprite2D
@export var animation_player: AnimationPlayer

@export_group("Sheet Configuration")
## Number of columns in sprite sheet
@export var h_frames: int = 4
## Number of rows in sprite sheet
@export var v_frames: int = 4
## Frames per second for animations
@export var default_fps: float = 10.0

@export_group("Visual Effects")
@export var enable_breathing: bool = true
@export var breathing_amount: float = 0.02
@export var breathing_speed: float = 1.5
@export var enable_shadow: bool = true
@export var brand_color: Color = Color.WHITE
@export var glow_color: Color = Color.WHITE

# =============================================================================
# ANIMATION DATA STRUCTURE
# =============================================================================

## Animation definition: which frames to play, timing, events
class AnimationDef:
	var name: String = ""
	var sheet_path: String = ""  # Which sprite sheet to use
	var sheet_index: int = 0  # Which sheet in the config
	var start_frame: int = 0
	var end_frame: int = 0
	var fps: float = 10.0
	var loop: bool = false
	var hit_frame: int = -1  # Frame that triggers damage
	var events: Dictionary = {}  # frame_number -> event_name
	
	func _init(p_name: String = "", p_sheet: String = "", p_start: int = 0, p_end: int = 0, p_fps: float = 10.0, p_loop: bool = false) -> void:
		name = p_name
		sheet_path = p_sheet
		start_frame = p_start
		end_frame = p_end
		fps = p_fps
		loop = p_loop

# =============================================================================
# STATE
# =============================================================================

var _animations: Dictionary = {}  # name -> AnimationDef
var _current_animation: String = ""
var _current_frame: int = 0
var _frame_timer: float = 0.0
var _is_playing: bool = false
var _is_reversed: bool = false

var _original_scale: Vector2 = Vector2.ONE
var _original_position: Vector2 = Vector2.ZERO
var _breathing_time: float = 0.0
var _is_enemy: bool = false

var _loaded_sheets: Dictionary = {}  # path -> Texture2D
var _current_sheet_path: String = ""
var _current_sheet_index: int = 0

# Monster configuration
var _monster_config: Dictionary = {}
var _monster_id: String = ""

# Tween references for cleanup
var _active_tweens: Array[Tween] = []

# Particle systems
var _particle_container: Node2D = null

# Sheet configurations cache
var _sheet_configs: Array = []

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	if sprite:
		_original_scale = sprite.scale
		_original_position = sprite.position
		sprite.hframes = h_frames
		sprite.vframes = v_frames

func setup(target_sprite: Sprite2D, is_enemy: bool = false) -> void:
	"""Initialize with a sprite to animate"""
	sprite = target_sprite
	_is_enemy = is_enemy
	
	if sprite:
		_original_scale = sprite.scale
		_original_position = sprite.position
		sprite.hframes = h_frames
		sprite.vframes = v_frames
		
		# Create particle container as sibling
		_particle_container = Node2D.new()
		_particle_container.name = "ParticleContainer"
		sprite.add_sibling(_particle_container)

func setup_from_config(target_sprite: Sprite2D, monster_id: String, is_enemy: bool = false) -> void:
	"""Initialize using MonsterSpriteConfig"""
	sprite = target_sprite
	_is_enemy = is_enemy
	_monster_id = monster_id
	
	# Load configuration
	_monster_config = MonsterSpriteConfig.get_config(monster_id)
	_sheet_configs = _monster_config.get("sheets", [])
	
	# Apply config
	h_frames = _monster_config.get("h_frames", 4)
	v_frames = _monster_config.get("v_frames", 4)
	brand_color = _monster_config.get("brand_color", Color.WHITE)
	glow_color = _monster_config.get("glow_color", Color.WHITE)
	
	if sprite:
		var config_scale: Vector2 = _monster_config.get("scale", Vector2(0.5, 0.5))
		sprite.scale = config_scale
		_original_scale = config_scale
		_original_position = sprite.position
		sprite.hframes = h_frames
		sprite.vframes = v_frames
		
		# Create particle container
		_particle_container = Node2D.new()
		_particle_container.name = "ParticleContainer"
		sprite.add_sibling(_particle_container)
	
	# Load all sheets and register animations
	_load_all_sheets()
	_register_all_animations()
	
	# Start with idle
	if _animations.has("idle"):
		play("idle")

func _load_all_sheets() -> void:
	"""Preload all sprite sheets from config"""
	for i in range(_sheet_configs.size()):
		var sheet_config: MonsterSpriteConfig.SheetConfig = _sheet_configs[i]
		if not _loaded_sheets.has(sheet_config.sheet_path):
			var texture: Texture2D = load(sheet_config.sheet_path)
			if texture:
				_loaded_sheets[sheet_config.sheet_path] = texture
			else:
				push_warning("SpriteSheetAnimator: Failed to load sheet: %s" % sheet_config.sheet_path)

func _register_all_animations() -> void:
	"""Register all animations from all sheets"""
	for i in range(_sheet_configs.size()):
		var sheet_config: MonsterSpriteConfig.SheetConfig = _sheet_configs[i]
		for anim_name in sheet_config.animations.keys():
			var frame_range: MonsterSpriteConfig.FrameRange = sheet_config.animations[anim_name]
			
			var anim := AnimationDef.new(
				anim_name,
				sheet_config.sheet_path,
				frame_range.start,
				frame_range.end,
				frame_range.fps,
				frame_range.loop
			)
			anim.sheet_index = i
			anim.hit_frame = frame_range.hit_frame
			
			# Don't overwrite if already exists (prefer earlier sheets)
			if not _animations.has(anim_name):
				_animations[anim_name] = anim

func configure_grid(columns: int, rows: int) -> void:
	"""Set the sprite sheet grid configuration"""
	h_frames = columns
	v_frames = rows
	if sprite:
		sprite.hframes = columns
		sprite.vframes = rows

# =============================================================================
# ANIMATION REGISTRATION
# =============================================================================

func register_animation(anim_name: String, sheet_path: String, start_frame: int, end_frame: int, fps: float = 10.0, loop: bool = false) -> AnimationDef:
	"""Register a new animation with its sprite sheet and frame range"""
	var anim := AnimationDef.new(anim_name, sheet_path, start_frame, end_frame, fps, loop)
	_animations[anim_name] = anim
	
	# Preload the sheet
	if not _loaded_sheets.has(sheet_path):
		var texture: Texture2D = load(sheet_path)
		if texture:
			_loaded_sheets[sheet_path] = texture
		else:
			push_warning("SpriteSheetAnimator: Failed to load sheet: %s" % sheet_path)
	
	return anim

func set_hit_frame(anim_name: String, frame: int) -> void:
	"""Set which frame triggers the hit event"""
	if _animations.has(anim_name):
		_animations[anim_name].hit_frame = frame

func add_animation_event(anim_name: String, frame: int, event_name: String) -> void:
	"""Add an event to trigger at a specific frame"""
	if _animations.has(anim_name):
		_animations[anim_name].events[frame] = event_name

# =============================================================================
# PLAYBACK
# =============================================================================

func play(anim_name: String, reversed: bool = false) -> void:
	"""Play an animation by name"""
	if not _animations.has(anim_name):
		# Try to find a fallback
		var fallback := _get_fallback_animation(anim_name)
		if fallback == "":
			push_warning("SpriteSheetAnimator: Unknown animation '%s' for %s" % [anim_name, _monster_id])
			return
		anim_name = fallback
	
	var anim: AnimationDef = _animations[anim_name]
	
	# Switch sprite sheet if needed (also updates h_frames/v_frames)
	if anim.sheet_path != _current_sheet_path:
		_switch_sheet(anim.sheet_path, anim.sheet_index)
	
	_current_animation = anim_name
	_current_frame = anim.start_frame if not reversed else anim.end_frame
	_frame_timer = 0.0
	_is_playing = true
	_is_reversed = reversed
	
	if sprite:
		sprite.frame = _current_frame
	else:
		push_error("SpriteSheetAnimator: No sprite to animate for %s" % _monster_id)

func _get_fallback_animation(anim_name: String) -> String:
	"""Get a fallback animation if the requested one doesn't exist"""
	# Common fallbacks
	var fallbacks := {
		"attack_heavy": "attack",
		"hurt_heavy": "hurt",
		"death_alt": "death",
		"idle_alt": "idle",
	}
	
	if fallbacks.has(anim_name) and _animations.has(fallbacks[anim_name]):
		return fallbacks[anim_name]
	
	# Skill fallbacks - try generic skill, then attack
	if anim_name.begins_with("skill_"):
		if _animations.has("skill"):
			return "skill"
		if _animations.has("attack"):
			return "attack"
	
	return ""

func stop() -> void:
	"""Stop current animation"""
	_is_playing = false

func is_playing() -> bool:
	return _is_playing

func get_current_animation() -> String:
	return _current_animation

func _switch_sheet(sheet_path: String, sheet_index: int = 0) -> void:
	"""Switch to a different sprite sheet"""
	if not sprite:
		return
	
	# Update grid configuration if sheet has different dimensions
	if sheet_index < _sheet_configs.size():
		var sheet_config: MonsterSpriteConfig.SheetConfig = _sheet_configs[sheet_index]
		if sprite.hframes != sheet_config.h_frames or sprite.vframes != sheet_config.v_frames:
			sprite.hframes = sheet_config.h_frames
			sprite.vframes = sheet_config.v_frames
	
	if _loaded_sheets.has(sheet_path):
		sprite.texture = _loaded_sheets[sheet_path]
		_current_sheet_path = sheet_path
		_current_sheet_index = sheet_index
	else:
		var texture: Texture2D = load(sheet_path)
		if texture:
			_loaded_sheets[sheet_path] = texture
			sprite.texture = texture
			_current_sheet_path = sheet_path
			_current_sheet_index = sheet_index
		else:
			push_error("SpriteSheetAnimator: Failed to load sheet: %s" % sheet_path)

func _process(delta: float) -> void:
	# NOTE: Debug prints removed - they were flooding console and causing MCP hangs
	_process_animation(delta)
	_process_breathing(delta)

func _process_animation(delta: float) -> void:
	if not _is_playing or not sprite:
		return
	
	if not _animations.has(_current_animation):
		return
	
	var anim: AnimationDef = _animations[_current_animation]
	_frame_timer += delta
	
	var frame_duration := 1.0 / anim.fps
	
	if _frame_timer >= frame_duration:
		_frame_timer -= frame_duration
		
		# Check for events on current frame
		if anim.events.has(_current_frame):
			animation_event.emit(anim.events[_current_frame], {"animation": _current_animation, "frame": _current_frame})
		
		# Check for hit frame
		if _current_frame == anim.hit_frame:
			hit_frame_reached.emit()
		
		# Advance frame
		if not _is_reversed:
			_current_frame += 1
			if _current_frame > anim.end_frame:
				if anim.loop:
					_current_frame = anim.start_frame
				else:
					_current_frame = anim.end_frame
					_is_playing = false
					animation_finished.emit(_current_animation)
		else:
			_current_frame -= 1
			if _current_frame < anim.start_frame:
				if anim.loop:
					_current_frame = anim.end_frame
				else:
					_current_frame = anim.start_frame
					_is_playing = false
					animation_finished.emit(_current_animation)
		
		sprite.frame = _current_frame

func _process_breathing(delta: float) -> void:
	if not enable_breathing or not sprite or _is_playing:
		return
	
	_breathing_time += delta * breathing_speed
	var breath_offset := sin(_breathing_time * TAU) * breathing_amount
	sprite.scale = _original_scale * Vector2(1.0, 1.0 + breath_offset)
	
	# Subtle vertical bob
	var bob_offset := sin(_breathing_time * TAU * 0.5) * 2.0
	sprite.position.y = _original_position.y + bob_offset

# =============================================================================
# COMBAT ANIMATIONS WITH EFFECTS
# =============================================================================

func play_attack(on_hit: Callable = Callable()) -> void:
	"""Play attack animation with hit callback"""
	if _animations.has("attack"):
		play("attack")
		if on_hit.is_valid():
			# Connect one-shot to hit frame
			var connection := func():
				on_hit.call()
			hit_frame_reached.connect(connection, CONNECT_ONE_SHOT)
	else:
		# Fallback to procedural attack
		await _procedural_attack()
		if on_hit.is_valid():
			on_hit.call()

func play_skill(skill_name: String, on_cast: Callable = Callable()) -> void:
	"""Play skill animation - looks for skill-specific animation first"""
	var skill_anim := "skill_" + skill_name.to_lower().replace(" ", "_")
	var anim_to_play := ""
	var has_hit_frame := false
	
	# Try skill-specific animation
	if _animations.has(skill_anim):
		anim_to_play = skill_anim
		has_hit_frame = _animations[skill_anim].hit_frame >= 0
	# Try generic special
	elif _animations.has("special"):
		anim_to_play = "special"
		has_hit_frame = _animations["special"].hit_frame >= 0
	# Try attack as fallback
	elif _animations.has("attack"):
		anim_to_play = "attack"
		has_hit_frame = _animations["attack"].hit_frame >= 0
	
	if anim_to_play != "":
		play(anim_to_play)
		
		if on_cast.is_valid():
			if has_hit_frame:
				# Connect to hit frame signal
				var connection := func():
					on_cast.call()
				hit_frame_reached.connect(connection, CONNECT_ONE_SHOT)
			else:
				# Trigger at midpoint
				await get_tree().create_timer(0.3).timeout
				on_cast.call()
	else:
		# Procedural fallback
		await _procedural_skill()
		if on_cast.is_valid():
			on_cast.call()

func play_hurt(is_critical: bool = false) -> void:
	"""Play hurt reaction with screen shake"""
	_stop_all_tweens()
	
	# Flash white
	_flash_color(Color.WHITE if not is_critical else Color(1.0, 0.3, 0.3), 0.1)
	
	# Squash effect
	_squash_stretch(0.15)
	
	if _animations.has("hurt"):
		play("hurt")
	else:
		await _procedural_hurt(is_critical)

func play_death() -> void:
	"""Play death animation with dissolve effect"""
	enable_breathing = false
	
	if _animations.has("death"):
		play("death")
	else:
		await _procedural_death()

func play_idle() -> void:
	"""Return to idle animation"""
	_stop_all_tweens()
	enable_breathing = true
	
	if _animations.has("idle"):
		play("idle")
	else:
		# Reset to first frame
		if sprite:
			sprite.frame = 0

func play_spawn() -> void:
	"""Play spawn/summon animation"""
	if not sprite:
		return
	
	sprite.modulate.a = 0.0
	sprite.scale = Vector2.ZERO
	
	var tween := create_tween()
	_active_tweens.append(tween)
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.3)
	tween.tween_property(sprite, "scale", _original_scale, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	await tween.finished
	
	if _animations.has("spawn"):
		play("spawn")
	
	# Spawn particles
	_spawn_particles("spawn", sprite.global_position)

func play_victory() -> void:
	"""Play victory celebration"""
	if _animations.has("victory"):
		play("victory")
	else:
		await _procedural_victory()

# =============================================================================
# PROCEDURAL ANIMATIONS (Fallback when no sprite sheet animation exists)
# =============================================================================

func _procedural_attack() -> void:
	"""Procedural attack animation using transforms"""
	if not sprite:
		return
	
	var dir := -1.0 if _is_enemy else 1.0
	var tween := create_tween()
	_active_tweens.append(tween)
	
	# Anticipation
	tween.tween_property(sprite, "position", _original_position + Vector2(-15 * dir, 5), 0.15)
	tween.tween_property(sprite, "scale", _original_scale * Vector2(0.95, 1.05), 0.15)
	
	# Lunge
	tween.tween_property(sprite, "position", _original_position + Vector2(60 * dir, -10), 0.1)
	tween.tween_property(sprite, "scale", _original_scale * Vector2(1.1, 0.95), 0.1)
	
	# Recovery
	tween.tween_property(sprite, "position", _original_position, 0.2)
	tween.tween_property(sprite, "scale", _original_scale, 0.2)
	
	await tween.finished

func _procedural_skill() -> void:
	"""Procedural skill animation"""
	if not sprite:
		return
	
	var tween := create_tween()
	_active_tweens.append(tween)
	
	# Rise up
	tween.tween_property(sprite, "position", _original_position + Vector2(0, -20), 0.2)
	tween.tween_property(sprite, "scale", _original_scale * 1.1, 0.2)
	
	# Glow
	tween.tween_property(sprite, "modulate", Color(1.3, 1.3, 1.5), 0.15)
	
	# Release
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	tween.tween_property(sprite, "position", _original_position, 0.25)
	tween.tween_property(sprite, "scale", _original_scale, 0.25)
	
	await tween.finished

func _procedural_hurt(is_critical: bool) -> void:
	"""Procedural hurt animation"""
	if not sprite:
		return
	
	var dir := -1.0 if _is_enemy else 1.0
	var intensity := 1.5 if is_critical else 1.0
	
	var tween := create_tween()
	_active_tweens.append(tween)
	
	# Recoil
	tween.tween_property(sprite, "position", _original_position + Vector2(-25 * dir * intensity, 0), 0.1)
	tween.tween_property(sprite, "rotation_degrees", -5 * dir * intensity, 0.1)
	
	# Recovery
	tween.tween_property(sprite, "position", _original_position, 0.2)
	tween.tween_property(sprite, "rotation_degrees", 0, 0.2)
	
	await tween.finished

func _procedural_death() -> void:
	"""Procedural death animation"""
	if not sprite:
		return
	
	var dir := -1.0 if _is_enemy else 1.0
	
	var tween := create_tween()
	_active_tweens.append(tween)
	
	# Stagger
	tween.tween_property(sprite, "position", _original_position + Vector2(-30 * dir, 0), 0.3)
	tween.tween_property(sprite, "rotation_degrees", -15 * dir, 0.3)
	
	# Fall
	tween.tween_property(sprite, "position", _original_position + Vector2(-50 * dir, 40), 0.4)
	tween.tween_property(sprite, "rotation_degrees", -90 * dir, 0.4)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	
	await tween.finished

func _procedural_victory() -> void:
	"""Procedural victory animation"""
	if not sprite:
		return
	
	var tween := create_tween()
	_active_tweens.append(tween)
	
	# Jump
	tween.tween_property(sprite, "position", _original_position + Vector2(0, -30), 0.2)
	tween.tween_property(sprite, "scale", _original_scale * Vector2(0.95, 1.1), 0.2)
	
	# Land
	tween.tween_property(sprite, "position", _original_position + Vector2(0, 5), 0.15)
	tween.tween_property(sprite, "scale", _original_scale * Vector2(1.1, 0.9), 0.15)
	
	# Settle
	tween.tween_property(sprite, "position", _original_position, 0.2)
	tween.tween_property(sprite, "scale", _original_scale, 0.2)
	
	await tween.finished

# =============================================================================
# VISUAL EFFECTS
# =============================================================================

func _flash_color(color: Color, duration: float) -> void:
	"""Flash the sprite a color"""
	if not sprite:
		return
	
	var original := sprite.modulate
	sprite.modulate = color
	
	var tween := create_tween()
	_active_tweens.append(tween)
	tween.tween_property(sprite, "modulate", original, duration)

func _squash_stretch(duration: float) -> void:
	"""Squash and stretch effect on impact"""
	if not sprite:
		return
	
	var tween := create_tween()
	_active_tweens.append(tween)
	
	# Squash
	tween.tween_property(sprite, "scale", _original_scale * Vector2(1.15, 0.85), duration * 0.3)
	# Stretch
	tween.tween_property(sprite, "scale", _original_scale * Vector2(0.9, 1.1), duration * 0.4)
	# Return
	tween.tween_property(sprite, "scale", _original_scale, duration * 0.3)

func _spawn_particles(effect_type: String, position: Vector2) -> void:
	"""Spawn particle effect at position"""
	if not _particle_container:
		return
	
	# Create GPU particles based on effect type
	var particles := GPUParticles2D.new()
	particles.position = position - sprite.global_position if sprite else position
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.amount = 16
	
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 20.0
	material.direction = Vector3(0, -1, 0)
	material.spread = 45.0
	material.initial_velocity_min = 50.0
	material.initial_velocity_max = 100.0
	material.gravity = Vector3(0, 200, 0)
	material.scale_min = 0.5
	material.scale_max = 1.5
	
	match effect_type:
		"spawn":
			material.color = Color(0.8, 0.6, 1.0, 0.8)
		"hit":
			material.color = Color(1.0, 0.3, 0.3, 0.9)
			material.direction = Vector3(1, 0, 0) if _is_enemy else Vector3(-1, 0, 0)
		"death":
			material.color = Color(0.2, 0.1, 0.3, 0.7)
			particles.amount = 32
		_:
			material.color = Color.WHITE
	
	particles.process_material = material
	particles.finished.connect(particles.queue_free)
	
	_particle_container.add_child(particles)

func _stop_all_tweens() -> void:
	"""Kill all active tweens"""
	for tween in _active_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_active_tweens.clear()

# =============================================================================
# UTILITY
# =============================================================================

func reset_transform() -> void:
	"""Reset sprite to original transform"""
	if sprite:
		sprite.position = _original_position
		sprite.scale = _original_scale
		sprite.rotation_degrees = 0
		sprite.modulate = Color.WHITE

func set_enemy(is_enemy: bool) -> void:
	_is_enemy = is_enemy

func get_animation_names() -> Array[String]:
	var names: Array[String] = []
	for key in _animations.keys():
		names.append(key)
	return names
