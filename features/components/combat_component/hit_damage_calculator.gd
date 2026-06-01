# hit_damage_calculator.gd
# Encapsulates damage calculation logic when a projectile hits a target
extends Node
class_name HitDamageCalculator

var actor_weapons: Array[WeaponComponent] = []
var charge_component: ChargeComponent = null
var heavy_attack_system: HeavyAttackSystem = null
var combo_system: ComboSystem = null

signal enemy_hit(target: Node, damage: float, armor_break: float, stagger: float)


func configure(
	p_actor_weapons: Array[WeaponComponent],
	p_charge_component: ChargeComponent,
	p_heavy_attack_system: HeavyAttackSystem,
	p_combo_system: ComboSystem
) -> void:
	actor_weapons = p_actor_weapons
	charge_component = p_charge_component
	heavy_attack_system = p_heavy_attack_system
	combo_system = p_combo_system


func on_enemy_hit(attacker: Node, target: Node, base_weapon_damage: float) -> void:
	if not charge_component:
		return

	if actor_weapons.is_empty():
		return

	var weapon: WeaponComponent = actor_weapons[0]
	if not weapon or not weapon.item_data:
		return

	var weapon_data: WeaponData = weapon.item_data.weapon_data as WeaponData
	if not weapon_data:
		return

	var damage_multiplier: float = 1.0
	var armor_break: float = 0.0
	var stagger_power: float = 0.0
	var charge_gain: int = 1

	# Check if this was a heavy attack
	if heavy_attack_system and heavy_attack_system.last_heavy_charge > 0.0:
		damage_multiplier = 1.0 + (heavy_attack_system.last_heavy_charge * HeavyAttackSystem.DAMAGE_CHARGE_SCALING_FACTOR)

		var heavy_data: HeavyAttackData = heavy_attack_system.get_heavy_attack_data(
			weapon_data, heavy_attack_system.last_heavy_charge
		)
		if heavy_data:
			armor_break = heavy_data.armor_break_power
			stagger_power = heavy_data.stagger_power

		GameLogger.debug(
			"combat",
			"Heavy attack hit - Charge: %.2f, Multiplier: %.2fx" % [heavy_attack_system.last_heavy_charge, damage_multiplier]
		)

		heavy_attack_system.last_heavy_charge = 0.0
	# Check if this was a combo attack
	elif not weapon_data.combo_attacks.is_empty() and combo_system and combo_system.combo_stage < weapon_data.combo_attacks.size():
		var combo_data: ComboAttackData = weapon_data.combo_attacks[combo_system.combo_stage]
		damage_multiplier = combo_data.damage_multiplier
		armor_break = combo_data.armor_break_power
		stagger_power = combo_data.stagger_power
		charge_gain = combo_data.charge_gain

	var damage_result: Dictionary = DamageCalculator.calculate_damage(
		attacker,
		target,
		base_weapon_damage,
		weapon_data.damage_type,
		damage_multiplier,
		armor_break
	)

	var final_damage: float = damage_result["final_damage"]
	var toughness_damage: float = damage_result["toughness_damage"]

	GameLogger.debug("combat", "Hit %s - Damage: %s Toughness: %s" % [target.name, final_damage, toughness_damage])
	GameLogger.debug("combat", "Damage breakdown: %s" % damage_result["damage_breakdown"])

	if target.has_method("take_damage"):
		target.take_damage(int(final_damage))

	if target is Actor:
		var target_actor := target as Actor
		# NEW: Prefer new StatSystem if entity is registered, else fallback to old component
		if target_actor.entity_id >= 0:
			var stat_system: StatSystem = ServiceRegistry.get_service("StatSystem")
			if stat_system:
				stat_system.modify_current(target_actor.entity_id, "toughness", -toughness_damage)
				var toughness_val: float = stat_system.get_stat_current(target_actor.entity_id, "toughness")
				if toughness_val <= stat_system.get_stat_value(target_actor.entity_id, "stagger_threshold", 0.0):
					# Trigger stagger via old component bridge for now
					if target_actor.attribute_component and target_actor.attribute_component.toughness_component:
						target_actor.attribute_component.toughness_component.apply_toughness_damage(0.001, stagger_power)
						return
		# Fallback to old system during transition
		if target_actor.attribute_component and target_actor.attribute_component.toughness_component:
			target_actor.attribute_component.toughness_component.apply_toughness_damage(toughness_damage, stagger_power)

	if weapon_data.light_attacks_build_charge:
		var progress_gain: float = charge_gain * 20.0
		charge_component.add_light_attack_charge(progress_gain)

	enemy_hit.emit(target, final_damage, armor_break, stagger_power)
