$path = "C:/Users/Conner/OneDrive/Documents/VeilbreakersGame/scripts/ui/battle_ui_controller.gd"
$content = Get-Content $path -Raw

# 1. Fix unused parameters - prefix with underscore
# _build_victory_rewards_display: party_data
$content = $content -replace 'func _build_victory_rewards_display\(([^)]*), party_data:', 'func _build_victory_rewards_display($1, _party_data:'

# show_defeat: data
$content = $content -replace 'func show_defeat\(data:', 'func show_defeat(_data:'

# flash_character: character and color
$content = $content -replace 'func flash_character\(character:', 'func flash_character(_character:'
$content = $content -replace 'func flash_character\(_character: CharacterBase, color:', 'func flash_character(_character: CharacterBase, _color:'

# shake_screen: intensity and duration
$content = $content -replace 'func shake_screen\(intensity:', 'func shake_screen(_intensity:'
$content = $content -replace 'func shake_screen\(_intensity: float, duration:', 'func shake_screen(_intensity: float, _duration:'

# _on_character_sprite_unhovered: character
$content = $content -replace 'func _on_character_sprite_unhovered\(character:', 'func _on_character_sprite_unhovered(_character:'

# _on_capture_attempt_started: vessel_tier
$content = $content -replace 'func _on_capture_attempt_started\(([^,]+), vessel_tier:', 'func _on_capture_attempt_started($1, _vessel_tier:'

# _on_capture_succeeded: bonus_data
$content = $content -replace 'func _on_capture_succeeded\(([^,]+), ([^,]+), bonus_data:', 'func _on_capture_succeeded($1, $2, _bonus_data:'

# 2. Fix unused variables - prefix with underscore
$content = $content -replace '\bvar original_color := ', 'var _original_color := '
$content = $content -replace '\bvar old_percent := ', 'var _old_percent := '

# 3. Fix shadowed variable 'char' (built-in function)
# Replace var char := with var char_ref :=
$content = $content -replace '\bvar char := ', 'var char_ref := '
$content = $content -replace '\bfor char in ', 'for char_ref in '
# Update usages after these declarations
$content = $content -replace '\bchar\.', 'char_ref.'
$content = $content -replace '\bchar\)', 'char_ref)'
$content = $content -replace '\bchar,', 'char_ref,'
$content = $content -replace '\bchar\]', 'char_ref]'

# 4. Fix shadowed variable 'name' (Node.name) - rename to monster_name or display_name_str
$content = $content -replace '\bvar name := monster\.display_name', 'var monster_display_name := monster.display_name'
$content = $content -replace '\bvar name := target\.display_name', 'var target_display_name := target.display_name'
# Update usages in capture-related functions
$content = $content -replace '(\t\t)name \+ " captured', '$1monster_display_name + " captured'
$content = $content -replace '(\t\t)name \+ " escaped', '$1target_display_name + " escaped'
$content = $content -replace '(\t)name \+ " resisted', '$1target_display_name + " resisted'
# Generic var name := patterns
$content = $content -replace '\bvar name := ([a-z_]+)\.display_name', 'var ${1}_display_name := $1.display_name'

# 5. Fix shadowed variable 'position' in show_damage_number
$content = $content -replace 'func show_damage_number\(([^,]+), position:', 'func show_damage_number($1, target_pos:'
# Update usages of position in that function
$content = $content -replace '(\tlabel\.global_position = )position\b', '$1target_pos'
$content = $content -replace 'label\.global_position = position\b', 'label.global_position = target_pos'

# 6. Remove trailing whitespace
$content = $content -replace '[ \t]+\r?\n', "`n"

# Write back
[System.IO.File]::WriteAllText($path, $content)
Write-Host "GDScript warnings fixed"
