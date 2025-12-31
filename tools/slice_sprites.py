#!/usr/bin/env python3
"""
Sprite Sheet Slicer for VEILBREAKERS UI Assets
Slices sprite sheets into individual icons based on grid configuration.
"""

from PIL import Image
import os

# Base paths
ASSETS_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHEETS_DIR = os.path.join(ASSETS_DIR, "assets", "ui", "sheets")
ICONS_DIR = os.path.join(ASSETS_DIR, "assets", "ui", "icons")

# Sprite sheet configurations: (filename, output_folder, cols, rows, icon_names)
SHEET_CONFIGS = [
    {
        "sheet": "buffs_sheet.png",
        "output": "buffs",
        "cols": 4, "rows": 4,
        "names": [
            "attack_up", "defense_up", "speed_up", "regen",
            "shield", "critical_up", "focus", "berserk",
            "blessed", "inspired", "protected", "haste",
            "empower", "fortify", "clarity", "overcharge"
        ]
    },
    {
        "sheet": "debuffs_sheet.png",
        "output": "debuffs",
        "cols": 4, "rows": 4,
        "names": [
            "poison", "burn", "bleed", "curse",
            "slow", "weak", "blind", "silence",
            "stun", "frozen", "confusion", "fear",
            "doom", "corruption", "exhausted", "marked"
        ]
    },
    {
        "sheet": "actions_sheet.png",
        "output": "actions",
        "cols": 4, "rows": 2,
        "names": [
            "attack", "defend", "skill", "item",
            "flee", "wait", "analyze", "special"
        ]
    },
    {
        "sheet": "item_categories_sheet.png",
        "output": "items",
        "cols": 4, "rows": 2,
        "names": [
            "consumable", "equipment", "material", "key_item",
            "weapon", "armor", "accessory", "currency"
        ]
    },
    {
        "sheet": "quest_icons_sheet.png",
        "output": "quests",
        "cols": 4, "rows": 2,
        "names": [
            "main_quest", "side_quest", "completed", "failed",
            "interact", "talk", "examine", "collect"
        ]
    },
    {
        "sheet": "rarity_frames_sheet.png",
        "output": "rarity",
        "cols": 4, "rows": 2,
        "names": [
            "common", "uncommon", "rare", "epic",
            "legendary", "mythic", "set", "quest"
        ]
    },
    {
        "sheet": "hud_icons_sheet.png",
        "output": "hud",
        "cols": 4, "rows": 2,
        "names": [
            "menu", "inventory", "map", "quest_log",
            "party", "settings", "save", "help"
        ]
    },
    {
        "sheet": "minimap_icons_sheet.png",
        "output": "minimap",
        "cols": 4, "rows": 4,
        "names": [
            "player", "enemy", "npc", "quest_marker",
            "shop", "save_point", "treasure", "boss",
            "entrance", "exit", "locked", "hidden",
            "herb", "ore", "fishing", "danger"
        ]
    },
    {
        "sheet": "npc_icons_sheet.png",
        "output": "npcs",
        "cols": 4, "rows": 3,
        "names": [
            "merchant", "blacksmith", "alchemist", "innkeeper",
            "quest_giver", "trainer", "healer", "sage",
            "beast_handler", "corrupted", "vera_terminal", "mystery"
        ]
    }
]


def slice_sheet(config):
    """Slice a sprite sheet into individual icons."""
    sheet_path = os.path.join(SHEETS_DIR, config["sheet"])
    output_dir = os.path.join(ICONS_DIR, config["output"])

    if not os.path.exists(sheet_path):
        print(f"  [SKIP] Sheet not found: {config['sheet']}")
        return 0

    os.makedirs(output_dir, exist_ok=True)

    img = Image.open(sheet_path)
    width, height = img.size

    cols = config["cols"]
    rows = config["rows"]
    icon_width = width // cols
    icon_height = height // rows

    print(f"  Sheet: {width}x{height}, Grid: {cols}x{rows}, Icon: {icon_width}x{icon_height}")

    count = 0
    for row in range(rows):
        for col in range(cols):
            idx = row * cols + col
            if idx >= len(config["names"]):
                break

            name = config["names"][idx]
            left = col * icon_width
            top = row * icon_height
            right = left + icon_width
            bottom = top + icon_height

            icon = img.crop((left, top, right, bottom))

            # Save as PNG with transparency
            output_path = os.path.join(output_dir, f"{name}.png")
            icon.save(output_path, "PNG")
            count += 1

    return count


def main():
    print("=" * 50)
    print("VEILBREAKERS Sprite Sheet Slicer")
    print("=" * 50)

    total_icons = 0

    for config in SHEET_CONFIGS:
        print(f"\nProcessing: {config['sheet']}")
        count = slice_sheet(config)
        total_icons += count
        print(f"  Extracted: {count} icons -> {config['output']}/")

    print("\n" + "=" * 50)
    print(f"COMPLETE: {total_icons} icons extracted")
    print("=" * 50)


if __name__ == "__main__":
    main()
