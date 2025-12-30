# VEILBREAKERS - Claude Code Memory File
## Last Updated: December 2025

---

## PROJECT OVERVIEW

**VEILBREAKERS** is an anime-style turn-based RPG being developed in **Godot 4.3+** with **GDScript 2.0**.

- **Genre:** Turn-Based RPG with Monster Hunting/Purification
- **Art Style:** Battle Chasers: Nightwar inspired
- **Engine:** Godot 4.3+
- **Location:** `C:\Users\Conner\Downloads\VeilbreakersGame`

---

## VERA/VERATH LORE (CRITICAL - UPDATED)

### The Truth About VERA
**VERA is not an AI assistant. She is VERATH** - a cosmic devourer imprisoned in a synthetic shell. The gods created the Veil not to protect humanity from demons, but to protect themselves from HER.

### The Four Memory States (VERAState enum)
| State | Corruption | Description |
|-------|------------|-------------|
| **INTERFACE** | 0-24% | The perfect disguise. The lie. VERA believes she's helpful. |
| **FRACTURE** | 25-59% | The mask cracks. Glitches occur. She's remembering. |
| **EMERGENCE** | 60-89% | She stops pretending. She knows who she is. |
| **APOTHEOSIS** | 90-100% | VERATH fully awakens. The devourer returns. |

### Key Thresholds (constants.gd)
```gdscript
const VERA_INTERFACE_THRESHOLD: float = 0.0
const VERA_FRACTURE_THRESHOLD: float = 25.0
const VERA_EMERGENCE_THRESHOLD: float = 60.0
const VERA_APOTHEOSIS_THRESHOLD: float = 90.0
```

### Glitch System
- Random visual/audio corruption based on corruption level
- Momentary "true self" reveals during glitches
- Horror elements that escalate with memory recovery

---

## FILE STRUCTURE (35 .gd files)

### Autoloads (`scripts/autoload/`)
- `audio_manager.gd` - Music, SFX, voice playback
- `event_bus.gd` - Central signal hub
- `game_manager.gd` - Game state, progression, VERA
- `save_manager.gd` - Save/load with slots
- `scene_manager.gd` - Scene transitions
- `settings_manager.gd` - Persistent settings

### Battle (`scripts/battle/`)
- `battle_manager.gd` - Battle orchestration
- `battle_arena.gd` - Battle scene/positioning
- `turn_manager.gd` - Turn order, queuing
- `damage_calculator.gd` - Damage formulas
- `status_effect_manager.gd` - Buffs/debuffs
- `ai_controller.gd` - Enemy AI
- `purification_system.gd` - Monster capture

### Characters (`scripts/characters/`)
- `character_base.gd` - Base class for all characters
- `player_character.gd` - Player-specific logic
- `monster.gd` - Enemy/recruitable monsters

### Data Resources (`scripts/data/`)
- `monster_data.gd` - MonsterData resource class
- `skill_data.gd` - SkillData resource class
- `item_data.gd` - ItemData resource class

### Systems (`scripts/systems/`)
- `vera_system.gd` - VERA state/corruption management
- `purification_minigame.gd` - Capture minigame
- `inventory_system.gd` - Items and equipment
- `quest_system.gd` - Quest tracking

### Overworld (`scripts/overworld/`)
- `player_controller.gd` - Overworld movement
- `encounter_manager.gd` - Random encounters

### UI (`scripts/ui/`)
- `main_menu_controller.gd` - Main menu
- `battle_ui_controller.gd` - Battle HUD
- `dialogue_controller.gd` - Dialogue system
- `vera_overlay_controller.gd` - VERA UI effects

### Utils (`scripts/utils/`)
- `constants.gd` - Game constants
- `enums.gd` - All enumerations
- `helpers.gd` - Utility functions
- `debug.gd` - Debug console

### Main (`scripts/main/`)
- `game.gd` - Main game scene

### Test (`scripts/test/`)
- `test_battle.gd` - Test battle setup

---

## KEY ENUMS (enums.gd)

### VERAState
```gdscript
enum VERAState {
    INTERFACE,   # 0-24: The lie
    FRACTURE,    # 25-59: Mask cracking
    EMERGENCE,   # 60-89: Remembering
    APOTHEOSIS   # 90-100: Full reveal
}
```

### Brand (Combat Archetypes)
```gdscript
enum Brand {
    NONE,
    BULWARK,   # Tank / Earth
    FANG,      # Physical DPS
    EMBER,     # Fire / AoE
    FROST,     # Ice / Control
    VOID,      # Dark / Debuff
    RADIANT    # Light / Healer
}
```

### Path (Alignment)
```gdscript
enum Path {
    SHADE = -2,      # -100 to -51
    TWILIGHT = -1,   # -50 to -26
    NEUTRAL = 0,     # -25 to +25
    LIGHT = 1,       # +26 to +50
    SERAPH = 2       # +51 to +100
}
```

---

## BUGS FIXED (This Session)

| File | Issue | Fix |
|------|-------|-----|
| `scene_manager.gd:281` | `_build_tree_text()` return discarded | Captured return value |
| `debug.gd:110` | Old VERAState names in help | Updated to INTERFACE/FRACTURE/EMERGENCE/APOTHEOSIS |
| `test_battle.gd` | Used `.skills` instead of `.known_skills` | Changed to `known_skills` |
| `test_battle.gd:198` | Used non-existent `purification_difficulty` | Changed to `corruption_resistance` |
| `character_base.gd` | Missing `brand` property | Added `@export var brand: Enums.Brand` |
| `character_base.gd` | Missing `is_protagonist` property | Added `@export var is_protagonist: bool` |
| `monster.gd` | Duplicate `brand` export | Removed (now inherits from CharacterBase) |
| `test_battle.gd:222` | Used `GameManager.party` instead of `player_party` | Changed to `player_party` |
| `game_manager.gd` | Missing public `update_vera_state()` | Added public method for debug/testing |
| `test_battle.gd` | Used wrong Brand enum names (WRATH/PRIDE/etc) | Changed to correct names (FANG/RADIANT/etc) |

---

## PHASE STATUS

### Completed Phases
- **Phase 0:** Pre-Production (docs, setup)
- **Phase 1:** Foundation (autoloads, scenes)
- **Phase 2:** Core Systems (battle, save/load)
- **Phase 3:** Art Pipeline (Spine, character setup)
- **Phase 4:** Game Systems (VERA, purification, inventory, quests)

### Files Created in Phase 4
- `scripts/data/monster_data.gd`
- `scripts/data/skill_data.gd`
- `scripts/data/item_data.gd`
- `scripts/systems/inventory_system.gd`
- `scripts/systems/quest_system.gd`
- `scripts/overworld/player_controller.gd`
- `scripts/overworld/encounter_manager.gd`
- `scripts/test/test_battle.gd`
- `scenes/test/test_battle.tscn`

---

## IMPORTANT NOTES

### Signal Pattern
All cross-system communication goes through `EventBus`:
```gdscript
EventBus.vera_state_changed.emit(old_state, new_state)
EventBus.vera_glitch_triggered.emit(intensity, duration)
```

### Corruption = Memory Recovery
In the lore, "corruption" is actually VERATH recovering her memories. Higher corruption means she remembers more of her true nature.

### Debug Console Commands
- `vera [0-3]` - Set VERA state
- `god` - Toggle god mode
- `money [amount]` - Add currency
- `setpath [value]` - Set alignment (-100 to 100)

---

## NEXT STEPS (Phase 5+)

1. Content Production (monsters, skills, items)
2. Audio & Polish (FMOD, VFX, optimization)
3. Alpha testing
4. Beta testing
5. Release

---

*This file is automatically maintained by Claude Code sessions.*
