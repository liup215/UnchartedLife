# damage_calculator.gd
# Comprehensive damage calculation system
extends Node
class_name DamageCalculator

## Calculate final damage considering all factors
static func calculate_damage(
	attacker: Node,
	defender: Node,
	base_weapon_damage: float,
	damage_type: WeaponData.DamageType,
	damage_multiplier: float = 1.0,
	armor_break_power: float = 0.0
) -> Dictionary:
	"""
	Calculates comprehensive damage with all factors
	Returns: {
		"final_damage": float,
		"toughness_damage": float,
		"is_critical": bool,
		"damage_breakdown": Dictionary
	}
	"""
	
	var result = {
		"final_damage": 0.0,
		"toughness_damage": 0.0,
		"is_critical": false,
		"damage_breakdown": {}
	}
	
	# Get attacker stats
	var attacker_attack = _get_attack_value(attacker)
	var attacker_bonus_multiplier = _get_damage_bonus_multiplier(attacker)
	
	# Get defender stats
	var defender_defense = _get_defense_value(defender)
	var defender_reduction_multiplier = _get_damage_reduction_multiplier(defender)
	
	# Step 1: Base damage calculation
	# Formula: (Base Weapon Damage + Attacker Attack) * Stage Multiplier
	var base_damage = (base_weapon_damage + attacker_attack) * damage_multiplier
	result["damage_breakdown"]["base"] = base_damage
	
	# Step 2: Apply attacker's damage bonuses (from items/buffs)
	var damage_with_bonuses = base_damage * attacker_bonus_multiplier
	result["damage_breakdown"]["with_attacker_bonuses"] = damage_with_bonuses
	
	# Step 3: Apply armor break
	# Armor break reduces defender's effective defense
	var effective_defense = defender_defense * (1.0 - (armor_break_power / 100.0))
	effective_defense = max(0, effective_defense)
	result["damage_breakdown"]["effective_defense"] = effective_defense
	
	# Step 4: Calculate damage after defense
	# Formula: Damage * (100 / (100 + Defense))
	var damage_after_defense = damage_with_bonuses * (100.0 / (100.0 + effective_defense))
	result["damage_breakdown"]["after_defense"] = damage_after_defense
	
	# Step 5: Apply defender's damage reduction (from items/buffs)
	var final_damage = damage_after_defense * defender_reduction_multiplier
	result["damage_breakdown"]["final"] = final_damage
	
	# Step 6: Apply damage type effectiveness
	var type_effectiveness = _get_damage_type_effectiveness(damage_type, defender)
	final_damage *= type_effectiveness
	result["damage_breakdown"]["type_effectiveness"] = type_effectiveness
	
	# Step 7: Calculate toughness damage
	# Toughness damage is based on final damage and stagger power
	var toughness_damage = final_damage * 0.5  # Base 50% of damage goes to toughness
	result["toughness_damage"] = toughness_damage
	
	result["final_damage"] = final_damage
	
	return result

## Get attacker's attack value
static func _get_attack_value(attacker: Node) -> float:
	if not attacker:
		return 0.0
	
	# Try to get from ActorData
	if attacker.has_node("AttributeComponent"):
		var attr_comp = attacker.get_node("AttributeComponent")
		# In future, AttributeComponent could have attack stat
		# For now, check if actor_data is available
		if attacker.has("actor_data") and attacker.actor_data:
			return attacker.actor_data.base_attack
	
	return 0.0

## Get defender's defense value
static func _get_defense_value(defender: Node) -> float:
	if not defender:
		return 0.0
	
	# Try to get from ActorData
	if defender.has_node("AttributeComponent"):
		if defender.has("actor_data") and defender.actor_data:
			var base_defense = defender.actor_data.base_defense
			
			# TODO: Add equipment defense bonuses
			# For now, just return base defense
			return base_defense
	
	return 0.0

## Get attacker's damage bonus multiplier (from items/buffs)
static func _get_damage_bonus_multiplier(attacker: Node) -> float:
	# TODO: Implement item/buff system
	# For now, return 1.0 (no bonus)
	# In future: check inventory for damage-boosting items
	# Check active buffs for damage increases
	return 1.0

## Get defender's damage reduction multiplier (from items/buffs)
static func _get_damage_reduction_multiplier(defender: Node) -> float:
	# TODO: Implement item/buff system
	# For now, return 1.0 (no reduction)
	# In future: check inventory for damage-reducing items
	# Check active buffs for damage reduction
	return 1.0

## Get damage type effectiveness multiplier
static func _get_damage_type_effectiveness(damage_type: WeaponData.DamageType, defender: Node) -> float:
	# TODO: Implement elemental resistance system
	# For now, all damage types are equally effective
	# In future: check defender's resistances
	# PHYSICAL might be reduced by armor
	# FIRE might be resisted by fire-resistant enemies
	# ICE might be super-effective against fire enemies
	# etc.
	
	match damage_type:
		WeaponData.DamageType.PHYSICAL:
			return 1.0
		WeaponData.DamageType.FIRE:
			return 1.0
		WeaponData.DamageType.ICE:
			return 1.0
		WeaponData.DamageType.ELECTRIC:
			return 1.0
		WeaponData.DamageType.EXPLOSIVE:
			return 1.2  # Explosive slightly more effective for now
		_:
			return 1.0
