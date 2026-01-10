# =============================================================================
# VEILBREAKERS Monster Sprite Configuration
# Defines animation frame mappings for each monster's sprite sheets
# Each monster can have multiple sheet variations with different animation styles
# =============================================================================

class_name MonsterSpriteConfig
extends RefCounted


## Animation frame definition
class FrameRange:
	var start: int = 0
	var end: int = 0
	var fps: float = 10.0
	var loop: bool = false
	var hit_frame: int = -1  # Frame where damage applies

	func _init(
		p_start: int = 0, p_end: int = 0, p_fps: float = 10.0, p_loop: bool = false, p_hit: int = -1
	) -> void:
		start = p_start
		end = p_end
		fps = p_fps
		loop = p_loop
		hit_frame = p_hit


## Sheet configuration for a monster
class SheetConfig:
	var sheet_path: String = ""
	var h_frames: int = 4
	var v_frames: int = 4
	var animations: Dictionary = {}  # anim_name -> FrameRange

	func add_animation(
		name: String,
		start: int,
		end: int,
		fps: float = 10.0,
		loop: bool = false,
		hit_frame: int = -1
	) -> SheetConfig:
		animations[name] = FrameRange.new(start, end, fps, loop, hit_frame)
		return self


# =============================================================================
# MONSTER CONFIGURATIONS
# =============================================================================


## Get configuration for a specific monster
static func get_config(monster_id: String) -> Dictionary:
	match monster_id.to_lower():
		"hollow":
			return _get_hollow_config()
		"chainbound":
			return _get_chainbound_config()
		"mawling":
			return _get_mawling_config()
		"crackling":
			return _get_crackling_config()
		"flicker":
			return _get_flicker_config()
		"skitter_teeth":
			return _get_skitter_teeth_config()
		"the_vessel":
			return _get_the_vessel_config()
		"ravener":
			return _get_ravener_config()
		"gluttony_polyp":
			return _get_gluttony_polyp_config()
		"voltgeist":
			return _get_voltgeist_config()
		"needlefang":
			return _get_needlefang_config()
		"corrodex":
			return _get_corrodex_config()
		"the_weeping":
			return _get_the_weeping_config()
		"sporecaller":
			return _get_sporecaller_config()
		"ironjaw":
			return _get_ironjaw_config()
		"bloodshade":
			return _get_bloodshade_config()
		"blightspawn":
			return _get_blightspawn_config()
		"venomspine":
			return _get_venomspine_config()
		"bonecrusher":
			return _get_bonecrusher_config()
		"blightsworn":
			return _get_blightsworn_config()
		"voidwraith":
			return _get_voidwraith_config()
		"grimthorn":
			return _get_grimthorn_config()
		_:
			return _get_default_config()


# =============================================================================
# HOLLOW - Shadow Entity with Red Core
# =============================================================================


static func _get_hollow_config() -> Dictionary:
	var config := {
		"monster_id": "hollow",
		"display_name": "Hollow",
		"default_sheet": 0,
		"h_frames": 4,
		"v_frames": 4,
		"scale": Vector2(1.25, 1.25),
		"sheets": [],
		"brand_color": Color(0.78, 0.24, 0.24),  # DREAD red
		"glow_color": Color(1.0, 0.4, 0.4),
		"particle_color": Color(0.5, 0.1, 0.1),
	}

	# SHEET 1 - Primary Idle/Attack (hollow_idle_sheet.png) - 4x4
	var sheet1 := SheetConfig.new()
	sheet1.sheet_path = "res://assets/sprites/monsters/sheets/hollow_idle_sheet.png"
	sheet1.h_frames = 4
	sheet1.v_frames = 4
	sheet1.add_animation("idle", 0, 3, 6.0, true)
	sheet1.add_animation("attack", 4, 7, 6.0, false, 5)
	sheet1.add_animation("skill_empty_grasp", 8, 11, 10.0, false, 10)
	sheet1.add_animation("block", 8, 9, 6.0, false)  # Defensive stance
	sheet1.add_animation("defend", 8, 9, 6.0, false)  # Alias for block
	sheet1.add_animation("death", 12, 15, 6.0, false)
	sheet1.add_animation("hurt", 8, 9, 12.0, false)
	config.sheets.append(sheet1)

	# SHEET 2 - Beam Attacks (hollow_attack_sheet.png) - 4x4
	var sheet2 := SheetConfig.new()
	sheet2.sheet_path = "res://assets/sprites/monsters/sheets/hollow_attack_sheet.png"
	sheet2.h_frames = 4
	sheet2.v_frames = 4
	sheet2.add_animation("idle_alt", 0, 3, 5.0, true)
	sheet2.add_animation("attack_heavy", 4, 7, 6.0, false, 5)
	sheet2.add_animation("skill_void_blast", 4, 7, 4.0, false, 5)
	sheet2.add_animation("skill_hollow_wail", 8, 11, 8.0, false, 9)
	sheet2.add_animation("death_alt", 12, 15, 5.0, false)
	sheet2.add_animation("hurt_heavy", 10, 11, 14.0, false)
	config.sheets.append(sheet2)

	# SHEET 3 - Special Skills (hollow_special_sheet.png) - 4x4
	var sheet3 := SheetConfig.new()
	sheet3.sheet_path = "res://assets/sprites/monsters/sheets/hollow_special_sheet.png"
	sheet3.h_frames = 4
	sheet3.v_frames = 4
	sheet3.add_animation("skill_dread_gaze", 4, 7, 10.0, false, 6)
	sheet3.add_animation("skill_void_touch", 8, 11, 12.0, false, 10)
	sheet3.add_animation("spawn", 12, 15, 8.0, false)
	config.sheets.append(sheet3)

	# SHEET 4 - Claw Attacks (hollow_claw_sheet.png) - 4x4
	var sheet4 := SheetConfig.new()
	sheet4.sheet_path = "res://assets/sprites/monsters/sheets/hollow_claw_sheet.png"
	sheet4.h_frames = 4
	sheet4.v_frames = 4
	sheet4.add_animation("idle_claw", 0, 3, 5.0, true)
	sheet4.add_animation("skill_shadow_rend", 4, 7, 8.0, false, 6)
	sheet4.add_animation("skill_void_beam", 8, 11, 6.0, false, 10)
	sheet4.add_animation("death_explode", 12, 15, 5.0, false)
	config.sheets.append(sheet4)

	# SHEET 5 - Hurt/Damage - DISABLED (hollow_hurt_sheet.png does not exist)
	# Hurt animations are mapped to sheet1 instead
	# var sheet5 := SheetConfig.new()
	# sheet5.sheet_path = "res://assets/sprites/monsters/sheets/hollow_hurt_sheet.png"
	# sheet5.h_frames = 4
	# sheet5.v_frames = 4
	# sheet5.add_animation("move", 0, 3, 8.0, true)
	# sheet5.add_animation("hurt_impact", 4, 7, 10.0, false)
	# sheet5.add_animation("hurt_stagger", 8, 11, 8.0, false)
	# sheet5.add_animation("idle_breathe", 12, 15, 4.0, true)
	# config.sheets.append(sheet5)

	# SHEET 6 - Tendril Skills (hollow_tendril_sheet.png) - 4x4
	var sheet6 := SheetConfig.new()
	sheet6.sheet_path = "res://assets/sprites/monsters/sheets/hollow_tendril_sheet.png"
	sheet6.h_frames = 4
	sheet6.v_frames = 4
	sheet6.add_animation("idle_spread", 0, 3, 5.0, true)
	sheet6.add_animation("skill_tendril_sweep", 4, 7, 10.0, false, 6)
	sheet6.add_animation("skill_void_lance", 8, 11, 6.0, false, 10)
	sheet6.add_animation("skill_void_orb", 12, 15, 8.0, false, 14)
	config.sheets.append(sheet6)

	# SHEET 7 - Vortex Skills - DISABLED (hollow_vortex_sheet.png does not exist)
	# Vortex animations fallback to other sheets
	# var sheet7 := SheetConfig.new()
	# sheet7.sheet_path = "res://assets/sprites/monsters/sheets/hollow_vortex_sheet.png"
	# sheet7.h_frames = 4
	# sheet7.v_frames = 4
	# sheet7.add_animation("skill_dread_surge", 0, 3, 6.0, false, 2)
	# sheet7.add_animation("skill_tendril_lash", 4, 7, 12.0, false, 6)
	# sheet7.add_animation("skill_consuming_vortex", 8, 11, 10.0, false, 10)
	# sheet7.add_animation("death_collapse", 12, 15, 4.0, false)
	# config.sheets.append(sheet7)

	# SHEET 8 - Power/Rage (hollow_power_sheet.png) - 4x5 (5 rows!)
	var sheet8 := SheetConfig.new()
	sheet8.sheet_path = "res://assets/sprites/monsters/sheets/hollow_power_sheet.png"
	sheet8.h_frames = 4
	sheet8.v_frames = 5
	sheet8.add_animation("power_stance", 0, 3, 4.0, true)
	sheet8.add_animation("skill_tendril_sweep_heavy", 4, 7, 8.0, false, 6)
	sheet8.add_animation("skill_void_blast_heavy", 8, 11, 5.0, false, 10)
	sheet8.add_animation("skill_abyssal_rage", 12, 15, 8.0, false, 14)
	sheet8.add_animation("death_final", 16, 19, 4.0, false)
	config.sheets.append(sheet8)

	return config


# =============================================================================
# CHAINBOUND - Rusted Chain Golem with Orange Core
# =============================================================================


static func _get_chainbound_config() -> Dictionary:
	var config := {
		"monster_id": "chainbound",
		"display_name": "Chainbound",
		"default_sheet": 0,
		"h_frames": 4,
		"v_frames": 4,
		"scale": Vector2(1.25, 1.25),  # 2.5x increase for better visibility (was 0.5)
		"sheets": [],
		"brand_color": Color(0.48, 0.53, 0.58),  # IRON gray
		"glow_color": Color(1.0, 0.6, 0.2),  # Orange core
		"particle_color": Color(0.3, 0.25, 0.2),
	}

	# Sheet 1 - Primary (idle_sheet - was chainbound_sheet2)
	var sheet1 := SheetConfig.new()
	sheet1.sheet_path = "res://assets/sprites/monsters/sheets/chainbound_idle_sheet.png"
	sheet1.h_frames = 4
	sheet1.v_frames = 4
	# Row 1: Idle standing menacingly
	sheet1.add_animation("idle", 0, 3, 5.0, true)
	# Row 2: Attack lunge - slowed to 7fps for visible impact
	sheet1.add_animation("attack", 4, 7, 7.0, false, 6)
	# Row 3: Combat stances with glowing core
	sheet1.add_animation("skill_iron_bind", 8, 11, 8.0, false, 10)
	sheet1.add_animation("block", 8, 9, 6.0, false)  # Defensive stance
	sheet1.add_animation("defend", 8, 9, 6.0, false)  # Alias for block
	# Row 4: Death crumble
	sheet1.add_animation("death", 12, 15, 5.0, false)
	sheet1.add_animation("hurt", 10, 11, 12.0, false)
	config.sheets.append(sheet1)

	# Sheet 2 - Alternate (attack_sheet - was chainbound_sheet3)
	var sheet2 := SheetConfig.new()
	sheet2.sheet_path = "res://assets/sprites/monsters/sheets/chainbound_attack_sheet.png"
	sheet2.h_frames = 4
	sheet2.v_frames = 4
	# Row 1: Power-up with chains spreading
	sheet2.add_animation("idle_alt", 0, 3, 6.0, true)
	sheet2.add_animation("skill_chain_wall", 0, 3, 8.0, false, 2)
	# Row 2: Heavy attack - slowed to 7fps
	sheet2.add_animation("attack_heavy", 4, 7, 7.0, false, 6)
	# Row 3: Hurt reactions
	sheet2.add_animation("hurt_heavy", 8, 11, 10.0, false)
	sheet2.add_animation("skill_shackle_slam", 8, 11, 10.0, false, 10)
	# Row 4: Death with smoke
	sheet2.add_animation("death_alt", 12, 15, 4.0, false)
	sheet2.add_animation("spawn", 15, 12, 6.0, false)  # Reverse for spawn
	config.sheets.append(sheet2)

	return config


# =============================================================================
# MAWLING - Floating Mouth Creature
# =============================================================================


static func _get_mawling_config() -> Dictionary:
	var config := {
		"monster_id": "mawling",
		"display_name": "Mawling",
		"default_sheet": 0,
		"h_frames": 4,
		"v_frames": 4,  # Sheet 1 is 4x4
		"scale": Vector2(1.125, 1.125),  # 2.5x increase (was 0.45) - still slightly smaller than others
		"sheets": [],
		"brand_color": Color(0.78, 0.24, 0.24),  # SAVAGE red
		"glow_color": Color(1.0, 0.3, 0.5),
		"particle_color": Color(0.2, 0.1, 0.15),
	}

	# Sheet 1 - Primary (idle_sheet - was mawling_sheet2)
	var sheet1 := SheetConfig.new()
	sheet1.sheet_path = "res://assets/sprites/monsters/sheets/mawling_idle_sheet.png"
	sheet1.h_frames = 4
	sheet1.v_frames = 4
	# Row 1: Idle floating with mouth open, frames 2-3 have slash marks (attack impact)
	sheet1.add_animation("idle", 0, 1, 6.0, true)
	sheet1.add_animation("attack", 0, 3, 8.0, false, 2)  # Slash on frame 2-3, slowed to 8fps
	# Row 2: Lunge attack with purple trail - frame 5 is the big lunge!
	sheet1.add_animation("skill_desperate_lunge", 4, 7, 12.0, false, 5)
	sheet1.add_animation("attack_heavy", 4, 7, 8.0, false, 5)  # Slowed to 8fps
	# Row 3: Various poses, hurt reactions - frame 10 shows splatter
	sheet1.add_animation("hurt", 8, 10, 12.0, false)
	sheet1.add_animation("skill_gnaw", 8, 11, 10.0, false, 10)
	sheet1.add_animation("block", 8, 9, 6.0, false)  # Defensive stance
	sheet1.add_animation("defend", 8, 9, 6.0, false)  # Alias for block
	# Row 4: Death - melting into puddle
	sheet1.add_animation("death", 12, 15, 5.0, false)
	config.sheets.append(sheet1)

	# Sheet 2 - Alternate (attack_sheet - was mawling_sheet3) - This one is 4x5!
	var sheet2 := SheetConfig.new()
	sheet2.sheet_path = "res://assets/sprites/monsters/sheets/mawling_attack_sheet.png"
	sheet2.h_frames = 4
	sheet2.v_frames = 5  # 5 rows!
	# Row 1: Idle bobbing
	sheet2.add_animation("idle_alt", 0, 3, 5.0, true)
	# Row 2: Attack windup and bite
	sheet2.add_animation("skill_frenzy_bite", 4, 7, 14.0, false, 6)
	# Row 3: Lunge attack with trail - frame 10 is the big swoosh!
	sheet2.add_animation("skill_pounce", 8, 11, 12.0, false, 10)
	# Row 4: More attack poses
	sheet2.add_animation("skill_feeding_frenzy", 12, 15, 16.0, false, 14)
	# Row 5: Death/puddle sequence
	sheet2.add_animation("death_alt", 16, 19, 4.0, false)
	sheet2.add_animation("spawn", 19, 16, 6.0, false)  # Reverse for spawn
	config.sheets.append(sheet2)

	return config


# =============================================================================
# BLIGHTSPAWN - Eldritch Eye Horror with Void Magic
# =============================================================================


static func _get_blightspawn_config() -> Dictionary:
	var config := {
		"monster_id": "blightspawn",
		"display_name": "Blightspawn",
		"default_sheet": 0,
		"h_frames": 4,
		"v_frames": 4,
		"scale": Vector2(1.25, 1.25),
		"sheets": [],
		"brand_color": Color(0.5, 0.2, 0.5),  # Purple corruption
		"glow_color": Color(0.8, 0.3, 0.8),
		"particle_color": Color(0.4, 0.1, 0.4),
	}

	var sheet1 := SheetConfig.new()
	sheet1.sheet_path = "res://assets/sprites/monsters/sheets/blightspawn_idle_sheet.png"
	sheet1.h_frames = 4
	sheet1.v_frames = 4
	# Row 1: Idle floating with eyes
	sheet1.add_animation("idle", 0, 3, 5.0, true)
	# Row 2: More idle poses - can also serve as block/defensive
	sheet1.add_animation("idle_alt", 4, 7, 4.0, true)
	sheet1.add_animation("block", 4, 5, 6.0, false)  # Eyes close for defense
	sheet1.add_animation("defend", 4, 5, 6.0, false)  # Alias for block
	sheet1.add_animation("skill_eldritch_shield", 4, 5, 6.0, false)
	# Row 3: Void vortex attack (purple spiral) - MULTI-USE
	sheet1.add_animation("attack", 8, 11, 10.0, false, 10)
	sheet1.add_animation("skill_void_burst", 8, 11, 8.0, false, 10)
	sheet1.add_animation("skill_chaos_vortex", 8, 11, 8.0, false, 10)
	sheet1.add_animation("skill_mind_rend", 8, 11, 10.0, false, 10)
	sheet1.add_animation("skill_nightmare_pulse", 8, 11, 8.0, false, 10)
	sheet1.add_animation("skill_eldritch_blast", 8, 11, 10.0, false, 10)
	sheet1.add_animation("attack_heavy", 8, 11, 8.0, false, 10)
	# Row 4: Hurt and death
	sheet1.add_animation("hurt", 12, 13, 10.0, false)
	sheet1.add_animation("death", 12, 15, 5.0, false)
	config.sheets.append(sheet1)

	return config


# =============================================================================
# VENOMSPINE - Serpentine Creature with Toxic Projectiles
# =============================================================================


static func _get_venomspine_config() -> Dictionary:
	var config := {
		"monster_id": "venomspine",
		"display_name": "Venomspine",
		"default_sheet": 0,
		"h_frames": 4,
		"v_frames": 4,
		"scale": Vector2(1.25, 1.25),
		"sheets": [],
		"brand_color": Color(0.2, 0.8, 0.3),  # Toxic green
		"glow_color": Color(0.4, 1.0, 0.5),
		"particle_color": Color(0.1, 0.5, 0.2),
	}

	var sheet1 := SheetConfig.new()
	sheet1.sheet_path = "res://assets/sprites/monsters/sheets/venomspine_idle_sheet.png"
	sheet1.h_frames = 4
	sheet1.v_frames = 4
	# Row 1: Idle swaying
	sheet1.add_animation("idle", 0, 3, 5.0, true)
	# Row 2: Projectile attack (green shots) - MULTI-USE
	sheet1.add_animation("attack", 4, 7, 10.0, false, 6)
	sheet1.add_animation("skill_venom_spit", 4, 7, 8.0, false, 6)
	sheet1.add_animation("skill_acid_spray", 4, 7, 8.0, false, 6)
	sheet1.add_animation("skill_poison_bolt", 4, 7, 10.0, false, 6)
	sheet1.add_animation("skill_fang_strike", 4, 7, 10.0, false, 6)
	# Row 3: Burst attack (radial projectiles) - MULTI-USE
	sheet1.add_animation("skill_toxic_burst", 8, 11, 12.0, false, 10)
	sheet1.add_animation("skill_venom_nova", 8, 11, 10.0, false, 10)
	sheet1.add_animation("skill_corrosive_wave", 8, 11, 10.0, false, 10)
	sheet1.add_animation("skill_spore_cloud", 8, 11, 8.0, false, 10)
	sheet1.add_animation("attack_heavy", 8, 11, 10.0, false, 10)
	sheet1.add_animation("block", 8, 9, 6.0, false)  # Coiled defensive stance
	sheet1.add_animation("defend", 8, 9, 6.0, false)  # Alias for block
	# Row 4: Hurt and death
	sheet1.add_animation("hurt", 12, 13, 10.0, false)
	sheet1.add_animation("death", 12, 15, 5.0, false)
	config.sheets.append(sheet1)

	return config


# =============================================================================
# BONECRUSHER - Armored Brute with Devastating Melee
# =============================================================================


static func _get_bonecrusher_config() -> Dictionary:
	var config := {
		"monster_id": "bonecrusher",
		"display_name": "Bonecrusher",
		"default_sheet": 0,
		"h_frames": 4,
		"v_frames": 5,
		"scale": Vector2(1.4, 1.4),  # Larger brute
		"sheets": [],
		"brand_color": Color(0.6, 0.5, 0.4),  # Bone/metal
		"glow_color": Color(0.9, 0.7, 0.5),
		"particle_color": Color(0.4, 0.3, 0.25),
	}

	var sheet1 := SheetConfig.new()
	sheet1.sheet_path = "res://assets/sprites/monsters/sheets/bonecrusher_idle_sheet.png"
	sheet1.h_frames = 4
	sheet1.v_frames = 5
	# Row 1: Idle standing menacingly
	sheet1.add_animation("idle", 0, 3, 4.0, true)
	# Row 2: Slash attack (red trail) - MULTI-USE
	sheet1.add_animation("attack", 4, 7, 10.0, false, 6)
	sheet1.add_animation("skill_bone_slash", 4, 7, 8.0, false, 6)
	sheet1.add_animation("skill_cleave", 4, 7, 8.0, false, 6)
	sheet1.add_animation("skill_rend", 4, 7, 10.0, false, 6)
	# Row 3: Ground pound (shockwave) - MULTI-USE
	sheet1.add_animation("skill_ground_pound", 8, 11, 8.0, false, 10)
	sheet1.add_animation("skill_earthquake", 8, 11, 8.0, false, 10)
	sheet1.add_animation("skill_shockwave", 8, 11, 8.0, false, 10)
	sheet1.add_animation("attack_heavy", 8, 11, 8.0, false, 10)
	sheet1.add_animation("block", 8, 9, 6.0, false)  # Use first frames for block stance
	sheet1.add_animation("defend", 8, 9, 6.0, false)  # Alias for block
	sheet1.add_animation("skill_iron_defense", 8, 9, 6.0, false)
	# Row 4: Hurt reactions
	sheet1.add_animation("hurt", 12, 15, 10.0, false)
	# Row 5: Death collapse
	sheet1.add_animation("death", 16, 19, 5.0, false)
	config.sheets.append(sheet1)

	return config


# =============================================================================
# BLIGHTSWORN - Corrupted Plague Knight with Toxic Magic
# =============================================================================


static func _get_blightsworn_config() -> Dictionary:
	var config := {
		"monster_id": "blightsworn",
		"display_name": "Blightsworn",
		"default_sheet": 0,
		"h_frames": 4,
		"v_frames": 5,
		"scale": Vector2(1.3, 1.3),
		"sheets": [],
		"brand_color": Color(0.4, 0.7, 0.2),  # Plague green
		"glow_color": Color(0.6, 1.0, 0.3),
		"particle_color": Color(0.2, 0.4, 0.1),
	}

	var sheet1 := SheetConfig.new()
	sheet1.sheet_path = "res://assets/sprites/monsters/sheets/blightsworn_idle_sheet.png"
	sheet1.h_frames = 4
	sheet1.v_frames = 5
	# Row 1: Idle standing
	sheet1.add_animation("idle", 0, 3, 4.0, true)
	# Row 2: Energy slash attack (green arc) - MULTI-USE
	sheet1.add_animation("attack", 4, 7, 10.0, false, 6)
	sheet1.add_animation("skill_plague_slash", 4, 7, 8.0, false, 6)
	sheet1.add_animation("skill_toxic_strike", 4, 7, 8.0, false, 6)
	sheet1.add_animation("skill_corrupted_blade", 4, 7, 10.0, false, 6)
	sheet1.add_animation("block", 4, 5, 6.0, false)  # Defensive stance
	sheet1.add_animation("defend", 4, 5, 6.0, false)  # Alias for block
	# Row 3: Explosion attack (massive green burst) - MULTI-USE
	sheet1.add_animation("skill_plague_burst", 8, 11, 6.0, false, 10)
	sheet1.add_animation("skill_toxic_nova", 8, 11, 6.0, false, 10)
	sheet1.add_animation("skill_blight_explosion", 8, 11, 6.0, false, 10)
	sheet1.add_animation("skill_virulent_wave", 8, 11, 6.0, false, 10)
	sheet1.add_animation("attack_heavy", 8, 11, 6.0, false, 10)
	# Row 4: Hurt reactions with green splatter
	sheet1.add_animation("hurt", 12, 15, 10.0, false)
	# Row 5: Death melting into toxic puddle
	sheet1.add_animation("death", 16, 19, 4.0, false)
	config.sheets.append(sheet1)

	return config


# =============================================================================
# VOIDWRAITH - Shadow Titan with Devastating Beam Attack
# =============================================================================


static func _get_voidwraith_config() -> Dictionary:
	var config := {
		"monster_id": "voidwraith",
		"display_name": "Voidwraith",
		"default_sheet": 0,
		"h_frames": 4,
		"v_frames": 5,
		"scale": Vector2(1.5, 1.5),  # Large boss-tier
		"sheets": [],
		"brand_color": Color(0.2, 0.1, 0.2),  # Dark shadow
		"glow_color": Color(1.0, 0.2, 0.2),  # Red eye glow
		"particle_color": Color(0.1, 0.05, 0.1),
	}

	var sheet1 := SheetConfig.new()
	sheet1.sheet_path = "res://assets/sprites/monsters/sheets/voidwraith_idle_sheet.png"
	sheet1.h_frames = 4
	sheet1.v_frames = 5
	# Row 1: Idle with glowing red eyes
	sheet1.add_animation("idle", 0, 3, 3.0, true)
	# Row 2: Tendril sweep attack - MULTI-USE
	sheet1.add_animation("attack", 4, 7, 8.0, false, 6)
	sheet1.add_animation("skill_shadow_sweep", 4, 7, 8.0, false, 6)
	sheet1.add_animation("skill_tendril_lash", 4, 7, 8.0, false, 6)
	sheet1.add_animation("skill_dark_grasp", 4, 7, 8.0, false, 6)
	sheet1.add_animation("skill_shadow_strike", 4, 7, 10.0, false, 6)
	sheet1.add_animation("block", 4, 5, 6.0, false)  # Shadow barrier stance
	sheet1.add_animation("defend", 4, 5, 6.0, false)  # Alias for block
	sheet1.add_animation("skill_shadow_veil", 4, 5, 6.0, false)
	# Row 3: DEVASTATING RED BEAM ATTACK - MULTI-USE
	sheet1.add_animation("skill_void_beam", 8, 11, 6.0, false, 10)
	sheet1.add_animation("skill_annihilation_ray", 8, 11, 5.0, false, 10)
	sheet1.add_animation("skill_crimson_blast", 8, 11, 6.0, false, 10)
	sheet1.add_animation("skill_doom_laser", 8, 11, 5.0, false, 10)
	sheet1.add_animation("attack_heavy", 8, 11, 6.0, false, 10)
	# Row 4: Hurt reactions
	sheet1.add_animation("hurt", 12, 15, 10.0, false)
	# Row 5: Death collapse
	sheet1.add_animation("death", 16, 19, 4.0, false)
	config.sheets.append(sheet1)

	return config


# =============================================================================
# CRACKLING - Blue Lightning Imp (4 Variants)
# =============================================================================


static func _get_crackling_config() -> Dictionary:
	# Randomly select one of 4 variants for visual variety
	var variants := ["a", "b", "c", "d"]
	var variant: String = variants[randi() % variants.size()]

	var config := {
		"monster_id": "crackling",
		"display_name": "Crackling",
		"default_sheet": 0,
		"h_frames": 5,
		"v_frames": 5,
		"scale": Vector2(1.0, 1.0),  # Small imp size
		"sheets": [],
		"brand_color": Color(0.3, 0.6, 0.9),  # Electric blue
		"glow_color": Color(0.5, 0.8, 1.0),
		"particle_color": Color(0.2, 0.5, 0.8),
	}

	var sheet1 := SheetConfig.new()
	sheet1.sheet_path = "res://assets/sprites/monsters/sheets/crackling_%s_sheet.png" % variant
	sheet1.h_frames = 5
	sheet1.v_frames = 5
	# Row 1: Idle standing
	sheet1.add_animation("idle", 0, 4, 6.0, true)
	# Row 2: Lightning attack
	sheet1.add_animation("attack", 5, 9, 12.0, false, 4)
	sheet1.add_animation("skill_lightning_bolt", 5, 9, 10.0, false, 4)
	# Row 3: Shield/Block
	sheet1.add_animation("block", 10, 14, 8.0, false)
	sheet1.add_animation("defend", 10, 14, 8.0, false)  # Alias for block
	sheet1.add_animation("skill_shield", 10, 14, 8.0, false)
	# Row 4: Hurt/Damage taken
	sheet1.add_animation("hurt", 15, 19, 10.0, false)
	# Row 5: Death sequence
	sheet1.add_animation("death", 20, 24, 6.0, false)
	config.sheets.append(sheet1)

	return config


# =============================================================================
# DEFAULT CONFIG - For monsters without custom sheets
# =============================================================================


static func _get_default_config() -> Dictionary:
	return {
		"monster_id": "default",
		"display_name": "Monster",
		"default_sheet": -1,  # No sprite sheet, use static sprite
		"h_frames": 1,
		"v_frames": 1,
		"scale": Vector2(1.25, 1.25),  # 2.5x increase for better visibility (was 0.5)
		"sheets": [],
		"brand_color": Color.WHITE,
		"glow_color": Color.WHITE,
		"particle_color": Color.GRAY,
	}


# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================


## Get the best animation for a given action from available sheets
static func get_animation_for_action(
	config: Dictionary, action: String, skill_name: String = ""
) -> Dictionary:
	var result := {"sheet_index": 0, "animation_name": action, "found": false}

	var sheets: Array = config.get("sheets", [])
	if sheets.is_empty():
		return result

	# If skill specified, look for skill-specific animation first
	if skill_name != "":
		var skill_anim := "skill_" + skill_name.to_lower().replace(" ", "_")
		for i in range(sheets.size()):
			var sheet: SheetConfig = sheets[i]
			if sheet.animations.has(skill_anim):
				result.sheet_index = i
				result.animation_name = skill_anim
				result.found = true
				return result

	# Look for the action in sheets (prefer primary sheet)
	for i in range(sheets.size()):
		var sheet: SheetConfig = sheets[i]
		if sheet.animations.has(action):
			result.sheet_index = i
			result.animation_name = action
			result.found = true
			return result

	# Fallback to alternate versions
	var alt_action := action + "_alt"
	for i in range(sheets.size()):
		var sheet: SheetConfig = sheets[i]
		if sheet.animations.has(alt_action):
			result.sheet_index = i
			result.animation_name = alt_action
			result.found = true
			return result

	return result


## Check if monster has sprite sheet animations
static func has_sprite_sheets(monster_id: String) -> bool:
	var config := get_config(monster_id)
	var sheets: Array = config.get("sheets", [])
	return not sheets.is_empty()
# =============================================================================
# FLICKER - Flying Spider with Blue Wings (9 variants: a-i)
# =============================================================================

static func _get_flicker_config() -> Dictionary:
	# Use sheet B specifically - slower, cleaner animation
	var variant: String = "b"

	var config := {
		"monster_id": "flicker",
		"display_name": "Flicker",
		"default_sheet": 0,
		"h_frames": 5,
		"v_frames": 5,
		"scale": Vector2(0.25, 0.25),  # Reduced significantly from 1.0
		"sheets": [],
		"brand_color": Color(0.2, 0.6, 0.9),
		"glow_color": Color(0.4, 0.8, 1.0),
		"particle_color": Color(0.2, 0.5, 0.8),
	}

	var sheet1 := SheetConfig.new()
	sheet1.sheet_path = "res://assets/sprites/monsters/sheets/flicker_%s_sheet.png" % variant
	sheet1.h_frames = 5
	sheet1.v_frames = 5
	sheet1.add_animation("idle", 0, 4, 3.0, true)  # Slower animation (was 8.0)
	sheet1.add_animation("attack", 5, 9, 12.0, false, 7)
	sheet1.add_animation("skill_lightning_strike", 5, 9, 10.0, false, 7)
	sheet1.add_animation("block", 10, 14, 8.0, false)
	sheet1.add_animation("defend", 10, 14, 8.0, false)  # Alias for block
	sheet1.add_animation("hurt", 15, 19, 10.0, false)
	sheet1.add_animation("death", 20, 24, 6.0, false)
	config.sheets.append(sheet1)

	return config


# =============================================================================
# SKITTER-TEETH - Armored Insectoid Brute (9 variants: a-i)
# =============================================================================

static func _get_skitter_teeth_config() -> Dictionary:
	var variants := ["a", "b", "c", "d", "e", "f", "g", "h", "i"]
	var variant: String = variants[randi() % variants.size()]

	var config := {
		"monster_id": "skitter_teeth",
		"display_name": "Skitter-Teeth",
		"default_sheet": 0,
		"h_frames": 5,
		"v_frames": 5,
		"scale": Vector2(1.3, 1.3),
		"sheets": [],
		"brand_color": Color(0.6, 0.5, 0.3),
		"glow_color": Color(0.9, 0.3, 0.2),
		"particle_color": Color(0.4, 0.3, 0.2),
	}

	var sheet1 := SheetConfig.new()
	sheet1.sheet_path = "res://assets/sprites/monsters/sheets/skitter_teeth_%s_sheet.png" % variant
	sheet1.h_frames = 5
	sheet1.v_frames = 5
	sheet1.add_animation("idle", 0, 4, 5.0, true)
	sheet1.add_animation("attack", 5, 9, 10.0, false, 7)
	sheet1.add_animation("skill_claw_slash", 5, 9, 10.0, false, 7)
	sheet1.add_animation("block", 10, 14, 6.0, false)
	sheet1.add_animation("defend", 10, 14, 6.0, false)  # Alias for block
	sheet1.add_animation("hurt", 15, 19, 10.0, false)
	sheet1.add_animation("death", 20, 24, 5.0, false)
	config.sheets.append(sheet1)

	return config


# =============================================================================
# THE VESSEL - Floating Hooded Figure (5 variants: a-e)
# =============================================================================

static func _get_the_vessel_config() -> Dictionary:
	var variants := ["a", "b", "c", "d", "e"]
	var variant: String = variants[randi() % variants.size()]

	var config := {
		"monster_id": "the_vessel",
		"display_name": "The Vessel",
		"default_sheet": 0,
		"h_frames": 5,
		"v_frames": 5,
		"scale": Vector2(1.2, 1.2),
		"sheets": [],
		"brand_color": Color(0.9, 0.8, 0.5),
		"glow_color": Color(1.0, 0.95, 0.7),
		"particle_color": Color(0.5, 0.4, 0.2),
	}

	var sheet1 := SheetConfig.new()
	sheet1.sheet_path = "res://assets/sprites/monsters/sheets/the_vessel_%s_sheet.png" % variant
	sheet1.h_frames = 5
	sheet1.v_frames = 5
	sheet1.add_animation("idle", 0, 4, 4.0, true)
	sheet1.add_animation("attack", 5, 9, 8.0, false, 7)
	sheet1.add_animation("skill_stolen_grace", 5, 9, 8.0, false, 7)
	sheet1.add_animation("block", 10, 14, 6.0, false)
	sheet1.add_animation("defend", 10, 14, 6.0, false)  # Alias for block
	sheet1.add_animation("hurt", 15, 19, 10.0, false)
	sheet1.add_animation("death", 20, 24, 5.0, false)
	config.sheets.append(sheet1)

	return config


# =============================================================================
# RAVENER - Black/Red Quadrupedal Beast (3 variants: a-c)
# =============================================================================

static func _get_ravener_config() -> Dictionary:
	var variants := ["a", "b", "c"]
	var variant: String = variants[randi() % variants.size()]

	var config := {
		"monster_id": "ravener",
		"display_name": "Ravener",
		"default_sheet": 0,
		"h_frames": 5,
		"v_frames": 5,
		"scale": Vector2(1.4, 1.4),
		"sheets": [],
		"brand_color": Color(0.2, 0.1, 0.1),
		"glow_color": Color(1.0, 0.3, 0.2),
		"particle_color": Color(0.3, 0.1, 0.1),
	}

	var sheet1 := SheetConfig.new()
	sheet1.sheet_path = "res://assets/sprites/monsters/sheets/ravener_%s_sheet.png" % variant
	sheet1.h_frames = 5
	sheet1.v_frames = 5
	sheet1.add_animation("idle", 0, 4, 5.0, true)
	sheet1.add_animation("attack", 5, 9, 12.0, false, 7)
	sheet1.add_animation("skill_savage_bite", 5, 9, 12.0, false, 7)
	sheet1.add_animation("block", 10, 14, 8.0, false)
	sheet1.add_animation("defend", 10, 14, 8.0, false)  # Alias for block
	sheet1.add_animation("hurt", 15, 19, 10.0, false)
	sheet1.add_animation("death", 20, 24, 5.0, false)
	config.sheets.append(sheet1)

	return config


# =============================================================================
# GLUTTONY POLYP - Green Stomach Creature (2 variants: a-b)
# =============================================================================

static func _get_gluttony_polyp_config() -> Dictionary:
	var variants := ["a", "b"]
	var variant: String = variants[randi() % variants.size()]

	var config := {
		"monster_id": "gluttony_polyp",
		"display_name": "Gluttony Polyp",
		"default_sheet": 0,
		"h_frames": 5,
		"v_frames": 5,
		"scale": Vector2(1.3, 1.3),
		"sheets": [],
		"brand_color": Color(0.3, 0.7, 0.2),
		"glow_color": Color(0.5, 1.0, 0.3),
		"particle_color": Color(0.2, 0.5, 0.1),
	}

	var sheet1 := SheetConfig.new()
	sheet1.sheet_path = "res://assets/sprites/monsters/sheets/gluttony_polyp_%s_sheet.png" % variant
	sheet1.h_frames = 5
	sheet1.v_frames = 5
	sheet1.add_animation("idle", 0, 4, 4.0, true)
	sheet1.add_animation("attack", 5, 9, 8.0, false, 7)
	sheet1.add_animation("skill_acid_spit", 5, 9, 8.0, false, 7)
	sheet1.add_animation("block", 10, 12, 6.0, false)
	sheet1.add_animation("defend", 10, 12, 6.0, false)  # Alias for block
	sheet1.add_animation("hurt", 15, 19, 10.0, false)
	sheet1.add_animation("death", 20, 24, 5.0, false)
	config.sheets.append(sheet1)

	return config


# =============================================================================
# VOLTGEIST - Lightning Elemental (4 variants: a-d)
# =============================================================================

static func _get_voltgeist_config() -> Dictionary:
	var variants := ["a", "b", "c", "d"]
	var variant: String = variants[randi() % variants.size()]

	var config := {
		"monster_id": "voltgeist",
		"display_name": "Voltgeist",
		"default_sheet": 0,
		"h_frames": 5,
		"v_frames": 5,
		"scale": Vector2(1.2, 1.2),
		"sheets": [],
		"brand_color": Color(0.3, 0.5, 0.9),
		"glow_color": Color(0.5, 0.8, 1.0),
		"particle_color": Color(0.2, 0.4, 0.8),
	}

	var sheet1 := SheetConfig.new()
	sheet1.sheet_path = "res://assets/sprites/monsters/sheets/voltgeist_%s_sheet.png" % variant
	sheet1.h_frames = 5
	sheet1.v_frames = 5
	sheet1.add_animation("idle", 0, 4, 6.0, true)
	sheet1.add_animation("attack", 5, 9, 10.0, false, 7)
	sheet1.add_animation("skill_lightning_bolt", 5, 9, 10.0, false, 7)
	sheet1.add_animation("block", 10, 12, 6.0, false)
	sheet1.add_animation("defend", 10, 12, 6.0, false)  # Alias for block
	sheet1.add_animation("hurt", 15, 19, 10.0, false)
	sheet1.add_animation("death", 20, 24, 6.0, false)
	config.sheets.append(sheet1)

	return config


# =============================================================================
# NEEDLEFANG - Serpentine with Green Nodes
# =============================================================================

static func _get_needlefang_config() -> Dictionary:
	var config := {
		"monster_id": "needlefang",
		"display_name": "Needlefang",
		"default_sheet": 0,
		"h_frames": 4,
		"v_frames": 4,
		"scale": Vector2(1.3, 1.3),
		"sheets": [],
		"brand_color": Color(0.2, 0.6, 0.3),
		"glow_color": Color(0.4, 1.0, 0.5),
		"particle_color": Color(0.1, 0.4, 0.2),
	}

	var sheet1 := SheetConfig.new()
	sheet1.sheet_path = "res://assets/sprites/monsters/sheets/needlefang_sheet.png"
	sheet1.h_frames = 4
	sheet1.v_frames = 4
	sheet1.add_animation("idle", 0, 3, 5.0, true)
	sheet1.add_animation("attack", 4, 7, 10.0, false, 6)
	sheet1.add_animation("skill_venom_spit", 4, 7, 8.0, false, 6)
	sheet1.add_animation("block", 8, 9, 6.0, false)
	sheet1.add_animation("defend", 8, 9, 6.0, false)  # Alias for block
	sheet1.add_animation("hurt", 12, 13, 10.0, false)
	sheet1.add_animation("death", 12, 15, 5.0, false)
	config.sheets.append(sheet1)

	return config


# =============================================================================
# CORRODEX - Knight Armor with Acid
# =============================================================================

static func _get_corrodex_config() -> Dictionary:
	var config := {
		"monster_id": "corrodex",
		"display_name": "Corrodex",
		"default_sheet": 0,
		"h_frames": 5,
		"v_frames": 5,
		"scale": Vector2(1.3, 1.3),
		"sheets": [],
		"brand_color": Color(0.4, 0.6, 0.2),
		"glow_color": Color(0.6, 1.0, 0.3),
		"particle_color": Color(0.3, 0.5, 0.1),
	}

	var sheet1 := SheetConfig.new()
	sheet1.sheet_path = "res://assets/sprites/monsters/sheets/corrodex_sheet.png"
	sheet1.h_frames = 5
	sheet1.v_frames = 5
	sheet1.add_animation("idle", 0, 4, 4.0, true)
	sheet1.add_animation("attack", 5, 9, 10.0, false, 7)
	sheet1.add_animation("skill_acid_slash", 5, 9, 8.0, false, 7)
	sheet1.add_animation("block", 10, 12, 6.0, false)
	sheet1.add_animation("defend", 10, 12, 6.0, false)  # Alias for block
	sheet1.add_animation("hurt", 15, 19, 10.0, false)
	sheet1.add_animation("death", 20, 24, 5.0, false)
	config.sheets.append(sheet1)

	return config


# =============================================================================
# THE WEEPING - Floating Eye Cluster
# =============================================================================

static func _get_the_weeping_config() -> Dictionary:
	var config := {
		"monster_id": "the_weeping",
		"display_name": "The Weeping",
		"default_sheet": 0,
		"h_frames": 5,
		"v_frames": 5,
		"scale": Vector2(1.2, 1.2),
		"sheets": [],
		"brand_color": Color(0.5, 0.2, 0.3),
		"glow_color": Color(0.8, 0.4, 0.5),
		"particle_color": Color(0.3, 0.1, 0.2),
	}

	var sheet1 := SheetConfig.new()
	sheet1.sheet_path = "res://assets/sprites/monsters/sheets/the_weeping_sheet.png"
	sheet1.h_frames = 5
	sheet1.v_frames = 5
	sheet1.add_animation("idle", 0, 4, 4.0, true)
	sheet1.add_animation("attack", 5, 9, 8.0, false, 7)
	sheet1.add_animation("skill_gaze", 5, 9, 6.0, false, 7)
	sheet1.add_animation("block", 10, 12, 6.0, false)
	sheet1.add_animation("defend", 10, 12, 6.0, false)  # Alias for block
	sheet1.add_animation("hurt", 15, 19, 10.0, false)
	sheet1.add_animation("death", 20, 24, 5.0, false)
	config.sheets.append(sheet1)

	return config


# =============================================================================
# SPORECALLER - Corrupted Deer with Spore Magic (6 variants: a-f)
# =============================================================================

static func _get_sporecaller_config() -> Dictionary:
	var variants := ["a", "b", "c", "d", "e", "f"]
	var variant: String = variants[randi() % variants.size()]

	var config := {
		"monster_id": "sporecaller",
		"display_name": "Sporecaller",
		"default_sheet": 0,
		"h_frames": 5,
		"v_frames": 5,
		"scale": Vector2(1.3, 1.3),
		"sheets": [],
		"brand_color": Color(0.3, 0.5, 0.2),
		"glow_color": Color(0.5, 0.8, 0.3),
		"particle_color": Color(0.2, 0.4, 0.1),
	}

	var sheet1 := SheetConfig.new()
	sheet1.sheet_path = "res://assets/sprites/monsters/sheets/sporecaller_%s_sheet.png" % variant
	sheet1.h_frames = 5
	sheet1.v_frames = 5
	sheet1.add_animation("idle", 0, 4, 5.0, true)
	sheet1.add_animation("attack", 5, 9, 10.0, false, 7)
	sheet1.add_animation("skill_spore_burst", 5, 9, 8.0, false, 7)
	sheet1.add_animation("block", 10, 12, 6.0, false)
	sheet1.add_animation("defend", 10, 12, 6.0, false)  # Alias for block
	sheet1.add_animation("hurt", 15, 19, 10.0, false)
	sheet1.add_animation("death", 20, 24, 5.0, false)
	config.sheets.append(sheet1)

	return config


# =============================================================================
# IRONJAW - Bear-like Beast with Trap Jaw
# =============================================================================

static func _get_ironjaw_config() -> Dictionary:
	var config := {
		"monster_id": "ironjaw",
		"display_name": "Ironjaw",
		"default_sheet": 0,
		"h_frames": 5,
		"v_frames": 5,
		"scale": Vector2(1.4, 1.4),
		"sheets": [],
		"brand_color": Color(0.5, 0.3, 0.2),
		"glow_color": Color(0.8, 0.5, 0.3),
		"particle_color": Color(0.3, 0.2, 0.15),
	}

	var sheet1 := SheetConfig.new()
	sheet1.sheet_path = "res://assets/sprites/monsters/sheets/ironjaw_sheet.png"
	sheet1.h_frames = 5
	sheet1.v_frames = 5
	sheet1.add_animation("idle", 0, 4, 4.0, true)
	sheet1.add_animation("attack", 5, 9, 10.0, false, 7)
	sheet1.add_animation("skill_trap_bite", 5, 9, 12.0, false, 7)
	sheet1.add_animation("block", 10, 12, 6.0, false)
	sheet1.add_animation("defend", 10, 12, 6.0, false)  # Alias for block
	sheet1.add_animation("hurt", 15, 19, 10.0, false)
	sheet1.add_animation("death", 20, 24, 5.0, false)
	config.sheets.append(sheet1)

	return config


# =============================================================================
# BLOODSHADE - Shadow That Drinks
# =============================================================================

static func _get_bloodshade_config() -> Dictionary:
	# TODO: Bloodshade sprites not yet created - uses default fallback
	return _get_default_config()


# =============================================================================
# GRIMTHORN - Thorny Plant-Based Venomous Creature
# =============================================================================

static func _get_grimthorn_config() -> Dictionary:
	var config := {
		"monster_id": "grimthorn",
		"display_name": "Grimthorn",
		"default_sheet": 0,
		"h_frames": 5,
		"v_frames": 5,
		"scale": Vector2(1.25, 1.25),
		"sheets": [],
		"brand_color": Color(0.2, 0.5, 0.15),  # VENOM green
		"glow_color": Color(0.4, 0.9, 0.3),  # Toxic glow
		"particle_color": Color(0.15, 0.4, 0.1),
	}

	var sheet1 := SheetConfig.new()
	sheet1.sheet_path = "res://assets/sprites/monsters/sheets/grimthorn_a_sheet.png"
	sheet1.h_frames = 5
	sheet1.v_frames = 5
	# Row 1: Idle - thorny mass swaying menacingly
	sheet1.add_animation("idle", 0, 4, 5.0, true)
	# Row 2: Attack animations - vine lash and poison attacks
	sheet1.add_animation("attack", 5, 9, 10.0, false, 7)
	sheet1.add_animation("skill_basic_attack", 5, 9, 10.0, false, 7)
	sheet1.add_animation("skill_poison_sting", 5, 9, 8.0, false, 7)
	sheet1.add_animation("skill_vine_whip", 5, 9, 12.0, false, 7)
	sheet1.add_animation("skill_toxic_spores", 5, 9, 8.0, false, 7)
	sheet1.add_animation("skill_venomous_bloom", 5, 9, 10.0, false, 7)
	# Row 3: Block/Defensive - thorns raised protectively
	sheet1.add_animation("block", 10, 14, 6.0, false)
	sheet1.add_animation("defend", 10, 14, 6.0, false)  # Alias for block
	sheet1.add_animation("skill_thorn_barrier", 10, 14, 8.0, false)
	# Row 4: Hurt reactions - thorns recoiling
	sheet1.add_animation("hurt", 15, 19, 10.0, false)
	# Row 5: Death - withering and crumbling
	sheet1.add_animation("death", 20, 24, 5.0, false)
	config.sheets.append(sheet1)

	return config
