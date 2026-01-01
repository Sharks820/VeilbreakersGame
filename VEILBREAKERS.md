# VEILBREAKERS - Project Memory

> **THE SINGLE SOURCE OF TRUTH** | Version: **v4.6** | Last updated: 2026-01-01

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
- 6 Brand system (SAVAGE, IRON, VENOM, SURGE, DREAD, LEECH)

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

### Battle UI (v4.0)
| Element | Size | Details |
|---------|------|---------|
| Party Sidebar | 170px wide | Left side, green HP/MP bars |
| Enemy Sidebar | 170px wide | Right side, red HP bars |
| Action Bar | 700px centered | Attack, Skills, Purify, Item, Defend, Flee |
| Combat Log | 210x170 | Bottom-right corner |
| Sprite Scale | 0.08 | Uniform for all characters |
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

## Heroes

| Hero | Path | Brand | Role | Signature Skills |
|------|------|-------|------|------------------|
| Bastion | IRONBOUND | IRON | Tank | shield_bash, taunt, iron_wall, fortress_stance |
| Rend | FANGBORN | SAVAGE | DPS | rending_strike, bloodletting, execute, frenzy |
| Marrow | VOIDTOUCHED | LEECH | Healer | life_tap, siphon_heal, essence_transfer, life_link |
| Mirage | UNCHAINED | DREAD | Illusionist | minor_illusion, fear_touch, mirror_image, mass_confusion |

- 4 paths: IRONBOUND, FANGBORN, VOIDTOUCHED, UNCHAINED
- 15 stats per character with growth rates
- Equipment: weapon, armor, 2 accessories

---

## Monsters

| Monster | Brand | Skills |
|---------|-------|--------|
| Mawling | SAVAGE | gnaw, desperate_lunge, devour_scraps |
| Hollow | DREAD | empty_grasp, hollow_wail, mimic_stance |
| Flicker | SURGE | blur_strike, too_fast, quicksilver_blitz |
| The Vessel | LEECH/HEALER | stolen_grace, merciful_light, sanctuary |

### Brand Bonuses
| Brand | Bonus |
|-------|-------|
| SAVAGE | +25% ATK |
| IRON | +30% HP |
| VENOM | - |
| SURGE | - |
| DREAD | - |
| LEECH | - |

### Capture System (v3.0)

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

**Monster Corruption:**
- All monsters start at 80%+ corruption
- Corruption drops slower based on rarity (Common 1.0x → Legendary 0.4x)
- Lower HP = faster corruption drop + higher capture chance
- Bosses (tier 3+, rarity 4+) cannot be captured

**Force Debuff:**
- -15% to one random stat until 15% purification progress

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
| 2026-01-01 | v4.6: Planning Brand overhaul (Option C - remove Elements, Brands become only type system) |

---

## PLANNED: Brand System Overhaul (Option C)

**Goal:** Remove Element enum entirely. Brands become the ONLY type system.

### Brand Effectiveness Matrix (Rock-Paper-Scissors)
```
SAVAGE → IRON → VENOM → SURGE → DREAD → LEECH → SAVAGE
       ↑_______________________________________|
```

| Attacker | Strong vs | Weak vs |
|----------|-----------|---------|
| SAVAGE | IRON | LEECH |
| IRON | VENOM | SAVAGE |
| VENOM | SURGE | IRON |
| SURGE | DREAD | VENOM |
| DREAD | LEECH | SURGE |
| LEECH | SAVAGE | DREAD |

**Damage Multipliers:**
- Strong vs target: 1.5x
- Weak vs target: 0.67x
- Neutral: 1.0x

**Files to Update:**
- enums.gd: Remove Element enum
- constants.gd: Add BRAND_EFFECTIVENESS matrix
- skill_data.gd: Change `element` to `brand_type`
- monster_data.gd: Remove `elements` array, use `brand` only
- damage_calculator.gd: Use brand effectiveness
- All 98 skill JSON files
- All 9 monster JSON files

---

*Claude Code reads this file at the start of every session per CLAUDE.md protocol.*
