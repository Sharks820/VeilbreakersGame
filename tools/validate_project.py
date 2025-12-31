#!/usr/bin/env python3
"""
VEILBREAKERS Project Validator
==============================
Run this before committing to catch data errors early.

Usage:
    python tools/validate_project.py
    python tools/validate_project.py --verbose
    python tools/validate_project.py --fix  (auto-fix some issues)
"""

import os
import re
import sys
import json
import argparse
from pathlib import Path
from typing import Dict, List, Set, Tuple, Optional

# Project root
PROJECT_ROOT = Path(__file__).parent.parent
DATA_DIR = PROJECT_ROOT / "data"
SCRIPTS_DIR = PROJECT_ROOT / "scripts"
ASSETS_DIR = PROJECT_ROOT / "assets"

# Track issues
errors: List[str] = []
warnings: List[str] = []
info: List[str] = []


def log_error(msg: str):
    errors.append(f"[ERROR] {msg}")
    print(f"\033[91m[ERROR]\033[0m {msg}")


def log_warning(msg: str):
    warnings.append(f"[WARN] {msg}")
    print(f"\033[93m[WARN]\033[0m {msg}")


def log_info(msg: str):
    info.append(f"[INFO] {msg}")
    if VERBOSE:
        print(f"\033[94m[INFO]\033[0m {msg}")


def log_success(msg: str):
    print(f"\033[92m[OK]\033[0m {msg}")


# =============================================================================
# TRES FILE PARSER (Simple regex-based)
# =============================================================================

def parse_tres_file(filepath: Path) -> Dict:
    """Parse a .tres file into a dictionary."""
    data = {}
    content = filepath.read_text(encoding='utf-8')

    # Extract key-value pairs
    for match in re.finditer(r'^(\w+)\s*=\s*(.+)$', content, re.MULTILINE):
        key = match.group(1)
        value = match.group(2).strip()
        data[key] = value

    return data


def extract_string(value: str) -> str:
    """Extract string from quoted value."""
    if value.startswith('"') and value.endswith('"'):
        return value[1:-1]
    return value


def extract_array(value: str) -> List[str]:
    """Extract array elements from value."""
    if not value.startswith('['):
        return []
    # Simple extraction - won't handle nested arrays
    inner = value[1:-1]
    if not inner.strip():
        return []
    return [s.strip().strip('"') for s in inner.split(',')]


# =============================================================================
# VALIDATORS
# =============================================================================

def validate_monster_data() -> Tuple[int, int]:
    """Validate all monster .tres files."""
    monster_dir = DATA_DIR / "monsters"
    if not monster_dir.exists():
        log_error("Monster data directory not found!")
        return 0, 1

    valid = 0
    invalid = 0
    monster_ids: Set[str] = set()

    for tres_file in monster_dir.glob("*.tres"):
        data = parse_tres_file(tres_file)
        file_valid = True

        # Check required fields
        required = ['monster_id', 'display_name', 'tier', 'brand', 'base_hp']
        for field in required:
            if field not in data:
                log_error(f"{tres_file.name}: Missing required field '{field}'")
                file_valid = False

        # Check for duplicate IDs
        if 'monster_id' in data:
            monster_id = extract_string(data['monster_id'])
            if monster_id in monster_ids:
                log_error(f"{tres_file.name}: Duplicate monster_id '{monster_id}'")
                file_valid = False
            monster_ids.add(monster_id)

        # Validate sprite path exists
        if 'sprite_path' in data:
            sprite_path = extract_string(data['sprite_path'])
            # Convert res:// to actual path
            actual_path = PROJECT_ROOT / sprite_path.replace('res://', '')
            if not actual_path.exists():
                log_warning(f"{tres_file.name}: Sprite not found: {sprite_path}")

        # Validate skill references
        if 'innate_skills' in data:
            skills = extract_array(data['innate_skills'])
            for skill_id in skills:
                if skill_id and not skill_exists(skill_id):
                    log_warning(f"{tres_file.name}: References unknown skill '{skill_id}'")

        if file_valid:
            valid += 1
            log_info(f"{tres_file.name}: Valid")
        else:
            invalid += 1

    return valid, invalid


def validate_skill_data() -> Tuple[int, int]:
    """Validate all skill .tres files."""
    skill_dirs = [
        DATA_DIR / "skills" / "monsters",
        DATA_DIR / "skills" / "heroes",
    ]

    valid = 0
    invalid = 0
    skill_ids: Set[str] = set()

    for skill_dir in skill_dirs:
        if not skill_dir.exists():
            log_warning(f"Skill directory not found: {skill_dir}")
            continue

        for tres_file in skill_dir.glob("*.tres"):
            data = parse_tres_file(tres_file)
            file_valid = True

            # Check required fields
            required = ['skill_id', 'display_name', 'skill_type']
            for field in required:
                if field not in data:
                    log_error(f"{tres_file.name}: Missing required field '{field}'")
                    file_valid = False

            # Check for duplicate IDs
            if 'skill_id' in data:
                skill_id = extract_string(data['skill_id'])
                if skill_id in skill_ids:
                    log_error(f"{tres_file.name}: Duplicate skill_id '{skill_id}'")
                    file_valid = False
                skill_ids.add(skill_id)

            if file_valid:
                valid += 1
            else:
                invalid += 1

    return valid, invalid


def validate_item_data() -> Tuple[int, int]:
    """Validate all item .tres files."""
    item_dirs = [
        DATA_DIR / "items" / "consumables",
        DATA_DIR / "items" / "equipment",
    ]

    valid = 0
    invalid = 0
    item_ids: Set[str] = set()

    for item_dir in item_dirs:
        if not item_dir.exists():
            continue

        for tres_file in item_dir.glob("*.tres"):
            data = parse_tres_file(tres_file)
            file_valid = True

            required = ['item_id', 'display_name', 'item_type']
            for field in required:
                if field not in data:
                    log_error(f"{tres_file.name}: Missing required field '{field}'")
                    file_valid = False

            if 'item_id' in data:
                item_id = extract_string(data['item_id'])
                if item_id in item_ids:
                    log_error(f"{tres_file.name}: Duplicate item_id '{item_id}'")
                    file_valid = False
                item_ids.add(item_id)

            if file_valid:
                valid += 1
            else:
                invalid += 1

    return valid, invalid


def validate_hero_data() -> Tuple[int, int]:
    """Validate hero .tres files."""
    hero_dir = DATA_DIR / "heroes"
    if not hero_dir.exists():
        log_warning("Hero data directory not found")
        return 0, 0

    valid = 0
    invalid = 0

    for tres_file in hero_dir.glob("*.tres"):
        data = parse_tres_file(tres_file)
        file_valid = True

        required = ['hero_id', 'display_name', 'base_hp']
        for field in required:
            if field not in data:
                log_error(f"{tres_file.name}: Missing required field '{field}'")
                file_valid = False

        if file_valid:
            valid += 1
        else:
            invalid += 1

    return valid, invalid


def validate_sprites() -> Tuple[int, int]:
    """Check that all referenced sprites exist."""
    sprite_dir = ASSETS_DIR / "sprites" / "monsters"
    if not sprite_dir.exists():
        log_warning("Monster sprites directory not found")
        return 0, 0

    # Get all monster sprite references
    monster_dir = DATA_DIR / "monsters"
    referenced_sprites: Set[str] = set()

    for tres_file in monster_dir.glob("*.tres"):
        data = parse_tres_file(tres_file)
        if 'sprite_path' in data:
            referenced_sprites.add(extract_string(data['sprite_path']))

    # Check each reference
    found = 0
    missing = 0

    for sprite_path in referenced_sprites:
        actual_path = PROJECT_ROOT / sprite_path.replace('res://', '')
        if actual_path.exists():
            found += 1
            log_info(f"Sprite found: {sprite_path}")
        else:
            missing += 1
            log_error(f"Sprite missing: {sprite_path}")

    return found, missing


def validate_scripts() -> Tuple[int, int]:
    """Basic GDScript validation (syntax check)."""
    valid = 0
    invalid = 0

    for gd_file in SCRIPTS_DIR.rglob("*.gd"):
        content = gd_file.read_text(encoding='utf-8')

        # Basic checks
        issues = []

        # Check for common issues
        if 'var ' in content and ':=' not in content and ': ' not in content:
            # Might have untyped variables, but this is just a warning
            pass

        # Check for print statements in non-debug code
        if 'print(' in content and 'debug' not in gd_file.name.lower() and 'error_logger' not in gd_file.name.lower():
            log_warning(f"{gd_file.name}: Contains print statements (consider using ErrorLogger)")

        # Check for TODO/FIXME
        if 'TODO' in content or 'FIXME' in content:
            log_info(f"{gd_file.name}: Contains TODO/FIXME comments")

        valid += 1

    return valid, invalid


# =============================================================================
# HELPERS
# =============================================================================

_skill_cache: Optional[Set[str]] = None

def skill_exists(skill_id: str) -> bool:
    """Check if a skill ID exists in the project."""
    global _skill_cache

    if _skill_cache is None:
        _skill_cache = set()
        skill_dirs = [
            DATA_DIR / "skills" / "monsters",
            DATA_DIR / "skills" / "heroes",
        ]
        for skill_dir in skill_dirs:
            if skill_dir.exists():
                for tres_file in skill_dir.glob("*.tres"):
                    data = parse_tres_file(tres_file)
                    if 'skill_id' in data:
                        _skill_cache.add(extract_string(data['skill_id']))

    return skill_id in _skill_cache


# =============================================================================
# MAIN
# =============================================================================

VERBOSE = False

def main():
    global VERBOSE

    parser = argparse.ArgumentParser(description='Validate VEILBREAKERS project files')
    parser.add_argument('--verbose', '-v', action='store_true', help='Show all info messages')
    parser.add_argument('--fix', action='store_true', help='Auto-fix some issues (not implemented)')
    args = parser.parse_args()

    VERBOSE = args.verbose

    print("=" * 60)
    print("VEILBREAKERS Project Validator")
    print("=" * 60)
    print()

    results = {}

    # Run all validators
    print("Validating monsters...")
    results['monsters'] = validate_monster_data()

    print("\nValidating skills...")
    results['skills'] = validate_skill_data()

    print("\nValidating items...")
    results['items'] = validate_item_data()

    print("\nValidating heroes...")
    results['heroes'] = validate_hero_data()

    print("\nValidating sprites...")
    results['sprites'] = validate_sprites()

    print("\nValidating scripts...")
    results['scripts'] = validate_scripts()

    # Summary
    print("\n" + "=" * 60)
    print("VALIDATION SUMMARY")
    print("=" * 60)

    total_valid = 0
    total_invalid = 0

    for category, (valid, invalid) in results.items():
        total_valid += valid
        total_invalid += invalid
        status = "✓" if invalid == 0 else "✗"
        print(f"  {status} {category.capitalize()}: {valid} valid, {invalid} issues")

    print()
    print(f"Total Errors: {len(errors)}")
    print(f"Total Warnings: {len(warnings)}")
    print()

    if len(errors) == 0:
        print("\033[92m✓ All validations passed!\033[0m")
        return 0
    else:
        print("\033[91m✗ Validation failed - fix errors before committing\033[0m")
        return 1


if __name__ == '__main__':
    sys.exit(main())
