# =============================================================================
# VEILBREAKERS Character Battle Animator
# Provides unique, dramatic animations for each action type in battle
# Every attack is a PERFORMANCE - distinct, expressive, brand-colored
# =============================================================================

class_name CharacterBattleAnimator
extends RefCounted

# =============================================================================
# ANIMATION CONFIGURATIONS
# Each action type has unique timing, movement, and visual effects
# =============================================================================

const ANIMATION_CONFIGS := {
	# BASIC ATTACK - Quick lunge forward, strike, return
	"ATTACK": {
		"phases": ["anticipate", "strike", "impact", "recover"],
		"anticipate": {
			"duration": 0.15,
			"scale": Vector2(0.95, 1.05),  # Slight crouch
			"offset": Vector2(-10, 0),      # Pull back
			"rotation": -5.0,               # Lean back
		},
		"strike": {
			"duration": 0.1,
			"scale": Vector2(1.1, 0.95),   # Stretch forward
			"offset": Vector2(80, 0),       # Lunge forward
			"rotation": 10.0,               # Lean into attack
		},
		"impact": {
			"duration": 0.05,
			"flash_color": Color(1.5, 1.5, 1.5),
			"shake": Vector2(8, 4),
		},
		"recover": {
			"duration": 0.2,
			"scale": Vector2(1.0, 1.0),
			"offset": Vector2(0, 0),
			"rotation": 0.0,
		},
	},
	
	# HEAVY ATTACK - Bigger windup, more dramatic
	"ATTACK_HEAVY": {
		"phases": ["anticipate", "charge", "strike", "impact", "recover"],
		"anticipate": {
			"duration": 0.25,
			"scale": Vector2(0.9, 1.1),
			"offset": Vector2(-20, 5),
			"rotation": -10.0,
		},
		"charge": {
			"duration": 0.15,
			"glow_intensity": 1.5,
			"shake": Vector2(2, 2),
		},
		"strike": {
			"duration": 0.08,
			"scale": Vector2(1.15, 0.9),
			"offset": Vector2(100, -10),
			"rotation": 15.0,
		},
		"impact": {
			"duration": 0.08,
			"flash_color": Color(2.0, 1.8, 1.5),
			"shake": Vector2(15, 8),
			"freeze_frame": 0.05,
		},
		"recover": {
			"duration": 0.3,
			"scale": Vector2(1.0, 1.0),
			"offset": Vector2(0, 0),
			"rotation": 0.0,
		},
	},
	
	# DAMAGE SKILL - Magical charge, projectile/wave, impact
	"SKILL_DAMAGE": {
		"phases": ["cast_start", "channel", "release", "impact", "recover"],
		"cast_start": {
			"duration": 0.2,
			"scale": Vector2(1.0, 1.05),
			"offset": Vector2(0, -10),      # Rise slightly
			"glow_intensity": 0.5,
		},
		"channel": {
			"duration": 0.3,
			"scale": Vector2(1.05, 1.05),
			"glow_intensity": 2.0,
			"particle_burst": true,
			"shake": Vector2(3, 3),
		},
		"release": {
			"duration": 0.15,
			"scale": Vector2(1.1, 0.95),
			"offset": Vector2(30, 0),
			"glow_intensity": 3.0,
			"projectile": true,
		},
		"impact": {
			"duration": 0.1,
			"flash_color": Color(1.8, 1.8, 2.0),
			"shake": Vector2(12, 6),
		},
		"recover": {
			"duration": 0.25,
			"scale": Vector2(1.0, 1.0),
			"offset": Vector2(0, 0),
			"glow_intensity": 0.0,
		},
	},
	
	# HEAL SKILL - Gentle rise, warm glow, particles ascend
	"SKILL_HEAL": {
		"phases": ["prepare", "channel", "release", "settle"],
		"prepare": {
			"duration": 0.2,
			"scale": Vector2(1.0, 1.02),
			"offset": Vector2(0, -5),
			"tint": Color(0.9, 1.1, 0.9),
		},
		"channel": {
			"duration": 0.4,
			"scale": Vector2(1.02, 1.05),
			"offset": Vector2(0, -15),
			"glow_intensity": 1.5,
			"glow_color": Color(0.4, 1.0, 0.5),
			"particles_rise": true,
		},
		"release": {
			"duration": 0.2,
			"scale": Vector2(1.05, 1.08),
			"glow_intensity": 2.5,
			"pulse": true,
		},
		"settle": {
			"duration": 0.3,
			"scale": Vector2(1.0, 1.0),
			"offset": Vector2(0, 0),
			"glow_intensity": 0.0,
		},
	},
	
	# BUFF SKILL - Power stance, aura expansion
	"SKILL_BUFF": {
		"phases": ["stance", "gather", "empower", "settle"],
		"stance": {
			"duration": 0.15,
			"scale": Vector2(1.05, 0.98),
			"offset": Vector2(0, 5),
		},
		"gather": {
			"duration": 0.25,
			"scale": Vector2(1.08, 1.02),
			"glow_intensity": 1.0,
			"glow_color": Color(1.0, 0.9, 0.3),
			"aura_contract": true,
		},
		"empower": {
			"duration": 0.2,
			"scale": Vector2(1.12, 1.12),
			"glow_intensity": 2.5,
			"aura_expand": true,
			"flash_color": Color(1.5, 1.4, 1.0),
		},
		"settle": {
			"duration": 0.25,
			"scale": Vector2(1.0, 1.0),
			"glow_intensity": 0.3,  # Lingering glow
		},
	},
	
	# DEBUFF SKILL - Dark gesture, curse wave
	"SKILL_DEBUFF": {
		"phases": ["gesture", "curse", "spread", "fade"],
		"gesture": {
			"duration": 0.2,
			"scale": Vector2(1.0, 1.03),
			"rotation": -8.0,
			"tint": Color(0.8, 0.7, 0.9),
		},
		"curse": {
			"duration": 0.25,
			"glow_intensity": 1.5,
			"glow_color": Color(0.5, 0.2, 0.6),
			"dark_particles": true,
		},
		"spread": {
			"duration": 0.15,
			"scale": Vector2(1.05, 0.98),
			"offset": Vector2(20, 0),
			"wave_effect": true,
		},
		"fade": {
			"duration": 0.2,
			"scale": Vector2(1.0, 1.0),
			"offset": Vector2(0, 0),
			"rotation": 0.0,
		},
	},
	
	# STATUS SKILL - Mystical gesture, orbiting effect
	"SKILL_STATUS": {
		"phases": ["focus", "invoke", "apply", "complete"],
		"focus": {
			"duration": 0.2,
			"scale": Vector2(1.0, 1.02),
			"glow_intensity": 0.5,
		},
		"invoke": {
			"duration": 0.3,
			"scale": Vector2(1.03, 1.05),
			"glow_intensity": 1.5,
			"orbit_particles": true,
		},
		"apply": {
			"duration": 0.2,
			"glow_intensity": 2.0,
			"projectile_to_target": true,
		},
		"complete": {
			"duration": 0.2,
			"scale": Vector2(1.0, 1.0),
			"glow_intensity": 0.0,
		},
	},
	
	# DEFEND - Shield stance, barrier shimmer
	"DEFEND": {
		"phases": ["brace", "shield", "hold"],
		"brace": {
			"duration": 0.1,
			"scale": Vector2(0.95, 1.02),
			"offset": Vector2(-5, 0),
		},
		"shield": {
			"duration": 0.15,
			"scale": Vector2(1.0, 1.0),
			"tint": Color(0.7, 0.85, 1.0),
			"glow_intensity": 1.0,
			"glow_color": Color(0.4, 0.6, 1.0),
			"shield_effect": true,
		},
		"hold": {
			"duration": 0.0,  # Stays in this state
			"tint": Color(0.8, 0.9, 1.0),
			"glow_intensity": 0.5,
		},
	},
	
	# PURIFY - Holy gesture, light beam
	"PURIFY": {
		"phases": ["raise", "channel", "beam", "complete"],
		"raise": {
			"duration": 0.2,
			"scale": Vector2(1.0, 1.05),
			"offset": Vector2(0, -10),
			"tint": Color(1.1, 1.1, 0.9),
		},
		"channel": {
			"duration": 0.4,
			"scale": Vector2(1.02, 1.08),
			"offset": Vector2(0, -20),
			"glow_intensity": 2.0,
			"glow_color": Color(1.0, 1.0, 0.7),
			"holy_particles": true,
		},
		"beam": {
			"duration": 0.3,
			"glow_intensity": 3.0,
			"flash_color": Color(1.5, 1.5, 1.2),
			"beam_effect": true,
		},
		"complete": {
			"duration": 0.25,
			"scale": Vector2(1.0, 1.0),
			"offset": Vector2(0, 0),
			"glow_intensity": 0.0,
		},
	},
	
	# FLEE - Quick retreat animation
	"FLEE": {
		"phases": ["startle", "turn", "run"],
		"startle": {
			"duration": 0.1,
			"scale": Vector2(1.1, 0.95),
			"offset": Vector2(10, 0),
		},
		"turn": {
			"duration": 0.1,
			"rotation": -30.0,
		},
		"run": {
			"duration": 0.3,
			"offset": Vector2(-200, 0),
			"scale": Vector2(0.8, 1.0),
		},
	},
	
	# ITEM USE - Quick gesture
	"ITEM": {
		"phases": ["reach", "use", "effect"],
		"reach": {
			"duration": 0.1,
			"scale": Vector2(1.0, 1.02),
			"offset": Vector2(0, -5),
		},
		"use": {
			"duration": 0.2,
			"glow_intensity": 1.0,
			"glow_color": Color(0.8, 1.0, 0.8),
		},
		"effect": {
			"duration": 0.2,
			"scale": Vector2(1.0, 1.0),
			"offset": Vector2(0, 0),
		},
	},
	
	# HURT - Recoil animation
	"HURT": {
		"phases": ["impact", "recoil", "recover"],
		"impact": {
			"duration": 0.05,
			"flash_color": Color(1.0, 0.3, 0.3),
			"shake": Vector2(10, 5),
		},
		"recoil": {
			"duration": 0.15,
			"scale": Vector2(0.95, 1.05),
			"offset": Vector2(-20, 0),
			"rotation": -5.0,
		},
		"recover": {
			"duration": 0.2,
			"scale": Vector2(1.0, 1.0),
			"offset": Vector2(0, 0),
			"rotation": 0.0,
		},
	},
	
	# HURT_CRITICAL - More dramatic recoil
	"HURT_CRITICAL": {
		"phases": ["impact", "stagger", "recover"],
		"impact": {
			"duration": 0.08,
			"flash_color": Color(1.0, 0.2, 0.2),
			"shake": Vector2(15, 10),
			"freeze_frame": 0.05,
		},
		"stagger": {
			"duration": 0.25,
			"scale": Vector2(0.9, 1.1),
			"offset": Vector2(-40, 5),
			"rotation": -10.0,
		},
		"recover": {
			"duration": 0.3,
			"scale": Vector2(1.0, 1.0),
			"offset": Vector2(0, 0),
			"rotation": 0.0,
		},
	},
	
	# DEATH - Dramatic fall
	"DEATH": {
		"phases": ["hit", "stagger", "fall", "ground"],
		"hit": {
			"duration": 0.1,
			"flash_color": Color(1.0, 0.3, 0.3),
			"shake": Vector2(12, 8),
		},
		"stagger": {
			"duration": 0.3,
			"scale": Vector2(0.95, 1.05),
			"offset": Vector2(-30, 0),
			"rotation": -15.0,
		},
		"fall": {
			"duration": 0.4,
			"scale": Vector2(1.0, 0.8),
			"offset": Vector2(-50, 30),
			"rotation": -45.0,
			"alpha": 0.7,
		},
		"ground": {
			"duration": 0.3,
			"scale": Vector2(1.1, 0.6),
			"offset": Vector2(-60, 50),
			"rotation": -90.0,
			"alpha": 0.0,
		},
	},
}

# =============================================================================
# PER-SKILL UNIQUE ANIMATIONS
# These override the generic skill type animations for specific skills
# Key = animation_id from SkillData, Value = custom animation config
# =============================================================================

const SKILL_SPECIFIC_ANIMATIONS := {
	# =========================================================================
	# SAVAGE BRAND SKILLS - Brutal, fast, bloody
	# =========================================================================
	"fury_strike": {
		"phases": ["crouch", "leap", "slash", "land"],
		"crouch": {
			"duration": 0.12,
			"scale": Vector2(1.1, 0.85),
			"offset": Vector2(-15, 10),
		},
		"leap": {
			"duration": 0.08,
			"scale": Vector2(0.9, 1.2),
			"offset": Vector2(60, -30),
			"rotation": 15.0,
		},
		"slash": {
			"duration": 0.06,
			"scale": Vector2(1.2, 0.9),
			"offset": Vector2(90, 0),
			"flash_color": Color(1.5, 0.3, 0.3),
			"shake": Vector2(12, 6),
		},
		"land": {
			"duration": 0.18,
			"scale": Vector2(1.0, 1.0),
			"offset": Vector2(0, 0),
			"rotation": 0.0,
		},
	},
	
	"apex_fury": {
		"phases": ["roar", "blur1", "blur2", "blur3", "finish"],
		"roar": {
			"duration": 0.25,
			"scale": Vector2(1.15, 1.15),
			"glow_intensity": 2.0,
			"glow_color": Color(0.9, 0.2, 0.2),
			"shake": Vector2(5, 5),
		},
		"blur1": {
			"duration": 0.06,
			"offset": Vector2(80, -20),
			"flash_color": Color(1.3, 0.4, 0.4),
		},
		"blur2": {
			"duration": 0.06,
			"offset": Vector2(100, 10),
			"flash_color": Color(1.3, 0.4, 0.4),
		},
		"blur3": {
			"duration": 0.06,
			"offset": Vector2(70, -10),
			"flash_color": Color(1.3, 0.4, 0.4),
		},
		"finish": {
			"duration": 0.15,
			"scale": Vector2(1.1, 0.95),
			"offset": Vector2(0, 0),
			"shake": Vector2(15, 10),
			"freeze_frame": 0.08,
		},
	},
	
	"rending_strike": {
		"phases": ["wind_up", "tear", "rip", "recover"],
		"wind_up": {
			"duration": 0.2,
			"scale": Vector2(0.95, 1.08),
			"offset": Vector2(-20, 0),
			"rotation": -15.0,
		},
		"tear": {
			"duration": 0.08,
			"scale": Vector2(1.15, 0.9),
			"offset": Vector2(70, 0),
			"rotation": 20.0,
		},
		"rip": {
			"duration": 0.1,
			"offset": Vector2(90, 10),
			"flash_color": Color(1.5, 0.2, 0.2),
			"shake": Vector2(10, 8),
			"freeze_frame": 0.04,
		},
		"recover": {
			"duration": 0.2,
			"scale": Vector2(1.0, 1.0),
			"offset": Vector2(0, 0),
			"rotation": 0.0,
		},
	},
	
	"frenzy": {
		"phases": ["rage_build", "thrash1", "thrash2", "thrash3", "exhaust"],
		"rage_build": {
			"duration": 0.2,
			"scale": Vector2(1.1, 1.1),
			"glow_intensity": 1.5,
			"glow_color": Color(1.0, 0.3, 0.2),
			"shake": Vector2(4, 4),
		},
		"thrash1": {
			"duration": 0.05,
			"offset": Vector2(50, -10),
			"rotation": 10.0,
		},
		"thrash2": {
			"duration": 0.05,
			"offset": Vector2(60, 15),
			"rotation": -8.0,
		},
		"thrash3": {
			"duration": 0.05,
			"offset": Vector2(70, -5),
			"rotation": 12.0,
			"flash_color": Color(1.4, 0.3, 0.3),
		},
		"exhaust": {
			"duration": 0.25,
			"scale": Vector2(1.0, 1.0),
			"offset": Vector2(0, 0),
			"rotation": 0.0,
		},
	},
	
	# =========================================================================
	# IRON BRAND SKILLS - Heavy, impactful, defensive
	# =========================================================================
	"shield_bash": {
		"phases": ["brace", "charge", "slam", "recover"],
		"brace": {
			"duration": 0.15,
			"scale": Vector2(1.05, 0.95),
			"offset": Vector2(-10, 5),
			"tint": Color(0.8, 0.85, 0.9),
		},
		"charge": {
			"duration": 0.1,
			"scale": Vector2(0.95, 1.0),
			"offset": Vector2(50, 0),
		},
		"slam": {
			"duration": 0.08,
			"scale": Vector2(1.1, 0.9),
			"offset": Vector2(80, 0),
			"flash_color": Color(1.2, 1.2, 1.3),
			"shake": Vector2(15, 5),
			"freeze_frame": 0.06,
		},
		"recover": {
			"duration": 0.25,
			"scale": Vector2(1.0, 1.0),
			"offset": Vector2(0, 0),
		},
	},
	
	"iron_wall": {
		"phases": ["plant", "fortify", "pulse", "hold"],
		"plant": {
			"duration": 0.1,
			"scale": Vector2(1.0, 0.95),
			"offset": Vector2(0, 5),
		},
		"fortify": {
			"duration": 0.2,
			"scale": Vector2(1.08, 1.08),
			"glow_intensity": 1.5,
			"glow_color": Color(0.6, 0.65, 0.7),
		},
		"pulse": {
			"duration": 0.15,
			"glow_intensity": 2.5,
			"flash_color": Color(0.9, 0.95, 1.1),
		},
		"hold": {
			"duration": 0.2,
			"scale": Vector2(1.05, 1.05),
			"glow_intensity": 0.8,
		},
	},
	
	"fortress_stance": {
		"phases": ["crouch", "anchor", "aura", "steady"],
		"crouch": {
			"duration": 0.15,
			"scale": Vector2(1.1, 0.9),
			"offset": Vector2(0, 8),
		},
		"anchor": {
			"duration": 0.2,
			"scale": Vector2(1.15, 0.85),
			"glow_intensity": 1.0,
			"glow_color": Color(0.5, 0.5, 0.6),
			"shake": Vector2(3, 0),
		},
		"aura": {
			"duration": 0.25,
			"glow_intensity": 2.0,
			"flash_color": Color(0.8, 0.85, 1.0),
		},
		"steady": {
			"duration": 0.15,
			"scale": Vector2(1.1, 0.9),
			"glow_intensity": 0.5,
		},
	},
	
	# =========================================================================
	# VENOM BRAND SKILLS - Toxic, spreading, lingering
	# =========================================================================
	"venom_spray": {
		"phases": ["inhale", "swell", "spray", "dissipate"],
		"inhale": {
			"duration": 0.15,
			"scale": Vector2(0.95, 1.05),
			"offset": Vector2(-10, 0),
		},
		"swell": {
			"duration": 0.2,
			"scale": Vector2(1.1, 1.1),
			"glow_intensity": 1.5,
			"glow_color": Color(0.3, 0.8, 0.2),
		},
		"spray": {
			"duration": 0.12,
			"scale": Vector2(1.05, 0.95),
			"offset": Vector2(40, 0),
			"glow_intensity": 2.5,
			"flash_color": Color(0.5, 1.2, 0.4),
		},
		"dissipate": {
			"duration": 0.25,
			"scale": Vector2(1.0, 1.0),
			"offset": Vector2(0, 0),
			"glow_intensity": 0.0,
		},
	},
	
	"toxic_cloud": {
		"phases": ["gather", "compress", "release", "spread"],
		"gather": {
			"duration": 0.25,
			"scale": Vector2(1.05, 1.05),
			"glow_intensity": 1.0,
			"glow_color": Color(0.4, 0.7, 0.3),
		},
		"compress": {
			"duration": 0.15,
			"scale": Vector2(0.95, 0.95),
			"glow_intensity": 2.0,
		},
		"release": {
			"duration": 0.1,
			"scale": Vector2(1.15, 1.15),
			"glow_intensity": 3.0,
			"flash_color": Color(0.6, 1.0, 0.5),
		},
		"spread": {
			"duration": 0.3,
			"scale": Vector2(1.0, 1.0),
			"glow_intensity": 0.5,
		},
	},
	
	# =========================================================================
	# SURGE BRAND SKILLS - Electric, fast, chain reactions
	# =========================================================================
	"lightning_bolt": {
		"phases": ["charge", "arc", "strike", "fade"],
		"charge": {
			"duration": 0.2,
			"scale": Vector2(1.0, 1.08),
			"offset": Vector2(0, -10),
			"glow_intensity": 2.0,
			"glow_color": Color(0.4, 0.7, 1.0),
			"shake": Vector2(3, 3),
		},
		"arc": {
			"duration": 0.05,
			"glow_intensity": 4.0,
			"flash_color": Color(0.8, 0.9, 1.5),
		},
		"strike": {
			"duration": 0.08,
			"scale": Vector2(1.1, 0.95),
			"offset": Vector2(30, 0),
			"shake": Vector2(12, 8),
			"freeze_frame": 0.04,
		},
		"fade": {
			"duration": 0.2,
			"scale": Vector2(1.0, 1.0),
			"offset": Vector2(0, 0),
			"glow_intensity": 0.0,
		},
	},
	
	"chain_lightning": {
		"phases": ["gather", "release", "chain1", "chain2", "chain3"],
		"gather": {
			"duration": 0.25,
			"glow_intensity": 2.0,
			"glow_color": Color(0.3, 0.6, 1.0),
			"shake": Vector2(4, 4),
		},
		"release": {
			"duration": 0.06,
			"offset": Vector2(30, 0),
			"flash_color": Color(0.7, 0.9, 1.5),
		},
		"chain1": {
			"duration": 0.04,
			"flash_color": Color(0.6, 0.8, 1.3),
		},
		"chain2": {
			"duration": 0.04,
			"flash_color": Color(0.5, 0.7, 1.2),
		},
		"chain3": {
			"duration": 0.04,
			"flash_color": Color(0.4, 0.6, 1.1),
		},
	},
	
	# =========================================================================
	# DREAD BRAND SKILLS - Fear, shadow, psychological
	# =========================================================================
	"nightmare": {
		"phases": ["darken", "manifest", "terror", "fade"],
		"darken": {
			"duration": 0.3,
			"tint": Color(0.6, 0.5, 0.7),
			"glow_intensity": 1.0,
			"glow_color": Color(0.4, 0.2, 0.5),
		},
		"manifest": {
			"duration": 0.2,
			"scale": Vector2(1.1, 1.1),
			"glow_intensity": 2.0,
			"shake": Vector2(5, 5),
		},
		"terror": {
			"duration": 0.15,
			"scale": Vector2(1.2, 1.2),
			"glow_intensity": 3.0,
			"flash_color": Color(0.8, 0.4, 1.0),
		},
		"fade": {
			"duration": 0.25,
			"scale": Vector2(1.0, 1.0),
			"tint": Color(1.0, 1.0, 1.0),
			"glow_intensity": 0.0,
		},
	},
	
	"fear_touch": {
		"phases": ["reach", "grasp", "inject", "release"],
		"reach": {
			"duration": 0.15,
			"scale": Vector2(1.0, 1.05),
			"offset": Vector2(30, 0),
			"tint": Color(0.7, 0.6, 0.8),
		},
		"grasp": {
			"duration": 0.1,
			"offset": Vector2(60, 0),
			"glow_intensity": 1.5,
			"glow_color": Color(0.5, 0.3, 0.6),
		},
		"inject": {
			"duration": 0.12,
			"glow_intensity": 2.5,
			"flash_color": Color(0.7, 0.4, 0.9),
			"shake": Vector2(6, 4),
		},
		"release": {
			"duration": 0.2,
			"scale": Vector2(1.0, 1.0),
			"offset": Vector2(0, 0),
			"tint": Color(1.0, 1.0, 1.0),
		},
	},
	
	# =========================================================================
	# LEECH BRAND SKILLS - Drain, siphon, life steal
	# =========================================================================
	"life_tap": {
		"phases": ["connect", "drain", "absorb", "complete"],
		"connect": {
			"duration": 0.15,
			"offset": Vector2(40, 0),
			"glow_intensity": 1.0,
			"glow_color": Color(0.8, 0.2, 0.4),
		},
		"drain": {
			"duration": 0.3,
			"glow_intensity": 2.0,
			"tint": Color(1.1, 0.9, 0.95),
		},
		"absorb": {
			"duration": 0.2,
			"scale": Vector2(1.05, 1.05),
			"glow_intensity": 2.5,
			"flash_color": Color(1.2, 0.5, 0.6),
		},
		"complete": {
			"duration": 0.15,
			"scale": Vector2(1.0, 1.0),
			"offset": Vector2(0, 0),
			"glow_intensity": 0.0,
		},
	},
	
	"siphon_heal": {
		"phases": ["latch", "pull", "transfer", "release"],
		"latch": {
			"duration": 0.12,
			"offset": Vector2(50, 0),
			"glow_intensity": 1.0,
			"glow_color": Color(0.7, 0.3, 0.5),
		},
		"pull": {
			"duration": 0.25,
			"glow_intensity": 1.8,
			"shake": Vector2(3, 3),
		},
		"transfer": {
			"duration": 0.2,
			"scale": Vector2(1.08, 1.08),
			"glow_intensity": 2.5,
			"glow_color": Color(0.5, 0.9, 0.5),
		},
		"release": {
			"duration": 0.18,
			"scale": Vector2(1.0, 1.0),
			"offset": Vector2(0, 0),
			"glow_intensity": 0.0,
		},
	},
	
	"mass_drain": {
		"phases": ["expand", "connect_all", "siphon", "consume"],
		"expand": {
			"duration": 0.2,
			"scale": Vector2(1.1, 1.1),
			"glow_intensity": 1.5,
			"glow_color": Color(0.6, 0.2, 0.4),
		},
		"connect_all": {
			"duration": 0.15,
			"glow_intensity": 2.5,
			"shake": Vector2(4, 4),
		},
		"siphon": {
			"duration": 0.35,
			"glow_intensity": 3.0,
			"tint": Color(1.2, 0.8, 0.9),
		},
		"consume": {
			"duration": 0.2,
			"scale": Vector2(1.15, 1.15),
			"flash_color": Color(1.3, 0.4, 0.5),
			"glow_intensity": 0.0,
		},
	},
	
	# =========================================================================
	# SPECIAL/ULTIMATE SKILLS
	# =========================================================================
	"execute": {
		"phases": ["judge", "raise", "descend", "execute", "finish"],
		"judge": {
			"duration": 0.3,
			"scale": Vector2(1.0, 1.1),
			"offset": Vector2(0, -15),
			"glow_intensity": 1.5,
			"glow_color": Color(0.8, 0.2, 0.2),
		},
		"raise": {
			"duration": 0.2,
			"scale": Vector2(1.05, 1.15),
			"offset": Vector2(0, -30),
			"glow_intensity": 2.5,
		},
		"descend": {
			"duration": 0.08,
			"scale": Vector2(1.15, 0.9),
			"offset": Vector2(80, 10),
			"rotation": 25.0,
		},
		"execute": {
			"duration": 0.1,
			"flash_color": Color(2.0, 0.3, 0.3),
			"shake": Vector2(20, 15),
			"freeze_frame": 0.1,
		},
		"finish": {
			"duration": 0.3,
			"scale": Vector2(1.0, 1.0),
			"offset": Vector2(0, 0),
			"rotation": 0.0,
		},
	},
	
	"true_terror": {
		"phases": ["gather_darkness", "expand", "overwhelm", "shatter"],
		"gather_darkness": {
			"duration": 0.4,
			"tint": Color(0.5, 0.4, 0.6),
			"glow_intensity": 2.0,
			"glow_color": Color(0.3, 0.1, 0.4),
			"shake": Vector2(3, 3),
		},
		"expand": {
			"duration": 0.25,
			"scale": Vector2(1.2, 1.2),
			"glow_intensity": 3.5,
		},
		"overwhelm": {
			"duration": 0.15,
			"scale": Vector2(1.3, 1.3),
			"glow_intensity": 5.0,
			"flash_color": Color(0.6, 0.3, 0.8),
		},
		"shatter": {
			"duration": 0.3,
			"scale": Vector2(1.0, 1.0),
			"tint": Color(1.0, 1.0, 1.0),
			"shake": Vector2(15, 12),
		},
	},
	
	"reality_shatter": {
		"phases": ["focus", "crack", "shatter", "reform"],
		"focus": {
			"duration": 0.35,
			"glow_intensity": 2.0,
			"glow_color": Color(0.8, 0.3, 1.0),
			"shake": Vector2(2, 2),
		},
		"crack": {
			"duration": 0.15,
			"glow_intensity": 4.0,
			"flash_color": Color(1.0, 0.5, 1.2),
		},
		"shatter": {
			"duration": 0.12,
			"scale": Vector2(1.2, 1.2),
			"shake": Vector2(25, 20),
			"freeze_frame": 0.08,
		},
		"reform": {
			"duration": 0.3,
			"scale": Vector2(1.0, 1.0),
			"glow_intensity": 0.0,
		},
	},
}

# =============================================================================
# BRAND COLORS FOR GLOW EFFECTS
# =============================================================================

const BRAND_GLOW_COLORS := {
	Enums.Brand.SAVAGE: Color(0.9, 0.2, 0.2),
	Enums.Brand.IRON: Color(0.5, 0.5, 0.6),
	Enums.Brand.VENOM: Color(0.3, 0.8, 0.2),
	Enums.Brand.SURGE: Color(0.3, 0.6, 1.0),
	Enums.Brand.DREAD: Color(0.5, 0.2, 0.7),
	Enums.Brand.LEECH: Color(0.8, 0.2, 0.5),
	Enums.Brand.BLOODIRON: Color(0.7, 0.3, 0.3),
	Enums.Brand.CORROSIVE: Color(0.4, 0.6, 0.3),
	Enums.Brand.VENOMSTRIKE: Color(0.4, 0.7, 0.5),
	Enums.Brand.TERRORFLUX: Color(0.4, 0.4, 0.8),
	Enums.Brand.NIGHTLEECH: Color(0.4, 0.2, 0.5),
	Enums.Brand.RAVENOUS: Color(0.6, 0.2, 0.3),
	Enums.Brand.NONE: Color(0.8, 0.8, 0.8),
}

# =============================================================================
# ANIMATION PLAYBACK
# =============================================================================

## Play a complete action animation sequence on a sprite
## Returns when animation is complete
static func play_action_animation(
	sprite: Node2D,
	action_type: String,
	brand: Enums.Brand = Enums.Brand.NONE,
	target_position: Vector2 = Vector2.ZERO,
	is_enemy: bool = false
) -> void:
	var config: Dictionary = ANIMATION_CONFIGS.get(action_type, ANIMATION_CONFIGS["ATTACK"])
	var phases: Array = config.get("phases", [])
	
	# Store original state
	var original_position := sprite.position
	var original_scale := sprite.scale
	var original_rotation := sprite.rotation_degrees
	var original_modulate := sprite.modulate
	
	# Direction multiplier (enemies animate in opposite direction)
	var dir := -1.0 if is_enemy else 1.0
	
	# Get brand glow color
	var glow_color: Color = BRAND_GLOW_COLORS.get(brand, Color.WHITE)
	
	# Play each phase
	for phase_name in phases:
		var phase: Dictionary = config.get(phase_name, {})
		var duration: float = phase.get("duration", 0.2)
		
		if duration <= 0:
			continue
		
		var tween := sprite.create_tween()
		tween.set_parallel(true)
		
		# Scale animation
		if phase.has("scale"):
			var target_scale: Vector2 = phase["scale"]
			tween.tween_property(sprite, "scale", original_scale * target_scale, duration)
		
		# Position offset
		if phase.has("offset"):
			var offset: Vector2 = phase["offset"]
			offset.x *= dir  # Flip direction for enemies
			tween.tween_property(sprite, "position", original_position + offset, duration)
		
		# Rotation
		if phase.has("rotation"):
			var rot: float = phase["rotation"] * dir
			tween.tween_property(sprite, "rotation_degrees", original_rotation + rot, duration)
		
		# Tint/modulate
		if phase.has("tint"):
			tween.tween_property(sprite, "modulate", phase["tint"], duration)
		
		# Alpha
		if phase.has("alpha"):
			var target_modulate := sprite.modulate
			target_modulate.a = phase["alpha"]
			tween.tween_property(sprite, "modulate", target_modulate, duration)
		
		# Flash effect (instant)
		if phase.has("flash_color"):
			_apply_flash(sprite, phase["flash_color"], 0.1)
		
		# Glow intensity
		if phase.has("glow_intensity"):
			var intensity: float = phase["glow_intensity"]
			var color: Color = phase.get("glow_color", glow_color)
			_apply_glow(sprite, color, intensity, duration)
		
		# Shake effect
		if phase.has("shake"):
			var shake_amount: Vector2 = phase["shake"]
			_apply_shake(sprite, shake_amount, duration)
		
		# Freeze frame (hitstop)
		if phase.has("freeze_frame"):
			await sprite.get_tree().create_timer(phase["freeze_frame"]).timeout
		
		# Wait for phase to complete
		await sprite.get_tree().create_timer(duration).timeout
	
	# Reset to original state (except for death)
	if action_type != "DEATH":
		var reset_tween := sprite.create_tween()
		reset_tween.set_parallel(true)
		reset_tween.tween_property(sprite, "position", original_position, 0.1)
		reset_tween.tween_property(sprite, "scale", original_scale, 0.1)
		reset_tween.tween_property(sprite, "rotation_degrees", original_rotation, 0.1)
		reset_tween.tween_property(sprite, "modulate", original_modulate, 0.1)

## Check if a skill has a unique animation defined
static func has_skill_specific_animation(animation_id: String) -> bool:
	return SKILL_SPECIFIC_ANIMATIONS.has(animation_id)

## Get the animation config for a skill - checks specific first, then falls back to type
static func get_skill_animation_config(skill: SkillData) -> Dictionary:
	# First check if this skill has a unique animation
	if skill.animation_id != "" and SKILL_SPECIFIC_ANIMATIONS.has(skill.animation_id):
		return SKILL_SPECIFIC_ANIMATIONS[skill.animation_id]
	
	# Fall back to generic skill type animation
	var type_key := get_skill_animation_type(skill.skill_type)
	return ANIMATION_CONFIGS.get(type_key, ANIMATION_CONFIGS["SKILL_DAMAGE"])

## Get the animation type for a skill based on its SkillType
static func get_skill_animation_type(skill_type: int) -> String:
	match skill_type:
		SkillData.SkillType.DAMAGE:
			return "SKILL_DAMAGE"
		SkillData.SkillType.HEAL:
			return "SKILL_HEAL"
		SkillData.SkillType.BUFF:
			return "SKILL_BUFF"
		SkillData.SkillType.DEBUFF:
			return "SKILL_DEBUFF"
		SkillData.SkillType.STATUS:
			return "SKILL_STATUS"
		_:
			return "SKILL_DAMAGE"

## Get animation type from BattleAction enum
static func get_action_animation_type(action: Enums.BattleAction) -> String:
	match action:
		Enums.BattleAction.ATTACK:
			return "ATTACK"
		Enums.BattleAction.SKILL:
			return "SKILL_DAMAGE"  # Will be overridden by skill type
		Enums.BattleAction.DEFEND:
			return "DEFEND"
		Enums.BattleAction.ITEM:
			return "ITEM"
		Enums.BattleAction.PURIFY:
			return "PURIFY"
		Enums.BattleAction.FLEE:
			return "FLEE"
		_:
			return "ATTACK"

# =============================================================================
# VISUAL EFFECTS HELPERS
# =============================================================================

static func _apply_flash(sprite: Node2D, color: Color, duration: float) -> void:
	"""Apply a quick flash effect to the sprite"""
	var original := sprite.modulate
	sprite.modulate = color
	
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "modulate", original, duration)

static func _apply_glow(sprite: Node2D, color: Color, intensity: float, duration: float) -> void:
	"""Apply a glow effect (using modulate for now, could use shader)"""
	var glow_modulate := Color(
		1.0 + (color.r * intensity * 0.3),
		1.0 + (color.g * intensity * 0.3),
		1.0 + (color.b * intensity * 0.3),
		1.0
	)
	
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "modulate", glow_modulate, duration * 0.5)
	tween.tween_property(sprite, "modulate", Color.WHITE, duration * 0.5)

static func _apply_shake(sprite: Node2D, amount: Vector2, duration: float) -> void:
	"""Apply a shake effect to the sprite"""
	var original_pos := sprite.position
	var shake_count := int(duration / 0.05)
	
	var tween := sprite.create_tween()
	for i in range(shake_count):
		var offset := Vector2(
			randf_range(-amount.x, amount.x),
			randf_range(-amount.y, amount.y)
		)
		tween.tween_property(sprite, "position", original_pos + offset, 0.025)
		tween.tween_property(sprite, "position", original_pos, 0.025)

# =============================================================================
# QUICK ANIMATION METHODS
# =============================================================================

## Play attack animation
static func play_attack(sprite: Node2D, brand: Enums.Brand, is_enemy: bool = false) -> void:
	await play_action_animation(sprite, "ATTACK", brand, Vector2.ZERO, is_enemy)

## Play heavy attack animation
static func play_heavy_attack(sprite: Node2D, brand: Enums.Brand, is_enemy: bool = false) -> void:
	await play_action_animation(sprite, "ATTACK_HEAVY", brand, Vector2.ZERO, is_enemy)

## Play skill animation based on skill type (legacy - use play_skill_with_data for unique anims)
static func play_skill(sprite: Node2D, skill_type: int, brand: Enums.Brand, is_enemy: bool = false) -> void:
	var anim_type := get_skill_animation_type(skill_type)
	await play_action_animation(sprite, anim_type, brand, Vector2.ZERO, is_enemy)

## Play skill animation with full SkillData - uses unique animation if available
static func play_skill_with_data(
	sprite: Node2D, 
	skill: SkillData, 
	brand: Enums.Brand, 
	target_position: Vector2 = Vector2.ZERO,
	is_enemy: bool = false
) -> void:
	# Check for skill-specific animation first
	if skill.animation_id != "" and SKILL_SPECIFIC_ANIMATIONS.has(skill.animation_id):
		await _play_custom_animation(sprite, SKILL_SPECIFIC_ANIMATIONS[skill.animation_id], brand, is_enemy)
	else:
		# Fall back to generic skill type animation
		var anim_type := get_skill_animation_type(skill.skill_type)
		await play_action_animation(sprite, anim_type, brand, target_position, is_enemy)

## Play a custom animation config (for skill-specific animations)
static func _play_custom_animation(
	sprite: Node2D,
	config: Dictionary,
	brand: Enums.Brand,
	is_enemy: bool
) -> void:
	var phases: Array = config.get("phases", [])
	
	# Store original state
	var original_position := sprite.position
	var original_scale := sprite.scale
	var original_rotation := sprite.rotation_degrees
	var original_modulate := sprite.modulate
	
	# Direction multiplier (enemies animate in opposite direction)
	var dir := -1.0 if is_enemy else 1.0
	
	# Get brand glow color
	var glow_color: Color = BRAND_GLOW_COLORS.get(brand, Color.WHITE)
	
	# Play each phase
	for phase_name in phases:
		var phase: Dictionary = config.get(phase_name, {})
		var duration: float = phase.get("duration", 0.2)
		
		if duration <= 0:
			continue
		
		var tween := sprite.create_tween()
		tween.set_parallel(true)
		
		# Scale animation
		if phase.has("scale"):
			var target_scale: Vector2 = phase["scale"]
			tween.tween_property(sprite, "scale", original_scale * target_scale, duration)
		
		# Position offset
		if phase.has("offset"):
			var offset: Vector2 = phase["offset"]
			offset.x *= dir  # Flip direction for enemies
			tween.tween_property(sprite, "position", original_position + offset, duration)
		
		# Rotation
		if phase.has("rotation"):
			var rot: float = phase["rotation"] * dir
			tween.tween_property(sprite, "rotation_degrees", original_rotation + rot, duration)
		
		# Tint/modulate
		if phase.has("tint"):
			tween.tween_property(sprite, "modulate", phase["tint"], duration)
		
		# Alpha
		if phase.has("alpha"):
			var target_modulate := sprite.modulate
			target_modulate.a = phase["alpha"]
			tween.tween_property(sprite, "modulate", target_modulate, duration)
		
		# Flash effect (instant)
		if phase.has("flash_color"):
			_apply_flash(sprite, phase["flash_color"], 0.1)
		
		# Glow intensity
		if phase.has("glow_intensity"):
			var intensity: float = phase["glow_intensity"]
			var color: Color = phase.get("glow_color", glow_color)
			_apply_glow(sprite, color, intensity, duration)
		
		# Shake effect
		if phase.has("shake"):
			var shake_amount: Vector2 = phase["shake"]
			_apply_shake(sprite, shake_amount, duration)
		
		# Freeze frame (hitstop)
		if phase.has("freeze_frame"):
			await sprite.get_tree().create_timer(phase["freeze_frame"]).timeout
		
		# Wait for phase to complete
		await sprite.get_tree().create_timer(duration).timeout
	
	# Reset to original state
	var reset_tween := sprite.create_tween()
	reset_tween.set_parallel(true)
	reset_tween.tween_property(sprite, "position", original_position, 0.1)
	reset_tween.tween_property(sprite, "scale", original_scale, 0.1)
	reset_tween.tween_property(sprite, "rotation_degrees", original_rotation, 0.1)
	reset_tween.tween_property(sprite, "modulate", original_modulate, 0.1)

## Play defend animation
static func play_defend(sprite: Node2D) -> void:
	await play_action_animation(sprite, "DEFEND")

## Play purify animation
static func play_purify(sprite: Node2D) -> void:
	await play_action_animation(sprite, "PURIFY")

## Play hurt animation
static func play_hurt(sprite: Node2D, is_critical: bool = false) -> void:
	var anim_type := "HURT_CRITICAL" if is_critical else "HURT"
	await play_action_animation(sprite, anim_type)

## Play death animation
static func play_death(sprite: Node2D, brand: Enums.Brand = Enums.Brand.NONE) -> void:
	await play_action_animation(sprite, "DEATH", brand)

## Play flee animation
static func play_flee(sprite: Node2D) -> void:
	await play_action_animation(sprite, "FLEE")

## Play item use animation
static func play_item(sprite: Node2D) -> void:
	await play_action_animation(sprite, "ITEM")
