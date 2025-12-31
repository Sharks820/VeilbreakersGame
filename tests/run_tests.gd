extends SceneTree
## Test Runner - Run all unit and integration tests
## Usage: godot --headless --script res://tests/run_tests.gd

var _total_passed := 0
var _total_failed := 0
var _total_tests := 0


func _init() -> void:
	print("=" * 60)
	print("VEILBREAKERS TEST SUITE")
	print("=" * 60)
	print()

	# Run unit tests
	_run_unit_tests()

	# Run integration tests
	_run_integration_tests()

	# Summary
	_print_summary()

	# Exit with appropriate code
	quit(0 if _total_failed == 0 else 1)


func _run_unit_tests() -> void:
	print("UNIT TESTS")
	print("-" * 40)

	# Load and run each test class
	var test_files := [
		"res://tests/unit/test_damage_calculator.gd",
		"res://tests/unit/test_status_effects.gd",
		"res://tests/unit/test_inventory.gd",
	]

	for test_path in test_files:
		if ResourceLoader.exists(test_path):
			var test_script := load(test_path)
			if test_script:
				var test_instance = test_script.new()
				if test_instance.has_method("run_all"):
					var results: Dictionary = test_instance.run_all()
					_total_passed += results.get("passed", 0)
					_total_failed += results.get("failed", 0)
					_total_tests += results.get("total", 0)
				test_instance.free()
		else:
			print("  [SKIP] %s (not found)" % test_path)

	print()


func _run_integration_tests() -> void:
	print("INTEGRATION TESTS")
	print("-" * 40)

	# These tests require game systems to be loaded
	var test_files := [
		"res://tests/integration/test_battle_flow.gd",
		"res://tests/integration/test_save_load.gd",
	]

	for test_path in test_files:
		if ResourceLoader.exists(test_path):
			var test_script := load(test_path)
			if test_script:
				var test_instance = test_script.new()
				if test_instance.has_method("run_all"):
					var results: Dictionary = test_instance.run_all()
					_total_passed += results.get("passed", 0)
					_total_failed += results.get("failed", 0)
					_total_tests += results.get("total", 0)
				test_instance.free()
		else:
			print("  [SKIP] %s (not found)" % test_path)

	print()


func _print_summary() -> void:
	print("=" * 60)
	print("TEST SUMMARY")
	print("=" * 60)
	print()
	print("  Total Tests: %d" % _total_tests)
	print("  Passed:      %d" % _total_passed)
	print("  Failed:      %d" % _total_failed)
	print()

	if _total_failed == 0:
		print("\033[92m✓ ALL TESTS PASSED\033[0m")
	else:
		print("\033[91m✗ %d TESTS FAILED\033[0m" % _total_failed)

	print()
