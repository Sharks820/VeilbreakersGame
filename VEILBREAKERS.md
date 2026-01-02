# VEILBREAKERS - Project Memory

> **THE SINGLE SOURCE OF TRUTH** | Version: **v0.61** | Last updated: 2026-01-02

---

## Project Overview

| Field | Value |
|-------|-------|
| Engine | Godot 4.5.1 |
| Genre | AAA 2D Turn-Based RPG |
| Art Style | Battle Chasers: Nightwar (Joe Madureira) |
| Resolution | 1920x1080 |
| GitHub | Sharks820/VeilbreakersGame |

### Core Systems
- Monster hunting/purification mechanics
- VERA/VERATH demon-in-disguise system
- 4 Path system (IRONBOUND, FANGBORN, VOIDTOUCHED, UNCHAINED)
- 12 Brand system (6 Pure + 6 Hybrid) + PRIMAL tier
- 3-stage evolution (Pure/Hybrid) vs 2-stage (PRIMAL)

---

## Main Menu UI

### Logo
| Property | Value |
|----------|-------|
| Scale | 0.11 |
| Pulse Range | 0.11 - 0.112 |
| Position | (960, 160) |

### Buttons
| Property | Value |
|----------|-------|
| Size | 480x220 |
| Spacing | -200 (HBoxContainer separation) |
| Container Offset | left=-420, top=-320, right=1100, bottom=-100 |
| NewGame/Continue Y Offset | -20 (alignment fix) |
| Position | Right side over lava field, raised to cliff edge |

### Monster Eye Animation (Sprite Sheet)
| Property | Value |
|----------|-------|
| Sprite Sheet | assets/ui/demon_eyes_angular_stretch.png |
| Dimensions | 1536x1792 (6x7 grid) |
| Frame Count | 42 frames |
| Frame Size | 256x256 |
| Position | (480, 400) |
| Scale | 0.5 |
| Frame Rate | 12 FPS |
| Z-Index | 10 |
| Source Video | asset_xfXLxe1WPDrs9pbE4TvEjUPz.mp4 |
| Background | Transparent (white removed via Python PIL) |

---

## Battle System

**Status: 75% complete**

### Architecture
- BattleManager, TurnManager, DamageCalculator
- StatusEffectManager, AIController
- 17 status effects (POISON, BURN, FREEZE, etc.)
- Lock-in turn order system (v2.8)

### Turn Order System (Lock-in)
```
1. PARTY LOCK-IN: All allies select actions (protagonist + AI monsters)
2. PARTY EXECUTION: All queued actions execute in order
3. ENEMY PHASE: Enemies get attack phases = alive party count
4. ROUND END: Return to step 1
```

**Key States:** PARTY_LOCK_IN, PARTY_EXECUTING, ENEMY_EXECUTING

### Damage Formula
```
power * ATK/DEF * level * element * variance * crits
```

### Battle UI (v4.1)
| Element | Size | Details |
|---------|------|---------|
| Party Sidebar | 170px wide | Left side, green HP/MP bars, death state fading |
| Enemy Sidebar | 170px wide | Right side, red HP bars, death state fading |
| Action Bar | 700px centered | Attack, Skills, Purify, Item, Defend, Flee (transparent bg) |
| Combat Log | 300x220 | Bottom-right corner, draggable, skill names shown |
| Player Sprite | 0.16 scale | Protagonist |
| Enemy Sprite | 0.15 scale | Regular monsters |
| Allied Monster | 0.14 scale | Captured monsters |
| Boss Sprite | 0.22 scale | Boss encounters |
| Turn Order | Top bar | Shows character names |

### Recent Fixes (Dec 2025)
- Lock-in turn system: party selects all actions before execution
- Turn order display with actual character portraits + arrows
- Enemy attacks = alive party members count
- Fixed stat modifier cleanup bug in StatusEffectManager
- Created KnockbackAnimator with multiple types (normal, critical, heavy, flinch, shake, death)
- AI healer targeting: +100 threat for healers, +30 for support
- AOE skill evaluation fixed: per-target bonus 15.0, base bonus 10.0
- Hit flash shader on damage with fallback modulate
- Screen shake: 12.0 intensity (crits), 4.0 (big hits)
- Status effect icons above characters with tooltips

---

## Heroes (Path-Based, No Brands)

| Hero | Path | Role | Signature Skills |
|------|------|------|------------------|
| Bastion | IRONBOUND | Tank | shield_bash, taunt, iron_wall, fortress_stance |
| Rend | FANGBORN | DPS | rending_strike, bloodletting, execute, frenzy |
| Marrow | VOIDTOUCHED | Healer | life_tap, siphon_heal, essence_transfer, life_link |
| Mirage | UNCHAINED | Illusionist | minor_illusion, fear_touch, mirror_image, mass_confusion |

### Path-Brand Synergy
| Path | Strong vs Brand | Weak vs Brand | Best Monster Brands |
|------|-----------------|---------------|---------------------|
| IRONBOUND | SAVAGE (1.35x) | VENOM (0.70x) | IRON, BLOODIRON, CORROSIVE |
| FANGBORN | LEECH (1.35x) | IRON (0.70x) | SAVAGE, RAVENOUS, BLOODIRON |
| VOIDTOUCHED | SURGE (1.35x) | DREAD (0.70x) | LEECH, DREAD, NIGHTLEECH |
| UNCHAINED | DREAD (1.35x) | LEECH (0.70x) | SURGE, DREAD, TERRORFLUX |

- Heroes get Paths (not Brands) - synergize with multiple monster brands
- 15 stats per character with growth rates
- Equipment: weapon, armor, 2 accessories

---

## Monster Brand System (v5.0 - LOCKED)

### Brand Tiers

| Tier | Brands | Bonus Power | Max Stages | Max Level |
|------|--------|-------------|------------|-----------|
| **PURE** | SAVAGE, IRON, VENOM, SURGE, DREAD, LEECH | 100% (120% at Evo 3) | 3 | 100 |
| **HYBRID** | BLOODIRON, CORROSIVE, VENOMSTRIKE, TERRORFLUX, NIGHTLEECH, RAVENOUS | 70% Primary + 30% Secondary | 3 | 100 |
| **PRIMAL** | Any 2 brands (assigned at Evo) | 50% Primary + 50% Secondary | 2 | 120 |

### Pure Brand Bonuses (100%)

| Brand | Bonus | Theme |
|-------|-------|-------|
| SAVAGE | +25% ATK | Raw destruction |
| IRON | +30% HP | Unyielding defense |
| VENOM | +20% Crit, +15% Status proc | Precision poison |
| SURGE | +25% SPD | Lightning speed |
| DREAD | +20% Evasion, +15% Fear proc | Terror incarnate |
| LEECH | +20% Lifesteal | Life drain |

### Hybrid Brand Bonuses (70% + 30%)

| Hybrid | Primary | Secondary | Effective Bonus |
|--------|---------|-----------|-----------------|
| BLOODIRON | SAVAGE | IRON | +17.5% ATK, +9% HP |
| CORROSIVE | IRON | VENOM | +21% HP, +6% Crit, +4.5% Status |
| VENOMSTRIKE | VENOM | SURGE | +14% Crit, +10.5% Status, +7.5% SPD |
| TERRORFLUX | SURGE | DREAD | +17.5% SPD, +6% Eva, +4.5% Fear |
| NIGHTLEECH | DREAD | LEECH | +14% Eva, +10.5% Fear, +6% Lifesteal |
| RAVENOUS | LEECH | SAVAGE | +14% Lifesteal, +7.5% ATK |

### Brand Effectiveness Wheel

```
SAVAGE ──► IRON ──► VENOM ──► SURGE ──► DREAD ──► LEECH ──┐
   ▲                                                       │
   └───────────────────────────────────────────────────────┘
```

| Attacker | 1.5x vs | 0.67x vs |
|----------|---------|----------|
| SAVAGE | IRON | LEECH |
| IRON | VENOM | SAVAGE |
| VENOM | SURGE | IRON |
| SURGE | DREAD | VENOM |
| DREAD | LEECH | SURGE |
| LEECH | SAVAGE | DREAD |

**Hybrids:** Use PRIMARY brand for effectiveness calculations

---

## Evolution & Leveling System (v5.0 - LOCKED)

### Pure/Hybrid Monsters (3 Stages)

| Stage | Level Range | XP Multiplier | Stat Growth/Level |
|-------|-------------|---------------|-------------------|
| Birth | 1-25 | 1.0x | Normal |
| Evo 2 | 26-50 | 1.5x (slower) | +15% bonus |
| **Evo 3** | 51-100 | **2.5x (much slower)** | **+30% bonus** |

**Evo 3 Pure Brand Bonus:**
- Brand bonus increases to 120% (was 100%)
- Unlocks ultimate skill
- Visual transformation (aura, size, effects)

### PRIMAL Monsters (2 Stages)

| Stage | Level Range | XP Multiplier | Stat Growth/Level |
|-------|-------------|---------------|-------------------|
| Birth | 1-35 | **0.6x (very fast)** | Normal |
| **Evolved** | 36-109 | **0.8x (fast)** | +10% bonus |
| **Overflow** | 110-120 | 1.0x | **+5% ALL stats/level** |

**PRIMAL Bonuses:**
- Level cap: 120 (vs 100 for Pure/Hybrid)
- No Path weakness (neutral to all paths)
- Both brands count as PRIMARY for skill scaling (50%+50%)
- Overflow stats Lv110-120: +50% all stats total
- Brands assigned at Evolution based on monster behavior

### Endgame Power Comparison (~150 hours)

| Monster Type | Likely Level | Strength |
|--------------|--------------|----------|
| Pure Evo 3 | ~85 | MASSIVE stats, ultimate skills, specialist |
| Hybrid Evo 3 | ~88 | Strong stats, versatile coverage |
| PRIMAL Evolved | ~115 | Highest level, no weakness, flexible |

---

## Capture System (v3.0 - PENDING OVERHAUL)

**4 Capture Methods:**
| Method | Rate | Conditions |
|--------|------|------------|
| ORB | Varies by tier | Primary method |
| PURIFY | 20-80% | Reduces corruption, more effective late battle |
| BARGAIN | 10-20% | RNG-based, no penalty for broken promises |
| FORCE | 60% | Monster < player level AND HP < 45%, applies debuff |

**Orb Tiers:**
| Tier | Rate | Availability |
|------|------|--------------|
| Basic | 5-25% | Shop (100g) |
| Greater | 15-40% | Shop (350g) |
| Master | 50-70% | Shop (800g) + Craftable |
| Legendary | 80% flat | Chest drop (5-10%) + Craftable |

*Note: User overhauling this system soon*

---

## MCP Workflow

### Active Servers (14 total)
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

### Asset Pipeline
1. HuggingFace generates base images
2. Image Process resizes/crops to spec
3. Godot Editor imports to project
4. Screenshots verify in-game appearance

---

## Trello Board

**Board:** VEILBREAKERS GAME DEV
**URL:** https://trello.com/b/6VhzFXH3/veilbreakers

### Lists
| List | ID |
|------|-----|
| BACKLOG | 6950d4eb393f78982014d8e5 |
| SPRINT | 6950d4ec787ad16c300203c9 |
| IN_PROGRESS | 6950d4ecff7a641faf2597c6 |
| TESTING | 6950d4ec9a6a7a3910f3fd16 |
| BUGS | 6950d4ed076082243950cf2e |
| IDEAS | 6950d4edb39f6b5aeed96742 |

### Labels
battle, ui, art, audio, vera, monsters, critical

---

## User Preferences

- Prefers visual verification with screenshots
- Wants auto-commit + push on all commits
- Likes AAA quality animations
- Prefers subtle, fast button animations
- Values pixel-perfect alignment

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

## Version History

| Commit | Description |
|--------|-------------|
| bebbda3 | VEILBREAKERSV2 - Complete system restoration |
| 7c71562 | Add GDAI MCP, minimal-godot MCP, godot-docs MCP |
| e89dfed | Enable Godot VCS integration + Git MCP |
| d67bf4e | Main menu button layout finalized |

---

## Session Log

| Date | Summary |
|------|---------|
| 2025-12-29 | Consolidated memory to single VEILBREAKERS.md file |
| 2025-12-29 | v2.3: Security fix - removed API keys from git history |
| 2025-12-29 | v2.4: Screenshot organization - all screenshots to screenshots/ folder |
| 2025-12-30 | v3.0: New Capture System - 4 methods (ORB, PURIFY, BARGAIN, FORCE), 4 orb tiers, 80%+ corruption baseline |
| 2025-12-31 | v3.7: Monster XP/leveling system, level up notifications, XP distribution to allied monsters |
| 2025-12-31 | v3.8: Battle animation interface in CharacterBase, victory->overworld transition for dev testing |
| 2025-12-31 | v4.0: Battle UI overhaul - party/enemy sidebars with portraits, centered action bar, combat log with scroll |
| 2025-12-31 | v4.1: Sidebar HP/MP bars now update on damage/heal/skill use via metadata references |
| 2025-12-31 | v4.2: Bug fixes - debug code removal, tween memory leaks, BargainUI Color fix, EventBus.skill_used signal |
| 2025-12-31 | v4.3: Critical fixes - DataManager innate_skills, status icon display on panels, CrashHandler init, SaveManager integration |
| 2025-12-31 | v4.5: Target highlighting - RED for enemies, BLUE for allies with glow effects |
| 2026-01-01 | v5.0: **MAJOR** - Brand System v5.0 LOCKED (12 brands, 3 tiers, evolution system) |
| 2026-01-01 | v5.2: Removed deprecated Element system, modernized to Brand-only damage |
| 2026-01-01 | v5.2.4: Fixed game_manager.gd to use new 4-Path system |
| 2026-01-01 | v0.53: Fixed Variant type inference errors in player_character.gd, added AGENTS.md + opencode.json |
| 2026-01-02 | **v0.60: MAJOR** - Agent architecture (6 agents), documentation system, style guide, version format change |
| 2026-01-02 | v0.61: Battle UI polish - VERA tutorial panel repositioned with continue button, combat log skill names + battle header, damage rebalanced (15-35 dmg), larger monster sprites, transparent action bar, sidebar death state handling |

---

## Recent Changes (v0.53-v0.60)

### Removed Systems
- **Element System** - Completely removed (was deprecated)
  - Deleted `Element_DEPRECATED` enum and `Element` alias from enums.gd
  - Removed legacy Path values (SHADE, TWILIGHT, NEUTRAL, LIGHT, SERAPH)
  - Removed `BRAND_BONUSES_DEPRECATED` dictionary from constants.gd
  - Updated damage_calculator.gd for Brand-only effectiveness

### Fixed Files
- `game_manager.gd` - `get_current_path()` renamed to `get_dominant_path()`, uses PathSystem
- `player_character.gd` - Fixed Variant type inference (line 167, 175)
- `damage_calculator.gd` - Rewritten for Brand-only effectiveness
- `character_base.gd` - Removed `elements` property
- `monster.gd`, `monster_data.gd` - Removed element references
- `skill_data.gd` - Removed deprecated `element` export
- `item_data.gd` - Removed `element_affinity` export
- `helpers.gd` - Removed `get_element_color()` function
- `data_manager.gd` - Removed `get_skills_by_element()`
- `status_effect_manager.gd` - Removed element-based immunities

### New Files
- `AGENTS.md` - Instructions for AI coding agents (OpenCode format)
- `opencode.json` - MCP server configuration for OpenCode (15 servers)

---

*Claude Code reads this file at the start of every session per CLAUDE.md protocol.*
