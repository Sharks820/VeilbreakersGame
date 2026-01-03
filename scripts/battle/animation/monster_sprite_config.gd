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
	
	func _init(p_start: int = 0, p_end: int = 0, p_fps: float = 10.0, p_loop: bool = false, p_hit: int = -1) -> void:
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
	
	func add_animation(name: String, start: int, end: int, fps: float = 10.0, loop: bool = false, hit_frame: int = -1) -> SheetConfig:
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
		"scale": Vector2(0.5, 0.5),  # Adjusted for 512px sheets
		"sheets": [],
		"brand_color": Color(0.78, 0.24, 0.24),  # DREAD red
		"glow_color": Color(1.0, 0.4, 0.4),
		"particle_color": Color(0.5, 0.1, 0.1),
	}
	
	# Sheet 1 - Primary animations (idle_sheet - was hallow_sheet2)
	var sheet1 := SheetConfig.new()
	sheet1.sheet_path = "res://assets/sprites/monsters/sheets/hollow_idle_sheet.png"
	sheet1.h_frames = 4
	sheet1.v_frames = 4
	# Row 1 (frames 0-3): Idle poses
	sheet1.add_animation("idle", 0, 3, 6.0, true)
	# Row 2 (frames 4-7): Attack with red burst - frame 5-6 are the impact
	# Slowed from 12fps to 6fps so the red beam effect is visible longer (~0.67s total)
	sheet1.add_animation("attack", 4, 7, 6.0, false, 5)
	# Row 3 (frames 8-11): Combat poses - use for skill
	sheet1.add_animation("skill_empty_grasp", 8, 11, 10.0, false, 10)
	# Row 4 (frames 12-15): Death dissolve
	sheet1.add_animation("death", 12, 15, 6.0, false)
	# Hurt can use frame 8-9 (recoil poses)
	sheet1.add_animation("hurt", 8, 9, 12.0, false)
	config.sheets.append(sheet1)
	
	# Sheet 2 - Alternate animations (attack_sheet - was hollow sheet 3)
	var sheet2 := SheetConfig.new()
	sheet2.sheet_path = "res://assets/sprites/monsters/sheets/hollow_attack_sheet.png"
	sheet2.h_frames = 4
	sheet2.v_frames = 4
	# Row 1: Idle with floating debris
	sheet2.add_animation("idle_alt", 0, 3, 5.0, true)
	# Row 2: Attack with different burst - slowed to match primary attack
	sheet2.add_animation("attack_heavy", 4, 7, 6.0, false, 5)
	# Row 3: Combat poses
	sheet2.add_animation("skill_hollow_wail", 8, 11, 8.0, false, 9)
	# Row 4: Death
	sheet2.add_animation("death_alt", 12, 15, 5.0, false)
	sheet2.add_animation("hurt_heavy", 10, 11, 14.0, false)
	config.sheets.append(sheet2)
	
	# Sheet 3 - Special/Skill animations (special_sheet - was hallow_sheet4)
	var sheet3 := SheetConfig.new()
	sheet3.sheet_path = "res://assets/sprites/monsters/sheets/hollow_special_sheet.png"
	sheet3.h_frames = 4
	sheet3.v_frames = 4
	# Use for special skills
	sheet3.add_animation("skill_dread_gaze", 4, 7, 10.0, false, 6)
	sheet3.add_animation("skill_void_touch", 8, 11, 12.0, false, 10)
	sheet3.add_animation("spawn", 12, 15, 8.0, false)  # Reverse for spawn-in
	config.sheets.append(sheet3)
	
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
		"scale": Vector2(0.5, 0.5),
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
		"scale": Vector2(0.45, 0.45),  # Slightly smaller - it's a small creature
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
# DEFAULT CONFIG - For monsters without custom sheets
# =============================================================================

static func _get_default_config() -> Dictionary:
	return {
		"monster_id": "default",
		"display_name": "Monster",
		"default_sheet": -1,  # No sprite sheet, use static sprite
		"h_frames": 1,
		"v_frames": 1,
		"scale": Vector2(0.5, 0.5),
		"sheets": [],
		"brand_color": Color.WHITE,
		"glow_color": Color.WHITE,
		"particle_color": Color.GRAY,
	}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

## Get the best animation for a given action from available sheets
static func get_animation_for_action(config: Dictionary, action: String, skill_name: String = "") -> Dictionary:
	var result := {
		"sheet_index": 0,
		"animation_name": action,
		"found": false
	}
	
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
