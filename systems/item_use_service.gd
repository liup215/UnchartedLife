# ItemUseService.gd
# Global service for handling item usage across different item types and effects
# Provides unified interface for using items with data-driven effects

extends Node

# class_name ItemUseService

# Signals
signal item_used(actor: Actor, item: ItemData, success: bool)
signal item_use_failed(actor: Actor, item: ItemData, reason: String)

# Cooldown tracking: item_resource_path -> {actor_id: cooldown_end_time}
var cooldown_map: Dictionary = {}

# Effect executors registry: effect_type -> Callable
var effect_executors: Dictionary = {}

func _ready():
	_register_effect_executors()

func _register_effect_executors():
	# Register all effect executors
	effect_executors["heal"] = _execute_heal
	effect_executors["restore_resource"] = _execute_restore_resource
	effect_executors["apply_buff"] = _execute_apply_buff
	effect_executors["grant_item"] = _execute_grant_item
	effect_executors["equip"] = _execute_equip
	effect_executors["trigger_quest"] = _execute_trigger_quest
	effect_executors["unlock_area"] = _execute_unlock_area
	effect_executors["teleport"] = _execute_teleport
	effect_executors["fire_event"] = _execute_fire_event
	effect_executors["revive"] = _execute_revive
	effect_executors["modify_stat"] = _execute_modify_stat
	effect_executors["consume_resource"] = _execute_consume_resource

# Main entry point for using items
func use_item(actor: Actor, item: ItemData, source_container: String) -> bool:
	if not _can_use_item(actor, item):
		return false

	var success: bool = _execute_item_effects(actor, item)

	if success:
		if item and item.item_type == ItemData.ItemType.WEAPON:
			# Weapons are moved from inventory into equipment on equip.
			if actor and actor.inventory_component and not source_container.is_empty():
				actor.inventory_component.remove_item(item, 1, source_container)
			EventBus.equipment_changed.emit(actor)
		else:
			_handle_consumption(actor, item, source_container)
		_apply_cooldown(actor, item)
		item_used.emit(actor, item, true)
		EventBus.item_used.emit(actor, item, true)
	else:
		item_use_failed.emit(actor, item, "Effect execution failed")
		EventBus.item_use_failed.emit(actor, item, "Effect execution failed")

	return success

func _can_use_item(actor: Actor, item: ItemData) -> bool:
	# Check if item is usable
	if not item.usable:
		item_use_failed.emit(actor, item, "Item is not usable")
		EventBus.item_use_failed.emit(actor, item, "Item is not usable")
		return false

	# Check cooldown
	if _is_on_cooldown(actor, item):
		var remaining = _get_cooldown_remaining(actor, item)
		var reason: String = "Item on cooldown: %.1f seconds remaining" % remaining
		item_use_failed.emit(actor, item, reason)
		EventBus.item_use_failed.emit(actor, item, reason)
		return false

	# Check requirements
	var requirement_check = _check_requirements(actor, item)
	if not requirement_check.success:
		item_use_failed.emit(actor, item, requirement_check.reason)
		EventBus.item_use_failed.emit(actor, item, requirement_check.reason)
		return false

	return true

func _execute_item_effects(actor: Actor, item: ItemData) -> bool:
	# Weapon items: equip via combat component and weapon_data
	if item.item_type == ItemData.ItemType.WEAPON:
		return _equip_weapon(actor, item)

	for effect_data in item.effects:
		if not effect_data.validate_params():
			push_warning("Invalid parameters for effect %s on item %s" % [effect_data.get_effect_type_name(), item.item_name])
			continue

		var effect_type_name = effect_data.get_effect_type_name().to_lower()
		if effect_executors.has(effect_type_name):
			var executor = effect_executors[effect_type_name]
			var result = executor.call(actor, effect_data.params)
			if not result:
				return false
		else:
			push_warning("No executor found for effect type: %s" % effect_type_name)

	return true

func _handle_consumption(actor: Actor, item: ItemData, source_container: String):
	match item.consumption_mode:
		0:  # ConsumeOnUse
			_consume_item(actor, item, source_container)
		1:  # ConsumeOnSuccess - already handled in _execute_item_effects
			_consume_item(actor, item, source_container)
		2:  # NotConsumable
			pass

func _consume_item(actor: Actor, item: ItemData, source_container: String):
	if actor.inventory_component:
		actor.inventory_component.remove_item(item, 1, source_container)

func _apply_cooldown(actor: Actor, item: ItemData):
	if item.cooldown > 0:
		var item_key = item.resource_path if item.resource_path else str(item.get_instance_id())
		var actor_key = str(actor.get_instance_id())

		if not cooldown_map.has(item_key):
			cooldown_map[item_key] = {}

		cooldown_map[item_key][actor_key] = Time.get_time_dict_from_system()["hour"] * 3600 + Time.get_time_dict_from_system()["minute"] * 60 + Time.get_time_dict_from_system()["second"] + item.cooldown

func _is_on_cooldown(actor: Actor, item: ItemData) -> bool:
	var item_key = item.resource_path if item.resource_path else str(item.get_instance_id())
	var actor_key = str(actor.get_instance_id())

	if cooldown_map.has(item_key) and cooldown_map[item_key].has(actor_key):
		var current_time = Time.get_time_dict_from_system()["hour"] * 3600 + Time.get_time_dict_from_system()["minute"] * 60 + Time.get_time_dict_from_system()["second"]
		return current_time < cooldown_map[item_key][actor_key]

	return false

func _get_cooldown_remaining(actor: Actor, item: ItemData) -> float:
	var item_key = item.resource_path if item.resource_path else str(item.get_instance_id())
	var actor_key = str(actor.get_instance_id())

	if cooldown_map.has(item_key) and cooldown_map[item_key].has(actor_key):
		var current_time = Time.get_time_dict_from_system()["hour"] * 3600 + Time.get_time_dict_from_system()["minute"] * 60 + Time.get_time_dict_from_system()["second"]
		return max(0, cooldown_map[item_key][actor_key] - current_time)

	return 0.0

func _check_requirements(actor: Actor, item: ItemData) -> Dictionary:
	for requirement in item.use_requirements:
		var req_type = requirement.get("type", "")
		match req_type:
			"quest_state":
				if not _check_quest_state(actor, requirement):
					return {"success": false, "reason": "Quest requirement not met"}
			"stat_min":
				if not _check_stat_min(actor, requirement):
					return {"success": false, "reason": "Stat requirement not met"}
			"zone":
				if not _check_zone(actor, requirement):
					return {"success": false, "reason": "Zone requirement not met"}
			_:
				push_warning("Unknown requirement type: %s" % req_type)

	return {"success": true, "reason": ""}

# Requirement checkers
func _check_quest_state(actor: Actor, requirement: Dictionary) -> bool:
	# TODO: Implement quest state checking
	return true

func _check_stat_min(actor: Actor, requirement: Dictionary) -> bool:
	var stat_name = requirement.get("stat", "")
	var min_value = requirement.get("value", 0)

	if actor.attribute_component:
		match stat_name:
			"health":
				return actor.attribute_component.current_health >= min_value
			"atp":
				return actor.attribute_component.current_atp >= min_value
			"glucose":
				return actor.attribute_component.current_glucose >= min_value

	return false

func _check_zone(actor: Actor, requirement: Dictionary) -> bool:
	var required_zone = requirement.get("zone", "")
	# TODO: Implement zone checking via MapManager
	return true

# Effect executors
func _execute_heal(actor: Actor, params: Dictionary) -> bool:
	var amount = params.get("amount", 0)
	if actor.attribute_component and actor.attribute_component.health_component:
		actor.attribute_component.health_component.heal(amount)
		return true
	return false

func _execute_restore_resource(actor: Actor, params: Dictionary) -> bool:
	var resource_type = params.get("resource_type", "")
	var amount = params.get("amount", 0)

	if actor.attribute_component:
		match resource_type:
			"atp":
				actor.attribute_component.restore_atp(amount)
				return true
			"glucose":
				actor.attribute_component.restore_glucose(amount)
				return true

	return false

func _execute_apply_buff(actor: Actor, params: Dictionary) -> bool:
	# TODO: Implement buff system
	EventBus.buff_applied.emit(actor, params.get("buff_id", ""), params.get("duration", 0))
	return true

func _execute_grant_item(actor: Actor, params: Dictionary) -> bool:
	var item_id = params.get("item_id", "")
	var quantity = params.get("quantity", 1)

	# TODO: Load item by ID and add to inventory
	return true

func _execute_equip(actor: Actor, params: Dictionary) -> bool:
	# Generic equip hook (armor/accessories). Weapons handled separately in _equip_weapon.
	return true

func _execute_trigger_quest(actor: Actor, params: Dictionary) -> bool:
	var quest_id = params.get("quest_id", "")
	var step = params.get("step", 0)

	EventBus.quest_triggered.emit(quest_id, step)
	return true

func _execute_unlock_area(actor: Actor, params: Dictionary) -> bool:
	var area_id = params.get("area_id", "")

	EventBus.area_unlocked.emit(area_id)
	return true

func _execute_teleport(actor: Actor, params: Dictionary) -> bool:
	# TODO: Implement teleportation
	return true

func _execute_fire_event(actor: Actor, params: Dictionary) -> bool:
	var event_name = params.get("event_name", "")
	var event_data = params.get("data", {})

	EventBus.emit_signal(event_name, actor, event_data)
	return true

func _execute_revive(actor: Actor, params: Dictionary) -> bool:
	# TODO: Implement revive logic
	return true

func _execute_modify_stat(actor: Actor, params: Dictionary) -> bool:
	# TODO: Implement permanent stat modification
	return true

func _execute_consume_resource(actor: Actor, params: Dictionary) -> bool:
	var resource_type = params.get("resource_type", "")
	var amount = params.get("amount", 0)

	if actor.attribute_component:
		match resource_type:
			"atp":
				return actor.attribute_component.consume_atp(amount)
			"glucose":
				return actor.attribute_component.consume_glucose(amount)

	return false

# Weapon equip helper
func _equip_weapon(actor: Actor, item: ItemData) -> bool:
	if not item.weapon_data:
		push_warning("Weapon item %s missing weapon_data" % item.item_name)
		return false

	if not actor or not actor.actor_combat_component:
		push_warning("Actor has no combat component; cannot equip weapon")
		return false

	# Respect weapon limit if defined on actor_data
	if actor.actor_data and actor.actor_data.weapon_number_limit > 0:
		if actor.actor_combat_component.actor_weapons.size() >= actor.actor_data.weapon_number_limit:
			item_use_failed.emit(actor, item, "Weapon slots are full")
			return false

	var weapon_scene := preload("res://features/components/weapon_component.tscn")
	if not weapon_scene:
		push_warning("Weapon component scene missing")
		return false

	var weapon_instance: WeaponComponent = weapon_scene.instantiate()
	weapon_instance.item_data = item
	weapon_instance.setup_weapon()
	actor.actor_combat_component.add_child(weapon_instance)
	actor.actor_combat_component.add_actor_weapon(weapon_instance)
	return true

func unequip_weapon(actor: Actor, target_container: String = "weapons") -> bool:
	if actor == null or actor.actor_combat_component == null:
		return false

	var combat: ActorCombatComponent = actor.actor_combat_component
	if combat.actor_weapons.is_empty():
		return false

	var weapon_component: WeaponComponent = combat.actor_weapons[0]
	if weapon_component == null or weapon_component.item_data == null:
		combat.remove_actor_weapon(0)
		return false

	var weapon_item: ItemData = weapon_component.item_data

	combat.remove_actor_weapon(0)
	if is_instance_valid(weapon_component):
		weapon_component.queue_free()

	if actor.inventory_component:
		var inv: InventoryComponent = actor.inventory_component
		var added: bool = false
		if not target_container.is_empty() and inv.containers.has(target_container):
			added = inv.add_item_to_container(target_container, weapon_item, 1)
		if not added:
			inv.add_item(weapon_item, 1)

	EventBus.equipment_changed.emit(actor)
	return true
