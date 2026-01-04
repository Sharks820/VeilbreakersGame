# VEILBREAKERS - Architectural Decisions Log

> Record of significant design decisions and their reasoning.

---

## Decision Format

```
## [DECISION-XXX] Title
**Date:** YYYY-MM-DD
**Status:** Accepted / Superseded / Deprecated
**Context:** Why this decision was needed
**Decision:** What was decided
**Consequences:** Impact of this decision
```

---

## [DECISION-001] Brand System Design (LOCKED)

**Date:** 2026-01-01
**Status:** ACCEPTED - LOCKED

**Context:**
Needed a type system for monsters that provides strategic depth without overwhelming complexity. Traditional elemental systems (fire/water/etc.) felt generic.

**Decision:**
- 12 Brands: 6 Pure + 6 Hybrid
- Effectiveness wheel: SAVAGE > IRON > VENOM > SURGE > DREAD > LEECH > SAVAGE
- 3 Tiers: Pure (specialist), Hybrid (versatile), Primal (endgame)
- Lower corruption = stronger (ASCENSION goal)

**Consequences:**
- All combat balance derived from this system
- Monster design tied to brand identity
- Equipment can be brand-locked
- System is LOCKED - no changes without user approval

---

## [DECISION-002] Path System for Heroes

**Date:** 2026-01-01
**Status:** ACCEPTED

**Context:**
Heroes needed differentiation from monsters. Using same Brand system would be confusing.

**Decision:**
- 4 Paths: IRONBOUND, FANGBORN, VOIDTOUCHED, UNCHAINED
- Paths synergize with multiple monster brands
- Each hero has one Path
- Paths have brand strengths/weaknesses (1.35x/0.70x)

**Consequences:**
- Heroes feel distinct from monsters
- Party composition matters
- Each hero has clear role identity

---

## [DECISION-003] Corruption Philosophy

**Date:** 2026-01-01
**Status:** ACCEPTED - CORE DESIGN

**Context:**
Needed to differentiate from Pokemon's "catch-em-all" approach. Theme is about redemption vs exploitation.

**Decision:**
- Lower corruption = STRONGER monster
- Goal is ASCENSION (0-10% corruption)
- DOMINATE method works but costs power
- PURIFY method rewards patience

**Consequences:**
- Unique gameplay loop
- Moral choice in capture method
- VERA's manipulation becomes ironic (she IS corruption)
- Cannot be changed without fundamentally altering game

---

## [DECISION-004] Version Format Change

**Date:** 2026-01-02
**Status:** ACCEPTED

**Context:**
Old format (v5.3) suggested game was nearly complete. Needed clearer pre-release versioning.

**Decision:**
- v0.XX format until release
- +0.01 for minor changes
- +0.10 for major updates
- v1.00 = release candidate

**Consequences:**
- Clearer development stage indication
- v5.3 became v0.53
- Major agent update = v0.60

---

## [DECISION-005] Agent Architecture

**Date:** 2026-01-02
**Status:** ACCEPTED

**Context:**
Complex game development requires specialized AI agents for different tasks.

**Decision:**
- 6 Primary agents with distinct roles
- Builder uses Opus 4.5 with extended thinking (best reasoning)
- Creative agents use higher temperature
- Operations manages coordination
- Agents can invoke subagents via @mention

**Consequences:**
- Parallel development possible
- Specialized expertise per domain
- Coordination overhead required
- Memory sync needed between agents

---

## [DECISION-006] Dark Fantasy Horror Art Style

**Date:** 2026-01-02
**Status:** ACCEPTED

**Context:**
Initially inspired by Battle Chasers comic style, but AI generation produced different results. Needed to define actual style.

**Decision:**
- Dark Fantasy Horror (not comic book)
- AI-generated digital painting
- Glowing elements, deep shadows
- Ominous, unsettling mood
- NOT: comic outlines, pixel art, bright fantasy

**Consequences:**
- All assets must match this style
- Scenario.gg models trained on this aesthetic
- Style guide created for consistency
- Battle Chasers refs are inspiration only, not target

---

## [DECISION-007] Operations Agent Cannot Delete

**Date:** 2026-01-02
**Status:** ACCEPTED

**Context:**
User concerned about unintended file deletion during autonomous operation.

**Decision:**
- Operations can reorganize, move, rename files
- Operations can archive files to `archive/` folder
- Operations can NEVER delete any file
- Archive acts as soft-delete

**Consequences:**
- archive/ folder may grow over time
- No accidental permanent data loss
- User retains final delete authority

---

## [DECISION-008] High-Risk Items Require User Approval

**Date:** 2026-01-02
**Status:** ACCEPTED

**Context:**
Autonomous agents could make breaking changes without user knowledge.

**Decision:**
High-risk items that MUST ask user:
- Change Brand/Path system design
- Modify save file format
- Remove or rename core classes
- Change corruption philosophy
- Major UI flow changes
- Game function/story/big script changes
- Delete ANY file

**Consequences:**
- Agents work autonomously on most tasks
- Critical changes have human oversight
- User trusts agents for routine work

---

## [DECISION-009] Single Source of Truth Files

**Date:** 2026-01-02
**Status:** ACCEPTED

**Context:**
Multiple documentation files caused confusion about which to update.

**Decision:**
- `AGENT_SYSTEMS.md` - Game systems (READ ONLY)
- `docs/STYLE_GUIDE.md` - Art direction
- `docs/CURRENT_STATE.md` - What's working now
- `docs/CHANGELOG.md` - Version history
- `VEILBREAKERS.md` - UI values, session notes

**Consequences:**
- Clear ownership per file
- Agents know where to read/write
- Reduces duplication

---

## [DECISION-010] Scenario.gg Direct API

**Date:** 2026-01-02
**Status:** ACCEPTED

**Context:**
No official Scenario.gg MCP server exists. Needed integration path.

**Decision:**
- Use direct API calls via curl/webfetch
- User-trained models free to use
- Public Scenario models require approval
- Credentials stored in AGENT_SYSTEMS.md

**Consequences:**
- Full Scenario.gg access without MCP
- Can use VeilBreakersV1 trained model
- V2 model (Dark Fantasy Creatures) training in progress

---

## [DECISION-011] Centralized Color and Style Management

**Date:** 2026-01-04
**Status:** ACCEPTED

**Context:**
Code audit revealed significant technical debt in UI styling:
- 816 hardcoded `Color()` calls scattered across codebase
- 98 `StyleBoxFlat.new()` calls creating duplicate styles
- Inconsistent colors (same color defined slightly differently in different files)
- Memory churn from repeated style allocations every frame
- Maintenance nightmare when attempting to change UI colors globally

**Decision:**
Implement a three-tier architecture for centralized style management:

### 1. Constants.gd - All Color Constants
All colors defined as `COLOR_*` constants:
```gdscript
# Brand colors
const COLOR_BRAND_SAVAGE := Color(0.9, 0.2, 0.2, 1.0)
const COLOR_BRAND_IRON := Color(0.6, 0.6, 0.7, 1.0)

# UI colors
const COLOR_HP_FILL := Color(0.2, 0.8, 0.2, 1.0)
const COLOR_MP_FILL := Color(0.2, 0.4, 0.9, 1.0)
const COLOR_PANEL_DARK := Color(0.05, 0.05, 0.08, 0.95)

# Helper functions
static func get_brand_color(brand: Enums.Brand) -> Color
static func get_hp_color(percent: float) -> Color
static func get_rarity_color(rarity: Enums.Rarity) -> Color
```

### 2. StyleManager (Autoload) - Style Factory
Factory singleton for all StyleBox instances:
```gdscript
# Semantic methods for common styles
func panel_dark() -> StyleBoxFlat
func panel_light() -> StyleBoxFlat
func hp_fill() -> StyleBoxFlat
func mp_fill() -> StyleBoxFlat
func button_normal() -> StyleBoxFlat
func button_hover() -> StyleBoxFlat
func button_pressed() -> StyleBoxFlat
func button_disabled() -> StyleBoxFlat

# Brand-specific styles
func brand_panel(brand: Enums.Brand) -> StyleBoxFlat
func brand_button(brand: Enums.Brand, state: String) -> StyleBoxFlat
```

### 3. UIStyleCache (Autoload) - Low-Level Caching
Caches StyleBoxFlat instances by property hash to prevent duplicate allocations:
```gdscript
func get_or_create_flat(bg_color: Color, border_color: Color, 
                        corner_radius: int, border_width: int) -> StyleBoxFlat
```

### Usage Rules (ENFORCED)
1. **NEVER** use `Color(r, g, b, a)` directly in scripts - use `Constants.COLOR_*`
2. **NEVER** use `StyleBoxFlat.new()` directly - use `StyleManager.*` methods
3. Run `python tools/validate_style_constants.py` before commits to check violations
4. Exceptions allowed ONLY in:
   - `constants.gd` (defining the constants)
   - `style_manager.gd` (creating cached styles)
   - `ui_style_cache.gd` (cache implementation)
   - Test files in `tests/` directory

### Migration Path
- Phase 1: Add all constants and StyleManager (DONE)
- Phase 2: Update UI scripts to use new system (IN PROGRESS)
- Phase 3: Run validation, fix remaining violations
- Phase 4: Add pre-commit hook for validation

**Consequences:**
- Reduces ~98 StyleBoxFlat allocations to ~20 cached instances
- Single place to update any color in the game
- Consistent look across all UI elements
- Improved performance from reduced allocations
- Easier theming support in future (dark mode, colorblind modes)
- New code pattern to learn for all UI work
- Validation script catches violations early

**Files Changed:**
- `scripts/utils/constants.gd` - Added 100+ color constants and helper functions
- `scripts/autoload/style_manager.gd` - NEW: Style factory singleton
- `scripts/autoload/ui_style_cache.gd` - Updated to use Constants colors
- `tools/validate_style_constants.py` - NEW: Validation script for CI/pre-commit
- `project.godot` - Added StyleManager to autoload order

---

*Add new decisions at the bottom with incrementing IDs.*
