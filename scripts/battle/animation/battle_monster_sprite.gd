# =============================================================================
# VEILBREAKERS Battle Monster Sprite
# Visual representation of a monster in battle with full animation support
# Integrates with SpriteSheetAnimator and particle effects
# =============================================================================

class_name BattleMonsterSprite
extends Node2D

## Emitted when animation events occur (for battle timing)
signal animation_event(event_name: String, data: Dictionary)
signal animation_finished(anim_name: String)
signal hit_frame_reached()
signal death_animation_complete()

# =============================================================================
# PRELOADS (for class references)
# =============================================================================

const SpriteSheetAnimatorScript := preload("res://scripts/battle/animation/sprite_sheet_animator.gd")
const MonsterSpriteConfigScript := preload("res://scripts/battle/animation/monster_sprite_config.gd")

# =============================================================================
# EXPORTS
# =============================================================================

@export_group("Monster Configuration")
@export var monster_id: String = ""
@export var is_enemy: bool = true

@export_group("Visual Components")
@export var main_sprite: Sprite2D
@export var shadow_sprite: Sprite2D
@export var glow_sprite: Sprite2D
@export var status_icon_container: Control

# =============================================================================
# STATE
# =============================================================================

var _animator: Node = null  # SpriteSheetAnimator instance
var _monster_config: Dictionary = {}
var _is_dead: bool = false

# Visual effect nodes
var _particle_emitters: Dictionary = {}  # effect_name -> GPUParticles2D
var _brand_color: Color = Color.WHITE
var _glow_color: Color = Color.WHITE

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	# Create sprite if not assigned
	if not main_sprite:
		main_sprite = Sprite2D.new()
		main_sprite.name = "MainSprite"
		add_child(main_sprite)
	
	# Create shadow
	if not shadow_sprite:
		_create_shadow()
	
	# Create animator
	_animator = SpriteSheetAnimatorScript.new()
	_animator.name = "Animator"
	add_child(_animator)
	
	# Connect animator signals
	_animator.animation_event.connect(_on_animation_event)
	_animator.animation_finished.connect(_on_animation_finished)
	_animator.hit_frame_reached.connect(_on_hit_frame)

func setup(p_monster_id: String, p_is_enemy: bool = true) -> void:
	"""Initialize the battle sprite for a specific monster"""
	monster_id = p_monster_id
	is_enemy = p_is_enemy
	
	# Ensure animator exists (may be called before _ready)
	if not _animator:
		_animator = SpriteSheetAnimatorScript.new()
		_animator.name = "Animator"
		add_child(_animator)
		# Connect signals
		if _animator.has_signal("animation_event"):
			_animator.animation_event.connect(_on_animation_event)
		if _animator.has_signal("animation_finished"):
			_animator.animation_finished.connect(_on_animation_finished)
		if _animator.has_signal("hit_frame_reached"):
			_animator.hit_frame_reached.connect(_on_hit_frame)
	
	# Check if monster has sprite sheet config
	if MonsterSpriteConfigScript.has_sprite_sheets(monster_id):
		_monster_config = MonsterSpriteConfigScript.get_config(monster_id)
		_brand_color = _monster_config.get("brand_color", Color.WHITE)
		_glow_color = _monster_config.get("glow_color", Color.WHITE)
		
		# Setup animator with config
		_animator.setup_from_config(main_sprite, monster_id, is_enemy)
		
		# Flip sprite for enemies (face left)
		if is_enemy:
			main_sprite.flip_h = true
	else:
		# Fallback to static sprite with procedural animation
		_setup_static_sprite()
	
	# Setup shadow
	_update_shadow()
	
	# Create brand-colored particle systems
	_create_particle_systems()

func _setup_static_sprite() -> void:
	"""Setup for monsters without sprite sheets"""
	# Load static sprite from monster data
	var monster_data: MonsterData = DataManager.get_monster(monster_id)
	if monster_data and monster_data.sprite_path:
		var texture: Texture2D = load(monster_data.sprite_path)
		if texture:
			main_sprite.texture = texture
			main_sprite.scale = Vector2(0.08, 0.08)  # Default monster scale
	
	# Setup animator for procedural animations
	_animator.setup(main_sprite, is_enemy)
	
	if is_enemy:
		main_sprite.flip_h = true

func _create_shadow() -> void:
	"""Create a simple shadow under the monster"""
	shadow_sprite = Sprite2D.new()
	shadow_sprite.name = "Shadow"
	
	# Create a simple ellipse texture for shadow
	var shadow_image := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	shadow_image.fill(Color(0, 0, 0, 0))
	
	# Draw ellipse shadow
	for x in range(64):
		for y in range(32):
			var dx := (x - 32.0) / 32.0
			var dy := (y - 16.0) / 16.0
			var dist := dx * dx + dy * dy
			if dist < 1.0:
				var alpha := (1.0 - dist) * 0.4
				shadow_image.set_pixel(x, y, Color(0, 0, 0, alpha))
	
	var shadow_texture := ImageTexture.create_from_image(shadow_image)
	shadow_sprite.texture = shadow_texture
	shadow_sprite.position = Vector2(0, 50)  # Below the monster
	shadow_sprite.z_index = -1
	
	add_child(shadow_sprite)

func _update_shadow() -> void:
	"""Update shadow size based on monster scale"""
	if shadow_sprite and main_sprite:
		var monster_scale: float = main_sprite.scale.x
		shadow_sprite.scale = Vector2(monster_scale * 3, monster_scale * 2)

func _create_particle_systems() -> void:
	"""Create reusable particle emitters for various effects"""
	# Hit particles
	var hit_particles := _create_particle_emitter("hit", _brand_color, 16)
	hit_particles.position = Vector2.ZERO
	_particle_emitters["hit"] = hit_particles
	
	# Death particles
	var death_particles := _create_particle_emitter("death", _brand_color, 32)
	death_particles.position = Vector2.ZERO
	_particle_emitters["death"] = death_particles
	
	# Skill/cast particles
	var skill_particles := _create_particle_emitter("skill", _glow_color, 24)
	skill_particles.position = Vector2.ZERO
	_particle_emitters["skill"] = skill_particles

func _create_particle_emitter(effect_type: String, color: Color, amount: int) -> GPUParticles2D:
	"""Create a configured particle emitter"""
	var particles := GPUParticles2D.new()
	particles.name = effect_type + "_particles"
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.amount = amount
	particles.lifetime = 0.8
	
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 30.0
	material.direction = Vector3(0, -1, 0)
	material.spread = 60.0
	material.initial_velocity_min = 80.0
	material.initial_velocity_max = 150.0
	material.gravity = Vector3(0, 300, 0)
	material.scale_min = 2.0
	material.scale_max = 5.0
	material.color = color
	
	# Customize based on effect type
	match effect_type:
		"hit":
			material.direction = Vector3(-1 if is_enemy else 1, -0.5, 0)
			material.spread = 30.0
			material.initial_velocity_min = 100.0
			material.initial_velocity_max = 200.0
		"death":
			material.direction = Vector3(0, -1, 0)
			material.spread = 180.0
			material.gravity = Vector3(0, 100, 0)
			particles.lifetime = 1.5
		"skill":
			material.direction = Vector3(0, -1, 0)
			material.spread = 45.0
			material.gravity = Vector3(0, -50, 0)  # Float upward
	
	particles.process_material = material
	add_child(particles)
	
	return particles

# =============================================================================
# ANIMATION API
# =============================================================================

func play_idle() -> void:
	"""Return to idle animation"""
	if _is_dead:
		return
	_animator.play_idle()

func play_attack(on_hit: Callable = Callable()) -> void:
	"""Play attack animation"""
	if _is_dead:
		return
	_animator.play_attack(on_hit)

func play_attack_heavy(on_hit: Callable = Callable()) -> void:
	"""Play heavy attack animation"""
	if _is_dead:
		return
	if _animator._animations.has("attack_heavy"):
		_animator.play("attack_heavy")
		if on_hit.is_valid():
			_animator.hit_frame_reached.connect(on_hit, CONNECT_ONE_SHOT)
	else:
		play_attack(on_hit)

func play_skill(skill_name: String, on_cast: Callable = Callable()) -> void:
	"""Play skill animation"""
	if _is_dead:
		return
	
	# Emit skill particles
	_emit_particles("skill")
	
	_animator.play_skill(skill_name, on_cast)

func play_hurt(is_critical: bool = false) -> void:
	"""Play hurt reaction"""
	if _is_dead:
		return
	
	# Emit hit particles
	_emit_particles("hit")
	
	# Screen shake handled by battle manager
	if is_critical and _animator._animations.has("hurt_heavy"):
		_animator.play("hurt_heavy")
	else:
		_animator.play_hurt(is_critical)

func play_death() -> void:
	"""Play death animation"""
	_is_dead = true
	
	# Emit death particles
	_emit_particles("death")
	
	# Fade shadow
	if shadow_sprite:
		var tween := create_tween()
		tween.tween_property(shadow_sprite, "modulate:a", 0.0, 1.0)
	
	_animator.play_death()

func play_spawn() -> void:
	"""Play spawn/summon animation"""
	_is_dead = false
	_animator.play_spawn()

func play_victory() -> void:
	"""Play victory animation"""
	if _is_dead:
		return
	_animator.play_victory()

# =============================================================================
# PARTICLE EFFECTS
# =============================================================================

func _emit_particles(effect_type: String) -> void:
	"""Trigger particle emission"""
	if _particle_emitters.has(effect_type):
		var particles: GPUParticles2D = _particle_emitters[effect_type]
		particles.restart()
		particles.emitting = true

func emit_custom_particles(color: Color, amount: int, direction: Vector2 = Vector2.UP) -> void:
	"""Emit custom one-shot particles"""
	var particles := GPUParticles2D.new()
	particles.one_shot = true
	particles.emitting = true
	particles.amount = amount
	particles.lifetime = 0.6
	particles.explosiveness = 0.9
	
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	material.direction = Vector3(direction.x, direction.y, 0)
	material.spread = 30.0
	material.initial_velocity_min = 100.0
	material.initial_velocity_max = 180.0
	material.gravity = Vector3(0, 200, 0)
	material.scale_min = 2.0
	material.scale_max = 4.0
	material.color = color
	
	particles.process_material = material
	particles.finished.connect(particles.queue_free)
	add_child(particles)

# =============================================================================
# VISUAL EFFECTS
# =============================================================================

func flash_color(color: Color, duration: float = 0.1) -> void:
	"""Flash the sprite a color"""
	if not main_sprite:
		return
	
	var original := main_sprite.modulate
	main_sprite.modulate = color
	
	var tween := create_tween()
	tween.tween_property(main_sprite, "modulate", original, duration)

func set_glow(enabled: bool, intensity: float = 1.0) -> void:
	"""Enable/disable glow effect"""
	if not main_sprite:
		return
	
	if enabled:
		var glow_mod := Color(1.0 + intensity * 0.3, 1.0 + intensity * 0.3, 1.0 + intensity * 0.2)
		main_sprite.modulate = glow_mod
	else:
		main_sprite.modulate = Color.WHITE

func pulse_glow(duration: float = 0.5, intensity: float = 0.5) -> void:
	"""Pulse glow effect"""
	if not main_sprite:
		return
	
	var tween := create_tween()
	tween.set_loops(2)
	var glow_color := Color(1.0 + intensity, 1.0 + intensity, 1.0 + intensity * 0.8)
	tween.tween_property(main_sprite, "modulate", glow_color, duration * 0.5)
	tween.tween_property(main_sprite, "modulate", Color.WHITE, duration * 0.5)

func shake(intensity: float = 5.0, duration: float = 0.3) -> void:
	"""Shake the sprite"""
	var original_pos := position
	var tween := create_tween()
	var shake_count := int(duration / 0.03)
	
	for i in range(shake_count):
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity * 0.5, intensity * 0.5))
		tween.tween_property(self, "position", original_pos + offset, 0.015)
		tween.tween_property(self, "position", original_pos, 0.015)

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_animation_event(event_name: String, data: Dictionary) -> void:
	animation_event.emit(event_name, data)

func _on_animation_finished(anim_name: String) -> void:
	animation_finished.emit(anim_name)
	
	if anim_name == "death" or anim_name == "death_alt":
		death_animation_complete.emit()

func _on_hit_frame() -> void:
	hit_frame_reached.emit()

# =============================================================================
# UTILITY
# =============================================================================

func is_animating() -> bool:
	return _animator.is_playing() if _animator else false

func get_current_animation() -> String:
	return _animator.get_current_animation() if _animator else ""

func get_brand_color() -> Color:
	return _brand_color

func get_glow_color() -> Color:
	return _glow_color

func is_dead() -> bool:
	return _is_dead

func reset() -> void:
	"""Reset to initial state"""
	_is_dead = false
	if main_sprite:
		main_sprite.modulate = Color.WHITE
	if shadow_sprite:
		shadow_sprite.modulate = Color.WHITE
	play_idle()
