$path = "C:/Users/Conner/OneDrive/Documents/VeilbreakersGame/scripts/ui/battle_ui_controller.gd"
$content = Get-Content $path -Raw

# 1. Fix unused signal - prefix with underscore
$content = $content -replace 'signal target_confirmed\(target: CharacterBase\)', 'signal _target_confirmed(target: CharacterBase)  # Prefixed - reserved for future use'

# 2. Fix remaining 'char' usages that weren't renamed to 'char_item'
$content = $content -replace 'and char in valid_targets:', 'and char_item in valid_targets:'
$content = $content -replace 'if char is Monster and \(char as Monster\)\.is_corrupted:', 'if char_item is Monster and (char_item as Monster).is_corrupted:'

# Write back
[System.IO.File]::WriteAllText($path, $content)
Write-Host "Final warning fixes applied"
