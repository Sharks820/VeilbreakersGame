# =============================================================================
# VEILBREAKERS VFX Manager
# Centralized visual effects spawning and management for turn-based combat
# Handles: Hit effects, status effects, capture effects, environmental effects
# =============================================================================

class_name VFXManager
extends Node

# -----------------------------------------------------------------------------
# SIGNALS
# -----------------------------------------------------------------------------
signal effect_spawned(effect_name: String, instance: Node)
signal effect_completed(effect_name: String)

# -----------------------------------------------------------------------------
# EFFECT SCENES - Configure in editor
# -----------------------------------------------------------------------------
@export_group("Hit Effects by Brand")
@export var hit_savage: PackedScene
@export var hit_iron: PackedScene
@export var hit_venom: PackedScene
@export var hit_surge: PackedScene
@export var hit_dread: PackedScene
@export var hit_leech: PackedScene
@export var hit_neutral: PackedScene
@export var hit_critical: PackedScene

@export_group("Status Effects")
@export var poison_tick: PackedScene
@export var burn_tick: PackedScene
@export var bleed_tick: PackedScene
@export var regen_tick: PackedScene
@export var stun_stars: PackedScene
@export var buff_sparkle: PackedScene
@export var debuff_spiral: PackedScene

@export_group("Status Apply/Remove")
@export var status_apply_poison: PackedScene
@export var status_apply_burn: PackedScene
@export var status_apply_stun: PackedScene
@export var status_apply_buff: PackedScene
@export var status_apply_debuff: PackedScene
@export var status_remove: PackedScene

@export_group("Capture Effects")
@export var capture_projectile: PackedScene
@export var capture_beam: PackedScene
@export var capture_shake: PackedScene
@export var capture_success: PackedScene
@export var capture_break: PackedScene

@export_group("Monster Effects")
@export var summon_effect: PackedScene
@export var return_effect: PackedScene
@export var death_effect: PackedScene
@export var evolve_effect: PackedScene

@export_group("Combat Effects")
@export var dust_cloud: PackedScene
@export var heal_effect: PackedScene
@export var revive_effect: PackedScene
@export var defend_effect: PackedScene
@export var skill_charge_generic: PackedScene

@export_group("Screen Effects")
@export var screen_flash_scene: PackedScene  # Full-screen flash

@export_group("Boss Effects")
@export var boss_death_explosion: PackedScene
@export var boss_rage_aura: PackedScene
@export var phase_transition_burst: PackedScene

# -----------------------------------------------------------------------------
# BRAND CONFIGURATIONS
# -----------------------------------------------------------------------------
const BRAND_COLORS = {
	"SAVAGE": {"primary": Color("c73e3e"), "secondary": Color("ff6b6b"), "particle": Color("8b0000")},
	"IRON": {"primary": Color("7b8794"), "secondary": Color("a8b5c4"), "particle": Color("4a5568")},
	"VENOM": {"primary": Color("6b9b37"), "secondary": Color("9acd32"), "particle": Color("2d4a0f")},
	"SURGE": {"primary": Color("4a90d9"), "secondary": Color("87ceeb"), "particle": Color("1e3a5f")},
	"DREAD": {"primary": Color("5d3e8c"), "secondary": Color("9370db"), "particle": Color("2d1f4a")},
	"LEECH": {"primary": Color("c75b8a"), "secondary": Color("ff91af"), "particle": Color("8b2252")},
	"NEUTRAL": {"primary": Color.WHITE, "secondary": Color.GRAY, "particle": Color.DARK_GRAY},
}

# -----------------------------------------------------------------------------
# OBJECT POOLS
# -----------------------------------------------------------------------------
var _pools: Dictionary = {}  # effect_name -> Array of instances
var _pool_sizes: Dictionary = {}
var _active_effects: Array = []

@export_group("Pooling")
@export var default_pool_size: int = 5
@export var max_pool_size: int = 20

# -----------------------------------------------------------------------------
# LIFECYCLE
# -----------------------------------------------------------------------------
func _ready() -> void:
	_initialize_pools()

func _initialize_pools() -> void:
	"""Pre-create commonly used effects"""
	var effects_to_pool = [
		["hit_savage", hit_savage],
		["hit_iron", hit_iron],
		["hit_venom", hit_venom],
		["hit_surge", hit_surge],
		["hit_dread", hit_dread],
		["hit_leech", hit_leech],
		["hit_neutral", hit_neutral],
		["hit_critical", hit_critical],
		["dust_cloud", dust_cloud],
		["heal_effect", heal_effect],
	]
	
	for effect_data in effects_to_pool:
		var effect_name = effect_data[0]
		var scene = effect_data[1]
		if scene:
			_create_pool(effect_name, scene, default_pool_size)

func _create_pool(effect_name: String, scene: PackedScene, size: int) -> void:
	if not scene:
		return
	
	_pools[effect_name] = []
	_pool_sizes[effect_name] = size
	
	for i in range(size):
		var instance = scene.instantiate()
		instance.visible = false
		add_child(instance)
		_pools[effect_name].append(instance)
		
		# Connect to finished signal if available
		if instance.has_signal("animation_finished"):
			instance.animation_finished.connect(_on_effect_finished.bind(effect_name, instance))
		elif instance is GPUParticles2D:
			instance.finished.connect(_on_effect_finished.bind(effect_name, instance))

# -----------------------------------------------------------------------------
# PUBLIC API - Spawn Effects
# -----------------------------------------------------------------------------
func spawn_hit_effect(data: Dictionary) -> Node:
	"""Spawn a hit effect at a position"""
	var brand = data.get("brand", "NEUTRAL").to_upper()
	var position = data.get("position", Vector2.ZERO)
	var is_critical = data.get("is_critical", false)
	
	var effect_name = "hit_critical" if is_critical else "hit_" + brand.to_lower()
	var effect = _get_from_pool(effect_name)
	
	if not effect:
		# Try to spawn directly
		effect = _spawn_direct(effect_name, _get_hit_scene(brand, is_critical))
	
	if effect:
		_activate_effect(effect, position, data)
		effect_spawned.emit(effect_name, effect)
	
	return effect

func spawn_status_tick(data: Dictionary) -> Node:
	"""Spawn status effect tick (poison drip, burn flare, etc.)"""
	var status = data.get("status", "poison")
	var position = data.get("position", Vector2.ZERO)
	
	var effect_name = status + "_tick"
	var effect = _get_from_pool(effect_name)
	
	if not effect:
		effect = _spawn_direct(effect_name, _get_status_tick_scene(status))
	
	if effect:
		_activate_effect(effect, position, data)
		effect_spawned.emit(effect_name, effect)
	
	return effect

func spawn_status_apply(data: Dictionary) -> Node:
	"""Spawn status application effect"""
	var status = data.get("status", "poison")
	var position = data.get("position", Vector2.ZERO)
	var brand = data.get("brand", "NEUTRAL")
	
	var effect_name = "status_apply_" + status
	var scene = _get_status_apply_scene(status)
	var effect = _spawn_direct(effect_name, scene)
	
	if effect:
		# Color by brand or status
		_apply_color(effect, BRAND_COLORS.get(brand, BRAND_COLORS["NEUTRAL"]))
		_activate_effect(effect, position, data)
		effect_spawned.emit(effect_name, effect)
	
	return effect

func spawn_capture_projectile(data: Dictionary) -> Node:
	"""Spawn capture throw projectile"""
	var from_pos = data.get("from", Vector2.ZERO)
	var to_pos = data.get("to", Vector2.ZERO)
	var duration = data.get("duration", 0.5)
	
	if not capture_projectile:
		return null
	
	var effect = capture_projectile.instantiate()
	add_child(effect)
	effect.global_position = from_pos
	
	# Animate to target
	var tween = create_tween()
	tween.tween_property(effect, "global_position", to_pos, duration).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		_return_to_pool("capture_projectile", effect)
	)
	
	effect_spawned.emit("capture_projectile", effect)
	return effect

func spawn_capture_beam(data: Dictionary) -> Node:
	"""Spawn capture beam effect around target"""
	var position = data.get("position", Vector2.ZERO)
	var brand = data.get("brand", "NEUTRAL")
	
	if not capture_beam:
		return null
	
	var effect = capture_beam.instantiate()
	add_child(effect)
	_apply_color(effect, BRAND_COLORS.get(brand, BRAND_COLORS["NEUTRAL"]))
	_activate_effect(effect, position, data)
	
	effect_spawned.emit("capture_beam", effect)
	return effect

func spawn_capture_shake(data: Dictionary) -> Node:
	"""Spawn single capture shake effect"""
	var position = data.get("position", Vector2.ZERO)
	var shake_number = data.get("shake_number", 1)
	
	if not capture_shake:
		return null
	
	var effect = capture_shake.instantiate()
	add_child(effect)
	_activate_effect(effect, position, data)
	
	effect_spawned.emit("capture_shake", effect)
	return effect

func spawn_capture_success(data: Dictionary) -> Node:
	"""Spawn capture success celebration"""
	var position = data.get("position", Vector2.ZERO)
	
	if not capture_success:
		return null
	
	var effect = capture_success.instantiate()
	add_child(effect)
	_activate_effect(effect, position, data)
	
	effect_spawned.emit("capture_success", effect)
	return effect

func spawn_capture_break(data: Dictionary) -> Node:
	"""Spawn capture break/fail effect"""
	var position = data.get("position", Vector2.ZERO)
	
	if not capture_break:
		return null
	
	var effect = capture_break.instantiate()
	add_child(effect)
	_activate_effect(effect, position, data)
	
	effect_spawned.emit("capture_break", effect)
	return effect

func spawn_heal_effect(data: Dictionary) -> Node:
	"""Spawn healing visual"""
	var position = data.get("position", Vector2.ZERO)
	
	var effect = _get_from_pool("heal_effect")
	if not effect and heal_effect:
		effect = heal_effect.instantiate()
		add_child(effect)
	
	if effect:
		_activate_effect(effect, position, data)
		effect_spawned.emit("heal_effect", effect)
	
	return effect

func spawn_death_effect(data: Dictionary) -> Node:
	"""Spawn death/defeat effect"""
	var position = data.get("position", Vector2.ZERO)
	var brand = data.get("brand", "NEUTRAL")
	
	if not death_effect:
		return null
	
	var effect = death_effect.instantiate()
	add_child(effect)
	_apply_color(effect, BRAND_COLORS.get(brand, BRAND_COLORS["NEUTRAL"]))
	_activate_effect(effect, position, data)
	
	effect_spawned.emit("death_effect", effect)
	return effect

func spawn_summon_effect(data: Dictionary) -> Node:
	"""Spawn monster summon/enter effect"""
	var position = data.get("position", Vector2.ZERO)
	var brand = data.get("brand", "NEUTRAL")
	
	if not summon_effect:
		return null
	
	var effect = summon_effect.instantiate()
	add_child(effect)
	_apply_color(effect, BRAND_COLORS.get(brand, BRAND_COLORS["NEUTRAL"]))
	_activate_effect(effect, position, data)
	
	effect_spawned.emit("summon_effect", effect)
	return effect

func spawn_defend_effect(data: Dictionary) -> Node:
	"""Spawn defend/guard effect"""
	var position = data.get("position", Vector2.ZERO)
	
	if not defend_effect:
		return null
	
	var effect = defend_effect.instantiate()
	add_child(effect)
	_activate_effect(effect, position, data)
	
	effect_spawned.emit("defend_effect", effect)
	return effect

func spawn_skill_charge(data: Dictionary) -> Node:
	"""Spawn skill charging effect"""
	var position = data.get("position", Vector2.ZERO)
	var brand = data.get("brand", "NEUTRAL")
	var duration = data.get("duration", 0.5)
	
	if not skill_charge_generic:
		return null
	
	var effect = skill_charge_generic.instantiate()
	add_child(effect)
	_apply_color(effect, BRAND_COLORS.get(brand, BRAND_COLORS["NEUTRAL"]))
	_activate_effect(effect, position, data)
	
	# Auto-remove after duration
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)
	
	effect_spawned.emit("skill_charge", effect)
	return effect

func spawn_dust_cloud(data: Dictionary) -> Node:
	"""Spawn dust/impact cloud"""
	var position = data.get("position", Vector2.ZERO)
	
	var effect = _get_from_pool("dust_cloud")
	if not effect and dust_cloud:
		effect = dust_cloud.instantiate()
		add_child(effect)
	
	if effect:
		_activate_effect(effect, position, data)
		effect_spawned.emit("dust_cloud", effect)
	
	return effect

# -----------------------------------------------------------------------------
# BOSS EFFECTS
# -----------------------------------------------------------------------------
func spawn_boss_death_explosion(data: Dictionary) -> Node:
	"""Epic boss death explosion"""
	var position = data.get("position", Vector2.ZERO)
	
	if not boss_death_explosion:
		return null
	
	var effect = boss_death_explosion.instantiate()
	add_child(effect)
	_activate_effect(effect, position, data)
	
	effect_spawned.emit("boss_death_explosion", effect)
	return effect

func spawn_boss_rage_aura(data: Dictionary) -> Node:
	"""Boss rage/phase transition aura"""
	var position = data.get("position", Vector2.ZERO)
	var phase = data.get("phase", 2)
	
	if not boss_rage_aura:
		return null
	
	var effect = boss_rage_aura.instantiate()
	add_child(effect)
	
	# Intensity based on phase
	if effect is GPUParticles2D:
		effect.amount = 50 * phase
	
	_activate_effect(effect, position, data)
	
	effect_spawned.emit("boss_rage_aura", effect)
	return effect

# -----------------------------------------------------------------------------
# SCREEN EFFECTS
# -----------------------------------------------------------------------------
func screen_flash(data: Dictionary) -> void:
	"""Flash the entire screen"""
	var color = data.get("color", Color.WHITE)
	var duration = data.get("duration", 0.1)
	
	if not screen_flash_scene:
		# Fallback: create a simple ColorRect flash
		var flash = ColorRect.new()
		flash.color = color
		flash.set_anchors_preset(Control.PRESET_FULL_RECT)
		get_tree().current_scene.add_child(flash)
		
		var tween = create_tween()
		tween.tween_property(flash, "modulate:a", 0.0, duration)
		tween.tween_callback(flash.queue_free)
		return
	
	var flash = screen_flash_scene.instantiate()
	get_tree().current_scene.add_child(flash)
	
	if flash.has_method("flash"):
		flash.flash(color, duration)
	else:
		var tween = create_tween()
		tween.tween_property(flash, "modulate:a", 0.0, duration)
		tween.tween_callback(flash.queue_free)

# -----------------------------------------------------------------------------
# INTERNAL - Pool Management
# -----------------------------------------------------------------------------
func _get_from_pool(effect_name: String) -> Node:
	if not _pools.has(effect_name):
		return null
	
	for instance in _pools[effect_name]:
		if not instance.visible:
			return instance
	
	# Pool exhausted - try to expand
	if _pools[effect_name].size() < max_pool_size:
		# Would need scene reference to create more
		pass
	
	return null

func _return_to_pool(effect_name: String, instance: Node) -> void:
	instance.visible = false
	_active_effects.erase(instance)

func _on_effect_finished(effect_name: String, instance: Node) -> void:
	_return_to_pool(effect_name, instance)
	effect_completed.emit(effect_name)

func _spawn_direct(effect_name: String, scene: PackedScene) -> Node:
	"""Spawn an effect without pooling"""
	if not scene:
		return null
	
	var instance = scene.instantiate()
	add_child(instance)
	
	# Auto-cleanup when done
	if instance.has_signal("animation_finished"):
		instance.animation_finished.connect(instance.queue_free)
	elif instance is GPUParticles2D:
		instance.finished.connect(instance.queue_free)
	else:
		# Fallback: remove after 2 seconds
		get_tree().create_timer(2.0).timeout.connect(func():
			if is_instance_valid(instance):
				instance.queue_free()
		)
	
	return instance

func _activate_effect(effect: Node, position: Vector2, data: Dictionary) -> void:
	"""Activate a pooled effect at a position"""
	effect.visible = true
	_active_effects.append(effect)
	
	if effect is Node2D:
		effect.global_position = position
	
	# Start playing if AnimatedSprite2D
	if effect is AnimatedSprite2D:
		effect.frame = 0
		effect.play()
	
	# Start emitting if particles
	if effect is GPUParticles2D:
		effect.restart()
	elif effect is CPUParticles2D:
		effect.restart()

func _apply_color(effect: Node, colors: Dictionary) -> void:
	"""Apply brand colors to an effect"""
	if effect is CanvasItem:
		effect.modulate = colors.get("primary", Color.WHITE)
	
	if effect.has_node("Particles") and effect.get_node("Particles") is GPUParticles2D:
		var particles = effect.get_node("Particles") as GPUParticles2D
		var material = particles.process_material
		if material is ParticleProcessMaterial:
			material.color = colors.get("particle", Color.WHITE)

func _get_hit_scene(brand: String, is_critical: bool) -> PackedScene:
	if is_critical:
		return hit_critical
	
	match brand.to_upper():
		"SAVAGE": return hit_savage
		"IRON": return hit_iron
		"VENOM": return hit_venom
		"SURGE": return hit_surge
		"DREAD": return hit_dread
		"LEECH": return hit_leech
		_: return hit_neutral

func _get_status_tick_scene(status: String) -> PackedScene:
	match status.to_lower():
		"poison", "poisoned": return poison_tick
		"burn", "burning": return burn_tick
		"bleed", "bleeding": return bleed_tick
		"regen", "regeneration": return regen_tick
		_: return poison_tick

func _get_status_apply_scene(status: String) -> PackedScene:
	match status.to_lower():
		"poison", "poisoned": return status_apply_poison
		"burn", "burning": return status_apply_burn
		"stun", "stunned": return status_apply_stun
		"buff": return status_apply_buff
		"debuff": return status_apply_debuff
		_: return status_apply_poison
