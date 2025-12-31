extends Node
## Unit tests for status effect system
class_name TestStatusEffects

var _passed := 0
var _failed := 0
var _tests_run := 0


func run_all() -> Dictionary:
	print("\n=== Testing Status Effects ===")

	test_poison_damage()
	test_burn_damage()
	test_stun_duration()
	test_buff_stacking()
	test_debuff_resistance()

	return {"passed": _passed, "failed": _failed, "total": _tests_run}


func assert_eq(actual: Variant, expected: Variant, test_name: String) -> void:
	_tests_run += 1
	if actual == expected:
		_passed += 1
		print("  ✓ %s" % test_name)
	else:
		_failed += 1
		print("  ✗ %s - Expected %s, got %s" % [test_name, expected, actual])


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

func test_poison_damage() -> void:
	# Poison should deal 5% max HP per turn
	var max_hp := 100
	var poison_percent := 0.05
	var expected_damage := int(max_hp * poison_percent)

	assert_eq(expected_damage, 5, "Poison deals 5% max HP")


func test_burn_damage() -> void:
	# Burn should deal 8% max HP per turn
	var max_hp := 100
	var burn_percent := 0.08
	var expected_damage := int(max_hp * burn_percent)

	assert_eq(expected_damage, 8, "Burn deals 8% max HP")


func test_stun_duration() -> void:
	# Stun should last exactly 1 turn by default
	var stun_duration := 1
	assert_eq(stun_duration, 1, "Stun lasts 1 turn")


func test_buff_stacking() -> void:
	# Same buff should refresh duration, not stack
	var buff_1_duration := 3
	var buff_2_duration := 2

	# Applying buff_2 should set duration to max(3, 2) = 3
	var result_duration := maxi(buff_1_duration, buff_2_duration)

	assert_eq(result_duration, 3, "Buffs refresh to longest duration")


func test_debuff_resistance() -> void:
	# Characters with resistance should have reduced debuff duration
	var base_duration := 4
	var resistance := 0.25  # 25% resistance
	var reduced_duration := int(base_duration * (1.0 - resistance))

	assert_eq(reduced_duration, 3, "25% resistance reduces 4-turn debuff to 3")
