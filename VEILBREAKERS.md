# VEILBREAKERS - Project Memory

> **THE SINGLE SOURCE OF TRUTH** | Version: **v2.4** | Last updated: 2025-12-29

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
| Sprite Sheet | assets/ui/monster_eye_spritesheet.png |
| Dimensions | 1536x1024 (6x4 grid) |
| Frame Count | 24 frames |
| Frame Size | 256x256 |
| Position | (480, 400) |
| Scale | 0.5 |
| Frame Rate | 12 FPS |
| Z-Index | 10 |
| Source Video | asset_xfXLxe1WPDrs9pbE4TvEjUPz.mp4 |
| Background | Transparent (white removed via Python PIL) |

---

## Battle System

**Status: 60-70% complete**

### Architecture
- BattleManager, TurnManager, DamageCalculator
- StatusEffectManager, AIController
- 17 status effects (POISON, BURN, FREEZE, etc.)
- Speed-based turn order calculation

### Damage Formula
```
power * ATK/DEF * level * element * variance * crits
```

### Recent Fixes (Dec 2025)
- Fixed stat modifier cleanup bug in StatusEffectManager
- Created KnockbackAnimator with multiple types (normal, critical, heavy, flinch, shake, death)
- AI healer targeting: +100 threat for healers, +30 for support
- AOE skill evaluation fixed: per-target bonus 15.0, base bonus 10.0
- Hit flash shader on damage with fallback modulate
- Screen shake: 12.0 intensity (crits), 4.0 (big hits)
- Status effect icons above characters with tooltips

---

## Heroes

| Hero | Path | Role | Signature Skills |
|------|------|------|------------------|
| Bastion | IRON | Tank | shield_bash, taunt, iron_wall, fortress_stance |
| Marrow | - | - | - |
| Mirage | - | - | - |
| Rend | - | - | - |

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

### Purification
- 0-100% scale
- Evolution at 50% and 100%

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

---

*Claude Code reads this file at the start of every session per CLAUDE.md protocol.*
