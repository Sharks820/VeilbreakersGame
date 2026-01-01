# =============================================================================
# VEILBREAKERS - PATH-BRAND SYNERGY SYSTEM (v5.2)
# Calculates party bonuses when Hero Paths match Monster Brands
# =============================================================================
#
# SYNERGY TIERS:
# - 1 synergy monster = Tier 1 (half bonus, +5%)
# - 2 synergy monsters = Tier 2 (full bonus, +10%)
# - 3+ synergy monsters = Tier 3 (full + 5% secondary)
#
# ASCENDED BONUS: Ascended monsters count as 2 for synergy stacking
# PLAYER ALIGNMENT: +15% additional synergy if player is 55%+ aligned with Brand

class_name PathBrandSynergy
extends RefCounted

# =============================================================================
# SYNERGY CALCULATION
# =============================================================================

static func calculate_party_synergy(hero: Node, party_monsters: Array) -> Dictionary:
	## Calculate synergy bonuses for a hero based on their Path and party monsters
	var result := {
		"tier": 0,
		"synergy_count": 0,
		"bonuses": {},
		"synergy_monsters": []
	}
	
	if hero == null or party_monsters.is_empty():
		return result
	
	# Get hero's Path
	var hero_path: String = ""
	if "current_path" in hero:
		hero_path = Enums.Path.keys()[hero.current_path]
	elif hero.has_method("get_path"):
		hero_path = hero.get_path()
	
	if hero_path == "" or hero_path == "NONE":
		return result
	
	# Get synergy brands for this path
	var synergy_brands: Array = Constants.PATH_SYNERGY_BRANDS.get(hero_path, [])
	if synergy_brands.is_empty():
		return result
	
	# Count synergy monsters (Ascended = 2)
	var synergy_count := 0
	for monster in party_monsters:
		if not is_instance_valid(monster):
			continue
		
		var monster_brand: String = ""
		if "brand" in monster:
			monster_brand = Enums.Brand.keys()[monster.brand]
		
		if monster_brand in synergy_brands:
			result.synergy_monsters.append(monster)
			
			# Ascended monsters count double
			if monster.has_method("is_ascended") and monster.is_ascended():
				synergy_count += Constants.SYNERGY_ASCENDED_COUNT_MULTIPLIER
			else:
				synergy_count += 1
	
	result.synergy_count = synergy_count
	
	# Determine tier
	if synergy_count >= Constants.SYNERGY_TIER_3_MONSTERS:
		result.tier = 3
	elif synergy_count >= Constants.SYNERGY_TIER_2_MONSTERS:
		result.tier = 2
	elif synergy_count >= Constants.SYNERGY_TIER_1_MONSTERS:
		result.tier = 1
	
	# Calculate bonuses
	if result.tier > 0:
		result.bonuses = _get_tier_bonuses(hero_path, result.tier)
	
	# Add player alignment bonus if applicable
	if hero.has_method("get_brand_alignment"):
		result.bonuses = _add_alignment_bonus(result.bonuses, hero, synergy_brands)
	
	return result

static func _get_tier_bonuses(path: String, tier: int) -> Dictionary:
	## Get the stat bonuses for a given path and tier
	var base_bonuses: Dictionary = Constants.PATH_SYNERGY_BONUSES.get(path, {})
	var result := {}
	
	match tier:
		1:
			# Half bonus
			for stat in base_bonuses:
				result[stat] = 1.0 + (base_bonuses[stat] - 1.0) * 0.5
		2:
			# Full bonus
			result = base_bonuses.duplicate()
		3:
			# Full + secondary
			result = base_bonuses.duplicate()
			for stat in result:
				result[stat] += Constants.SYNERGY_TIER_3_SECONDARY_BONUS
	
	return result

static func _add_alignment_bonus(bonuses: Dictionary, hero: Node, synergy_brands: Array) -> Dictionary:
	## Add +15% bonus if player has 55%+ alignment with any synergy Brand
	var has_alignment_bonus := false
	
	for brand_key in synergy_brands:
		if brand_key in ["BLOODIRON", "CORROSIVE", "VENOMSTRIKE", 
						 "TERRORFLUX", "NIGHTLEECH", "RAVENOUS"]:
			continue  # Skip hybrid brands for alignment check
		
		var alignment: float = hero.get_brand_alignment(brand_key)
		if alignment >= Constants.BRAND_EQUIPMENT_THRESHOLD:
			has_alignment_bonus = true
			break
	
	if has_alignment_bonus:
		var result := bonuses.duplicate()
		for stat in result:
			result[stat] *= (1.0 + Constants.SYNERGY_PLAYER_ALIGNMENT_BONUS)
		return result
	
	return bonuses

# =============================================================================
# PATH-BRAND COMBAT MODIFIERS
# =============================================================================

static func get_path_vs_brand_modifier(path: int, brand: int) -> float:
	## Get damage modifier when a Path attacks a Brand
	## Returns multiplier (1.35 for strong, 0.70 for weak, 1.0 for neutral)
	
	var path_key: String = Enums.Path.keys()[path] if path >= 0 else ""
	var brand_key: String = Enums.Brand.keys()[brand] if brand >= 0 else ""
	
	if path_key == "" or brand_key == "":
		return 1.0
	
	# Check strength
	var strong_brand: String = Constants.PATH_BRAND_STRENGTH.get(path_key, "")
	if brand_key == strong_brand:
		return Constants.PATH_STRONG_MULTIPLIER
	
	# Check weakness
	var weak_brand: String = Constants.PATH_BRAND_WEAKNESS.get(path_key, "")
	if brand_key == weak_brand:
		return Constants.PATH_WEAK_MULTIPLIER
	
	# Handle hybrid brands - use primary brand
	if Constants.HYBRID_BRAND_COMPONENTS.has(brand_key):
		var primary: String = Constants.HYBRID_BRAND_COMPONENTS[brand_key].get("primary", "")
		if primary == strong_brand:
			return Constants.PATH_STRONG_MULTIPLIER
		elif primary == weak_brand:
			return Constants.PATH_WEAK_MULTIPLIER
	
	return 1.0

static func get_path_effectiveness_text(path: int, brand: int) -> String:
	## Get text description of path vs brand effectiveness
	var modifier := get_path_vs_brand_modifier(path, brand)
	
	if modifier > 1.2:
		return "Strong"
	elif modifier < 0.8:
		return "Weak"
	return "Neutral"

# =============================================================================
# SYNERGY UI HELPERS
# =============================================================================

static func get_synergy_description(path: String) -> String:
	## Get description of what brands synergize with this path
	var brands: Array = Constants.PATH_SYNERGY_BRANDS.get(path, [])
	if brands.is_empty():
		return "No synergy brands"
	
	return "Synergizes with: " + ", ".join(brands)

static func get_synergy_bonus_text(path: String, tier: int) -> String:
	## Get text description of synergy bonuses
	if tier == 0:
		return "No synergy bonus"
	
	var bonuses := _get_tier_bonuses(path, tier)
	var texts: Array[String] = []
	
	for stat in bonuses:
		var percent: int = int((bonuses[stat] - 1.0) * 100)
		var stat_name: String = stat.replace("_mult", "").to_upper()
		texts.append("+%d%% %s" % [percent, stat_name])
	
	return "Tier %d: %s" % [tier, ", ".join(texts)]

static func get_synergy_tier_name(tier: int) -> String:
	match tier:
		0: return "None"
		1: return "Resonance"
		2: return "Harmony"
		3: return "Unity"
	return "Unknown"

# =============================================================================
# PARTY ANALYSIS
# =============================================================================

static func analyze_party_composition(hero: Node, monsters: Array) -> Dictionary:
	## Analyze the full party composition for synergies and conflicts
	var analysis := {
		"synergy": calculate_party_synergy(hero, monsters),
		"brand_distribution": {},
		"corruption_average": 0.0,
		"ascended_count": 0,
		"recommendations": []
	}
	
	if monsters.is_empty():
		return analysis
	
	# Count brands and calculate averages
	var total_corruption := 0.0
	for monster in monsters:
		if not is_instance_valid(monster):
			continue
		
		# Brand distribution
		var brand_key: String = ""
		if "brand" in monster:
			brand_key = Enums.Brand.keys()[monster.brand]
		if brand_key != "":
			analysis.brand_distribution[brand_key] = \
				analysis.brand_distribution.get(brand_key, 0) + 1
		
		# Corruption average
		if "corruption_level" in monster:
			total_corruption += monster.corruption_level
		
		# Ascended count
		if monster.has_method("is_ascended") and monster.is_ascended():
			analysis.ascended_count += 1
	
	analysis.corruption_average = total_corruption / monsters.size()
	
	# Generate recommendations
	analysis.recommendations = _generate_recommendations(analysis, hero)
	
	return analysis

static func _generate_recommendations(analysis: Dictionary, hero: Node) -> Array[String]:
	## Generate party composition recommendations
	var recs: Array[String] = []
	
	# Synergy recommendations
	if analysis.synergy.tier == 0:
		var path_key: String = ""
		if hero and "current_path" in hero:
			path_key = Enums.Path.keys()[hero.current_path]
		if path_key != "":
			var synergy_brands: Array = Constants.PATH_SYNERGY_BRANDS.get(path_key, [])
			if synergy_brands.size() > 0:
				recs.append("Add %s monsters for synergy bonus" % synergy_brands[0])
	elif analysis.synergy.tier < 3:
		recs.append("Add more synergy monsters for stronger bonus")
	
	# Ascension recommendations
	if analysis.ascended_count == 0 and analysis.corruption_average > 25:
		recs.append("Purify monsters at Shrines to reach Ascension")
	
	# Corruption recommendation
	if analysis.corruption_average > 50:
		recs.append("High party corruption - visit a Sanctum Shrine")
	
	return recs
