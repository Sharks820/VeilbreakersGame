class_name BrandSystem
extends RefCounted
## BrandSystem: Centralized brand effectiveness and utility functions.
## Single source of truth for all brand-related calculations.
## Eliminates duplication between DamageCalculator, AIController, and VFX systems.

# =============================================================================
# BRAND NAME CONVERSION
# =============================================================================

## Convert Brand enum to string name
static func get_brand_name(brand: Enums.Brand) -> String:
	match brand:
		Enums.Brand.SAVAGE: return "SAVAGE"
		Enums.Brand.IRON: return "IRON"
		Enums.Brand.VENOM: return "VENOM"
		Enums.Brand.SURGE: return "SURGE"
		Enums.Brand.DREAD: return "DREAD"
		Enums.Brand.LEECH: return "LEECH"
		Enums.Brand.BLOODIRON: return "BLOODIRON"
		Enums.Brand.CORROSIVE: return "CORROSIVE"
		Enums.Brand.VENOMSTRIKE: return "VENOMSTRIKE"
		Enums.Brand.TERRORFLUX: return "TERRORFLUX"
		Enums.Brand.NIGHTLEECH: return "NIGHTLEECH"
		Enums.Brand.RAVENOUS: return "RAVENOUS"
		_: return "NONE"

## Convert string name to Brand enum
static func get_brand_from_name(name: String) -> Enums.Brand:
	match name.to_upper():
		"SAVAGE": return Enums.Brand.SAVAGE
		"IRON": return Enums.Brand.IRON
		"VENOM": return Enums.Brand.VENOM
		"SURGE": return Enums.Brand.SURGE
		"DREAD": return Enums.Brand.DREAD
		"LEECH": return Enums.Brand.LEECH
		"BLOODIRON": return Enums.Brand.BLOODIRON
		"CORROSIVE": return Enums.Brand.CORROSIVE
		"VENOMSTRIKE": return Enums.Brand.VENOMSTRIKE
		"TERRORFLUX": return Enums.Brand.TERRORFLUX
		"NIGHTLEECH": return Enums.Brand.NIGHTLEECH
		"RAVENOUS": return Enums.Brand.RAVENOUS
		_: return Enums.Brand.NONE

# =============================================================================
# PRIMARY BRAND (for hybrids)
# =============================================================================

## Get the PRIMARY brand for effectiveness calculations
## Hybrids use their primary component (70% influence)
static func get_primary_brand(brand: Enums.Brand) -> Enums.Brand:
	match brand:
		Enums.Brand.BLOODIRON:
			return Enums.Brand.SAVAGE
		Enums.Brand.CORROSIVE:
			return Enums.Brand.IRON
		Enums.Brand.VENOMSTRIKE:
			return Enums.Brand.VENOM
		Enums.Brand.TERRORFLUX:
			return Enums.Brand.SURGE
		Enums.Brand.NIGHTLEECH:
			return Enums.Brand.DREAD
		Enums.Brand.RAVENOUS:
			return Enums.Brand.LEECH
		_:
			return brand

## Get the PRIMARY brand as a string name
static func get_primary_brand_name(brand: Enums.Brand) -> String:
	var brand_name := get_brand_name(brand)
	if Constants.HYBRID_BRAND_COMPONENTS.has(brand_name):
		return Constants.HYBRID_BRAND_COMPONENTS[brand_name]["primary"]
	return brand_name

## Get the SECONDARY brand for hybrids (30% influence)
static func get_secondary_brand(brand: Enums.Brand) -> Enums.Brand:
	match brand:
		Enums.Brand.BLOODIRON:
			return Enums.Brand.IRON
		Enums.Brand.CORROSIVE:
			return Enums.Brand.VENOM
		Enums.Brand.VENOMSTRIKE:
			return Enums.Brand.SURGE
		Enums.Brand.TERRORFLUX:
			return Enums.Brand.DREAD
		Enums.Brand.NIGHTLEECH:
			return Enums.Brand.LEECH
		Enums.Brand.RAVENOUS:
			return Enums.Brand.SAVAGE
		_:
			return Enums.Brand.NONE

# =============================================================================
# BRAND EFFECTIVENESS
# =============================================================================

## Calculate brand effectiveness multiplier
## Wheel: SAVAGE → IRON → VENOM → SURGE → DREAD → LEECH → SAVAGE
static func get_effectiveness(attacker_brand: Enums.Brand, defender_brand: Enums.Brand) -> float:
	if attacker_brand == Enums.Brand.NONE or defender_brand == Enums.Brand.NONE:
		return Constants.BRAND_NEUTRAL

	var attacker_primary := get_primary_brand_name(attacker_brand)
	var defender_primary := get_primary_brand_name(defender_brand)

	# Check effectiveness matrix from Constants
	if Constants.BRAND_EFFECTIVENESS.has(attacker_primary):
		var matchups: Dictionary = Constants.BRAND_EFFECTIVENESS[attacker_primary]
		if matchups.has(defender_primary):
			return matchups[defender_primary]

	return Constants.BRAND_NEUTRAL

## Check if attacker has advantage over defender
static func has_advantage(attacker_brand: Enums.Brand, defender_brand: Enums.Brand) -> bool:
	return get_effectiveness(attacker_brand, defender_brand) >= Constants.BRAND_STRONG

## Check if attacker has disadvantage against defender
static func has_disadvantage(attacker_brand: Enums.Brand, defender_brand: Enums.Brand) -> bool:
	return get_effectiveness(attacker_brand, defender_brand) <= Constants.BRAND_WEAK

## Get the brand that this brand is strong against
static func get_strong_against(brand: Enums.Brand) -> Enums.Brand:
	var primary := get_primary_brand(brand)
	match primary:
		Enums.Brand.SAVAGE: return Enums.Brand.IRON
		Enums.Brand.IRON: return Enums.Brand.VENOM
		Enums.Brand.VENOM: return Enums.Brand.SURGE
		Enums.Brand.SURGE: return Enums.Brand.DREAD
		Enums.Brand.DREAD: return Enums.Brand.LEECH
		Enums.Brand.LEECH: return Enums.Brand.SAVAGE
		_: return Enums.Brand.NONE

## Get the brand that this brand is weak against
static func get_weak_against(brand: Enums.Brand) -> Enums.Brand:
	var primary := get_primary_brand(brand)
	match primary:
		Enums.Brand.SAVAGE: return Enums.Brand.LEECH
		Enums.Brand.IRON: return Enums.Brand.SAVAGE
		Enums.Brand.VENOM: return Enums.Brand.IRON
		Enums.Brand.SURGE: return Enums.Brand.VENOM
		Enums.Brand.DREAD: return Enums.Brand.SURGE
		Enums.Brand.LEECH: return Enums.Brand.DREAD
		_: return Enums.Brand.NONE

# =============================================================================
# BRAND CLASSIFICATION
# =============================================================================

## Check if a brand is a pure brand (not hybrid)
static func is_pure_brand(brand: Enums.Brand) -> bool:
	match brand:
		Enums.Brand.SAVAGE, Enums.Brand.IRON, Enums.Brand.VENOM, \
		Enums.Brand.SURGE, Enums.Brand.DREAD, Enums.Brand.LEECH:
			return true
		_:
			return false

## Check if a brand is a hybrid brand
static func is_hybrid_brand(brand: Enums.Brand) -> bool:
	match brand:
		Enums.Brand.BLOODIRON, Enums.Brand.CORROSIVE, Enums.Brand.VENOMSTRIKE, \
		Enums.Brand.TERRORFLUX, Enums.Brand.NIGHTLEECH, Enums.Brand.RAVENOUS:
			return true
		_:
			return false

## Get all pure brands
static func get_pure_brands() -> Array[Enums.Brand]:
	return [
		Enums.Brand.SAVAGE,
		Enums.Brand.IRON,
		Enums.Brand.VENOM,
		Enums.Brand.SURGE,
		Enums.Brand.DREAD,
		Enums.Brand.LEECH
	]

## Get all hybrid brands
static func get_hybrid_brands() -> Array[Enums.Brand]:
	return [
		Enums.Brand.BLOODIRON,
		Enums.Brand.CORROSIVE,
		Enums.Brand.VENOMSTRIKE,
		Enums.Brand.TERRORFLUX,
		Enums.Brand.NIGHTLEECH,
		Enums.Brand.RAVENOUS
	]

# =============================================================================
# EFFECTIVENESS TEXT (for UI)
# =============================================================================

## Get human-readable effectiveness text
static func get_effectiveness_text(modifier: float) -> String:
	if modifier >= Constants.BRAND_STRONG:
		return "Super Effective!"
	elif modifier > 1.0:
		return "Effective!"
	elif modifier <= Constants.BRAND_WEAK:
		return "Resisted..."
	elif modifier < 1.0:
		return "Not Very Effective..."
	return ""

## Get effectiveness text color for UI
static func get_effectiveness_color(modifier: float) -> Color:
	if modifier >= Constants.BRAND_STRONG:
		return Color(1.0, 0.8, 0.2)  # Gold - super effective
	elif modifier > 1.0:
		return Color(0.4, 0.9, 0.4)  # Green - effective
	elif modifier <= Constants.BRAND_WEAK:
		return Color(0.5, 0.5, 0.7)  # Gray-blue - resisted
	elif modifier < 1.0:
		return Color(0.7, 0.5, 0.5)  # Muted red - not effective
	return Color.WHITE

# =============================================================================
# BRAND STAT BONUSES
# =============================================================================

## Get stat bonuses for a brand from Constants
static func get_brand_bonuses(brand: Enums.Brand) -> Dictionary:
	var brand_name := get_brand_name(brand)
	if Constants.BRAND_BONUSES.has(brand_name):
		return Constants.BRAND_BONUSES[brand_name].duplicate()
	return {}

## Apply brand bonus to a stat value
static func apply_brand_bonus(base_value: float, brand: Enums.Brand, stat_key: String) -> float:
	var bonuses := get_brand_bonuses(brand)
	if bonuses.has(stat_key):
		return base_value * bonuses[stat_key]
	return base_value

# =============================================================================
# BRAND COLORS (moved from deprecated Helpers class)
# =============================================================================

## Get color for a Brand - primary color for UI and effects
static func get_brand_color(brand: Enums.Brand) -> Color:
	match brand:
		# Pure Brands
		Enums.Brand.SAVAGE:
			return Color("c73e3e")  # Red - Raw destruction
		Enums.Brand.IRON:
			return Color("7b8794")  # Steel gray - Unyielding defense
		Enums.Brand.VENOM:
			return Color("6b9b37")  # Green - Precision poison
		Enums.Brand.SURGE:
			return Color("4a90d9")  # Blue - Lightning speed
		Enums.Brand.DREAD:
			return Color("5d3e8c")  # Purple - Terror incarnate
		Enums.Brand.LEECH:
			return Color("c75b8a")  # Pink - Life drain
		# Hybrid Brands - use primary brand color
		Enums.Brand.BLOODIRON:
			return Color("c73e3e")  # SAVAGE primary (70%)
		Enums.Brand.CORROSIVE:
			return Color("7b8794")  # IRON primary (70%)
		Enums.Brand.VENOMSTRIKE:
			return Color("6b9b37")  # VENOM primary (70%)
		Enums.Brand.TERRORFLUX:
			return Color("4a90d9")  # SURGE primary (70%)
		Enums.Brand.NIGHTLEECH:
			return Color("5d3e8c")  # DREAD primary (70%)
		Enums.Brand.RAVENOUS:
			return Color("c75b8a")  # LEECH primary (70%)
		Enums.Brand.NONE, _:
			return Color.WHITE

## Get brand color from string name (convenience method)
static func get_brand_color_by_name(brand_name: String) -> Color:
	var brand := get_brand_from_name(brand_name)
	return get_brand_color(brand)

## Get brand glow color (secondary/highlight color for effects)
static func get_brand_glow_color(brand: Enums.Brand) -> Color:
	match brand:
		Enums.Brand.SAVAGE, Enums.Brand.BLOODIRON, Enums.Brand.RAVENOUS:
			return Color("ff6b6b")
		Enums.Brand.IRON, Enums.Brand.CORROSIVE:
			return Color("a8b5c4")
		Enums.Brand.VENOM, Enums.Brand.VENOMSTRIKE:
			return Color("9acd32")
		Enums.Brand.SURGE, Enums.Brand.TERRORFLUX:
			return Color("87ceeb")
		Enums.Brand.DREAD, Enums.Brand.NIGHTLEECH:
			return Color("9370db")
		Enums.Brand.LEECH:
			return Color("ff91af")
		_:
			return Color.GRAY
