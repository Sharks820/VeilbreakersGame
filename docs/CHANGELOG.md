# VEILBREAKERS - Changelog

> Version Format: v0.XX (+0.01 minor, +0.10 major, v1.00 = release)

---

## [v0.65] - 2026-01-02

### Added
- **Victory Fanfare** - Enhanced victory screen with dramatic animations
  - Screen flash effect on victory
  - Animated "VICTORY!" title with letter-by-letter reveal
  - Title pulse and glow effects
  - Battle stats summary (turns, damage dealt/taken, captures)
  - Staggered reward reveals
- **Defeat Screen Polish** - Enhanced defeat screen
  - Red screen flash effect
  - Animated "DEFEAT" title with shake effect
  - Somber fade-in timing
- **Character Select → Game Flow** - Full integration
  - GameManager stores selected hero
  - PlayerCharacter.initialize_from_hero_data() method
  - Character select transitions to test battle
  - Hero's Path determines starting Brand alignment

### Changed
- PlayerCharacter now initializes from HeroData resource
- GameManager tracks selected_hero_id and player_character

---

## [v0.64] - 2026-01-02

### Added
- **Character Select HUD** - Full hero selection screen
  - 4 heroes displayed: Bastion (Tank), Rend (DPS), Marrow (Healer), Mirage (Illusionist)
  - Left panel: Hero cards with portraits, names, titles, roles
  - Center: Large animated hero sprite with breathing animation
  - Right panel: Path/Brand alignment, description, 8 base stats, combat style, starting skills
  - Path → Brand mapping visualization (IRONBOUND→IRON, FANGBORN→SAVAGE, etc.)
  - Role-colored cards (Tank=blue, DPS=red, Healer=green, Illusionist=purple)
  - Keyboard (up/down/enter/escape) and mouse navigation
  - Animated hero transitions with fade + scale pop
- New files: `scripts/ui/character_select_controller.gd`, `scenes/ui/character_select.tscn`

### Changed
- Main Menu "New Game" now goes to Character Select instead of directly to battle

---

## [v0.63] - 2026-01-02

### Added
- **Capture UI Animations** - Full visual feedback for capture system
  - Corruption bar pulse/glow during capture attempts
  - Floating "-X% CORRUPTION" popup on corruption reduction
  - Semi-transparent overlay during capture phase
  - Success popup with green flash ("CAPTURED!")
  - Failure popup with red flash ("ESCAPED!")
  - Monster panel color flash effects
  - Smooth corruption bar decrease animation
- Connected CaptureSystem signals to BattleUIController

---

## [v0.62] - 2026-01-02

### Changed
- **Monster Sprites Overhaul** - All 19 monster sprites regenerated
  - User-approved horror art with proper transparency
  - All sprites resized to 1024x1024 PNG format
  - More terror/sinister aesthetic (not just zombie style)
  - Backgrounds removed using external tool (not Python PIL)
  - Archived old sprites to assets/sprites/monsters/archive/

### Added
- 10 new monsters with complete art: Bloodshade, Chainbound, Corrodex, Crackling, Ironjaw, Needlefang, Sporecaller, The Broodmother, The Bulwark, Voltgeist

---

## [v0.61] - 2026-01-02

### Fixed
- Background transparency for needlefang and sporecaller sprites
- Brand display in battle UI tooltips and party sidebar

---

## [v0.60] - 2026-01-02 (MAJOR)

### Added
- **Agent Architecture** - 6 primary agents with specialized roles
  - Builder (Opus 4.5 + extended thinking) - Autonomous coding
  - Operations - Task orchestration, documentation management
  - Scenario/Assets - Art generation and style consistency
  - Monster/Lore - Story, creatures, quests
  - Map Creator - World design, environments
  - Code Review - Quality analysis, optimization
- **Documentation System**
  - `docs/STYLE_GUIDE.md` - Comprehensive art bible
  - `docs/CHANGELOG.md` - Version history (this file)
  - `docs/CURRENT_STATE.md` - Current project state
  - `docs/ROADMAP.md` - Planned features
  - `docs/DECISIONS.md` - Architectural decisions log
- **Version Format Overhaul** - Changed from v5.X to v0.XX format
- **Scenario.gg Integration** - Full API access with trained models

### Changed
- Updated `AGENTS.md` with agent summaries and merged CLAUDE.md content
- Archived `CLAUDE.md` to `archive/CLAUDE.md`

---

## [v0.56] - 2026-01-01

### Fixed
- Combat log doubling - removed duplicate log_action() call
- Enemy sidebar HP labels - added missing HPLabel nodes
- Blue ally highlighting - fixed panel meta key checks
- Defend ally mechanic - full UI + backend implementation
- Hit rate investigation - confirmed formula is correct (~90%)

---

## [v0.55] - 2026-01-01

### Fixed
- Variant type inference errors in player_character.gd

---

## [v0.54] - 2026-01-01

### Fixed
- game_manager.gd to use new 4-Path system

---

## [v0.53] - 2026-01-01

### Added
- AGENTS.md - Instructions for AI coding agents
- opencode.json - MCP server configuration (15 servers)

---

## [v0.52] - 2026-01-01

### Removed
- **Element System** - Completely deprecated
  - Removed Element_DEPRECATED enum
  - Removed legacy Path values (SHADE, TWILIGHT, etc.)
  - Removed BRAND_BONUSES_DEPRECATED dictionary
  - Updated damage_calculator.gd for Brand-only effectiveness

### Changed
- Modernized all files to Brand-only damage system

---

## [v0.50] - 2026-01-01 (MAJOR)

### Added
- **Brand System v5.0** - LOCKED
  - 12 brands (6 Pure + 6 Hybrid)
  - 3 tiers (Pure, Hybrid, Primal)
  - Brand effectiveness wheel
  - Evolution system (3 stages Pure/Hybrid, 2 stages Primal)
- AGENT_SYSTEMS.md - Complete game systems documentation
- docs/BRAND_REFERENCE.md - Quick brand reference
- docs/EVOLUTION_REFERENCE.md - Evolution system reference

---

## [v0.45] - 2025-12-31

### Added
- Target highlighting - RED for enemies, BLUE for allies with glow effects

---

## [v0.43] - 2025-12-31

### Fixed
- DataManager innate_skills loading
- Status icon display on panels
- CrashHandler initialization
- SaveManager integration

---

## [v0.42] - 2025-12-31

### Fixed
- Debug code removal
- Tween memory leaks
- BargainUI Color fix
- Added EventBus.skill_used signal

---

## [v0.41] - 2025-12-31

### Fixed
- Sidebar HP/MP bars now update on damage/heal/skill use

---

## [v0.40] - 2025-12-31 (MAJOR)

### Added
- **Battle UI Overhaul**
  - Party sidebar (170px, left side, green bars)
  - Enemy sidebar (170px, right side, red bars)
  - Centered action bar (700px)
  - Combat log with scroll (210x170, bottom-right)
  - Uniform sprite scale (0.08)
  - Turn order display (top bar)

---

## [v0.38] - 2025-12-31

### Added
- Battle animation interface in CharacterBase
- Victory -> overworld transition for dev testing

---

## [v0.37] - 2025-12-31

### Added
- Monster XP/leveling system
- Level up notifications
- XP distribution to allied monsters

---

## [v0.30] - 2025-12-30 (MAJOR)

### Added
- **New Capture System**
  - 4 methods: ORB, PURIFY, BARGAIN, FORCE
  - 4 orb tiers: Basic, Greater, Master, Legendary
  - 80%+ corruption baseline

---

## [v0.24] - 2025-12-29

### Changed
- Screenshot organization - all screenshots to screenshots/ folder

---

## [v0.23] - 2025-12-29

### Security
- Removed API keys from git history

---

## [v0.22] - 2025-12-29

### Changed
- Consolidated memory to single VEILBREAKERS.md file

---

## Earlier Versions

| Version | Date | Summary |
|---------|------|---------|
| v0.20 | 2025-12-28 | Lock-in turn order system |
| v0.15 | 2025-12-27 | Main menu button layout finalized |
| v0.10 | 2025-12-26 | Initial project setup |

---

*Maintained by Operations Agent*
