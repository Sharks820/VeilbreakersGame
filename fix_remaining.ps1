$path = "C:/Users/Conner/OneDrive/Documents/VeilbreakersGame/scripts/ui/battle_ui_controller.gd"
$content = Get-Content $path -Raw

# 1. Fix integer division on line 2346
# Change: exp_gained / maxi(1, alive_count)
# To: int(float(exp_gained) / float(maxi(1, alive_count)))
# Or simpler: just ensure we want integer result, add explicit int()
$content = $content -replace 'var xp_per_member: int = exp_gained / maxi\(1, alive_count\) if alive_count > 0 else 0', 'var xp_per_member: int = int(float(exp_gained) / maxi(1, alive_count)) if alive_count > 0 else 0'

# 2. Fix incompatible ternary on line 4257
# Change: -330 (int) to -330.0 (float)
$content = $content -replace '_log_start_top if _log_start_top != 0\.0 else -330\b', '_log_start_top if _log_start_top != 0.0 else -330.0'

# 3. Fix shadowed 'name' variables in capture-related functions (lines 4483, 4538, 4564, 4601, 4622)
# These all follow the pattern: var name: String = monster.character_name if ...
$content = $content -replace 'var name: String = monster\.character_name if "character_name" in monster else "Monster"', 'var monster_name: String = monster.character_name if "character_name" in monster else "Monster"'

# Also update usages of 'name' in the format strings after these declarations
# Pattern: % [name, ...] or % name
$content = $content -replace '\[name, chance \* 100\]', '[monster_name, chance * 100]'
$content = $content -replace '\[name, reduction\]', '[monster_name, reduction]'
$content = $content -replace '" % name\)', '" % monster_name)'
$content = $content -replace '\[name, method_name\]', '[monster_name, method_name]'

# Write back
[System.IO.File]::WriteAllText($path, $content)
Write-Host "Remaining issues fixed"
