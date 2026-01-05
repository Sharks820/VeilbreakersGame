@tool
extends EditorScript
## Duplication Detector - Scans codebase for anti-patterns
## Run via: Godot Editor > Script > Run (Ctrl+Shift+X)
##
## This tool identifies code that should use centralized utilities instead
## of manual implementations.

const SCRIPTS_PATH := "res://scripts/"
const EXCLUDE_PATHS := ["res://scripts/utils/", "res://scripts/tools/"]

# Anti-patterns to detect with their recommended replacements
const ANTI_PATTERNS := {
	# UIStyleFactory patterns
	"StyleBoxFlat.new()": "UIStyleFactory.create_panel_style() or create_dark_panel()",
	"add_theme_font_size_override": "UIStyleFactory.FONT_* constants",
	"add_theme_color_override(\"font_color\"": "UIStyleFactory.COLOR_* constants",

	# NodeHelpers patterns
	"is_instance_valid(": "NodeHelpers.is_valid() or safe_free()",
	"queue_free()": "NodeHelpers.safe_free() if preceded by validity check",
	"for child in": "NodeHelpers.for_each_child() or clear_children()",
	".get_children()": "NodeHelpers.get_children_of_type() if filtering",

	# StringHelpers patterns
	"\"%d/%d\" %": "StringHelpers.format_hp() or format_mp()",
	"\"%.0f%%\"": "StringHelpers.format_percent()",
	"\"Lv. %d\"": "StringHelpers.format_level()",
	".replace(\"_\", \" \")": "StringHelpers.enum_to_display()",

	# AnimationEffects patterns
	".set_ease(Tween.EASE_": "AnimationEffects.ease_out_back() etc",
	"create_tween().set_parallel": "AnimationEffects.create_parallel_tween()",
	"modulate.a = 0": "AnimationEffects.fade_in() / popup_entrance()",
	"tween_property.*\"scale\".*1.05": "AnimationEffects.button_hover()",

	# Constants patterns
	"create_timer(0.3)": "Constants.WAIT_SHORT",
	"create_timer(0.5)": "Constants.WAIT_STANDARD",
	"create_timer(0.2)": "Constants.WAIT_QUICK",

	# MathHelpers patterns
	"float(.*) / float(": "MathHelpers.get_hp_percent() or safe_divide()",
	"clampf(.*0.05.*0.95": "MathHelpers.clamp_probability()",
}

# Patterns that are OK in utility files but bad elsewhere
const UTILITY_ONLY_PATTERNS := [
	"StyleBoxFlat.new()",
	"Label.new()",
	"ProgressBar.new()",
	"Button.new()",
]

var results: Dictionary = {}
var total_issues := 0


func _run() -> void:
	print("\n" + "=".repeat(60))
	print("DUPLICATION DETECTOR - Scanning for anti-patterns...")
	print("=".repeat(60) + "\n")

	results.clear()
	total_issues = 0

	scan_directory(SCRIPTS_PATH)

	print_results()


func scan_directory(path: String) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		push_error("Cannot open directory: %s" % path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		var full_path := path.path_join(file_name)

		if dir.current_is_dir():
			if not is_excluded(full_path):
				scan_directory(full_path)
		elif file_name.ends_with(".gd"):
			if not is_excluded(full_path):
				scan_file(full_path)

		file_name = dir.get_next()

	dir.list_dir_end()


func is_excluded(path: String) -> bool:
	for exclude in EXCLUDE_PATHS:
		if path.begins_with(exclude):
			return true
	return false


func scan_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return

	var content := file.get_as_text()
	var lines := content.split("\n")
	var file_issues: Array = []

	for i in lines.size():
		var line := lines[i]
		var line_num := i + 1

		# Skip comments
		if line.strip_edges().begins_with("#"):
			continue

		for pattern in ANTI_PATTERNS:
			if pattern in line:
				file_issues.append({
					"line": line_num,
					"pattern": pattern,
					"suggestion": ANTI_PATTERNS[pattern],
					"code": line.strip_edges().substr(0, 80)
				})
				total_issues += 1

	if not file_issues.is_empty():
		results[path] = file_issues


func print_results() -> void:
	if results.is_empty():
		print("✅ No anti-patterns detected! Code is clean.")
		return

	print("⚠️  ANTI-PATTERNS DETECTED\n")

	# Sort by number of issues
	var sorted_paths := results.keys()
	sorted_paths.sort_custom(func(a, b): return results[a].size() > results[b].size())

	for path in sorted_paths:
		var issues: Array = results[path]
		var short_path := path.replace("res://scripts/", "")
		print("📄 %s (%d issues)" % [short_path, issues.size()])

		for issue in issues:
			print("   Line %d: %s" % [issue["line"], issue["pattern"]])
			print("   → Use: %s" % issue["suggestion"])
			print("   Code: %s" % issue["code"])
			print("")

	print("=".repeat(60))
	print("SUMMARY: %d anti-patterns found in %d files" % [total_issues, results.size()])
	print("=".repeat(60))
	print("\nRun this regularly to prevent code duplication!")
	print("See docs/CODE_PATTERNS.md for the correct patterns.\n")
