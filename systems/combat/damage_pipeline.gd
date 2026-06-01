# systems/combat/damage_pipeline.gd
# Encapsulates the entire damage flow as a PURE FUNCTION.
# Replaces HitDamageCalculator.on_enemy_hit() mixed concerns.
# Input: attacker entity_id, target entity_id, base_weapon_damage, optional charge/combo data.
# Output: structured DamageResult with all effects to apply.
# No node references; all lookups via ServiceRegistry.
extends Node
class_name DamagePipeline

class DamageResult:
	var final_damage: float = 0.0
	var toughness_damage: float = 0.0
	var stagger_power: float = 0.0
	var armor_break: float = 0.0
	## Whether the target should enter stagger state.
	var should_stagger: bool = false
	## Charge progress to add (for light attacks that build charge).
	var charge_gain: float = 0.0
	## Whether this was a heavy attack.
	var is_heavy_attack: bool = false
	## Charge level used (for signal emission).
	var charge_level: int = 0
	## For logging / debug only.
	var damage_breakdown: Dictionary = {}

## Central entry point.
func calculate_damage(
		attacker_id: int,
		target_id: int,
		base_weapon_damage: float,
		weapon_data: WeaponData = null,
		charge_level: int = 0,
		combo_stage: int = -1
	) -> DamageResult:
	var result := DamageResult.new()
	
	# Step 1: Base weapon scaling
	var damage_multiplier: float = 1.0
	if weapon_data:
		# Heavy attack scaling
		if charge_level > 0:
			result.is_heavy_attack = true
			result.charge_level = charge_level
			damage_multiplier = 1.0 + (charge_level * HeavyAttackSystem.DAMAGE_CHARGE_SCALING_FACTOR)
			var heavy_data := _get_heavy_attack_data(weapon_data, charge_level)
			if heavy_data:
				result.armor_break = heavy_data.armor_break_power
				result.stagger_power = heavy_data.stagger_power
		# Combo attack scaling
		elif combo_stage >= 0 and combo_stage < weapon_data.combo_attacks.size():
			var combo_data: ComboAttackData = weapon_data.combo_attacks[combo_stage]
			damage_multiplier = combo_data.damage_multiplier
			result.armor_break = combo_data.armor_break_power
			result.stagger_power = combo_data.stagger_power
			result.charge_gain = combo_data.charge_gain * 20.0
		
		if weapon_data.light_attacks_build_charge and not result.is_heavy_attack:
			result.charge_gain = combo_stage * 20.0 if combo_stage >= 0 else 0.0
	
	# Step 2: Base attacker attributes (from StatSystem)
	var attacker_attack: float = _get_stat_or_default(attacker_id, "base_attack", 10.0)
	
	# Step 3: Target attributes (from StatSystem)
	var target_defense: float = _get_stat_or_default(target_id, "base_defense", 5.0)
	
	# Step 4: Damage formula
	var raw_damage = (base_weapon_damage * damage_multiplier) + attacker_attack
	var defense_mitigation = target_defense * 0.5  # 1 defense = 0.5 damage reduction
	result.final_damage = max(raw_damage - defense_mitigation, 1.0)
	
	# Step 5: Toughness damage (proportional to final damage)
	result.toughness_damage = result.final_damage * 0.5 + result.stagger_power
	
	# Step 6: Check stagger threshold
	var current_toughness: float = _get_stat_or_default(target_id, "toughness", 100.0)
	if current_toughness - result.toughness_damage <= 0:
		result.should_stagger = true
	
	result.damage_breakdown = {
		"base_weapon_damage": base_weapon_damage,
		"damage_multiplier": damage_multiplier,
		"attacker_attack": attacker_attack,
		"target_defense": target_defense,
		"defense_mitigation": defense_mitigation,
		"final_damage": result.final_damage,
		"toughness_damage": result.toughness_damage,
	}
	
	return result

func _get_stat_or_default(entity_id: int, stat_id: String, default_val: float) -> float:
	if entity_id < 0:
		return default_val
	var stat_system = ServiceRegistry.get_service("StatSystem")
	if stat_system:
		return stat_system.get_stat_value(entity_id, stat_id, default_val)
	return default_val

func _get_heavy_attack_data(weapon_data: WeaponData, charge_level: int) -> HeavyAttackData:
	if not weapon_data or weapon_data.heavy_attacks.is_empty():
		return null
	var idx = clampi(charge_level - 1, 0, weapon_data.heavy_attacks.size() - 1)
	return weapon_data.heavy_attacks[idx]

## Apply a DamageResult to the game world.
## This is the ONLY place that should call take_damage() / apply_toughness_damage().
func apply_damage_result(attacker: Node, target: Node, result: DamageResult) -> void:
	if not is_instance_valid(target):
		return
	
	# Apply HP damage
	if target.has_method("take_damage"):
		target.take_damage(int(result.final_damage))
	
	# Apply toughness damage
	if target is Actor:
		var target_actor := target as Actor
		if target_actor.attribute_component and target_actor.attribute_component.toughness_component:
			target_actor.attribute_component.toughness_component.apply_toughness_damage(result.toughness_damage, result.stagger_power)
		# Trigger stagger if needed via old component bridge
		if result.should_stagger and target_actor.attribute_component and target_actor.attribute_component.toughness_component:
			# The apply_toughness_damage already triggers stagger if threshold is crossed
			pass
	
	# Emit hit event
	EventBus.enemy_hit.emit(target, result.final_damage, result.armor_break, result.stagger_power)
