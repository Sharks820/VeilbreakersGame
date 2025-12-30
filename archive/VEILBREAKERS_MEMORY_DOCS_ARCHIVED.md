# VEILBREAKERS - Claude Code Memory File
## Last Updated: December 28, 2025 (Session 9)

---

## CHANGELOG

### December 28, 2025 - Session 9 (Battle System Implementation)

**Purpose:** Created FULLY FUNCTIONAL battle system with working heroes, monsters, and enemy AI

**MAJOR DELIVERABLES:**

#### 1. Battle System Core Fixes
**Files Modified:**
- `scripts/test/test_battle.gd` - Complete overhaul of battle initialization
- `scripts/battle/ai_controller.gd` - Added skill path fallbacks
- `scripts/ui/battle_ui_controller.gd` - Fixed party/enemy membership detection
- `scenes/test/test_battle.tscn` - Now instances proper battle_ui.tscn

**Key Changes:**
- Added `_setup_battle_manager()` to create and connect BattleManager
- Fixed `_start_battle()` to actually call `battle_manager.start_battle(party, enemies)`
- Added `_load_hero()` function to load HeroData resources
- Added `HERO_IDS` constant: ["rend", "bastion", "marrow", "mirage"]
- Added `MONSTER_TEMPLATES` with 5 monsters (mawling, hollow, gluttony_polyp, ravener, skitter_teeth)

#### 2. Skill ID Fixes
**Old (Wrong) → New (Correct):**
- `basic_attack` → `attack_basic`
- `fury_strike` → `rending_strike`
- `stone_wall` → `iron_wall`
- `terrify` → `fear_touch`
- `drain_essence` → `life_tap`

#### 3. AI Skill Path Loading
**File:** `scripts/battle/ai_controller.gd`
Added `_load_skill_data()` function with fallback paths:
- `res://data/skills/%s.tres`
- `res://data/skills/monsters/%s.tres`
- `res://data/skills/heroes/%s.tres`
- `res://data/skills/common/%s.tres`

#### 4. Hero Integration
**4 Heroes Now Working:**
| Hero | Role | Brand | Key Skills |
|------|------|-------|------------|
| Rend | DPS | SAVAGE | rending_strike, frenzy |
| Bastion | Tank | IRON | shield_bash, taunt, iron_wall |
| Marrow | Healer | LEECH | life_tap, siphon_heal |
| Mirage | Illusionist | DREAD | fear_touch, nightmare |

#### 5. Monster Templates
**5 Test Monsters:**
| Monster | Brand | Skills |
|---------|-------|--------|
| mawling | SAVAGE | gnaw, desperate_lunge |
| hollow | DREAD | empty_grasp, hollow_wail |
| gluttony_polyp | LEECH | acid_spit, absorb |
| ravener | SAVAGE | rend, pounce |
| skitter_teeth | VENOM | razor_swarm, frenzy_bite |

#### 6. Battle UI Status
**Working Features:**
- Turn Order display ("Round 1")
- Party member panels (Name, HP bar, MP bar)
- Action menu (Attack, Skills, Purify, Item, Defend, Flee)
- Debug controls (F5-F9)

**VALIDATION:**
- Battle starts when loading test_battle scene ✓
- Party displays show Rend, Bastion, Marrow ✓
- Action menu visible and responsive ✓
- BattleManager properly instantiated ✓

---

### December 27, 2025 - Session 8 (UI Assets Integration + Title Screen)

**Purpose:** Integrated all UI sprite sheets from Scenario.gg, AI-upscaled icons with Real-ESRGAN, added title screen art

**MAJOR DELIVERABLES:**

#### 1. UI Asset Integration (145 Icons)
**Location:** `assets/ui/`

**Folder Structure:**
```
assets/ui/
├── icons/
│   ├── actions/    (8 icons) - attack, defend, skill, item, flee, wait, analyze, special
│   ├── buffs/      (16 icons) - attack_up, defense_up, speed_up, etc.
│   ├── debuffs/    (16 icons) - poison, burn, freeze, stun, etc.
│   ├── items/      (8 icons) - consumable, weapon, armor, accessory, etc.
│   ├── quests/     (8 icons) - main_quest, side_quest, bounty, etc.
│   ├── rarity/     (8 icons) - common, uncommon, rare, epic, legendary, mythic, unique, cursed
│   ├── hud/        (8 icons) - health, mana, stamina, experience, gold, time, compass, menu
│   ├── minimap/    (16 icons) - player, enemy, npc, shop, inn, quest_giver, etc.
│   └── npcs/       (12 icons) - merchant, blacksmith, innkeeper, quest_giver, etc.
├── frames/         (4 frames) - panel_frame, dialogue_frame, quest_tracker_panel, loot_popup_frame
├── sheets/         (9 sprite sheets) - source sheets from Scenario.gg
├── bars/           (1 file) - hp_mp_bars.png
└── title/          (2 files) - title_background.png, title_logo.png
```

#### 2. AI Upscaling with Real-ESRGAN
- Downloaded Real-ESRGAN ncnn-vulkan portable
- Re-extracted all 100 icons from sprite sheets
- Applied 4x AI upscaling to each icon
- Downscaled to 128x128 with LANCZOS for crisp in-game display
- **Result:** Sharp, clean icons instead of blurry downscaled art

#### 3. Title Screen Art
**Files Added:**
- `assets/ui/title/title_background.png` - Dramatic Veil scene (vertical composition, red lightning storm)
- `assets/ui/title/title_logo.png` - "VEILBREAKERS" shattered metallic logo

**Main Menu Updated:** `scenes/main/main_menu.tscn`
- Background image (title_background.png)
- Logo (title_logo.png) instead of text title
- Dark overlay for readability
- Styled buttons with larger font
- Subtitle: "The Veil is Cracking..."

#### 4. Battle UI Updated
**File:** `scenes/test/test_battle.tscn`
- Action buttons now display icons (Attack, Skills, Items, Purify, Defend, Flee)
- Icons displayed at 64x64 in 140x110 buttons
- Proper icon loading with TextureRect nodes

#### 5. Python Tools Created
**Location:** `tools/`

| Script | Purpose |
|--------|---------|
| `slice_sprites.py` | Extracts icons from sprite sheets (4x4, 4x3, 4x2 grids) |
| `update_battle_ui.py` | Updates battle_ui.tscn with icon references |
| `update_dialogue_ui.py` | Updates dialogue_box.tscn with new frame |
| `update_test_battle.py` | Updates test_battle.tscn with action icons |

#### 6. Sprite Sheet Configurations

| Sheet | Grid | Icons |
|-------|------|-------|
| actions_sheet.png | 4x2 | attack, defend, skill, item, flee, wait, analyze, special |
| buffs_sheet.png | 4x4 | 16 buff icons |
| debuffs_sheet.png | 4x4 | 16 debuff icons |
| item_categories_sheet.png | 4x2 | 8 item type icons |
| quest_icons_sheet.png | 4x2 | 8 quest type icons |
| rarity_frames_sheet.png | 4x2 | 8 rarity borders |
| hud_icons_sheet.png | 4x2 | 8 HUD element icons |
| minimap_icons_sheet.png | 4x4 | 16 minimap markers |
| npc_icons_sheet.png | 4x3 | 12 NPC type icons |

**VALIDATION RESULTS:**
- 145 icon PNG files (AI-upscaled to 128x128)
- 4 UI frame PNG files
- 2 title art PNG files
- 9 sprite sheet source files
- All scene references valid
- Godot imports successful

---

### December 26, 2025 - Session 7 (Monster Skills + DataManager)

**Purpose:** Created all monster skill .tres files and implemented DataManager autoload for centralized resource loading

**MAJOR DELIVERABLES:**

#### 1. Monster Skill Resource Files (55 total)
**Location:** `data/skills/monsters/`

| Monster | Skills Created | Key Abilities |
|---------|----------------|---------------|
| Mawling (5) | gnaw, desperate_lunge, devour_scraps, loyal_bite, pack_feast | Bleed DoT, pack synergy |
| Hollow (5) | empty_grasp, hollow_wail, mimic_stance, void_touch, defined_purpose | Lifesteal, Silence, defense copying |
| Gluttony Polyp (5) | acid_spit, absorb, bloat, regurgitate, toxic_cloud | Burn, buff steal, poison |
| Skitter-Teeth (5) | razor_swarm, burrow, leg_trap, frenzy_bite, scatter | Multi-hit, immobilize, self-damage burst |
| Ravener (6) | rend, terror_roar, blood_scent, pounce, eviscerate, predators_mark | Bleed, fear, execute, prey marking |
| The Vessel (6) | soul_siphon, vessels_burden, host_body, expel_soul, bind_spirit, empty_husk | MP drain, redirect damage, auto-revive |
| Flicker (6) | phase_shift, reality_tear, blink_strike, distortion_field, unstable_form, warp | Intangibility, ignore defense, teleport |
| The Weeping (6) | tears_of_sorrow, mourning_cry, sorrowful_embrace, drown_in_despair, reflected_pain, endless_grief | Sorrow debuff, lifesteal, damage reflect |
| The Congregation (11) | mass_of_flesh, collective_scream, assimilate, multiply, unified_will, overwhelming_presence, consume_the_weak, regenerating_mass, many_eyes, schism, final_form | Boss mechanics, summon minions, enrage |

#### 2. DataManager Autoload (NEW)
**Location:** `scripts/autoload/data_manager.gd`

Features implemented:
- Centralized loading of all .tres resources on game start
- Cached dictionaries for monsters, heroes, skills, items
- Public getters: `get_monster()`, `get_hero()`, `get_skill()`, `get_item()`
- Collection getters: `get_all_monsters()`, `get_monsters_by_tier()`, `get_skills_for_monster()`
- Utility functions: `get_random_monster()`, `get_random_item()`, `reload_all()`
- Signal: `data_loaded` fires when all resources cached

**Registered in project.godot as autoload** (loads after EventBus, before GameManager)

#### 3. File Structure Updates

```
VeilbreakersGame/
├── data/
│   ├── heroes/          (4 .tres files)
│   ├── monsters/        (9 .tres files)
│   ├── skills/
│   │   ├── heroes/      (30 .tres files)
│   │   └── monsters/    (55 .tres files - NEW)
│   └── items/
│       ├── consumables/ (19 .tres files)
│       └── equipment/   (14 .tres files)
└── scripts/
    └── autoload/
        └── data_manager.gd (NEW)
```

**VERIFIED:**
- ✅ 131 .tres resource files (30 hero skills + 55 monster skills + 9 monsters + 4 heroes + 33 items)
- ✅ 39 .gd script files (+1 DataManager)
- ✅ DataManager registered in project.godot autoloads

---

### December 26, 2025 - Session 6 (Data Resources + Art Assets + Path System Implementation)

**Purpose:** Created all game data resource files, implemented path_system.gd, generated art assets with Scenario.gg

**MAJOR DELIVERABLES:**

#### 1. Monster Resource Files (9 total)
**Location:** `data/monsters/`

| File | Monster | Category | Brand | Role |
|------|---------|----------|-------|------|
| `mawling.tres` | Mawling | BASIC | SAVAGE | DPS |
| `hollow.tres` | Hollow | BASIC | DREAD | Support |
| `gluttony_polyp.tres` | Gluttony Polyp | BASIC | LEECH | Healer |
| `skitter_teeth.tres` | Skitter-Teeth | BASIC | IRON | Tank |
| `ravener.tres` | Ravener | PATH | SAVAGE | DPS (FANGBORN) |
| `the_vessel.tres` | The Vessel | PATH | LEECH | Healer (VOIDTOUCHED) |
| `flicker.tres` | Flicker | PATH | SURGE | Speed (FANGBORN/UNCHAINED) |
| `the_weeping.tres` | The Weeping | PATH | DREAD | Debuffer (IRONBOUND/VOIDTOUCHED) |
| `the_congregation.tres` | The Congregation | BOSS | N/A | Tutorial Boss |

#### 2. Hero Resource Files (4 total)
**Location:** `data/heroes/`

| File | Hero | Brand | Path | Role |
|------|------|-------|------|------|
| `rend.tres` | Rend | SAVAGE | FANGBORN | Physical DPS |
| `bastion.tres` | Bastion | IRON | IRONBOUND | Tank |
| `marrow.tres` | Marrow | LEECH | VOIDTOUCHED | Healer |
| `mirage.tres` | Mirage | DREAD | VOIDTOUCHED | Illusionist |

#### 3. Skill Resource Files (30 total)
**Location:** `data/skills/`

**Common Skills:**
- `attack_basic.tres`, `defend.tres`

**Bastion Skills (Tank):**
- `shield_bash.tres`, `taunt.tres`, `iron_wall.tres`, `cover_ally.tres`
- `fortress_stance.tres`, `unbreakable.tres`, `last_bastion.tres` (Ultimate)

**Rend Skills (DPS):**
- `rending_strike.tres`, `bloodletting.tres`, `predator_leap.tres`, `execute.tres`
- `frenzy.tres`, `apex_fury.tres`, `avatar_of_the_hunt.tres` (Ultimate)

**Marrow Skills (Healer):**
- `life_tap.tres`, `siphon_heal.tres`, `essence_transfer.tres`, `pain_split.tres`
- `life_link.tres`, `mass_drain.tres`, `vessel_of_souls.tres` (Ultimate)

**Mirage Skills (Illusionist):**
- `minor_illusion.tres`, `fear_touch.tres`, `mirror_image.tres`, `mass_confusion.tres`
- `nightmare.tres`, `reality_shatter.tres`, `true_terror.tres` (Ultimate)

#### 4. PathSystem Autoload (NEW)
**Location:** `scripts/autoload/path_system.gd`

Features implemented:
- Four independent path affinities (IRONBOUND, FANGBORN, VOIDTOUCHED, UNCHAINED)
- 30% unlock threshold for skill trees
- Skill tree states (LOCKED, UNLOCKED, DARK)
- Skill point allocation system
- Monster catching by brand/path alignment
- Path-brand alignment matrix
- Serialization for save/load
- Connected to EventBus.level_up signal

**Registered in project.godot as autoload**

#### 5. Item Resource Files (33 total)
**Location:** `data/items/`

**Consumables (19):** `data/items/consumables/`
| Category | Items |
|----------|-------|
| Healing | `potion_minor`, `potion_standard`, `potion_greater` |
| MP Restore | `ether`, `hi_ether` |
| Full Restore | `elixir` |
| Revive | `phoenix_down` |
| Status Cure | `antidote`, `smelling_salts`, `remedy` |
| Buffs | `attack_tonic`, `defense_tonic`, `speed_tonic` |
| Capture | `capture_orb`, `greater_capture_orb` |
| Special | `purification_crystal`, `skill_reset_token`, `veil_fragment`, `light_essence` |

**Equipment (14):** `data/items/equipment/`
| Hero | Weapon | Armor |
|------|--------|-------|
| Rend | `bone_axes` | `hunter_leathers` |
| Bastion | `tower_shield` | `fortress_plate` |
| Marrow | `heart_staff` | `drainer_robes` |
| Mirage | `eye_staff` | `shifting_robes` |

**Shop Items:**
- Weapons: `iron_sword`, `mage_staff`
- Armor: `leather_armor`
- Accessories: `iron_ring`, `swift_boots`, `lucky_charm`

#### 6. Art Assets Generated (Scenario.gg with VeilbreakersV1 LoRA)
**Location:** `assets/characters/`

**Heroes:** `assets/characters/heroes/`
- `rend.png`
- `bastion.png`
- `marrow.png`
- `mirage.png`

**VERA States:** `assets/characters/vera/`
- `vera_interface.png` (0-24% corruption)
- `vera_fracture.png` (25-59% corruption)
- `vera_emergence.png` (60-89% corruption)
- `vera_apotheosis.png` (90-100% corruption)

**Monsters:** `assets/characters/monsters/` (awaiting generation)

#### 6. Bugs Fixed

| Issue | Location | Fix |
|-------|----------|-----|
| Signal name mismatch | `path_system.gd:80` | Changed `player_leveled_up` to `level_up` |
| Signal signature mismatch | `path_system.gd:276` | Updated callback params to match EventBus signal |
| Invalid status effect | `last_bastion.tres:30` | Changed effect 21 to 10 (REGEN) + 14 (DEFENSE_UP) |
| Invalid status effect | `vessel_of_souls.tres:30` | Changed effect 21 to 10 (REGEN) |
| PathSystem not registered | `project.godot` | Added PathSystem to autoload section |

#### 8. File Structure Updates

```
VeilbreakersGame/
├── data/
│   ├── heroes/          (4 .tres files)
│   ├── monsters/        (9 .tres files)
│   ├── skills/          (30 .tres files)
│   └── items/
│       ├── consumables/ (19 .tres files - NEW)
│       └── equipment/   (14 .tres files - NEW)
├── assets/characters/
│   ├── heroes/          (4 .png files)
│   ├── vera/            (4 .png files)
│   └── monsters/        (awaiting art)
└── scripts/
    ├── autoload/
    │   └── path_system.gd
    └── data/
        └── hero_data.gd
```

**VERIFIED - Full Scan Results:**
- ✅ 76 .tres resource files (30 skills + 9 monsters + 4 heroes + 33 items)
- ✅ 38 .gd script files
- ✅ 7 .tscn scene files
- ✅ All script paths in .tres files valid
- ✅ All enum values within bounds
- ✅ All hero skill references match existing skill files
- ✅ PathSystem registered in project.godot
- ✅ Signal connections valid

---

### December 26, 2025 - Session 5 (Path/Brand System Overhaul + Combat Design + Heroes)

**Purpose:** Completely revised Path and Brand systems, designed weapon rarity, monster skill learning, player skill trees, and starter heroes

**MAJOR SYSTEM CHANGES:**

**Path System (REPLACED):**
- OLD: Single value -100 to +100 (SHADE/TWILIGHT/NEUTRAL/LIGHT/SERAPH)
- NEW: Four independent paths, each tracked 0-100% separately
- Paths: IRONBOUND, FANGBORN, VOIDTOUCHED, UNCHAINED
- 30% threshold unlocks skill tree + monster catching for that path
- No passive decay - changes ONLY from player choices
- Can have multiple paths at 30%+ simultaneously

**Brand System (REPLACED):**
- OLD: Combat archetypes for players (BULWARK, FANG, EMBER, etc.)
- NEW: Monster corruption types (SAVAGE, IRON, VENOM, SURGE, DREAD, LEECH)
- Brands define HOW a monster was corrupted through the Veil
- Each path aligns with 2 primary brands

**Weapon System (NEW):**
- 6 rarity tiers: Common, Uncommon, Rare, Epic, Legendary, Mythic
- Flat damage scaling (worst to best = ~5x, not percentage-based)
- Higher rarity = more affix slots + active abilities
- Skill damage bonuses capped at 10-12% max

**Monster Skill System (NEW):**
- All monsters have 4 preset skills that scale with level
- Max 4 skills at a time (expandable to 5 with special items)
- Learning new skills = must replace existing one
- Skill pools are species-specific (based on Brand + physical form)
- Random skill assignment when caught (no cookie-cutter monsters)

**Monster Skill Progression by Rarity:**
| Rarity | Skill Levels | Max Skills | Notes |
|--------|--------------|------------|-------|
| Common | 5,10,15,20,25,30 | 10 total options | Standard growth |
| Uncommon | 5,10,15,20,25,30 | 10 total options | Same as Common |
| Rare | 5,10,20,40,80,100 | 6 total options | Fewer but stronger |
| Epic | 5,10,20,40,80,100 | 6 total options | Same + Ultimate at 30 |
| Legendary | 10,30,60,100 | 4 + 1 Ultimate | Preset base + learned |
| Mythic | 50,75,100 | Preset + 3 | Caught at high levels |

**Ultimate Abilities:**
- Epic+ monsters learn Ultimate at level 30
- MUST replace one of 4 skills to learn (mandatory)
- High cooldown OR cannot use until Round 2

**Player Skill Tree:**
- Skills tied to Path alignment (not Brand)
- 30% affinity = skill tree UNLOCKED
- Below 30% = skill tree goes DARK (can't add points, skills still work)
- Skill Reset Token refunds points for reallocation

**CODE UPDATES COMPLETED (Verified):**

| File | Changes Made |
|------|--------------|
| `enums.gd` | New Path enum (4 paths), new Brand enum (6 brands), SkillTreeState, MonsterRarity |
| `constants.gd` | PATH_SKILL_TREE_UNLOCK (30%), BRAND_EFFECTIVENESS matrix, WEAPON_ATK_RANGES, removed old PATH_MIN/MAX |
| `monster.gd` | Replaced `get_path_weakness()` with `get_brand_effectiveness()` using matrix lookup |
| `player_character.gd` | Updated brand descriptions to new names, added deprecation notes |
| `character_base.gd` | Brand multiplier now uses new BRAND_BONUSES with SAVAGE/IRON/etc. |
| `game_manager.gd` | Added `path_affinities` dict, `modify_path_affinity()`, `get_path_affinity()`, `is_path_unlocked()` |
| `debug.gd` | Updated brand unlock command to new names, deprecated old path command |
| `test_battle.gd` | All test party/skill references updated to new brands |
| `purification_system.gd` | Uses `get_path_affinity(Enums.Path.IRONBOUND)` instead of old alignment |

**VERIFIED NO ERRORS:**
- ✅ No references to old brands (BULWARK, FANG, EMBER, FROST, VOID, RADIANT)
- ✅ No references to old paths (SHADE, TWILIGHT, NEUTRAL, LIGHT, SERAPH)
- ✅ All 36 GDScript files updated consistently
- ✅ Deprecated functions kept for backward compatibility with clear comments

**Backward Compatibility:**
- `path_alignment` (old float) kept for save migration
- `get_alignment()` returns dominant path's affinity
- `modify_path_alignment()` deprecated but functional

**Files Still Needed (Future):**
- `path_system.gd` - New autoload for managing player path affinities
- Path skill trees (4 trees, one per path)

---

### December 26, 2025 - Session 4 (Monster System Implementation)

**Purpose:** Designed complete monster system with world lore, implemented code updates

**World Lore Established:**
- The Veil: Physical barrier between realms, leaking corruption through cracks
- Corruption IS the monster: Raw hunger given form, not twisted creatures
- Distance decay: Monsters weaken away from Veil
- Purification = granting consciousness and free will

**Monster System Design:**
- **Two Progression Systems:** Leveling (XP for stats) vs Purification (evolution/loyalty)
- **Two Categories:** BASIC (2 evo, fast XP, no path bonuses) vs PATH (3 evo, path synergies)
- **Purification Bonuses:** 50% (+5%), 75% (+10%), 100% (+20% + Ascension ability for PATH)
- **Path Bonuses:** 1/3 (+5%), 2/3 (+12%), 3/3 (+25% but easily countered)
- **Loyalty System:** Tied to purification, affects obedience

**Tier 1 Monster Roster Created (8 + 1 Boss):**

| Type | Monster | Evolution(s) | Role/Path |
|------|---------|--------------|-----------|
| BASIC | Mawling | Loyal Maw | DPS |
| BASIC | Hollow | The Defined | Support |
| BASIC | Gluttony Polyp | Nurturing Sphere | Healer |
| BASIC | Skitter-Teeth | Bone Warden | Tank |
| PATH | Ravener | Bloodfang → Apex | FANG |
| PATH | The Vessel | Absolution → The Devoted | RADIANT |
| PATH | Flicker | Stormwing → Quicksilver | EMBER |
| PATH | The Weeping | Gazing Dread → The Witness | FROST |
| BOSS | The Congregation | N/A (Not Capturable) | Tutorial Boss |

**Code Files Updated:**

| File | Changes |
|------|---------|
| `enums.gd` | Added `MonsterCategory`, `EvolutionStage`, `MonsterRole` enums |
| `constants.gd` | Added purification thresholds, XP rates, path bonuses, loyalty thresholds |
| `monster.gd` | Added `monster_category`, `evolution_stage`, `purification_level`, evolution/loyalty/path methods |
| `monster_data.gd` | Added `category`, `role`, `evolution_names`, `evolution_sprites` exports |

**Backward Compatibility:**
- Legacy `corruption_level` property mapped via getter/setter to `purification_level`
- Old saves automatically migrated

**Full Scan Completed:** 36+ GDScript files verified, 0 bugs/errors

---

### December 26, 2025 - Session 3 (Battle Chasers LoRA Dataset Collection)

**Purpose:** Collected high-quality Battle Chasers: Nightwar reference images for AI LoRA training on scenario.gg

**Final Dataset (5-STAR Quality):**
- **Location:** `battle_chasers_refs/style/`
- **Total Images:** 60
- **Total Size:** ~28 MB
- **Recommended Trigger Word:** `battle_chasers_style` or `bcnw_style`

**Dataset Contents:**

| Category | Count | Description |
|----------|-------|-------------|
| NPC Vendor Art | 7 | Joe Madureira character designs |
| Vendor + Backgrounds | 10 | Characters with environments (best for style) |
| Character Concepts | 12 | Heroes, enemies, monsters (Grace Liu) |
| Combat Environments | 8 | Forest, cave, arena, wintervein backgrounds |
| World Map Locations | 11 | Overworld location art |
| Key Art / Banners | 4 | Hero group compositions |
| Comic Covers | 4 | BC #10, #11, #12 covers (Billy Garretsen) |
| Colored Vignettes | 1 | Multi-character scene |
| Misc Creatures | 3 | Slimes, robotic enemies |

**Artists Represented:**
- **Joe Madureira** - Original creator, linework master
- **Grace Liu** - Lead coloring, environments, character concepts
- **Billy Garretsen** - Cover colors, vendor coloring, UI design

**Style Characteristics Captured:**
- Vibrant, saturated colors (bold comic book palette)
- Strong thick linework (Joe Mad signature style)
- Dynamic action-ready poses
- Fantasy RPG aesthetic (armor, weapons, magic)
- Warm golden/amber lighting
- Detailed environment art

**Additional Resources:**
- `battle_chasers_refs/ui/` - 19 UI screenshots & weapon icons (for separate training)
- `battle_chasers_refs/excluded/` - 2 B&W Inktober sketches (removed from style training)
- `battle_chasers_refs/DATASET_README.md` - Full documentation

**Download Scripts Created:**
| Script | Purpose |
|--------|---------|
| `download_bc_final.js` | Initial 24 curated images |
| `download_bc_ui.js` | 19 UI/icon reference images |
| `download_bc_style_complete.js` | 17 vendor backgrounds + covers |
| `download_bc_premium.js` | 19 premium 5-star environment art |

**scenario.gg Training Recommendations:**
- Use ONLY the `/style/` folder
- Steps: 1500-2500
- Learning rate: 1e-4 to 5e-5
- Batch size: 1-2

---

### December 26, 2025 - Session 2 (Bug Fix & Polish Pass)

**Files Modified (10):**

| File | Changes Made |
|------|--------------|
| `game_manager.gd` | Removed duplicate VERA state tracking; added `_get_vera_system()`, `get_vera_state()`, `get_vera_corruption()`, `reduce_vera_corruption()` delegation methods; changed `player_party` and `reserve_party` to `Array[CharacterBase]` typed arrays |
| `vera_system.gd` | Fixed corruption decay math (was 60x too fast - rate was per minute but multiplied by delta); made `modify_corruption()` and `evaluate_state()` public with backwards-compatible private aliases |
| `character_base.gd` | Added `_get_brand_multiplier()` to apply Constants.BRAND_BONUSES in `get_stat()`; implemented `_get_equipment_bonus()` querying InventorySystem for all 4 equipment slots; added `is_confused()`, `is_blinded()`, `get_confusion_target()` status effect methods; added growth rate exports (`growth_hp`, `growth_attack`, etc.) and `_calculate_stat_gain()` for level-ups |
| `player_character.gd` | Fixed `_get_equipment_bonus()` override to call `super._get_equipment_bonus(stat)` instead of returning 0 |
| `battle_manager.gd` | Implemented full skill execution system with `_load_skill_data()`, `_execute_damage_skill()`, `_execute_heal_skill()`, `_execute_buff_skill()`, `_execute_debuff_skill()`; connected item usage to `InventorySystem.use_item()`; integrated purification minigame with `_on_purification_success()` and `_on_purification_failure()` signal handlers |
| `damage_calculator.gd` | Added `calculate_skill_damage()` method for skill-based damage with power scaling and element modifiers |
| `ai_controller.gd` | Complete rewrite with utility-based AI; added `UTILITY_WEIGHTS` dictionary; implemented scoring functions for attacks, skills, defense, items; considers kill potential, self-preservation, healing efficiency |
| `battle_arena.gd` | Removed @onready for battle subsystems (caused null refs); subsystems now created dynamically in `_setup_battle_manager()`; reordered `_ready()` to create subsystems before UI |
| `save_manager.gd` | Added `SAVE_VERSION` constant; implemented `_migrate_save_data()` with version chaining; added `_migrate_v1_to_v2()` example adding VERA story flags |
| `constants.gd` | Added `BATTLE_SPRITE_SIZE`, `BATTLE_BOSS_SPRITE_SIZE`, `BATTLE_SPRITE_OFFSET`, `BATTLE_BOSS_SPRITE_OFFSET`, `DEFEND_BONUS_MULTIPLIER` |

**Files Created (1):**

| File | Purpose |
|------|---------|
| `scripts/utils/paths.gd` | Centralized scene and resource path constants to eliminate magic strings |

**Bugs Fixed (20+):**

| Priority | Issue | Resolution |
|----------|-------|------------|
| CRITICAL | VERA state tracked in both GameManager and VERASystem causing desync | GameManager now delegates all VERA operations to VERASystem |
| CRITICAL | Corruption decay 60x faster than intended (per-minute rate × delta) | Fixed: `decay_per_second := rate / 60.0` |
| CRITICAL | BattleArena @onready for TurnManager/DamageCalculator expected scene nodes | Subsystems created dynamically via `.new()` |
| HIGH | GameManager called private `_modify_corruption()` | Made public `modify_corruption()` method |
| HIGH | `player_party` and `reserve_party` were untyped arrays | Changed to `Array[CharacterBase]` |
| HIGH | Brand bonuses defined in Constants but never applied | Added `_get_brand_multiplier()` in `get_stat()` |
| HIGH | Equipment bonuses always returned 0 | Implemented `_get_equipment_bonus()` querying InventorySystem |
| HIGH | PlayerCharacter equipment override returned 0 | Changed to `super._get_equipment_bonus(stat)` |
| MEDIUM | Skill execution was placeholder returning empty dict | Implemented full skill system with SkillData loading |
| MEDIUM | Item usage stub did nothing | Connected to `InventorySystem.use_item()` |
| MEDIUM | Purification minigame not connected | Added signal handlers for success/failure |
| MEDIUM | No skill damage calculation method | Added `calculate_skill_damage()` to DamageCalculator |
| MEDIUM | Level-up stat gains were random | Implemented growth rate system with chance-based gains |
| MEDIUM | Confusion/Blind status effects not handled | Added `is_confused()`, `is_blinded()`, `get_confusion_target()` |
| MEDIUM | AI was simple/predictable | Rewrote with utility-based weighted scoring |
| LOW | Battle sprite sizes hardcoded | Added constants to `constants.gd` |
| LOW | No save data migration system | Added `_migrate_save_data()` with version chaining |
| LOW | Scene paths were magic strings | Created `paths.gd` with centralized constants |

**Final Scan Result:** ALL CLEAR - 0 critical issues, 0 syntax errors, 0 breaking bugs

---

## PROJECT OVERVIEW

**VEILBREAKERS** is an anime-style turn-based RPG being developed in **Godot 4.3+** with **GDScript 2.0**.

- **Genre:** Turn-Based RPG with Monster Hunting/Purification
- **Art Style:** Battle Chasers: Nightwar inspired
- **Engine:** Godot 4.3+
- **Location:** `C:\Users\Conner\Downloads\VeilbreakersGame`

---

## VERA/VERATH LORE (CRITICAL)

### The Truth About VERA
**VERA is VERATH** - an ancient demon/devourer who doesn't know her own true nature. She appears as a gentle elven healer, believing herself to be good and helpful. As "corruption" increases, she's actually **recovering her memories** and remembering who she truly is.

**Reference Art Location:** `data/brands/` (vera preview pure stage.webp, vera preview beast stage.webp)

### The Four States (VERAState enum)
| State | Corruption | Narrative | Visual |
|-------|------------|-----------|--------|
| **INTERFACE** | 0-24% | The perfect disguise. VERA believes she's helpful. No memories of true self. | Pure healer. Soft teal eyes, golden-auburn hair, cream dress, silver circlet. Warm, nurturing. |
| **FRACTURE** | 25-59% | Memories starting to return. Glimpses of her past. Confusion, denial. | Shadow shows horns/wings. Eyes flash amber. Voice has faint echo. Hair moves against wind. |
| **EMERGENCE** | 60-89% | She remembers. She knows who she is. Fighting against or embracing it. | Black veins visible. Circlet cracking. Small horns sprouting. Demon silhouette behind her. |
| **APOTHEOSIS** | 90-100% | VERATH fully awakens. The devourer returns. All memories restored. | Full beast form. Massive demon, VERA's body embedded in chest like puppet. |

### Visual Effects: Demon Bleed-Through (Replaces Digital Glitches)
As memories return, physical signs of her true form emerge:
- **Shadow mismatch** - shadow shows beast features she doesn't have yet
- **Eye flicker** - teal → amber/red flash
- **Voice echo** - deeper demonic voice underneath
- **Hair movement** - moves unnaturally, something underneath
- **Circlet damage** - the seal cracking as beast emerges
- **Vein darkening** - black/purple veins spreading
- **Partial transformation** - horns, claws, elongated features

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

## FILE STRUCTURE (38 .gd files)

### Autoloads (`scripts/autoload/`)
- `audio_manager.gd` - Music, SFX, voice playback
- `event_bus.gd` - Central signal hub (50+ signals)
- `game_manager.gd` - Game state, progression, delegates VERA to VERASystem
- `path_system.gd` - **NEW** Path affinity management, skill trees, monster catching
- `save_manager.gd` - Save/load with slots + migration system
- `scene_manager.gd` - Scene transitions
- `settings_manager.gd` - Persistent settings

### Battle (`scripts/battle/`)
- `battle_manager.gd` - Battle orchestration, skill/item execution
- `battle_arena.gd` - Battle scene, character placement, dynamically creates subsystems
- `turn_manager.gd` - Speed-based turn order
- `damage_calculator.gd` - Damage formulas with skill support
- `status_effect_manager.gd` - Buffs/debuffs
- `ai_controller.gd` - Utility AI with weighted scoring
- `purification_system.gd` - Monster capture mechanics

### Characters (`scripts/characters/`)
- `character_base.gd` - Base class with brand bonuses, equipment, growth rates
- `player_character.gd` - Player-specific logic, brand system
- `monster.gd` - Enemy/recruitable monsters with AI patterns

### Data Resources (`scripts/data/`)
- `hero_data.gd` - **NEW** HeroData resource class with stat growth
- `monster_data.gd` - MonsterData resource class
- `skill_data.gd` - SkillData resource class with type enum
- `item_data.gd` - ItemData resource class

### Data Files (`data/`)
- `data/heroes/` - 4 hero .tres files (rend, bastion, marrow, mirage)
- `data/monsters/` - 9 monster .tres files (8 Tier 1 + 1 boss)
- `data/skills/` - 30 skill .tres files (common + all hero skill trees)
- `data/items/consumables/` - 19 consumable .tres files
- `data/items/equipment/` - 14 equipment .tres files

### Art Assets (`assets/characters/`)
- `heroes/` - 4 hero portrait PNGs
- `vera/` - 4 VERA state PNGs (interface, fracture, emergence, apotheosis)
- `monsters/` - (awaiting generation)

### Systems (`scripts/systems/`)
- `vera_system.gd` - VERA state/corruption management (SOURCE OF TRUTH)
- `purification_minigame.gd` - Rhythm-based capture minigame
- `inventory_system.gd` - Items, equipment, usage
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
- `constants.gd` - Game constants, brand bonuses, battle visuals
- `enums.gd` - All enumerations
- `helpers.gd` - Utility functions
- `debug.gd` - Debug console
- `paths.gd` - Centralized scene/resource path constants (NEW)

### Main (`scripts/main/`)
- `game.gd` - Main game scene

### Test (`scripts/test/`)
- `test_battle.gd` - Test battle setup

---

## KEY ARCHITECTURE DECISIONS

### VERA State Management
- **VERASystem** is the single source of truth for VERA state/corruption
- **GameManager** delegates all VERA operations to VERASystem via `_get_vera_system()`
- Public methods: `modify_corruption()`, `evaluate_state()`, `add_corruption()`

### Battle Subsystem Initialization
- **BattleArena** dynamically creates BattleManager, TurnManager, DamageCalculator
- No @onready for subsystems - prevents null reference crashes
- Subsystems added as children for proper process calls

### Type Safety
- `GameManager.player_party: Array[CharacterBase]`
- `GameManager.reserve_party: Array[CharacterBase]`
- `GameManager.owned_monsters: Array[Dictionary]`

### Brand Bonuses (Applied in CharacterBase.get_stat())
```gdscript
func _get_brand_multiplier(stat: Enums.Stat) -> float:
    # Reads from Constants.BRAND_BONUSES
    # Returns multiplier for stat based on character's brand
```

### Equipment Bonuses
- `CharacterBase._get_equipment_bonus()` queries InventorySystem
- Checks all 4 equipment slots for stat bonuses

### Growth Rate System
```gdscript
@export var growth_hp: float = 0.8      # 80% chance per level
@export var growth_attack: float = 0.4  # 40% chance per level
# etc.
```

### Utility AI (ai_controller.gd)
- Evaluates all possible actions with weighted scoring
- Considers: damage, kill potential, self-preservation, healing efficiency
- Tunable weights for different AI personalities

### Save Migration System (save_manager.gd)
- `SAVE_VERSION` constant tracks format version
- `_migrate_save_data()` chains version migrations
- Example: `_migrate_v1_to_v2()` adds VERA story flags

---

## PATH SYSTEM (CRITICAL - Session 5)

### The Four Paths
Players develop path affinity through choices. Each path tracked independently (0-100%).

| Path | Philosophy | Combat Focus | Color | Primary Brands |
|------|------------|--------------|-------|----------------|
| **IRONBOUND** | Protection, order, sacrifice, duty | Tank/Defense | `#7B8794` | IRON, DREAD |
| **FANGBORN** | Strength, dominance, survival, apex | Attack/DPS | `#8B2942` | SAVAGE, SURGE |
| **VOIDTOUCHED** | Knowledge, truth, patience, secrets | Utility/Special | `#5D3E8C` | DREAD, LEECH |
| **UNCHAINED** | Freedom, chaos, adaptability | Hybrid/Disruptor | `#2D8B72` | VENOM, SURGE |

### Expected Player Distribution
Most players naturally settle around: 60% main, 20% secondary, 10% tertiary, 10% fourth.

### Path Thresholds
| Threshold | What It Unlocks |
|-----------|-----------------|
| **30%** | Skill tree UNLOCKED, can catch path-aligned monsters |
| **40%** | Path gear at full effectiveness |
| **37-39%** | Path gear has minor penalty |
| **Below 30%** | Skill tree goes DARK, gear has negative effects |

### Skill Tree States
1. **LOCKED** - Below 30%, cannot access
2. **UNLOCKED** - 30%+, can allocate points
3. **DARK** - Was unlocked, dropped below 30%. Points stuck but skills still work.

### Skill Reset Token
- Rare consumable (drop, quest, purchasable)
- Refunds all skill points from selected path
- Points can be reallocated to any UNLOCKED path (30%+)

### Affinity Changes (ONLY From Choices - No Decay)
| Choice Type | Add | Reduce |
|-------------|-----|--------|
| Minor dialogue | +1 to +3 | -1 to -2 |
| Side quest | +3 to +5 | -3 to -5 |
| Major decision | +5 to +10 | -3 to -5 |
| Convergence point | +10 to +15 | -5 to -10 |

### Three Convergence Points
Major story decisions where all paths converge - massive affinity shifts possible.

---

## BRAND SYSTEM (CRITICAL - Session 5)

### The Six Brands
Brands represent HOW a monster was corrupted passing through the Veil. Every monster has exactly ONE brand.

| Brand | Identity | Combat Style | Color |
|-------|----------|--------------|-------|
| **SAVAGE** | Tearing, brutality, raw violence | Bleed, crits, physical DPS | `#C73E3E` |
| **IRON** | Endurance, protection, immovability | Tank, shields, damage reduction | `#7B8794` |
| **VENOM** | Poison, corruption, decay | DoT, debuffs, stat weakening | `#6B9B37` |
| **SURGE** | Overload, magical burst | Burst magic, AoE, explosive | `#4A90D9` |
| **DREAD** | Fear, psychological control | Debuffs, stuns, accuracy reduction | `#5D3E8C` |
| **LEECH** | Drain, parasitic sustain | Lifesteal, stat theft, drain | `#C75B8A` |

### Brand Effectiveness Matrix
```
ATTACKER →    SAVAGE   IRON    VENOM   SURGE   DREAD   LEECH
DEFENDER ↓
SAVAGE        1.0x     1.5x    0.75x   1.5x    0.75x   0.75x
IRON          0.75x    1.0x    1.5x    0.75x   0.75x   1.5x
VENOM         1.5x     0.75x   1.0x    1.5x    0.75x   0.75x
SURGE         0.75x    1.5x    0.75x   1.0x    1.5x    0.75x
DREAD         1.5x     1.5x    1.5x    0.75x   1.0x    0.75x
LEECH         1.5x     0.75x   1.5x    1.5x    1.5x    1.0x
```

### Quick Reference
| Brand | Strong Against (1.5x) | Weak Against (0.75x) |
|-------|----------------------|----------------------|
| SAVAGE | DREAD, LEECH | IRON, SURGE |
| IRON | SAVAGE, SURGE | VENOM, LEECH |
| VENOM | IRON, DREAD | SURGE, SAVAGE |
| SURGE | VENOM, LEECH | IRON, DREAD |
| DREAD | SURGE, IRON | SAVAGE, VENOM |
| LEECH | DREAD, VENOM | SURGE, SAVAGE |

---

## WEAPON SYSTEM (Session 5)

### Weapon Rarity Tiers
Based on research from Skyrim, Battle Chasers, Octopath Traveler, Diablo.

| Rarity | ATK Range | Affix Slots | Active Ability | Progression |
|--------|-----------|-------------|----------------|-------------|
| **Common** | 5-8 | 0 | ❌ | 1.0x |
| **Uncommon** | 9-14 | 1 minor | ❌ | ~1.5x |
| **Rare** | 15-22 | 1-2 minor | ❌ | ~2.2x |
| **Epic** | 23-32 | 2 (1 moderate) | ✅ Weak | ~3x |
| **Legendary** | 33-42 | 2-3 (1 strong) | ✅ Moderate | ~4x |
| **Mythic** | 43-50 | 3 (1 unique) | ✅ Strong | ~5x |

### Affix Tiers
| Tier | Example |
|------|---------|
| Minor | +3 ATK, +2 SPD, +5% crit |
| Moderate | +8 ATK, +5% element damage, +status on crit |
| Strong | +12 ATK, +10% element damage, +status effect |
| Unique | +15 ATK, Lifesteal 5%, unique proc |

### Balance Rules
- **Max skill damage bonus: 10-12%** (never exceeds weakness multiplier)
- Worst to best weapon = ~5x difference (not percentage-based)
- Active abilities cost MP (can't spam)
- Actives scale with weapon, not stats (fixed damage ranges)

### Example Weapons
```
Common - Iron Sword
ATK: +5
(No bonuses)

Rare - Flamberge
ATK: +16
Passive: +7% Fire skill damage

Legendary - Sunfire Crusader
ATK: +40
Passive: +14% Fire damage
Passive: +5% crit vs Burned enemies
Active: "Solar Flare" (35-45 Fire, applies Burn) - 12 MP
```

---

## MONSTER SKILL SYSTEM (Session 5)

### Core Rules
- **All monsters have 4 preset skills** that scale with level
- **Max 4 skills at a time** (expandable to 5 with special items/totems)
- **Learning new skills = must replace one**
- **Skill pools are species-specific** based on Brand + physical form

### Physical Form Gating
A frost demon can learn "Frost Fang" but NOT "Frost Fist" (no fists).
Skills are limited by what the monster can physically do.

### Skill Progression by Rarity
| Rarity | Skill Levels | Total Options | Notes |
|--------|--------------|---------------|-------|
| **Common** | 5, 10, 15, 20, 25, 30 | 10 | Standard steady growth |
| **Uncommon** | 5, 10, 15, 20, 25, 30 | 10 | Same as Common |
| **Rare** | 5, 10, 20, 40, 80, 100 | 6 | Fewer but stronger |
| **Epic** | 5, 10, 20, 40, 80, 100 | 6 | Same + Ultimate at 30 |
| **Legendary** | 10, 30, 60, 100 | 4 + 1 Ultimate | Preset base + learned |
| **Mythic** | 50, 75, 100 | Preset + 3 | Caught at high levels |

### Ultimate Abilities (Epic+ Only)
- Learned at level 30
- **MUST replace one of 4 skills** (mandatory)
- High cooldown OR cannot use until Round 2
- Maximum of 3 + 1 Ultimate (or 4 + 1 with special item)

### Random Skill Assignment (Anti-Cookie-Cutter)
When catching a monster, it retroactively "rolled" for each skill threshold:

**Example - Level 45 Rare caught:**
```
Level 5  → Rolled Skill A (from pool of options)
Level 10 → Rolled Skill B (from pool of options)
Level 20 → Rolled Skill C (from pool of options)
Level 40 → Rolled Skill D (from pool of options)
Level 80 → Not yet reached
Level 100 → Not yet reached
```

Two level 45 Rares of the same species could have completely different loadouts!

---

## PLAYER COMBAT SYSTEM (Session 5)

### Combat Turn Options
On a **hero's turn**:
- **Attack** (basic, uses weapon)
- **Skill** (Path-based ability)
- **Weapon Art** (weapon's active ability, if Epic+)
- **Item**
- **Defend**

On a **monster's turn**:
- Player picks skill + target (or auto-battle)

### Player Skills
- Tied to **Path alignment** (IRONBOUND, FANGBORN, etc.)
- Each path has its own skill tree
- Unlocked at 30% affinity
- Skill points earned on level-up, allocated to any UNLOCKED tree
- Weapons have basic attacks; Path determines special abilities

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

### Path (Player Moral Alignment - 4 Independent Values)
```gdscript
enum Path {
    NONE = -1,
    IRONBOUND = 0,    # Protection, order, sacrifice, duty (Tank/Defense)
    FANGBORN = 1,     # Strength, dominance, survival, apex (Attack/DPS)
    VOIDTOUCHED = 2,  # Knowledge, truth, patience, secrets (Utility/Special)
    UNCHAINED = 3     # Freedom, chaos, adaptability (Hybrid/Disruptor)
}
```

### Brand (Monster Corruption Type - 6 Types)
```gdscript
enum Brand {
    NONE = -1,
    SAVAGE = 0,   # Bleed, crits, raw physical DPS
    IRON = 1,     # Tank, shields, damage reduction
    VENOM = 2,    # DoT, debuff spread, stat weakening
    SURGE = 3,    # Burst magic, AoE, explosive
    DREAD = 4,    # Fear, stuns, accuracy reduction
    LEECH = 5     # Lifesteal, stat theft, drain
}
```

### Path-Brand Alignment
```gdscript
# Which brands align with which paths
const PATH_BRAND_ALIGNMENT = {
    Path.IRONBOUND: [Brand.IRON, Brand.DREAD],
    Path.FANGBORN: [Brand.SAVAGE, Brand.SURGE],
    Path.VOIDTOUCHED: [Brand.DREAD, Brand.LEECH],
    Path.UNCHAINED: [Brand.VENOM, Brand.SURGE]
}
```

### SkillTreeState
```gdscript
enum SkillTreeState {
    LOCKED,      # Below 30% - cannot access
    UNLOCKED,    # 30%+ - can allocate points
    DARK         # Was unlocked, now below 30% - points stuck, skills work
}
```

### SkillType (SkillData)
```gdscript
enum SkillType {
    DAMAGE, HEAL, BUFF, DEBUFF, STATUS, UTILITY, PASSIVE
}
```

### MonsterRarity (Spawn Rate + Skill Progression)
```gdscript
enum MonsterRarity {
    COMMON,      # 5,10,15,20,25,30 skill levels, 10 options
    UNCOMMON,    # 5,10,15,20,25,30 skill levels, 10 options
    RARE,        # 5,10,20,40,80,100 skill levels, 6 options
    EPIC,        # 5,10,20,40,80,100 skill levels, 6 options + Ultimate@30
    LEGENDARY,   # 10,30,60,100 skill levels, 4 + Ultimate
    MYTHIC       # 50,75,100 skill levels, preset + 3
}
```

---

## BUGS FIXED (Session 1)

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
| `test_battle.gd` | Used wrong Brand enum names | Changed to correct names (FANG/RADIANT/etc) |

---

## BUGS FIXED (Session 2)

### Critical Fixes
| File | Issue | Fix |
|------|-------|-----|
| `game_manager.gd` | VERA state duplication with VERASystem | GameManager now delegates to VERASystem |
| `vera_system.gd:81` | Corruption decay math bug (per minute vs per frame) | Fixed: `decay_per_second := rate / 60.0` |
| `battle_arena.gd` | @onready for subsystems caused null refs | Subsystems now created dynamically in `_setup_battle_manager()` |

### High Priority Fixes
| File | Issue | Fix |
|------|-------|-----|
| `game_manager.gd` | Untyped arrays for party/reserve | Added `Array[CharacterBase]` types |
| `character_base.gd` | Brand bonuses never applied | Added `_get_brand_multiplier()` in `get_stat()` |
| `character_base.gd` | Equipment bonuses returned 0 | Implemented `_get_equipment_bonus()` to query InventorySystem |
| `vera_system.gd` | Private methods called externally | Made `modify_corruption()` and `evaluate_state()` public |
| `player_character.gd` | Equipment override returned 0 | Changed to `super._get_equipment_bonus(stat)` |

### Medium Priority Fixes
| File | Issue | Fix |
|------|-------|-----|
| `battle_manager.gd` | Skill execution was placeholder | Implemented full skill system with SkillData loading |
| `battle_manager.gd` | Item usage not implemented | Connected to InventorySystem.use_item() |
| `battle_manager.gd` | Purification minigame not integrated | Connected to PurificationMinigame with signals |
| `damage_calculator.gd` | No skill damage calculation | Added `calculate_skill_damage()` method |
| `character_base.gd` | Random level-up stats | Implemented growth rate system |
| `character_base.gd` | Missing confusion/blind handling | Added `is_confused()`, `is_blinded()`, `get_confusion_target()` |
| `ai_controller.gd` | Simple AI only | Implemented utility-based AI with scoring system |

### Low Priority Fixes
| File | Issue | Fix |
|------|-------|-----|
| `constants.gd` | Missing battle visual constants | Added BATTLE_SPRITE_SIZE, DEFEND_BONUS_MULTIPLIER, etc. |
| `save_manager.gd` | No save migration system | Added `_migrate_save_data()` with version chaining |
| N/A | No centralized path constants | Created `scripts/utils/paths.gd` |

---

## NEW FILES CREATED (Session 2)

- `scripts/utils/paths.gd` - Centralized scene and resource path constants

---

## PHASE STATUS

### Completed Phases
- **Phase 0:** Pre-Production (docs, setup)
- **Phase 1:** Foundation (autoloads, scenes)
- **Phase 2:** Core Systems (battle, save/load)
- **Phase 3:** Art Pipeline (Spine, character setup)
- **Phase 4:** Game Systems (VERA, purification, inventory, quests)
- **Phase 4.5:** Bug Fixes & Polish (this session)

### Current State
- 39 GDScript files (+1 DataManager from Session 7)
- 131 Resource files (.tres) - 85 skills (30 hero + 55 monster), 9 monsters, 4 heroes, 33 items
- 8 Art assets - 4 heroes, 4 VERA states
- All core systems functional
- PathSystem autoload implemented
- DataManager autoload implemented (Session 7)
- Utility AI implemented
- Growth rate system implemented
- Save migration system in place
- **PHASE 5 COMPLETE** - All content resources created
- **PHASE 5.5 COMPLETE** - Monster skills + DataManager

---

## IMPORTANT NOTES

### Signal Pattern
All cross-system communication goes through `EventBus`:
```gdscript
EventBus.vera_state_changed.emit(old_state, new_state)
EventBus.vera_glitch_triggered.emit(intensity, duration)
```

### Corruption = Memory Recovery
In the lore, "corruption" is actually VERATH recovering her memories. Higher corruption means she remembers more of her true nature as an ancient demon/devourer.

---

## WORLD LORE

### The Veil
The Veil is a **physical barrier between realms** - a massive, ancient wall of energy that separates the mortal world from something darker beyond. It was created long ago (the truth: to contain VERATH, though this is forgotten). The Veil has begun to crack, and through these cracks, corruption leaks into the world.

### The World Before
The world was once **bright and full of illumination**. However, the mortal races (humans, elves, etc.) constantly fought each other for dominance of the realm. Wars, betrayals, and conquest defined history. The Veil was always there, but stable - a distant barrier no one questioned.

### The World Now (Gradient System)
The world exists on a **corruption gradient** based on proximity to the Veil:

| Distance from Veil | Environment | Monster Strength |
|--------------------|-------------|------------------|
| **Far (Player Start)** | Bright, illuminated, resembles the old world | Weak, newly spawned monsters |
| **Mid** | Dimming, shadows growing, unease | Established monsters, some have consumed significantly |
| **Near Veil** | Dark, corrupted hellscape, reality breaks down | Ancient horrors, massive amalgamations |

### How Corruption Works
**Corruption IS the monster.** When cracks form in the Veil:
1. Raw corruption leaks through as a formless hunger
2. It immediately begins to **devour** - animals, plants, people, anything living
3. Each consumption makes it stronger, more defined, more terrifying
4. Monsters do NOT twist existing creatures - they ARE corruption given form, wearing trophies of what they consumed

**Distance Decay:** Monsters weaken as they move away from the Veil. The connection to the source fades. This is why frontier areas are safer - monsters there are cut off from power.

### Purification & Recruitment
Humans discovered that monsters can be captured and **purified** through:
- Training alongside humans
- Battling together
- Special items and food
- Time and bonding

**What Purification Does:**
- The monster consumes other monsters in battle, gaining strength
- Through this, they gain **consciousness** - awareness beyond hunger
- They realize how controlled they were by the Veil's evil
- **Free will** becomes enticing - they CHOOSE to fight, improve, and ascend
- They become loyal companions who remember what they were and never want to return to it

---

## MONSTER SYSTEM (CRITICAL)

### Two Progression Systems

**LEVELING (XP System):**
| Aspect | Detail |
|--------|--------|
| Source | Battle XP |
| Effect | Increases base stats |
| Abilities | Unlock at level thresholds |
| Cap | Same for all monsters |
| Rate | Basic types = fast forever / Path types = normal, slows at Ascension |

**PURIFICATION (Evolution System):**
| Aspect | Detail |
|--------|--------|
| Source | Training, battles, items, food, time |
| Effect | Evolution form, loyalty, visual state |
| Capture State | All monsters captured at 25% |
| Bonuses | 50% (small), 75% (medium), 100% (large + Ascension bonus for Path types) |

### Monster Categories

**BASIC TYPE MONSTERS:**
| Aspect | Detail |
|--------|--------|
| Evolutions | 2 forms: Corrupted (25-49%) → Awakened (50%+) |
| Visual Change | At 50% purification, stays that form forever |
| XP Rate | **Fast forever** - always scaling |
| Purification Bonuses | Yes (50%, 75%, 100%) |
| Path Bonuses | **None** - Brand is BASIC |
| Role Subtypes | Tank, DPS, Healer, Support |
| Strength | Flexibility, raw level scaling, reliable |

**PATH TYPE MONSTERS:**
| Aspect | Detail |
|--------|--------|
| Evolutions | 3 forms: Corrupted (25-49%) → Awakened (50-99%) → Ascended (100%) |
| Visual Changes | At 50% AND 100% purification |
| XP Rate | Normal until Ascended, then **slows** |
| Purification Bonuses | Yes (50%, 75%, 100% includes unique ability) |
| Path Bonuses | **Yes** - team synergies |
| Paths | FANG, RADIANT, EMBER, FROST, VOID, BULWARK |
| Strength | Unique abilities, high ceiling, team synergies |

### Purification Bonuses (All Monster Types)

| Threshold | Bonus Type |
|-----------|------------|
| 50% | Small stat bonus (+5% to primary stat) |
| 75% | Medium stat bonus (+10% to primary, +5% secondary) |
| 100% | Large stat bonus (+15% primary, +10% secondary) + Ascension ability (Path types only) |

### Path Bonus System (Path Types Only, Active Party Only)

| Matching Paths | Bonus |
|----------------|-------|
| 1/3 same path | Small (+5% to path's key stat) |
| 2/3 same path | Medium (+12% key stat, +5% secondary) |
| 3/3 same path | Large (+20% key stat, +10% secondary, +team passive) **BUT easily countered** |

### Path Weaknesses (Rock-Paper-Scissors)
```
FANG (Physical DPS) → weak to BULWARK (Tank)
BULWARK (Tank) → weak to VOID (Debuff)
VOID (Debuff) → weak to RADIANT (Holy)
RADIANT (Holy) → weak to FANG (Physical)
EMBER (Fire/Speed) ↔ FROST (Ice/Control) - mutual weakness
```

### Loyalty System
Loyalty is tied to purification level:
| Purification | Loyalty State |
|--------------|---------------|
| 25-39% | May disobey orders, acts on instinct |
| 40-59% | Usually follows orders, occasional independence |
| 60-79% | Reliable, protective instincts emerging |
| 80-99% | Fully loyal, communicates intent |
| 100% | Devoted, will sacrifice for trainer |

---

## TIER 1 MONSTER ROSTER

### BASIC TYPE MONSTERS (2 Evolutions, Fast XP, No Path Bonuses)

#### 1. MAWLING → LOYAL MAW
**Role:** Basic DPS

**Corrupted Form (25-49%):**
A small, hovering mass of dark viscous matter with a single oversized mouth taking up 70% of its body. No eyes. Mismatched teeth - some human, some animal - trophies of first small meals. Size of a dog. Makes wet, desperate sounds.

**Awakened Form (50%+):**
Mouth shrinks proportionally. Primitive eye-spots develop. Body becomes more stable, less dripping. Teeth organize into proper rows. Still hungry, but controlled.

**Lore:**
The most basic form corruption takes. Pure hunger - no thought, no plan. Drawn to warmth and movement. Most never grow beyond this stage. When purified, becomes intensely loyal - the first creature to show it anything other than fear. Follows commands with eager enthusiasm. Doesn't speak but understands. It WANTS to be good.

**Abilities (By Level):**
| Level | Ability | Description |
|-------|---------|-------------|
| 1 | Gnaw | Basic physical attack, chance to Bleed |
| 5 | Desperate Lunge | Charges lowest HP target |
| 12 | Devour Scraps | Consume fallen ally to heal (battle only) |
| 20 | Loyal Bite | Increased damage when trainer is injured |
| 30 | Pack Feast | Bonus damage if other Mawlings in party |

**Base Stats (Level 1):**
```
HP: 45 | MP: 0 | ATK: 14 | DEF: 6 | MAG: 2 | RES: 4 | SPD: 11 | LUCK: 3
```

**Drops:** Viscous Residue, Cracked Fang

---

#### 2. HOLLOW → THE DEFINED
**Role:** Basic Support (Debuffer)

**Corrupted Form (25-49%):**
A towering shadow entity with a muscular upper form that dissolves into writhing tendrils below. A single glowing red core pulses in its chest - the only light in its darkness. Massive clawed hands reach outward as debris floats in its presence, reality warping around it. No face, no features - just an imposing silhouette against a purple void. Reaches toward living beings, confused why they run.

**Awakened Form (50%+):**
The red core dims to a gentle amber. Upper form becomes more defined, almost noble. Tendrils stabilize into flowing robes of shadow. A face emerges - sorrowful but kind. The floating debris settles. Moves with purpose and grace instead of menace.

**Lore:**
Forms near recent death or great grief. Hasn't consumed enough to have identity. Wanders, reaching toward living beings not to attack, but because it senses they have something it lacks: substance. Lonely in a way it can't comprehend. When purified, finally gains definition. The first thing it does is look at its hands in wonder. Speaks in fragments at first, then sentences. Grateful but melancholy - fears returning to emptiness. Fights to REMAIN someone.

**Abilities (By Level):**
| Level | Ability | Description |
|-------|---------|-------------|
| 1 | Empty Grasp | Drains small HP, heals self |
| 5 | Hollow Wail | AoE inflicts Sorrow (reduces ATK) |
| 10 | Mimic Stance | Copies last attacker's defensive stats temporarily |
| 18 | Void Touch | Single target MAG damage + chance Silence |
| 25 | Defined Purpose | Self buff, increases all stats when protecting ally |

**Base Stats (Level 1):**
```
HP: 35 | MP: 15 | ATK: 8 | DEF: 8 | MAG: 12 | RES: 10 | SPD: 9 | LUCK: 5
```

**Drops:** Essence Fragment, Shadow Wisp

---

#### 3. GLUTTONY POLYP → NURTURING SPHERE
**Role:** Basic Healer

**Corrupted Form (25-49%):**
A translucent, stomach-like sac about 3 feet across, floating slightly off ground. Inside: half-digested plants, flowers, small animals - all slowly dissolving. Multiple small feeding tendrils extend from base. Pulses rhythmically. Things inside aren't dead - they're being slowly absorbed. Disturbingly passive.

**Awakened Form (50%+):**
Membrane becomes opaque, soft green/gold glow instead of visible digestion. Tendrils become gentle, reaching to touch allies. Internal glow pulses with healing energy. The horror becomes nurturing.

**Lore:**
Forms in fertile areas, immediately consuming plant life. A mobile digestive system - nothing more. Has no brain, just a network of consumption. When purified, releases everything it held - a surge of seeds, bones, and memories. Reshapes into something that GIVES rather than takes. Becomes obsessed with growing things, healing things. The guilt weighs heavy, channeled into nurturing. Never forgets the faces of what it consumed.

**Abilities (By Level):**
| Level | Ability | Description |
|-------|---------|-------------|
| 1 | Soothing Pulse | Single target heal |
| 5 | Acid Splash | Ranged attack using digestive fluids |
| 10 | Absorb Pain | Takes damage instead of ally |
| 15 | Nurturing Light | AoE heal to all allies |
| 22 | Life Returned | Revive fallen ally with 25% HP (once per battle) |

**Base Stats (Level 1):**
```
HP: 55 | MP: 20 | ATK: 6 | DEF: 12 | MAG: 10 | RES: 14 | SPD: 4 | LUCK: 6
```

**Drops:** Digested Essence, Membrane Fragment, (rare) Living Seed

---

#### 4. SKITTER-TEETH → BONE WARDEN
**Role:** Basic Tank

**Corrupted Form (25-49%):**
A ribcage crawling on finger-like legs, with a jaw that splits four ways. Made of bones from multiple creatures fused wrong - deer skull with human fingers for teeth, bird bones woven through ribs. Moves in jerky, stop-motion bursts. Collects bones constantly.

**Awakened Form (50%+):**
Bones settle into stable, intentional form. Armored appearance - ribcage becomes chest plate, skull becomes helmet-like. Movements become smooth, protective stances. No longer scavenging - standing guard.

**Lore:**
Forms where death gathers - battlefields, graveyards, predator feeding grounds. Builds itself from remains. The bones are just MATERIAL - the corruption animates them. When purified, becomes guardian of the dead. Understands bones are sacred, not material. Fights to prevent others from becoming what it was forced to be. "Speaks" by clattering bones in patterns.

**Abilities (By Level):**
| Level | Ability | Description |
|-------|---------|-------------|
| 1 | Bone Snap | Fast physical attack, high crit |
| 5 | Harvest | Gains DEF when any creature dies nearby |
| 10 | Reassemble | Heal by consuming corpse on battlefield |
| 16 | Bone Wall | Reduce damage to adjacent ally |
| 24 | Warden's Stand | Taunt + DEF boost for 3 turns |

**Base Stats (Level 1):**
```
HP: 50 | MP: 5 | ATK: 12 | DEF: 14 | MAG: 3 | RES: 8 | SPD: 10 | LUCK: 5
```

**Drops:** Fused Bone Fragment, Chattering Jaw, (rare) Intact Skull

---

### PATH TYPE MONSTERS (3 Evolutions, Path Bonuses, Unique Ascension Abilities)

#### 5. RAVENER → BLOODFANG → APEX
**Brand:** SAVAGE (Physical DPS) | **Path Alignment:** FANGBORN

**Corrupted Form - Ravener (25-49%):**
Quadrupedal nightmare built from consumed predators. Wolf haunches, bear claws, big cat fangs - overlapping, excessive. Six eyes from different hunters. Lean, scarred, constantly tensed. Ridge of spines down back. Drools constantly. ALWAYS hungry. Targets weakest enemy, never retreats.

**Awakened Form - Bloodfang (50-99%):**
Features harmonize - still multi-predator but coherent. Eyes reduce to four, focused. Movements become calculated instead of frantic. Muscles defined, not chaotic. Controlled aggression. Scars become war trophies, not wounds.

**Ascended Form - Apex (100%):**
Sleek, powerful, noble. Two golden eyes. Single predator form - the ultimate hunter, not a patchwork. Clean lines, purposeful movement. Still dangerous, but chooses its prey. The chaos became mastery.

**Lore:**
Forms in hunting grounds near apex predators. Absorbs their instincts, aggression, need to kill. Doesn't eat to survive - kills because killing is all it knows. Every predator consumed added another layer of hunting instinct. When purified, the many predators settle into one. Becomes hunter with PURPOSE. Fiercely protective of trainer. The first time it refuses to kill something helpless, it surprises even itself.

**Abilities (By Level):**
| Level | Ability | Description |
|-------|---------|-------------|
| 1 | Rend | Heavy physical damage, ignores portion of DEF |
| 1 | Bloodscent | Passive: +damage to bleeding targets |
| 8 | Prey on Weak | Bonus damage to targets below 50% HP |
| 15 | Feeding Frenzy | After kill, immediately attack again |
| 22 | Pack Tactics | +ATK when allies alive |
| 30 | **Apex Strike** | **(100% Ascension)** Massive single-target, ignores DEF, once per battle |

**Base Stats (Level 1):**
```
HP: 38 | MP: 0 | ATK: 22 | DEF: 5 | MAG: 2 | RES: 4 | SPD: 14 | LUCK: 8
```

**Drops:** Predator Fang, Ravener Claw, (rare) Apex Core

---

#### 6. THE VESSEL → ABSOLUTION → THE DEVOTED
**Brand:** LEECH (Healer/Drain) | **Path Alignment:** VOIDTOUCHED

**Corrupted Form - The Vessel (25-49%):**
Humanoid figure in tattered robes, floating slightly. Open cavity where chest should be, glowing with soft stolen light. Face is serene but wrong - features taken from priests, healers, mothers. Hands always extended, palms up, offering. Light pools in palms like water. Speaks in fragments of prayers.

**Awakened Form - Absolution (50-99%):**
Robes mend themselves, become white and gold. Cavity partially closes, light now emanates from whole body. Face settles into something peaceful, genuine. Offers healing intentionally, not instinctively.

**Ascended Form - The Devoted (100%):**
Cavity fully closed - no longer needs to be filled. Light is its OWN, not stolen. Robes flow like living cloth. Face shows genuine emotion. Speaks in chorus of gentle voices - all the healers within, finally at peace. Weeps when allies hurt, rejoices when saved.

**Lore:**
Consumed those who gave life - healers, priests, mothers. Took their compassion, their healing touch. Still WANTS to heal - but twisted. Approaches wounded creatures and "heals" them by absorbing them. Doesn't understand why people flee its mercy. When purified, the stolen light becomes its own. Remembers every healer it consumed, honors them by continuing their work properly.

**Abilities (By Level):**
| Level | Ability | Description |
|-------|---------|-------------|
| 1 | Stolen Grace | Strong single-target heal |
| 5 | Merciful Light | AoE heal all allies |
| 10 | Absorb Suffering | Take damage instead of ally, heal self portion |
| 15 | Blessed Touch | Remove one debuff from ally |
| 20 | Sanctuary | Party-wide damage reduction 2 turns |
| 28 | **Divine Devotion** | **(100% Ascension)** Full party heal + cleanse all debuffs + revive fallen, once per battle |

**Base Stats (Level 1):**
```
HP: 50 | MP: 40 | ATK: 3 | DEF: 8 | MAG: 18 | RES: 15 | SPD: 6 | LUCK: 9
```

**Drops:** Healer's Essence, Stolen Light, (rare) Tear of Compassion

---

#### 7. FLICKER → STORMWING → QUICKSILVER
**Brand:** SURGE (Speed/Burst) | **Path Alignment:** FANGBORN/UNCHAINED

**Corrupted Form - Flicker (25-49%):**
Barely visible. A blur. An afterimage. Occasionally stops for fraction of second: something insectoid but wrong, made of consumed wings (bird, bat, butterfly, dragonfly) all layered. Dozens of legs from fast creatures - rabbit, deer, fox. No solid core - just motion given form. Vibrates intensely when still. Cannot stop.

**Awakened Form - Stormwing (50-99%):**
Form stabilizes enough to see: sleek, aerodynamic, still multi-winged but organized. Lightning crackles along edges. Can hold still for moments. Eyes visible - constantly tracking everything.

**Ascended Form - Quicksilver (100%):**
Beautiful, mercury-like creature. Flows between shapes but has a default form - elegant, winged, fast. Can be still. Discovered that moments contain thought, peace. Still impossibly fast, but CHOOSES when to move. Appreciates moments because it can finally experience them.

**Lore:**
Consumed nothing but speed. Ate wind where Veil cracks tore air. Devoured birds mid-flight. Took legs from anything that ran. Cannot stop - stillness is death. Exists between moments. Doesn't think - thinking is too slow. When purified, learns to be still. Just for a moment. Then another. Discovers the space between movements contains... thought. Peace. Darts around trainer excitedly but always returns. Learned that staying is not the same as stopping.

**Abilities (By Level):**
| Level | Ability | Description |
|-------|---------|-------------|
| 1 | Blur Strike | Fast attack, high evasion until next turn |
| 1 | Too Fast | Passive: 30% base evasion |
| 7 | Between Seconds | Act twice, weaker attacks |
| 12 | Interrupt | If enemy casting, instant attack + cancel |
| 18 | Hit and Run | Attack then swap to back row |
| 25 | **Quicksilver Blitz** | **(100% Ascension)** 6 rapid attacks on random enemies, each can crit, once per battle |

**Base Stats (Level 1):**
```
HP: 28 | MP: 10 | ATK: 11 | DEF: 4 | MAG: 8 | RES: 6 | SPD: 26 | LUCK: 12
```

**Drops:** Velocity Shard, Blur Feather, (rare) Moment Frozen

---

#### 8. THE WEEPING → GAZING DREAD → THE WITNESS
**Brand:** DREAD (Control/Debuff) | **Path Alignment:** IRONBOUND/VOIDTOUCHED

**Corrupted Form - The Weeping (25-49%):**
Floating cluster of eyes - dozens, all different sizes and colors, harvested from various creatures. Connected by wet, red threads of tissue. All look in different directions, constantly crying dark oily fluid. No mouth. No body. Just eyes. Watches. Tracks all enemies simultaneously.

**Awakened Form - Gazing Dread (50-99%):**
Eyes organize into patterns. Some close permanently. Remaining eyes larger, more focused. Tears become crystalline, less disturbing. A central "main" eye emerges. Can focus instead of seeing everything.

**Ascended Form - The Witness (100%):**
Most eyes closed, keeping only a few that hold beautiful memories. Central eye dominant, wise. No longer crying - at peace with what it's seen. Becomes oracle, seer. Speaks through visions, sharing what it sees with those it trusts. Never takes another eye - knows sight is a gift.

**Lore:**
Became obsessed with SEEING. Consumed only eyes - plucking them from animals, sleeping travelers, the dying. Sees everything, understands nothing. Every eye carries fragments of former owner's last sight. Haunted by visions it can't process - a child's face, a sunset, a lover's smile, a blade. Weeps because it cannot stop seeing. When purified, chooses which eyes to keep - those with beautiful memories. Uses vision for guidance, not hunting.

**Abilities (By Level):**
| Level | Ability | Description |
|-------|---------|-------------|
| 1 | Witnessed | Attack that always hits |
| 5 | Glimpse of Death | Shows target worst memory, chance Fear |
| 10 | Many-Eyed Gaze | Debuff increases damage taken |
| 14 | Shared Vision | Buff ally accuracy significantly |
| 20 | Foresight | Party-wide evasion buff |
| 26 | **Absolute Vision** | **(100% Ascension)** All enemies: accuracy debuff + cannot evade + revealed weaknesses, 3 turns, once per battle |

**Base Stats (Level 1):**
```
HP: 30 | MP: 25 | ATK: 4 | DEF: 5 | MAG: 16 | RES: 12 | SPD: 8 | LUCK: 10
```

**Drops:** Weeping Eye, Vision Thread, (rare) Memory Lens

---

### BOSS: THE CONGREGATION (Not Capturable)

**Visual:**
Massive - 15 feet tall. Writhing pillar of absorbed humanity - dozens of bodies fused into one, still moving, still reaching. Faces press against surface from inside, mouths in silent screams. Arms extend at random angles. Dominant face at top - larger, more defined, the one who ate the others. Wears fragments of clothing from entire village: child's shoe, blacksmith's apron, bride's veil. Massive vertical mouth down entire torso.

**Lore:**
Was once a single Hollow that drifted into a small village during a festival. Everyone gathered. Everyone celebrating. Consumed them one by one over a single night - baker, smith, elder, children. Each absorption made it stronger, smarter, MORE. By dawn, village was empty. Speaks with their voices - sometimes one at a time, sometimes all at once. Introduces itself using all their names. Remembers all their memories. Considers itself a community.

First hint of what corruption TRULY becomes when allowed to grow. And it's still far from the Veil.

**Battle Mechanics:**

*Phase 1 (100-60% HP):*
- Takes 2 actions per turn
- *The Smith's Hammer* - Heavy physical
- *The Elder's Wisdom* - Buffs DEF/RES
- *The Mother's Embrace* - Grapple + DoT + heal self
- *Chorus of Names* - AoE Despair (reduces all stats)

*Phase 2 (60-30% HP):*
Torso-mouth opens. Desperate.
- *Invitation* - Grab attempt, must interrupt or massive damage + Devoured (removed 2 turns)
- *The Children's Laughter* - Chance Confuse all
- *Festival Dance* - Random multi-hit
- *"We Were Happy"* - Heals while showing visions

*Phase 3 (30-0% HP):*
Faces inside fight back. Village wants freedom.
- Sometimes skips turns (internal battle)
- *Desperate Consumption* - Stronger but erratic
- *"Help Us"* - Random debuffs (villagers sabotaging)
- *Final Gathering* - At 10% HP, must interrupt or heals 25%

**Defeat:**
Doesn't purify - RELEASES. Dozens of ghostly figures pour out, finally free. They don't speak, but bow before fading. Last to leave: small child who waves goodbye. What remains crumbles to nothing.

**Stats:**
```
HP: 450 | MP: 60 | ATK: 18 | DEF: 14 | MAG: 16 | RES: 12 | SPD: 7 | LUCK: 5
```

**Drops:**
- Congregation Core (guaranteed)
- Village Memory (guaranteed, key item)
- Festival Remnant (rare, accessory)
- Bride's Veil (rare, equipment)

---

## MONSTER ROSTER SUMMARY

### Basic Types (2 Evo, Fast XP, No Path Bonuses)
| # | Monster | Awakened | Role |
|---|---------|----------|------|
| 1 | Mawling | Loyal Maw | Basic DPS |
| 2 | Hollow | The Defined | Basic Support |
| 3 | Gluttony Polyp | Nurturing Sphere | Basic Healer |
| 4 | Skitter-Teeth | Bone Warden | Basic Tank |

### Path Types (3 Evo, Path Bonuses, Ascension Abilities)
| # | Monster | Awakened | Ascended | Brand | Path Alignment |
|---|---------|----------|----------|-------|----------------|
| 5 | Ravener | Bloodfang | Apex | SAVAGE | FANGBORN |
| 6 | The Vessel | Absolution | The Devoted | LEECH | VOIDTOUCHED |
| 7 | Flicker | Stormwing | Quicksilver | SURGE | FANGBORN/UNCHAINED |
| 8 | The Weeping | Gazing Dread | The Witness | DREAD | IRONBOUND/VOIDTOUCHED |

### Bosses (Not Capturable)
| # | Boss | Location |
|---|------|----------|
| 9 | The Congregation | Abandoned Village (Tutorial Area Boss) |

### Debug Console Commands
- `vera [0-3]` - Set VERA state
- `god` - Toggle god mode
- `money [amount]` - Add currency
- `setpath [value]` - Set alignment (-100 to 100)

---

## ALPHA ROADMAP

### PHASE 5: CONTENT CREATION ✅ COMPLETE
| Task | Status | Details |
|------|--------|---------|
| Starter Heroes | ✅ DONE | 4 heroes designed + .tres files created |
| Monster Data | ✅ DONE | 9 monster .tres files (8 Tier 1 + 1 Boss) |
| Hero Skill Data | ✅ DONE | 30 skill .tres files (all 4 hero skill trees) |
| Monster Skill Data | ✅ DONE | 55 skill .tres files (all 9 monsters) |
| PathSystem | ✅ DONE | path_system.gd autoload implemented |
| DataManager | ✅ DONE | data_manager.gd autoload for resource loading |
| Item Data | ✅ DONE | 33 item .tres files (19 consumables + 14 equipment) |

### PHASE 6: ART ASSETS ← Current Phase
| Task | Status | Details |
|------|--------|---------|
| Hero Art | ✅ DONE | 4 hero portraits generated with Scenario.gg |
| VERA Art | ✅ DONE | 4 VERA states generated with Scenario.gg |
| Monster Art | IN PROGRESS | 8 Tier 1 + Congregation boss (user generating) |
| Environments | Pending | Backgrounds, locations |
| UI/Icons | Pending | Menus, buttons, item icons |

### PHASE 7: MAP SYSTEM
| Task | Status | Details |
|------|--------|---------|
| TileMap Setup | Pending | Godot tilemap configuration |
| Tutorial Zone | Pending | First playable area |
| Area Transitions | Pending | Zone-to-zone movement |

### PHASE 8: ALPHA INTEGRATION
| Task | Status | Details |
|------|--------|---------|
| Wire Content | Pending | Connect all .tres to systems |
| Game Loop | Pending | Explore → Battle → Progress |
| VERA Content | Pending | Dialogue, demon bleed-through effects |

### PHASE 9: ALPHA TESTING
| Task | Status | Details |
|------|--------|---------|
| Playtest | Pending | Internal core loop testing |
| Balance Pass | Pending | Combat numbers tuning |
| Bug Fixing | Pending | Squash everything found |

---

## STARTER HEROES (Session 5 - Approved)

The 4 starter heroes are young prodigies of the Compact - the most promising of their generation. Each aligns with a Brand and Path, representing different combat roles.

### 1. REND (Physical DPS)
**Brand:** SAVAGE | **Path:** FANGBORN | **Role:** Physical DPS

**Visual Design:**
- Young beast hunter, late teens/early 20s
- Ritual scars across arms and face (self-inflicted tribal marks)
- Wild, partially braided dark red hair with bone beads
- Trophy cloak made from creature pelts and teeth
- Twin bone axes, jagged and brutal
- Lean, scarred physique - built for speed and violence
- Amber eyes with predatory intensity
- War paint in blood-red patterns

**Backstory:**
Born to a nomadic tribe that hunts corruption at the frontier. Rend earned their name at age 14 by single-handedly killing a Ravener that slaughtered half their hunting party. The Compact recruited them after they tracked and eliminated a pack of corrupted beasts that had been terrorizing trade routes. Rend doesn't talk much - prefers to let actions speak. Every scar is a lesson learned, every trophy a victory remembered. Fights with primal fury but tactical precision. Believes the only good corruption is dead corruption.

**Combat Style:**
- Bleed-focused attacks
- High crit rate
- Execute abilities on low HP targets
- Aggressive, front-line berserker

---

### 2. BASTION (Tank)
**Brand:** IRON | **Path:** IRONBOUND | **Role:** Tank/Protector

**Visual Design:**
- Massive frame, tall and broad (late teens but built like a fortress)
- Full plate armor, heavily customized with reinforced edges
- Tower shield almost as tall as they are, covered in dents and scratches
- Single-handed warhammer
- Helm with narrow eye slit, face rarely seen
- Cape torn and battle-worn but still proudly displayed
- Armor engraved with protective runes/symbols
- Steel gray and deep blue color scheme

**Backstory:**
Child of the Shield Wall - an ancient order sworn to hold the line against the Veil. Bastion was born in a fortress that overlooks the nearest Veil breach, raised to the sound of monsters dying against the walls. They've never known a world without the threat. At 16, during a breach event, they held a collapsed gatehouse alone for six hours while civilians evacuated. The Compact didn't recruit Bastion - they requested transfer, wanting to take the fight TO the corruption instead of just holding it back. Speaks in short sentences. Never retreats. Never leaves an ally behind.

**Combat Style:**
- Taunt and damage redirection
- Damage reduction abilities
- Shield bash stuns
- Party-wide defense buffs

---

### 3. MARROW (Healer)
**Brand:** LEECH | **Path:** VOIDTOUCHED | **Role:** Healer/Drain Support

**Visual Design:**
- Pale, almost ghostly complexion
- White-silver hair, long and flowing
- Eyes with faint purple luminescence
- Elegant dark robes with subtle anatomical patterns
- Carries glass vials of glowing life essence on belt
- Slender fingers with slightly elongated nails
- Calm, unsettling beauty
- Staff topped with a preserved heart in crystal
- Purple and black color scheme with bio-luminescent accents

**Backstory:**
Marrow was dying. A wasting disease consumed them from age 8, and by 12, they'd accepted death. Then they discovered they could take. Not maliciously - they touched a dying bird and felt its remaining life flow into them. The disease stopped. But so did the bird. They've spent years learning to control it, to take only what's freely given, to give back what they've stored. The Compact found them healing plague victims in a quarantined village - taking a little from many to give much to the sick. Marrow speaks softly, moves gently, and is acutely aware of the darkness within their gift. Heals through touch, taking damage into themselves and redistributing life force.

**Combat Style:**
- Drain healing (damage enemies to heal allies)
- Life transfer abilities
- Self-sacrifice heals (take damage to heal more)
- Debuff enemies to strengthen party

---

### 4. MIRAGE (Illusionist/Mage)
**Brand:** DREAD | **Path:** VOIDTOUCHED | **Role:** Illusionist/Control Mage

**Visual Design:**
- Eyes that reflect like mirrors, showing observers their own fears
- Androgynous features, gender ambiguous
- Robes that seem to shift patterns when not directly observed
- Short dark hair with silver streaks
- Carries an ornate staff with a crystalline eye at the top
- Moves in slightly wrong ways - too smooth, too precise
- Faint afterimages trail their movements
- Purple, silver, and black color scheme
- Often surrounded by faint visual distortions

**Backstory:**
No one knows where Mirage came from. They appeared at the Compact's gates three years ago, asking to join, knowing things they shouldn't know. Tests revealed they're human - mostly. Something touched them near the Veil as a child, and now they see what isn't there and can make others see it too. Reality is... flexible around them. The Compact keeps them close because the alternative - Mirage alone and unsupervised - is terrifying. They're genuinely trying to help, but their perception of "help" is sometimes skewed. Finds humor in situations others find horrifying. May or may not be aware of conversations happening in other rooms.

**Combat Style:**
- Fear and confusion infliction
- Accuracy debuffs (enemies miss from terror)
- Illusory clones and misdirection
- Mental damage abilities

---

### HERO STAT BASELINES (Level 1)

| Hero | HP | MP | ATK | DEF | MAG | RES | SPD | LUCK |
|------|----|----|-----|-----|-----|-----|-----|------|
| Rend | 42 | 8 | 18 | 8 | 4 | 6 | 14 | 8 |
| Bastion | 65 | 10 | 12 | 18 | 6 | 14 | 6 | 5 |
| Marrow | 38 | 35 | 6 | 8 | 16 | 12 | 8 | 10 |
| Mirage | 35 | 30 | 5 | 6 | 18 | 10 | 10 | 12 |

---

## HERO GENERATION PROMPTS (scenario.gg)

### REND (Physical DPS):
```
battlechasers style, young beast hunter warrior, late teens,
ritual scars on arms and face, wild dark red partially braided hair with bone beads,
trophy cloak of creature pelts and teeth, twin bone axes,
lean scarred muscular build, amber predatory eyes, blood-red war paint,
fierce aggressive stance, thick linework, cel shading, action pose
```

### BASTION (Tank):
```
battlechasers style, massive armored knight, late teens but huge build,
full plate armor steel gray and deep blue, enormous tower shield with battle damage,
single hand warhammer, narrow helm eye slit, torn battle cape,
protective runes engraved on armor, fortress stance,
thick linework, cel shading, defensive pose
```

### MARROW (Healer):
```
battlechasers style, pale ghostly healer, white silver flowing hair,
faint purple glowing eyes, elegant dark robes with anatomical patterns,
glass vials of glowing essence on belt, slender elongated fingers,
staff with preserved heart in crystal, unsettling calm beauty,
purple and black with bioluminescent accents, thick linework, cel shading
```

### MIRAGE (Illusionist):
```
battlechasers style, mysterious illusionist mage, androgynous features,
mirror-like reflective eyes, robes with shifting patterns,
short dark hair with silver streaks, ornate staff with crystalline eye,
faint visual distortions and afterimages, slightly wrong smooth movement,
purple silver and black colors, thick linework, cel shading, ethereal pose
```

### Negative Prompt (All Heroes):
```
blurry, low quality, amateur, sketch, realistic photo, 3d render,
chibi, deformed hands, extra fingers, watermark, signature
```

---

## VERA GENERATION PROMPTS (scenario.gg)

### INTERFACE (Pure Healer - 0-24%):
```
battlechasers style, beautiful young woman healer, soft kind teal eyes,
warm golden-auburn wavy hair, delicate silver circlet, cream white flowing dress,
warm skin, gentle caring smile, pointed ears, golden healing light,
thick linework, cel shading, bright warm palette
```

### FRACTURE (Subtle Wrongness - 25-59%):
```
battlechasers style, beautiful healer woman with unsettling shadow,
soft teal eyes with faint amber glow, golden-auburn hair moving unnaturally,
silver circlet with hairline crack, cream white dress,
shadow behind her shows horns and wings she doesnt have, subtle wrongness,
warm lighting with purple edge, thick linework, cel shading
```

### EMERGENCE (Transformation - 60-89%):
```
battlechasers style, healer woman transforming, teal eyes turning amber,
golden-auburn hair with dark streaks, cracked silver circlet,
cream dress torn revealing dark veins underneath, small black horns sprouting,
elongated fingers with dark nails, demonic silhouette looming behind her,
struggling expression, purple corruption creeping, thick linework, cel shading
```

### APOTHEOSIS (Full Beast - 90-100%):
```
battlechasers style, demonic beast form, massive horned demon with multiple wings,
pale woman embedded in chest like puppet or host, glowing ember eyes on demon head,
bladed limbs, bone spikes, tattered remains of cream dress on woman portion,
void energy, dark purple and amber palette, monstrous, thick linework, cel shading
```

### Negative Prompt (All States):
```
blurry, low quality, amateur, sketch, realistic photo, 3d render,
chibi, deformed hands, extra fingers, watermark, signature
```

---

*This file is automatically maintained by Claude Code sessions.*
