class_name SkillVFXController
extends Node
## SkillVFXController: Manages visual effects for skill execution.
## Creates and plays particle effects based on skill type and brand.
## Enhanced with unique visual styles per skill type for distinct combat feedback.

# =============================================================================
# PRELOADED EFFECT SCENES
# =============================================================================

const HIT_EFFECT := preload("res://scenes/vfx/hit_effect.tscn")
const HEAL_EFFECT := preload("res://scenes/vfx/heal_effect.tscn")
const BUFF_EFFECT := preload("res://scenes/vfx/buff_effect.tscn")
const DEBUFF_EFFECT := preload("res://scenes/vfx/debuff_effect.tscn")
const DEATH_EFFECT := preload("res://scenes/vfx/death_effect.tscn")

# =============================================================================
# SKILL TYPE VISUAL CONFIGURATIONS
# =============================================================================

# Each skill type has unique particle behavior settings
const SKILL_VFX_CONFIG := {
	"DAMAGE": {
		"particle_count": 12,
		"spread": 45.0,
		"speed_min": 150.0,
		"speed_max": 300.0,
		"lifetime": 0.4,
		"scale": Vector2(1.0, 1.0),
		"gravity": Vector2(0, 200),
		"emission_shape": "sphere"  # Burst outward
	},
	"HEAL": {
		"particle_count": 20,
		"spread": 360.0,
		"speed_min": 30.0,
		"speed_max": 80.0,
		"lifetime": 1.0,
		"scale": Vector2(0.8, 0.8),
		"gravity": Vector2(0, -50),  # Float upward
		"emission_shape": "ring"
	},
	"BUFF": {
		"particle_count": 15,
		"spread": 360.0,
		"speed_min": 20.0,
		"speed_max": 60.0,
		"lifetime": 0.8,
		"scale": Vector2(0.6, 0.6),
		"gravity": Vector2(0, -80),  # Rise up
		"emission_shape": "spiral"
	},
	"DEBUFF": {
		"particle_count": 18,
		"spread": 360.0,
		"speed_min": 10.0,
		"speed_max": 40.0,
		"lifetime": 1.2,
		"scale": Vector2(0.7, 0.7),
		"gravity": Vector2(0, 30),  # Sink down
		"emission_shape": "drip"
	},
	"STATUS": {
		"particle_count": 25,
		"spread": 180.0,
		"speed_min": 5.0,
		"speed_max": 25.0,
		"lifetime": 1.5,
		"scale": Vector2(0.5, 0.5),
		"gravity": Vector2(0, 0),  # Orbit around target
		"emission_shape": "orbit"
	}
}

# =============================================================================
# BRAND COLORS
# =============================================================================

const BRAND_COLORS := {
	Enums.Brand.SAVAGE: Color(0.9, 0.2, 0.2),      # Red
	Enums.Brand.IRON: Color(0.5, 0.5, 0.6),        # Gray
	Enums.Brand.VENOM: Color(0.3, 0.8, 0.2),       # Green
	Enums.Brand.SURGE: Color(0.3, 0.6, 1.0),       # Blue
	Enums.Brand.DREAD: Color(0.5, 0.2, 0.7),       # Purple
	Enums.Brand.LEECH: Color(0.8, 0.2, 0.5),       # Pink
	Enums.Brand.BLOODIRON: Color(0.7, 0.3, 0.3),   # Dark red
	Enums.Brand.CORROSIVE: Color(0.4, 0.6, 0.3),   # Olive
	Enums.Brand.VENOMSTRIKE: Color(0.4, 0.7, 0.5), # Teal
	Enums.Brand.TERRORFLUX: Color(0.4, 0.4, 0.8),  # Light purple
	Enums.Brand.NIGHTLEECH: Color(0.4, 0.2, 0.5),  # Dark purple
	Enums.Brand.RAVENOUS: Color(0.6, 0.2, 0.3),    # Maroon
	Enums.Brand.NONE: Color(0.8, 0.8, 0.8),        # White/gray
}

# =============================================================================
# EFFECT SPAWNING
# =============================================================================

static func spawn_hit_effect(parent: Node, position: Vector2, brand: Enums.Brand = Enums.Brand.NONE, is_critical: bool = false) -> GPUParticles2D:
	"""Spawn a hit effect at the given position"""
	var effect: GPUParticles2D = HIT_EFFECT.instantiate()
	parent.add_child(effect)
	effect.global_position = position
	
	# Apply brand color
	var color: Color = BRAND_COLORS.get(brand, Color.WHITE)
	if is_critical:
		color = color.lightened(0.3)
	
	var material: ParticleProcessMaterial = effect.process_material
	if material:
		material.color = color
	
	# Scale up for critical hits
	if is_critical:
		effect.amount = 20
		effect.scale = Vector2(1.5, 1.5)
	
	effect.emitting = true
	
	# Auto-cleanup after effect finishes
	effect.finished.connect(func(): effect.queue_free())
	
	return effect

static func spawn_heal_effect(parent: Node, position: Vector2) -> GPUParticles2D:
	"""Spawn a healing effect at the given position"""
	var effect: GPUParticles2D = HEAL_EFFECT.instantiate()
	parent.add_child(effect)
	effect.global_position = position
	effect.emitting = true
	effect.finished.connect(func(): effect.queue_free())
	return effect

static func spawn_buff_effect(parent: Node, position: Vector2, color: Color = Color(1, 0.9, 0.3)) -> GPUParticles2D:
	"""Spawn a buff application effect"""
	var effect: GPUParticles2D = BUFF_EFFECT.instantiate()
	parent.add_child(effect)
	effect.global_position = position
	
	var material: ParticleProcessMaterial = effect.process_material
	if material:
		material.color = color
	
	effect.emitting = true
	effect.finished.connect(func(): effect.queue_free())
	return effect

static func spawn_debuff_effect(parent: Node, position: Vector2, color: Color = Color(0.6, 0.2, 0.6)) -> GPUParticles2D:
	"""Spawn a debuff application effect"""
	var effect: GPUParticles2D = DEBUFF_EFFECT.instantiate()
	parent.add_child(effect)
	effect.global_position = position
	
	var material: ParticleProcessMaterial = effect.process_material
	if material:
		material.color = color
	
	effect.emitting = true
	effect.finished.connect(func(): effect.queue_free())
	return effect

static func spawn_death_effect(parent: Node, position: Vector2, brand: Enums.Brand = Enums.Brand.NONE) -> GPUParticles2D:
	"""Spawn a death effect at the given position"""
	var effect: GPUParticles2D = DEATH_EFFECT.instantiate()
	parent.add_child(effect)
	effect.global_position = position
	
	var color: Color = BRAND_COLORS.get(brand, Color(0.3, 0.1, 0.3))
	var material: ParticleProcessMaterial = effect.process_material
	if material:
		material.color = color
	
	effect.emitting = true
	effect.finished.connect(func(): effect.queue_free())
	return effect

# =============================================================================
# SKILL-BASED EFFECTS (Enhanced with unique visuals per type)
# =============================================================================

static func spawn_skill_effect(parent: Node, skill_data: SkillData, caster_pos: Vector2, target_pos: Vector2, brand: Enums.Brand) -> void:
	"""Spawn appropriate effects based on skill type with unique visual styles"""
	if not skill_data:
		return
	
	# Use SkillData.SkillType enum with enhanced visuals
	match skill_data.skill_type:
		SkillData.SkillType.DAMAGE:
			spawn_damage_skill_effect(parent, target_pos, brand, skill_data)
		SkillData.SkillType.HEAL:
			spawn_heal_skill_effect(parent, target_pos, skill_data)
		SkillData.SkillType.BUFF:
			spawn_buff_skill_effect(parent, target_pos, skill_data)
		SkillData.SkillType.DEBUFF:
			spawn_debuff_skill_effect(parent, target_pos, brand, skill_data)
		SkillData.SkillType.STATUS:
			spawn_status_skill_effect(parent, target_pos, brand, skill_data)
		_:
			# Default to hit effect for UTILITY, PASSIVE, etc.
			spawn_hit_effect(parent, target_pos, brand, false)

static func spawn_damage_skill_effect(parent: Node, position: Vector2, brand: Enums.Brand, skill_data: SkillData) -> GPUParticles2D:
	"""Spawn damage skill effect with brand-colored burst"""
	var effect: GPUParticles2D = HIT_EFFECT.instantiate()
	parent.add_child(effect)
	effect.global_position = position
	
	var color: Color = BRAND_COLORS.get(brand, Color.WHITE)
	var config: Dictionary = SKILL_VFX_CONFIG.get("DAMAGE", {})
	
	var material: ParticleProcessMaterial = effect.process_material
	if material:
		material.color = color
		# Apply damage-specific settings
		material.spread = config.get("spread", 45.0)
		material.initial_velocity_min = config.get("speed_min", 150.0)
		material.initial_velocity_max = config.get("speed_max", 300.0)
		material.gravity = config.get("gravity", Vector2(0, 200))
	
	effect.amount = config.get("particle_count", 12)
	effect.lifetime = config.get("lifetime", 0.4)
	
	# Scale based on skill power
	var power_scale: float = clampf(skill_data.base_power / 20.0, 0.8, 2.0) if skill_data else 1.0
	effect.scale = config.get("scale", Vector2(1.0, 1.0)) * power_scale
	
	effect.emitting = true
	effect.finished.connect(func(): effect.queue_free())
	return effect

static func spawn_heal_skill_effect(parent: Node, position: Vector2, skill_data: SkillData) -> GPUParticles2D:
	"""Spawn healing effect with rising green particles"""
	var effect: GPUParticles2D = HEAL_EFFECT.instantiate()
	parent.add_child(effect)
	effect.global_position = position
	
	var config: Dictionary = SKILL_VFX_CONFIG.get("HEAL", {})
	
	var material: ParticleProcessMaterial = effect.process_material
	if material:
		material.color = Color(0.3, 1.0, 0.4, 0.9)  # Bright green
		material.spread = config.get("spread", 360.0)
		material.initial_velocity_min = config.get("speed_min", 30.0)
		material.initial_velocity_max = config.get("speed_max", 80.0)
		material.gravity = config.get("gravity", Vector2(0, -50))
	
	effect.amount = config.get("particle_count", 20)
	effect.lifetime = config.get("lifetime", 1.0)
	effect.scale = config.get("scale", Vector2(0.8, 0.8))
	
	effect.emitting = true
	effect.finished.connect(func(): effect.queue_free())
	return effect

static func spawn_buff_skill_effect(parent: Node, position: Vector2, skill_data: SkillData) -> GPUParticles2D:
	"""Spawn buff effect with golden rising sparkles"""
	var effect: GPUParticles2D = BUFF_EFFECT.instantiate()
	parent.add_child(effect)
	effect.global_position = position
	
	var config: Dictionary = SKILL_VFX_CONFIG.get("BUFF", {})
	
	var material: ParticleProcessMaterial = effect.process_material
	if material:
		material.color = Color(1.0, 0.9, 0.3, 0.9)  # Golden yellow
		material.spread = config.get("spread", 360.0)
		material.initial_velocity_min = config.get("speed_min", 20.0)
		material.initial_velocity_max = config.get("speed_max", 60.0)
		material.gravity = config.get("gravity", Vector2(0, -80))
	
	effect.amount = config.get("particle_count", 15)
	effect.lifetime = config.get("lifetime", 0.8)
	effect.scale = config.get("scale", Vector2(0.6, 0.6))
	
	effect.emitting = true
	effect.finished.connect(func(): effect.queue_free())
	return effect

static func spawn_debuff_skill_effect(parent: Node, position: Vector2, brand: Enums.Brand, skill_data: SkillData) -> GPUParticles2D:
	"""Spawn debuff effect with sinking dark particles"""
	var effect: GPUParticles2D = DEBUFF_EFFECT.instantiate()
	parent.add_child(effect)
	effect.global_position = position
	
	var config: Dictionary = SKILL_VFX_CONFIG.get("DEBUFF", {})
	
	# Debuffs use darker brand colors
	var base_color: Color = BRAND_COLORS.get(brand, Color(0.6, 0.2, 0.6))
	var dark_color: Color = base_color.darkened(0.3)
	
	var material: ParticleProcessMaterial = effect.process_material
	if material:
		material.color = dark_color
		material.spread = config.get("spread", 360.0)
		material.initial_velocity_min = config.get("speed_min", 10.0)
		material.initial_velocity_max = config.get("speed_max", 40.0)
		material.gravity = config.get("gravity", Vector2(0, 30))  # Sink down
	
	effect.amount = config.get("particle_count", 18)
	effect.lifetime = config.get("lifetime", 1.2)
	effect.scale = config.get("scale", Vector2(0.7, 0.7))
	
	effect.emitting = true
	effect.finished.connect(func(): effect.queue_free())
	return effect

static func spawn_status_skill_effect(parent: Node, position: Vector2, brand: Enums.Brand, skill_data: SkillData) -> GPUParticles2D:
	"""Spawn status effect with orbiting particles"""
	var effect: GPUParticles2D = DEBUFF_EFFECT.instantiate()  # Reuse debuff base
	parent.add_child(effect)
	effect.global_position = position
	
	var config: Dictionary = SKILL_VFX_CONFIG.get("STATUS", {})
	
	# Status effects use brand color with transparency
	var status_color: Color = BRAND_COLORS.get(brand, Color(0.5, 0.5, 0.8))
	status_color.a = 0.7
	
	var material: ParticleProcessMaterial = effect.process_material
	if material:
		material.color = status_color
		material.spread = config.get("spread", 180.0)
		material.initial_velocity_min = config.get("speed_min", 5.0)
		material.initial_velocity_max = config.get("speed_max", 25.0)
		material.gravity = config.get("gravity", Vector2(0, 0))
		# Add orbital motion for status effects
		material.orbit_velocity_min = 0.5
		material.orbit_velocity_max = 1.0
	
	effect.amount = config.get("particle_count", 25)
	effect.lifetime = config.get("lifetime", 1.5)
	effect.scale = config.get("scale", Vector2(0.5, 0.5))
	
	effect.emitting = true
	effect.finished.connect(func(): effect.queue_free())
	return effect

# =============================================================================
# STATUS EFFECT COLORS
# =============================================================================

static func get_status_color(effect: Enums.StatusEffect) -> Color:
	"""Get the color associated with a status effect"""
	match effect:
		Enums.StatusEffect.POISON:
			return Color(0.3, 0.8, 0.2)
		Enums.StatusEffect.BURN:
			return Color(1.0, 0.4, 0.1)
		Enums.StatusEffect.FREEZE:
			return Color(0.4, 0.8, 1.0)
		Enums.StatusEffect.PARALYSIS:
			return Color(1.0, 1.0, 0.3)
		Enums.StatusEffect.SLEEP:
			return Color(0.6, 0.6, 0.9)
		Enums.StatusEffect.CONFUSION:
			return Color(0.9, 0.5, 0.9)
		Enums.StatusEffect.BLIND:
			return Color(0.3, 0.3, 0.3)
		Enums.StatusEffect.SILENCE:
			return Color(0.5, 0.5, 0.7)
		Enums.StatusEffect.BLEED:
			return Color(0.8, 0.1, 0.1)
		Enums.StatusEffect.REGEN:
			return Color(0.3, 1.0, 0.4)
		Enums.StatusEffect.SHIELD:
			return Color(0.4, 0.6, 1.0)
		Enums.StatusEffect.ATTACK_UP, Enums.StatusEffect.DEFENSE_UP, Enums.StatusEffect.SPEED_UP:
			return Color(1.0, 0.9, 0.3)
		Enums.StatusEffect.ATTACK_DOWN, Enums.StatusEffect.DEFENSE_DOWN, Enums.StatusEffect.SPEED_DOWN:
			return Color(0.6, 0.2, 0.2)
		_:
			return Color.WHITE
