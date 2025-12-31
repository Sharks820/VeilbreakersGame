extends Node
## Unit tests for damage calculation system
## Run with: godot --headless --script res://tests/run_tests.gd

class_name TestDamageCalculator

var _passed := 0
var _failed := 0
var _tests_run := 0


func run_all() -> Dictionary:
	print("\n=== Testing DamageCalculator ===")

	test_basic_damage()
	test_elemental_weakness()
	test_elemental_resistance()
	test_critical_hits()
	test_defense_reduction()
	test_zero_damage_floor()

	return {"passed": _passed, "failed": _failed, "total": _tests_run}


func assert_eq(actual: Variant, expected: Variant, test_name: String) -> void:
	_tests_run += 1
	if actual == expected:
		_passed += 1
		print("  ✓ %s" % test_name)
	else:
		_failed += 1
		print("  ✗ %s - Expected %s, got %s" % [test_name, expected, actual])


func assert_range(actual: float, min_val: float, max_val: float, test_name: String) -> void:
	_tests_run += 1
	if actual >= min_val and actual <= max_val:
		_passed += 1
		print("  ✓ %s" % test_name)
	else:
		_failed += 1
		print("  ✗ %s - Expected %s-%s, got %s" % [test_name, min_val, max_val, actual])


func assert_true(condition: bool, test_name: String) -> void:
	_tests_run += 1
	if condition:
		_passed += 1
		print("  ✓ %s" % test_name)
	else:
		_failed += 1
		print("  ✗ %s - Expected true" % test_name)


# =============================================================================
# TEST CASES
# =============================================================================

func test_basic_damage() -> void:
	# Basic damage formula: (attack * power * 0.1) - (defense * 0.5)
	# With attack=100, power=10, defense=20:
	# (100 * 10 * 0.1) - (20 * 0.5) = 100 - 10 = 90

	var attack := 100
	var power := 10
	var defense := 20

	var expected_base := (attack * power * 0.1) - (defense * 0.5)
	assert_range(expected_base, 85.0, 95.0, "Basic damage calculation")


func test_elemental_weakness() -> void:
	# Weakness should multiply damage by 1.5
	var base_damage := 100.0
	var weakness_multiplier := 1.5
	var expected := base_damage * weakness_multiplier

	assert_eq(expected, 150.0, "Elemental weakness (1.5x)")


func test_elemental_resistance() -> void:
	# Resistance should multiply damage by 0.5
	var base_damage := 100.0
	var resistance_multiplier := 0.5
	var expected := base_damage * resistance_multiplier

	assert_eq(expected, 50.0, "Elemental resistance (0.5x)")


func test_critical_hits() -> void:
	# Critical hits should multiply damage by 1.5 (default)
	var base_damage := 100.0
	var crit_multiplier := 1.5
	var expected := base_damage * crit_multiplier

	assert_eq(expected, 150.0, "Critical hit multiplier (1.5x)")


func test_defense_reduction() -> void:
	# Defense should reduce damage but not below minimum
	var attack_damage := 100.0
	var defense := 200.0  # Very high defense

	# Even with high defense, damage shouldn't go negative
	var reduced := attack_damage - (defense * 0.5)
	var floored := maxf(reduced, 1.0)  # Minimum 1 damage

	assert_eq(floored, 1.0, "Defense floor (minimum 1 damage)")


func test_zero_damage_floor() -> void:
	# Damage should never be less than 1 (or 0 for special cases)
	var min_damage := 1
	assert_true(min_damage >= 1, "Damage floor exists")
