# VEILBREAKERS - THE ULTIMATE GAME DEV TITAN

## Mission: AAA 2D Turn-Based RPG. NO COMPROMISES. NO RIVALS.

---

# ⚠️ MANDATORY: SESSION PROTOCOLS

## 1. Memory Protocol
**EVERY SESSION MUST:**
1. **READ `VEILBREAKERS.md`** at the start of every conversation
2. **ACKNOWLEDGE** current project state before taking any action
3. **UPDATE `VEILBREAKERS.md`** when making significant changes (new systems, UI values, lessons learned)

> **VEILBREAKERS.md is THE SINGLE SOURCE OF TRUTH for cross-session memory.**
> Do NOT rely on MCP memory server. Do NOT create new memory files.
> All persistent project knowledge lives in VEILBREAKERS.md.

## 2. Auto-Save Protocol (EVERY 15 MINUTES - NO EXCEPTIONS)

⏰ **COMMIT AND PUSH EVERY 15 MINUTES. PERIOD.**

This is NON-NEGOTIABLE. Every 15 minutes of active work:
1. Increment version in VEILBREAKERS.md header (v2.3 → v2.4 → v2.5...)
2. `git add -A`
3. `git commit -m "v2.X: [brief description]"`
4. `git push`

### Version Format
- **Major:** v3.0, v4.0 = Major milestones (new systems, releases)
- **Minor:** v2.1, v2.2, v2.3 = Every single commit increments by 0.1
- **Current version is in VEILBREAKERS.md header** - ALWAYS increment before commit

### Commit Message Rules
- **NO** "Generated with Claude Code" tags
- **NO** "Co-Authored-By: Claude" tags
- **NO** mentions of Claude or AI in commits
- Keep messages clean and professional

**Why:** Unexpected shutdowns happen. Losing work is unacceptable.

**Track time mentally.** After approximately 15 minutes of work, stop and commit.
If unsure, err on the side of committing MORE often, not less.

## 3. Screenshot Protocol (MANDATORY)

**ALL screenshots MUST go to: `screenshots/`**

When capturing screenshots:
```
screenshots/screenshot_[descriptive_name].png
```

**NEVER save screenshots to:**
- Project root ❌
- assets/ folder ❌
- Any other location ❌

This keeps the project clean. Screenshots are debug artifacts, not game assets.

### What to Update in VEILBREAKERS.md:
- UI position/scale values that work
- New systems implemented
- Bug fixes worth remembering
- User preferences discovered
- Lessons learned (failed approaches)
- Version history (important commits)

### What NOT to Put in VEILBREAKERS.md:
- Temporary debugging info
- Session-specific context
- Duplicate info from CLAUDE.md

---

# THE ARSENAL - 15 MCP SERVERS

## GODOT ENGINE CONTROL

### 1. godot-screenshots (THE EYES)
**Run game + capture in-game screenshots for visual verification**
```
- Run/stop Godot projects
- Capture viewport screenshots
- Search scenes and monitor output
- Visual feedback loop - SEE what's happening
```
[Source: fernforestgames/mcp-server-godot](https://github.com/fernforestgames/mcp-server-godot)

### 2. godot-editor (THE HANDS)
**Direct Godot editor manipulation**
```
- Launch editor, run projects
- Create scenes, add nodes
- Load sprites, save scenes
- Get project info and debug output
```
[Source: Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp)

---

## 2D ANIMATION POWERHOUSE

### 3. gsap-animation (THE CHOREOGRAPHER)
**Animation expertise - natural language to code**
```
- 100+ production patterns
- 60fps optimization
- Timeline choreography
- Scroll effects, parallax, reveals
- Transferable to Godot Tween
```
[Source: bruzethegreat/gsap-master-mcp-server](https://github.com/bruzethegreat/gsap-master-mcp-server)

### 4. spine2d-animation (THE RIGGER)
**2D skeletal animation from PSD files**
```
- Bone rigging from PSD layers
- IK constraints
- Natural language: "Make character run scared"
- Animation export for game engines
```
[Source: ampersante/spine2d-animation-mcp](https://github.com/ampersante/spine2d-animation-mcp)

### 5. lottiefiles (ANIMATION LIBRARY)
**Search and retrieve Lottie animations**
```
- Search 500,000+ free animations
- Get animation details and data
- Popular animations discovery
- JSON-based, lightweight
```
[Source: junmer/mcp-server-lottiefiles](https://github.com/junmer/mcp-server-lottiefiles)

---

## AI & REASONING

### 6. sequential-thinking (THE LOGIC)
**Complex problem decomposition**
```
- Break down battle systems
- Architectural decisions
- Multi-step problem solving
- Game balance calculations
```
[Source: @modelcontextprotocol/server-sequential-thinking](https://github.com/modelcontextprotocol/servers)

### 7. memory (THE MEMORY)
**Persistent knowledge graph across sessions**
```
- Remember project decisions
- Track entity relationships
- User preferences
- Cross-session context
```
[Source: @modelcontextprotocol/server-memory](https://github.com/modelcontextprotocol/servers)

---

## ASSET CREATION & PROCESSING

### 8. image-process (THE PROCESSOR)
**Image manipulation without external tools**
```
- Crop, resize, rotate
- Format conversion
- Batch processing
- Sharp library powered
```
[Source: x007xyz/image-process-mcp-server](https://github.com/x007xyz/image-process-mcp-server)

### 9. color-palette (THE ARTIST)
**Generate harmonious color schemes**
```
- Monochrome, analogic, complementary
- Hex, RGB, HSL input
- Game art style consistency
- Battle Chasers palette matching
```
[Source: deepakkumardewani/color-scheme-mcp](https://github.com/deepakkumardewani/color-scheme-mcp)

### 10. huggingface (THE GENERATOR)
**FREE AI image/sprite generation**
```
- Generate sprites from text prompts
- Access to FLUX models
- Free Hugging Face credits
- "pixel art sword" → instant asset
```
[Source: Hugging Face MCP Server](https://huggingface.co/docs/hub/en/hf-mcp-server)

### 11. pixel-mcp (ASEPRITE MASTER)
**40+ tools for pixel art with Aseprite**
```
- Canvas & layer management
- Drawing primitives, flood fill
- 15 dithering patterns
- Spritesheet export (PNG, GIF, JSON)
- Animation frames
```
[Source: willibrandon/pixel-mcp](https://github.com/willibrandon/pixel-mcp)

---

## UI & DESIGN

### 12. figma (UI DESIGN-TO-CODE)
**Convert Figma designs to code**
```
- Design-to-code workflow
- Extract variables, components
- Layout data for UI
- Works with design systems
```
[Source: Figma MCP](https://www.figma.com/blog/introducing-figma-mcp-server/)

---

## PROJECT MANAGEMENT

### 13. trello (TASK TRACKING)
**Manage boards, lists, and cards**
```
- Create/update cards
- Track tasks
- Sprint planning
- AI-assisted project management
```
[Source: delorenj/mcp-server-trello](https://github.com/delorenj/mcp-server-trello)

---

## LOCALIZATION

### 14. i18n (TRANSLATION)
**Internationalization for games**
```
- Manage JSON language files
- Generate translations
- Multi-language support
- Game localization workflow
```
[Source: reinier-millo/i18n-mcp-server](https://github.com/reinier-millo/i18n-mcp-server)

---

## MATH & PHYSICS

### 15. wolfram (CALCULATIONS)
**Wolfram Alpha computational engine**
```
- Complex math formulas
- Physics calculations
- Game balance math
- Scientific queries
```
[Source: cnosuke/mcp-wolfram-alpha](https://github.com/cnosuke/mcp-wolfram-alpha)

---

## ALREADY ACTIVE (Built-in)

### Playwright MCP
**Browser automation for web-based testing**

### Cloudflare Docs MCP
**Cloud infrastructure reference**

---

# TECHNICAL REFERENCE

## Godot Executable
```
C:/Users/Conner/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.5.1-stable_win64_console.exe
```

## Project Structure
```
VeilbreakersGame/
├── assets/
│   ├── sprites/monsters/     # 9 monsters
│   ├── sprites/heroes/       # 4 heroes
│   ├── ui/title/             # Title screen
│   └── ui/buttons/           # Menu buttons
├── data/                     # JSON (99 skills, 33 items)
├── scenes/main/              # Main scenes
├── scripts/
│   ├── autoload/             # Singletons
│   ├── ui/                   # UI controllers
│   └── battle/               # Battle logic
├── .mcp.json                 # MCP config (15 servers)
└── CLAUDE.md                 # This file
```

## Autoload Singletons
| Singleton | Purpose |
|-----------|---------|
| ErrorLogger | Debug logging |
| DataManager | JSON data |
| GameManager | Game state |
| SaveManager | Save/load |
| AudioManager | Sound/music |
| SettingsManager | Settings |
| VeraSystem | VERA AI |
| InventorySystem | Inventory |
| SceneManager | Scenes |

---

# ART STYLE

**Battle Chasers: Nightwar** (Joe Madureira)
- Hand-painted 2D, comic book influence
- Dynamic lighting, dramatic shadows
- Bold outlines, saturated colors
- Heroic proportions

---

# ANIMATION PATTERNS

## Button Hover (Working)
```gdscript
func _on_button_hover(button: BaseButton) -> void:
    create_tween().tween_property(button, "scale", Vector2(1.05, 1.05), 0.15)
    create_tween().tween_property(button, "modulate", Color(1.4, 0.9, 0.9, 1.0), 0.15)

func _on_button_unhover(button: BaseButton) -> void:
    create_tween().tween_property(button, "scale", Vector2(1.0, 1.0), 0.15)
    create_tween().tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
```

## Standard Timings
| Animation | Duration |
|-----------|----------|
| Button hover | 0.15s |
| Button press | 0.1s |
| Scene fade | 0.3s |
| Menu slide | 0.25s |

---

# LESSONS LEARNED

## FAILED (Don't Repeat)
- Lightning effects - background has them
- Custom eye drawing - artwork has them
- Complex logo animation - caused glitching

## WORKS
- TextureButton with texture_disabled
- Simple scale/modulate tweens
- Clean button transparency
- Subtle, fast animations

---

# SETUP

## Increase MCP Token Limit (Windows)
```cmd
set MAX_MCP_OUTPUT_TOKENS=100000
cd C:\Users\Conner\Downloads\VeilbreakersGame
claude
```

## Make Permanent
```cmd
setx MAX_MCP_OUTPUT_TOKENS 100000
```

---

# PHILOSOPHY

1. **AAA or nothing** - No shortcuts
2. **Visual verification** - Use screenshots
3. **Working > Fancy broken** - Simple wins
4. **Don't duplicate** - Check artwork first
5. **User is judge** - They see what matters

---

# MCP SOURCES

All FREE and open-source:
- [PulseMCP Directory (7460+ servers)](https://www.pulsemcp.com/servers)
- [Awesome MCP Servers](https://github.com/punkpeye/awesome-mcp-servers)
- [Official MCP Registry](https://registry.modelcontextprotocol.io)
- [mcpservers.org](https://mcpservers.org/)
