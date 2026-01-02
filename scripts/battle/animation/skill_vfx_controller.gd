class_name SkillVFXController
extends Node
## SkillVFXController: Manages visual effects for skill execution.
## Creates and plays particle effects based on skill type and brand.

# =============================================================================
# PRELOADED EFFECT SCENES
# =============================================================================

const HIT_EFFECT := preload("res://scenes/vfx/hit_effect.tscn")
const HEAL_EFFECT := preload("res://scenes/vfx/heal_effect.tscn")
const BUFF_EFFECT := preload("res://scenes/vfx/buff_effect.tscn")
const DEBUFF_EFFECT := preload("res://scenes/vfx/debuff_effect.tscn")
const DEATH_EFFECT := preload("res://scenes/vfx/death_effect.tscn")

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
# SKILL-BASED EFFECTS
# =============================================================================

static func spawn_skill_effect(parent: Node, skill_data: SkillData, caster_pos: Vector2, target_pos: Vector2, brand: Enums.Brand) -> void:
	"""Spawn appropriate effects based on skill type"""
	if not skill_data:
		return
	
	# Use SkillData.SkillType enum
	match skill_data.skill_type:
		SkillData.SkillType.DAMAGE:
			spawn_hit_effect(parent, target_pos, brand, false)
		SkillData.SkillType.HEAL:
			spawn_heal_effect(parent, target_pos)
		SkillData.SkillType.BUFF:
			spawn_buff_effect(parent, target_pos)
		SkillData.SkillType.DEBUFF:
			spawn_debuff_effect(parent, target_pos)
		SkillData.SkillType.STATUS:
			# Status effects use debuff visual
			spawn_debuff_effect(parent, target_pos)
		_:
			# Default to hit effect for UTILITY, PASSIVE, etc.
			spawn_hit_effect(parent, target_pos, brand, false)

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
