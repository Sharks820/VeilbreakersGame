class_name Paths
extends RefCounted
## Paths: Centralized scene and resource path constants.
## Prevents typos and makes refactoring easier.

# =============================================================================
# SCENE PATHS
# =============================================================================

# Main Scenes
const MAIN_MENU := "res://scenes/main/main_menu.tscn"
const GAME := "res://scenes/main/game.tscn"
const LOADING := "res://scenes/main/loading.tscn"

# Battle Scenes
const BATTLE_ARENA := "res://scenes/battle/battle_arena.tscn"
const BATTLE_UI := "res://scenes/battle/battle_ui.tscn"

# Overworld Scenes
const OVERWORLD := "res://scenes/overworld/overworld.tscn"
const STARTING_VILLAGE := "res://scenes/overworld/starting_village.tscn"

# UI Scenes
const DIALOGUE_BOX := "res://scenes/ui/dialogue_box.tscn"
const VERA_OVERLAY := "res://scenes/ui/vera_overlay.tscn"
const INVENTORY_MENU := "res://scenes/ui/inventory_menu.tscn"
const PARTY_MENU := "res://scenes/ui/party_menu.tscn"
const PAUSE_MENU := "res://scenes/ui/pause_menu.tscn"
const SAVE_LOAD_MENU := "res://scenes/ui/save_load_menu.tscn"
const SETTINGS_MENU := "res://scenes/ui/settings_menu.tscn"

# Test Scenes
const TEST_BATTLE := "res://scenes/test/test_battle.tscn"

# =============================================================================
# DATA PATHS
# =============================================================================

const DATA_MONSTERS := "res://data/monsters/"
const DATA_SKILLS := "res://data/skills/"
const DATA_ITEMS := "res://data/items/"
const DATA_BRANDS := "res://data/brands/"
const DATA_PATHS := "res://data/paths/"
const DATA_DIALOGUE := "res://data/dialogue/"
const DATA_MAPS := "res://data/maps/"

# =============================================================================
# ASSET PATHS
# =============================================================================

# Sprites
const SPRITES_CHARACTERS := "res://assets/sprites/characters/"
const SPRITES_MONSTERS := "res://assets/sprites/monsters/"
const SPRITES_EFFECTS := "res://assets/sprites/effects/"
const SPRITES_ENVIRONMENTS := "res://assets/sprites/environments/"
const SPRITES_UI := "res://assets/sprites/ui/"

# Spine Animations
const SPINE_CHARACTERS := "res://assets/spine/characters/"
const SPINE_MONSTERS := "res://assets/spine/monsters/"
const SPINE_EXPORTS := "res://assets/spine/exports/"

# Audio
const AUDIO_MUSIC := "res://assets/audio/music/"
const AUDIO_SFX := "res://assets/audio/sfx/"
const AUDIO_VOICE := "res://assets/audio/voice/"

# Fonts
const FONTS := "res://assets/fonts/"

# Shaders
const SHADERS := "res://assets/shaders/"

# =============================================================================
# PORTRAIT PATHS
# =============================================================================

const PORTRAIT_VERA_NORMAL := "res://assets/sprites/characters/portraits/vera_normal.png"
const PORTRAIT_VERA_GLITCH := "res://assets/sprites/characters/portraits/vera_glitch.png"
const PORTRAIT_VERA_DARK := "res://assets/sprites/characters/portraits/vera_dark.png"
const PORTRAIT_VERA_MONSTER := "res://assets/sprites/characters/portraits/vera_monster.png"

# =============================================================================
# HELPER METHODS
# =============================================================================

static func get_monster_data_path(monster_id: String) -> String:
	return DATA_MONSTERS + monster_id + ".tres"

static func get_skill_data_path(skill_id: String) -> String:
	return DATA_SKILLS + skill_id + ".tres"

static func get_item_data_path(item_id: String) -> String:
	return DATA_ITEMS + item_id + ".tres"

static func get_monster_sprite_path(monster_id: String) -> String:
	return SPRITES_MONSTERS + monster_id + ".png"

static func get_character_sprite_path(character_id: String) -> String:
	return SPRITES_CHARACTERS + character_id + ".png"

static func get_music_path(track_id: String) -> String:
	return AUDIO_MUSIC + track_id + ".ogg"

static func get_sfx_path(sfx_id: String) -> String:
	return AUDIO_SFX + sfx_id + ".wav"

static func get_voice_path(voice_id: String) -> String:
	return AUDIO_VOICE + voice_id + ".ogg"

static func scene_exists(path: String) -> bool:
	return ResourceLoader.exists(path)

static func resource_exists(path: String) -> bool:
	return ResourceLoader.exists(path)
