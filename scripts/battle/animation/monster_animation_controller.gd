# =============================================================================
# VEILBREAKERS Monster Animation Controller (Turn-Based)
# Each animation is a PERFORMANCE for the player to watch
# Dramatic, expressive, brand-specific
# =============================================================================

class_name MonsterAnimationController
extends Node

# -----------------------------------------------------------------------------
# SIGNALS
# -----------------------------------------------------------------------------
signal animation_started(anim_name: String)
signal animation_finished(anim_name: String)
signal animation_event(event_name: String, data: Dictionary)

# Key gameplay signals
signal hit_frame_reached(data: Dictionary)  # When damage should apply
signal effect_spawn_requested(effect_type: String, data: Dictionary)
signal sound_requested(sound_id: String, data: Dictionary)

# -----------------------------------------------------------------------------
# EXPORTS - Node References
# -----------------------------------------------------------------------------
@export_group("Required Nodes")
@export var animated_sprite: AnimatedSprite2D
@export var animation_player: AnimationPlayer  # For complex sequences

@export_group("Optional Nodes")
@export var vfx_spawn_point: Marker2D
@export var hit_spark_point: Marker2D
@export var shadow_sprite: Sprite2D

@export_group("Materials")
@export var flash_material: ShaderMaterial
@export var dissolve_material: ShaderMaterial
@export var brand_glow_material: ShaderMaterial

# -----------------------------------------------------------------------------
# EXPORTS - Monster Identity
# -----------------------------------------------------------------------------
@export_group("Monster Configuration")
@export var monster_name: String = "Monster"
@export var brand: String = "SAVAGE"  # SAVAGE, IRON, VENOM, SURGE, DREAD, LEECH
@export var is_boss: bool = false
@export var boss_phases: int = 1

# -----------------------------------------------------------------------------
# EXPORTS - Animation Tuning
# -----------------------------------------------------------------------------
@export_group("Timing - Turn Based Feel")
@export var idle_variation_interval: float = 4.0
@export var attack_anticipation_time: float = 0.4
@export var attack_strike_time: float = 0.2
@export var attack_recovery_time: float = 0.3
@export var hurt_reaction_time: float = 0.4
@export var death_sequence_time: float = 2.0

@export_group("Visual Polish")
@export var breathing_scale: float = 0.02
@export var breathing_speed: float = 1.5
@export var hit_flash_duration: float = 0.1
@export var squash_stretch_amount: float = 0.15

# -----------------------------------------------------------------------------
# BRAND CONFIGURATION
# -----------------------------------------------------------------------------
const BRAND_CONFIG = {
	"SAVAGE": {
		"color": Color("c73e3e"),
		"glow": Color("ff6b6b"),
		"particles": Color("8b0000"),
		"hit_sound": "hit_flesh",
		"death_sound": "death_beast",
	},
	"IRON": {
		"color": Color("7b8794"),
		"glow": Color("a8b5c4"),
		"particles": Color("4a5568"),
		"hit_sound": "hit_metal",
		"death_sound": "death_construct",
	},
	"VENOM": {
		"color": Color("6b9b37"),
		"glow": Color("9acd32"),
		"particles": Color("2d4a0f"),
		"hit_sound": "hit_acid",
		"death_sound": "death_dissolve",
	},
	"SURGE": {
		"color": Color("4a90d9"),
		"glow": Color("87ceeb"),
		"particles": Color("1e3a5f"),
		"hit_sound": "hit_electric",
		"death_sound": "death_discharge",
	},
	"DREAD": {
		"color": Color("5d3e8c"),
		"glow": Color("9370db"),
		"particles": Color("2d1f4a"),
		"hit_sound": "hit_shadow",
		"death_sound": "death_fade",
	},
	"LEECH": {
		"color": Color("c75b8a"),
		"glow": Color("ff91af"),
		"particles": Color("8b2252"),
		"hit_sound": "hit_drain",
		"death_sound": "death_wither",
	},
}

# -----------------------------------------------------------------------------
# ANIMATION LIBRARY - Standard Monster Animations
# -----------------------------------------------------------------------------
# All monsters should have these animations in their SpriteFrames
const ANIMATIONS = {
	# IDLE - Living, breathing creature
	"idle": {"fps": 8, "loop": true},
	"idle_breathe": {"fps": 6, "loop": true},  # Subtle breathing
	"idle_blink": {"fps": 10, "loop": false},  # Eye blink
	"idle_look": {"fps": 8, "loop": false},    # Look around
	"idle_fidget": {"fps": 10, "loop": false}, # Small movement
	
	# COMBAT IDLE - Ready for battle
	"combat_idle": {"fps": 10, "loop": true},
	"combat_ready": {"fps": 12, "loop": false},  # Entering combat stance
	
	# ATTACK - Multi-part for timing control
	"attack_anticipate": {"fps": 8, "loop": false},   # Wind up
	"attack_strike": {"fps": 20, "loop": false},      # Fast hit
	"attack_recover": {"fps": 10, "loop": false},     # Return to idle
	
	# HEAVY ATTACK
	"attack_heavy_anticipate": {"fps": 6, "loop": false},  # Longer windup
	"attack_heavy_strike": {"fps": 24, "loop": false},     # Powerful hit
	"attack_heavy_recover": {"fps": 8, "loop": false},
	
	# SPECIAL/SKILL - Brand-specific
	"special_charge": {"fps": 10, "loop": false},    # Gathering power
	"special_execute": {"fps": 16, "loop": false},   # Releasing power
	"special_recover": {"fps": 10, "loop": false},
	
	# REACTIONS
	"hurt_light": {"fps": 12, "loop": false},
	"hurt_heavy": {"fps": 10, "loop": false},
	"hurt_critical": {"fps": 10, "loop": false},  # Extra dramatic
	
	# DEATH - Multi-stage for drama
	"death_hit": {"fps": 16, "loop": false},     # Initial impact
	"death_stagger": {"fps": 8, "loop": false},  # Stumbling
	"death_fall": {"fps": 10, "loop": false},    # Collapsing
	"death_ground": {"fps": 6, "loop": false},   # On ground
	
	# CAPTURE - The tension sequence
	"capture_react": {"fps": 12, "loop": false},   # Initial surprise
	"capture_struggle": {"fps": 14, "loop": false}, # Fighting capture
	"capture_weaken": {"fps": 8, "loop": false},   # Growing weak
	"capture_success": {"fps": 10, "loop": false}, # Being captured
	"capture_break": {"fps": 16, "loop": false},   # Breaking free
	
	# STATUS EFFECTS - Looping overlays
	"status_poisoned": {"fps": 6, "loop": true},
	"status_burning": {"fps": 12, "loop": true},
	"status_stunned": {"fps": 4, "loop": true},
	"status_buffed": {"fps": 8, "loop": true},
	"status_debuffed": {"fps": 6, "loop": true},
	
	# SPAWN/SUMMON
	"spawn_emerge": {"fps": 12, "loop": false},
	"spawn_roar": {"fps": 10, "loop": false},
	
	# VICTORY/DEFEAT
	"victory": {"fps": 10, "loop": false},
	"taunt": {"fps": 10, "loop": false},
	"defeated": {"fps": 6, "loop": true},  # Slumped, barely alive
	
	# BOSS-SPECIFIC
	"boss_intro": {"fps": 8, "loop": false},
	"phase_transition": {"fps": 10, "loop": false},
	"signature_charge": {"fps": 8, "loop": false},
	"signature_execute": {"fps": 18, "loop": false},
	"enrage": {"fps": 12, "loop": false},
}

# -----------------------------------------------------------------------------
# STATE
# -----------------------------------------------------------------------------
enum State {
	IDLE,
	COMBAT_IDLE,
	ATTACKING,
	HURT,
	DYING,
	DEAD,
	BEING_CAPTURED,
	SPAWNING,
	SPECIAL,
	PHASE_TRANSITION
}

var current_state: State = State.IDLE
var previous_state: State = State.IDLE
var is_in_combat: bool = false

# Animation state
var current_animation: String = ""
var animation_queue: Array = []
var is_animation_locked: bool = false

# Idle variation
var idle_timer: float = 0.0
var last_idle_variation: String = ""

# Status tracking
var active_statuses: Array = []  # Array of status effect names

# Boss state
var current_phase: int = 1

# Visual state
var _original_scale: Vector2 = Vector2.ONE
var _breathing_offset: float = 0.0
var _is_flashing: bool = false

# HIGH FIX: Track tweens to prevent accumulation during rapid hits
var _flash_tween: Tween = null
var _squash_tween: Tween = null

# -----------------------------------------------------------------------------
# LIFECYCLE
# -----------------------------------------------------------------------------
func _ready() -> void:
	if animated_sprite:
		_original_scale = animated_sprite.scale
		animated_sprite.animation_finished.connect(_on_animation_finished)
		# If using frame-by-frame events
		animated_sprite.frame_changed.connect(_on_frame_changed)
	
	_setup_brand_visuals()
	play_idle()

func _process(delta: float) -> void:
	_process_breathing(delta)
	_process_idle_variations(delta)

func _setup_brand_visuals() -> void:
	"""Configure visuals based on brand"""
	if brand_glow_material and brand in BRAND_CONFIG:
		brand_glow_material.set_shader_parameter("brand_color", BRAND_CONFIG[brand].color)
		brand_glow_material.set_shader_parameter("glow_color", BRAND_CONFIG[brand].glow)

# -----------------------------------------------------------------------------
# BREATHING & IDLE LIFE
# -----------------------------------------------------------------------------
func _process_breathing(delta: float) -> void:
	if current_state != State.IDLE and current_state != State.COMBAT_IDLE:
		return
	
	_breathing_offset += delta * breathing_speed
	var breath_scale = 1.0 + sin(_breathing_offset * TAU) * breathing_scale
	animated_sprite.scale = _original_scale * Vector2(1.0, breath_scale)

func _process_idle_variations(delta: float) -> void:
	if current_state != State.IDLE and current_state != State.COMBAT_IDLE:
		idle_timer = 0.0
		return
	
	if is_animation_locked:
		return
	
	idle_timer += delta
	
	if idle_timer >= idle_variation_interval:
		idle_timer = 0.0
		_play_random_idle_variation()

func _play_random_idle_variation() -> void:
	var variations = ["idle_blink", "idle_look", "idle_fidget"]
	variations.erase(last_idle_variation)
	
	if variations.is_empty():
		return
	
	var variation = variations.pick_random()
	last_idle_variation = variation
	
	if _has_animation(variation):
		_play_animation(variation, false)
		# Will return to idle when finished

# -----------------------------------------------------------------------------
# CORE ANIMATION PLAYBACK
# -----------------------------------------------------------------------------
func _play_animation(anim_name: String, lock: bool = true) -> void:
	if not animated_sprite:
		return
	
	if not _has_animation(anim_name):
		push_warning("MonsterAnimationController: Missing animation '%s' for %s" % [anim_name, monster_name])
		return
	
	current_animation = anim_name
	is_animation_locked = lock
	
	animated_sprite.play(anim_name)
	animation_started.emit(anim_name)

func _has_animation(anim_name: String) -> bool:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return false
	return animated_sprite.sprite_frames.has_animation(anim_name)

func _on_animation_finished() -> void:
	animation_finished.emit(current_animation)
	is_animation_locked = false
	
	# Handle animation flow
	match current_animation:
		"attack_anticipate":
			_play_animation("attack_strike")
		"attack_strike":
			_play_animation("attack_recover")
		"attack_recover":
			_return_to_idle()
		
		"attack_heavy_anticipate":
			_play_animation("attack_heavy_strike")
		"attack_heavy_strike":
			_play_animation("attack_heavy_recover")
		"attack_heavy_recover":
			_return_to_idle()
		
		"special_charge":
			_play_animation("special_execute")
		"special_execute":
			_play_animation("special_recover")
		"special_recover":
			_return_to_idle()
		
		"hurt_light", "hurt_heavy", "hurt_critical":
			_return_to_idle()
		
		"death_hit":
			_play_animation("death_stagger")
		"death_stagger":
			_play_animation("death_fall")
		"death_fall":
			_play_animation("death_ground")
		"death_ground":
			current_state = State.DEAD
		
		"spawn_emerge":
			if _has_animation("spawn_roar"):
				_play_animation("spawn_roar")
			else:
				_return_to_idle()
		"spawn_roar":
			_return_to_idle()
		
		"capture_react":
			# Wait for struggle calls
			pass
		"capture_struggle":
			# Wait for result
			pass
		
		"phase_transition":
			current_state = State.COMBAT_IDLE
			_return_to_idle()
		
		_:
			# For one-shot variations, return to idle
			if current_animation.begins_with("idle_"):
				_return_to_idle()

func _return_to_idle() -> void:
	if current_state == State.DEAD or current_state == State.BEING_CAPTURED:
		return
	
	if is_in_combat:
		current_state = State.COMBAT_IDLE
		_play_animation("combat_idle", false)
	else:
		current_state = State.IDLE
		_play_animation("idle", false)

# -----------------------------------------------------------------------------
# FRAME EVENTS - For precise timing
# -----------------------------------------------------------------------------
func _on_frame_changed() -> void:
	if not animated_sprite:
		return
	
	var frame = animated_sprite.frame
	
	# Attack hit frames
	if current_animation == "attack_strike" and frame == 1:
		hit_frame_reached.emit({"type": "normal", "power": 1.0})
		_request_hit_effect()
	
	if current_animation == "attack_heavy_strike" and frame == 2:
		hit_frame_reached.emit({"type": "heavy", "power": 1.5})
		_request_hit_effect()
	
	if current_animation == "special_execute" and frame == 3:
		hit_frame_reached.emit({"type": "special", "power": 2.0, "brand": brand})
		_request_special_effect()
	
	# Death events
	if current_animation == "death_fall" and frame == 4:
		sound_requested.emit("body_fall", {"position": global_position})
		effect_spawn_requested.emit("dust_cloud", {"position": global_position})
	
	# Capture events
	if current_animation == "capture_struggle" and frame == 2:
		sound_requested.emit("capture_shake", {"position": global_position})

func _request_hit_effect() -> void:
	var effect_name = "hit_" + brand.to_lower()
	var position = hit_spark_point.global_position if hit_spark_point else global_position
	effect_spawn_requested.emit(effect_name, {"position": position, "brand": brand})
	var brand_data: Dictionary = BRAND_CONFIG.get(brand, {"hit_sound": "hit_default"})
	sound_requested.emit(brand_data.get("hit_sound", "hit_default"), {"position": position})

func _request_special_effect() -> void:
	var position = vfx_spawn_point.global_position if vfx_spawn_point else global_position
	effect_spawn_requested.emit("special_" + brand.to_lower(), {"position": position, "brand": brand})

# -----------------------------------------------------------------------------
# PUBLIC API - Combat Actions
# -----------------------------------------------------------------------------
func enter_combat() -> void:
	"""Called when battle starts"""
	is_in_combat = true
	current_state = State.COMBAT_IDLE
	if _has_animation("combat_ready"):
		_play_animation("combat_ready")
	else:
		_play_animation("combat_idle", false)

func exit_combat() -> void:
	"""Called when battle ends"""
	is_in_combat = false
	current_state = State.IDLE
	_play_animation("idle", false)

func play_idle() -> void:
	_return_to_idle()

# -----------------------------------------------------------------------------
# ATTACK ANIMATIONS
# -----------------------------------------------------------------------------
func play_attack() -> void:
	"""Standard attack sequence"""
	current_state = State.ATTACKING
	_play_animation("attack_anticipate")

func play_attack_heavy() -> void:
	"""Heavy attack sequence"""
	current_state = State.ATTACKING
	_play_animation("attack_heavy_anticipate")

func play_special() -> void:
	"""Special/skill attack"""
	current_state = State.SPECIAL
	_play_animation("special_charge")

func play_attack_windup() -> void:
	"""Just the windup portion"""
	current_state = State.ATTACKING
	_play_animation("attack_anticipate")

func play_attack_strike() -> void:
	"""Just the strike portion"""
	_play_animation("attack_strike")

func play_attack_recovery() -> void:
	"""Just the recovery portion"""
	_play_animation("attack_recover")

# -----------------------------------------------------------------------------
# REACTION ANIMATIONS
# -----------------------------------------------------------------------------
func play_hurt(is_critical: bool = false) -> void:
	"""Play hurt reaction"""
	current_state = State.HURT
	
	# Flash white
	_flash_white()
	
	# Squash on impact
	_squash()
	
	if is_critical and _has_animation("hurt_critical"):
		_play_animation("hurt_critical")
	else:
		_play_animation("hurt_heavy" if is_critical else "hurt_light")

func _flash_white() -> void:
	if not flash_material or _is_flashing:
		return

	_is_flashing = true
	var original_material = animated_sprite.material
	animated_sprite.material = flash_material
	flash_material.set_shader_parameter("flash_amount", 1.0)

	# HIGH FIX: Kill previous flash tween to prevent accumulation
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()

	_flash_tween = create_tween()
	_flash_tween.tween_property(flash_material, "shader_parameter/flash_amount", 0.0, hit_flash_duration)
	_flash_tween.tween_callback(func():
		animated_sprite.material = original_material
		_is_flashing = false
	)

func _squash() -> void:
	"""Squash on impact, stretch on recovery"""
	# HIGH FIX: Kill previous squash tween to prevent stacking
	if _squash_tween and _squash_tween.is_valid():
		_squash_tween.kill()

	_squash_tween = create_tween()

	# Squash
	_squash_tween.tween_property(
		animated_sprite,
		"scale",
		_original_scale * Vector2(1.0 + squash_stretch_amount, 1.0 - squash_stretch_amount),
		0.05
	)

	# Stretch
	_squash_tween.tween_property(
		animated_sprite,
		"scale",
		_original_scale * Vector2(1.0 - squash_stretch_amount * 0.5, 1.0 + squash_stretch_amount * 0.5),
		0.1
	)

	# Return
	_squash_tween.tween_property(animated_sprite, "scale", _original_scale, 0.15)

# -----------------------------------------------------------------------------
# DEATH ANIMATIONS
# -----------------------------------------------------------------------------
func play_death() -> void:
	"""Full death sequence"""
	current_state = State.DYING
	
	# Initial impact
	_flash_white()
	_play_animation("death_hit")
	
	# Start dissolve shader
	if dissolve_material:
		animated_sprite.material = dissolve_material
		var tween = create_tween()
		tween.tween_property(
			dissolve_material,
			"shader_parameter/dissolve_amount",
			1.0,
			death_sequence_time
		).set_delay(death_sequence_time * 0.5)
	
	sound_requested.emit(BRAND_CONFIG[brand].death_sound, {"position": global_position})

func is_dead() -> bool:
	return current_state == State.DEAD

# -----------------------------------------------------------------------------
# CAPTURE ANIMATIONS
# -----------------------------------------------------------------------------
func play_capture_react() -> void:
	"""Initial capture reaction"""
	current_state = State.BEING_CAPTURED
	_play_animation("capture_react")

func play_capture_struggle() -> void:
	"""Each shake/struggle"""
	_play_animation("capture_struggle")

func play_capture_success() -> void:
	"""Being successfully captured"""
	_play_animation("capture_success")
	
	# Shrink into capture
	var tween = create_tween()
	tween.tween_property(animated_sprite, "scale", Vector2.ZERO, 0.5)
	tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.3)

func play_capture_break() -> void:
	"""Breaking free from capture"""
	_play_animation("capture_break")
	
	# Burst out effect
	effect_spawn_requested.emit("capture_break_burst", {
		"position": global_position,
		"brand": brand
	})

# -----------------------------------------------------------------------------
# SPAWN ANIMATIONS
# -----------------------------------------------------------------------------
func play_spawn() -> void:
	"""Monster entering battle"""
	current_state = State.SPAWNING
	
	# Start invisible/small
	animated_sprite.modulate.a = 0.0
	animated_sprite.scale = Vector2.ZERO
	
	# Fade/scale in
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.3)
	tween.tween_property(animated_sprite, "scale", _original_scale, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	await tween.finished
	
	_play_animation("spawn_emerge")
	
	effect_spawn_requested.emit("summon_" + brand.to_lower(), {
		"position": global_position,
		"brand": brand
	})

func play_intro() -> void:
	"""Boss intro animation"""
	if not is_boss:
		return
	
	_play_animation("boss_intro")

# -----------------------------------------------------------------------------
# STATUS EFFECT VISUALS
# -----------------------------------------------------------------------------
func show_status_effect(status: String) -> void:
	"""Show persistent status effect visual"""
	if status in active_statuses:
		return
	
	active_statuses.append(status)
	
	# Play status animation overlay if available
	var status_anim = "status_" + status
	if _has_animation(status_anim):
		# This would need a secondary AnimatedSprite2D for overlay
		pass
	
	# Apply shader effect based on status
	match status:
		"poisoned":
			_apply_status_tint(BRAND_CONFIG["VENOM"].color, 0.2)
		"burning":
			_apply_status_tint(Color.ORANGE, 0.3)
		"stunned":
			# Maybe add shader wobble
			pass

func hide_status_effect(status: String) -> void:
	"""Remove status effect visual"""
	active_statuses.erase(status)
	
	if active_statuses.is_empty():
		_clear_status_tint()

func _apply_status_tint(color: Color, intensity: float) -> void:
	# Use modulate for simple tint
	animated_sprite.modulate = animated_sprite.modulate.lerp(color, intensity)

func _clear_status_tint() -> void:
	animated_sprite.modulate = Color.WHITE

# -----------------------------------------------------------------------------
# BOSS ANIMATIONS
# -----------------------------------------------------------------------------
func play_phase_transition(phase: int) -> void:
	"""Boss phase transition"""
	if not is_boss:
		return
	
	current_phase = phase
	current_state = State.PHASE_TRANSITION
	
	# Dramatic glow increase
	if brand_glow_material:
		var tween = create_tween()
		tween.tween_property(brand_glow_material, "shader_parameter/glow_intensity", 3.0, 0.5)
		tween.tween_property(brand_glow_material, "shader_parameter/glow_intensity", 1.5, 0.5)
	
	_play_animation("phase_transition")
	
	sound_requested.emit("boss_roar", {"position": global_position})
	effect_spawn_requested.emit("phase_transition_" + brand.to_lower(), {
		"position": global_position,
		"phase": phase
	})

func play_enrage() -> void:
	"""Boss enrage animation"""
	if _has_animation("enrage"):
		_play_animation("enrage")
	
	# Visual intensity increase
	if brand_glow_material:
		brand_glow_material.set_shader_parameter("glow_intensity", 2.5)

func play_signature_attack() -> void:
	"""Boss signature move"""
	current_state = State.SPECIAL
	_play_animation("signature_charge")

# -----------------------------------------------------------------------------
# VICTORY/DEFEAT
# -----------------------------------------------------------------------------
func play_victory() -> void:
	"""Victory pose"""
	if _has_animation("victory"):
		_play_animation("victory")
	elif _has_animation("taunt"):
		_play_animation("taunt")

func play_taunt() -> void:
	"""Taunt animation"""
	if _has_animation("taunt"):
		_play_animation("taunt")

# -----------------------------------------------------------------------------
# SKILL ANIMATIONS (called with skill name)
# -----------------------------------------------------------------------------
func play_skill_cast(skill_name: String) -> void:
	"""Play skill-specific cast animation or default"""
	var skill_anim = "skill_" + skill_name.to_lower().replace(" ", "_")
	
	if _has_animation(skill_anim + "_charge"):
		_play_animation(skill_anim + "_charge")
	elif _has_animation("special_charge"):
		_play_animation("special_charge")
	else:
		_play_animation("attack_anticipate")

# -----------------------------------------------------------------------------
# UTILITY
# -----------------------------------------------------------------------------
func get_brand_config() -> Dictionary:
	return BRAND_CONFIG.get(brand, BRAND_CONFIG["SAVAGE"])

func get_brand_color() -> Color:
	return get_brand_config().color

func get_spawn_point() -> Vector2:
	if vfx_spawn_point:
		return vfx_spawn_point.global_position
	return global_position
