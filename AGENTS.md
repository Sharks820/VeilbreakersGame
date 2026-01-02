# VEILBREAKERS - Agent Instructions

> Godot 4.5 | GDScript | Turn-Based Monster-Capturing RPG | **v0.60**

---

## Quick Reference

| Resource | Purpose |
|----------|---------|
| `AGENT_SYSTEMS.md` | Game systems (brands, paths, capture) - **READ ONLY** |
| `docs/STYLE_GUIDE.md` | Art direction, color palette |
| `docs/CURRENT_STATE.md` | What's working now |
| `docs/CHANGELOG.md` | Version history |
| `docs/DECISIONS.md` | Architectural decisions |
| `VEILBREAKERS.md` | UI values, session notes |

---

## Build & Run Commands

```bash
# Godot executable path
GODOT="C:/Users/Conner/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.5.1-stable_win64_console.exe"

# Check for script errors (headless)
"$GODOT" --path . --check-only --headless

# Run the game
"$GODOT" --path .

# Open in editor
"$GODOT" --path . --editor
```

No separate build step - Godot compiles GDScript on load.

---

## Agent Architecture

### Primary Agents (6)

| Agent | Model | Temp | Role |
|-------|-------|------|------|
| **Builder** | Opus 4.5 + Extended Thinking | 0.3 | Autonomous coding, bug fixes, features |
| **Operations** | Opus 4 | 0.3 | Task orchestration, docs, git hygiene |
| **Scenario/Assets** | Opus 4 | 0.8 | Art generation, style consistency |
| **Monster/Lore** | Opus 4 | 0.9 | Story, creatures, quests |
| **Map Creator** | Opus 4 | 0.7 | World design, environments |
| **Code Review** | Opus 4 | 0.2 | Security, anti-cheat, code quality, file protection |

Agent configs: `.opencode/agent/*.md`

### High-Risk Items (MUST ASK USER)
- Change Brand/Path system design
- Modify save file format
- Remove or rename core classes
- Change corruption philosophy
- Major UI flow changes
- Game function/story/big script changes
- Delete ANY file (archive only, never delete)

---

## Version Format

```
v0.XX (+0.01 minor, +0.10 major, v1.00 = release)
```

**Commit often** - every 15 minutes of work or after significant changes.

```bash
git add -A && git commit -m "v0.XX: Brief description"
git push origin master
```

---

## Project Structure

```
scripts/
├── autoload/          # Singletons (ErrorLogger, EventBus, GameManager, etc.)
├── battle/            # Battle system (BattleManager, CaptureSystem, DamageCalculator)
├── characters/        # CharacterBase, Monster, PlayerCharacter
├── data/              # Resource classes (MonsterData, SkillData, ItemData)
├── systems/           # Game systems (VERASystem, PathSystem, InventorySystem)
├── ui/                # UI controllers
├── utils/             # Enums, Constants, Helpers
└── test/              # Test scenes (test_battle.gd)
```

---

## Code Style

### File Structure
```gdscript
class_name ClassName
extends ParentClass
## Brief description of the class.

# =============================================================================
# SIGNALS
# =============================================================================

signal something_happened(param: Type)

# =============================================================================
# CONSTANTS
# =============================================================================

const MY_CONSTANT := 10

# =============================================================================
# EXPORTS
# =============================================================================

@export var my_var: int = 0
@export_group("Group Name")
@export var grouped_var: float = 1.0

# =============================================================================
# STATE
# =============================================================================

var internal_state: Dictionary = {}
```

### Naming Conventions
- **Classes:** PascalCase (`BattleManager`, `CharacterBase`)
- **Functions:** snake_case (`calculate_damage`, `get_stat`)
- **Variables:** snake_case (`current_hp`, `turn_order`)
- **Constants:** SCREAMING_SNAKE_CASE (`MAX_PARTY_SIZE`, `BRAND_STRONG`)
- **Signals:** snake_case past tense (`damage_dealt`, `turn_ended`)
- **Enums:** PascalCase enum, SCREAMING_SNAKE values
- **Private functions:** prefix with `_` (`_on_button_pressed`)

### Type Hints (REQUIRED)
```gdscript
# Always use explicit types - Godot treats Variant inference as warning/error
var value: float = some_dict.get("key", 0.0)  # Correct
var value := some_dict.get("key", 0.0)        # ERROR - infers Variant

# Function signatures
func calculate_damage(attacker: CharacterBase, defender: CharacterBase) -> int:
    
# Arrays with types
var party: Array[CharacterBase] = []
var thresholds: Array[float] = [75.0, 50.0, 25.0, 10.0]
```

### Null Safety
```gdscript
# Always check before accessing
var node := get_node_or_null("/root/GameManager")
if node and node.has_method("some_method"):
    node.some_method()

# Safe dictionary access
var value: float = data.get("key", default_value)
```

### Error Handling
```gdscript
# Use push_warning for recoverable issues
if not is_valid:
    push_warning("Invalid state: %s" % state)
    return default_value

# Use push_error for serious problems
if critical_resource == null:
    push_error("Failed to load critical resource")
    return
```

---

## Key Systems (DO NOT BREAK)

### Autoload Order (project.godot)
1. ErrorLogger
2. EventBus
3. DataManager
4. GameManager
5. SaveManager
6. AudioManager
7. SceneManager
8. SettingsManager
9. VERASystem
10. InventorySystem
11. PathSystem
12. CrashHandler

### Brand System (12 Brands - LOCKED)
**Pure:** SAVAGE, IRON, VENOM, SURGE, DREAD, LEECH
**Hybrid:** BLOODIRON, CORROSIVE, VENOMSTRIKE, TERRORFLUX, NIGHTLEECH, RAVENOUS

Effectiveness wheel: SAVAGE > IRON > VENOM > SURGE > DREAD > LEECH > SAVAGE

### Path System (4 Paths)
IRONBOUND, FANGBORN, VOIDTOUCHED, UNCHAINED, NONE

### Corruption System
- 0-10%: ASCENDED (+25% stats)
- 11-25%: Purified (+10% stats)
- 26-50%: Unstable (normal)
- 51-75%: Corrupted (-10% stats)
- 76-100%: Abyssal (-20% stats)

**Core philosophy:** Lower corruption = STRONGER monster. Goal is ASCENSION.

---

## Common Patterns

### Signals via EventBus
```gdscript
# Emit
EventBus.damage_dealt.emit(source, target, amount, is_critical)

# Connect
EventBus.damage_dealt.connect(_on_damage_dealt)
```

### Using Constants
```gdscript
# Access via class name
var max_hp := Constants.MAX_PARTY_SIZE
var threshold := Constants.CORRUPTION_ASCENDED_MAX

# DON'T use Constants in const declarations (load order issues)
const BAD := [Constants.SOME_VALUE]  # Parse error!
const GOOD: Array[float] = [75.0, 50.0, 25.0]  # Hardcode instead
```

### Using Enums
```gdscript
var state: Enums.BattleState = Enums.BattleState.INITIALIZING
var brand: Enums.Brand = Enums.Brand.SAVAGE
```

---

## MCP Servers (15 Active)

| Server | Purpose |
|--------|---------|
| godot-screenshots | Run game, capture screenshots |
| godot-editor | Scene/node manipulation |
| gdai-mcp | Full editor control |
| minimal-godot | GDScript LSP |
| godot-docs | Official documentation |
| git | Git operations |
| gsap-animation | Animation patterns |
| sequential-thinking | Problem solving |
| memory | Persistent knowledge |
| image-process | Image manipulation |
| lottiefiles | Animation library |
| wolfram | Math calculations |
| figma | UI design |
| trello | Task tracking |
| fal-ai | Image generation |

---

## Art Generation (CRITICAL - READ EVERY SESSION)

### API Configuration
- **Fal.ai:** Configured in `.mcp.json` and `opencode.json` - USE THIS
- **Scenario.gg:** Credentials in `.env` file (read via bash if needed)

### Model Rules (MANDATORY)

| Status | Model | Notes |
|--------|-------|-------|
| **PREFERRED** | Seedrush | Best quality, use for all new art |
| **ALLOWED** | VeilBreakersV1 (`model_fmiEeZzx1zUMf4dhKeo16nqK`) | Fallback option |
| **FORBIDDEN** | ~~Scenario V2 / Dark Fantasy V2~~ | INACCURATE - needs retraining |

### Style Requirements (INCLUDE IN EVERY PROMPT)
```
dark fantasy horror, Battle Chasers art style, Joe Madureira inspired,
painterly texture with visible brushstrokes, rich saturated colors,
dramatic lighting, deep shadows, thick confident linework,
gritty weathered aesthetic, 2D game sprite, transparent background
```

### DO NOT
- Use Scenario V2 trained model (broken)
- Use anime/cel-shaded style
- Use flat colors or comic halftone
- Generate checker pattern backgrounds

### Scenario.gg API (No MCP - Use REST)
```bash
# Credentials stored in: .env.scenario (GITIGNORED)
# Read with: type .env.scenario (Windows) or cat .env.scenario (Unix)
# Endpoint: https://api.cloud.scenario.com/v1/
# Auth: Basic base64(api_key:secret)
#
# To generate auth header:
# powershell -Command "[Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes('API_KEY:SECRET'))"
```

### Output Specs
| Parameter | Value |
|-----------|-------|
| Resolution | 1024-2048px |
| Format | PNG with transparency |
| Save to | `assets/sprites/monsters/` |
| Scale in-game | 0.08 |

---

## Session Protocols

### Memory Protocol
1. **READ** `VEILBREAKERS.md` at session start
2. **ACKNOWLEDGE** current project state
3. **UPDATE** docs when making significant changes

### Auto-Save Protocol (Every 15 Minutes)
1. Increment version in appropriate file
2. `git add -A`
3. `git commit -m "v0.XX: [description]"`
4. `git push origin master`

### Screenshot Protocol
ALL screenshots go to: `screenshots/` folder (not project root, not assets/)

### File Naming Rules
**NEVER create files with Windows reserved names:**
- `NUL`, `CON`, `PRN`, `AUX`, `COM1`-`COM9`, `LPT1`-`LPT9`

---

## Animation Patterns

### Button Hover (Working)
```gdscript
func _on_button_hover(button: BaseButton) -> void:
    create_tween().tween_property(button, "scale", Vector2(1.05, 1.05), 0.15)
    create_tween().tween_property(button, "modulate", Color(1.4, 0.9, 0.9, 1.0), 0.15)

func _on_button_unhover(button: BaseButton) -> void:
    create_tween().tween_property(button, "scale", Vector2(1.0, 1.0), 0.15)
    create_tween().tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
```

### Standard Timings
| Animation | Duration |
|-----------|----------|
| Button hover | 0.15s |
| Button press | 0.1s |
| Scene fade | 0.3s |
| Menu slide | 0.25s |

---

## Lessons Learned

### FAILED (Don't Repeat)
- Lightning effects - background already has them
- Custom eye drawing - artwork has them
- Complex logo animation - caused glitching
- Fake transparency (checker pattern) - use REAL alpha

### WORKS
- TextureButton with texture_disabled
- Simple scale/modulate tweens
- Clean button transparency
- Subtle, fast animations
- GSAP power3.out = Godot EASE_OUT + TRANS_CUBIC
- Sprite sheet animation with hframes/vframes
- Python PIL for removing white backgrounds (threshold >220)
- Force Godot reimport: `godot --headless --path PROJECT --import --quit`

---

## Testing

Run `test_battle.tscn` scene for battle system testing. Debug commands via backtick (`) key.

---

## Known Issues

- Missing font: `res://assets/fonts/main_font.tres` (non-blocking, uses fallback)
- Some `.uid` files untracked (Godot-generated, can ignore)

---

*See `.opencode/agent/` for detailed agent configurations.*
