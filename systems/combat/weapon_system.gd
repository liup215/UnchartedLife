# systems/combat/weapon_system.gd
# Central authority for all WeaponData and equipped weapon queries.
# Replaces scattered weapon state in ActorCombatComponent and Player.gd.
# Holds a DICTIONARY of entity_id -> equipped weapons array.
# No node references; only data operations.
extends Node
class_name WeaponSystem

## entity_id -> Array[ItemData] (the weapons)
var _entity_weapons: Dictionary[int, Array] = {}

## entity_id -> int (currently selected weapon index for light attacks)
var _entity_active_weapon_index: Dictionary[int, int] = {}

## --- Equipment ---

func register_entity(entity_id: int) -> void:
	if not _entity_weapons.has(entity_id):
		_entity_weapons[entity_id] = []
		_entity_active_weapon_index[entity_id] = 0

func unregister_entity(entity_id: int) -> void:
	_entity_weapons.erase(entity_id)
	_entity_active_weapon_index.erase(entity_id)

func equip_weapon(entity_id: int, weapon_item: ItemData) -> bool:
	register_entity(entity_id)
	_entity_weapons[entity_id].append(weapon_item)
	return true

func unequip_weapon(entity_id: int, index: int) -> bool:
	if not _entity_weapons.has(entity_id):
		return false
	var weapons = _entity_weapons[entity_id]
	if index >= 0 and index < weapons.size():
		weapons.remove_at(index)
		return true
	return false

func clear_weapons(entity_id: int) -> void:
	register_entity(entity_id)
	_entity_weapons[entity_id].clear()

## --- Queries ---

func get_weapons(entity_id: int) -> Array:
	if not _entity_weapons.has(entity_id):
		return []
	return _entity_weapons[entity_id].duplicate()

func get_weapon_count(entity_id: int) -> int:
	if not _entity_weapons.has(entity_id):
		return 0
	return _entity_weapons[entity_id].size()

func get_active_weapon(entity_id: int) -> ItemData:
	if not _entity_weapons.has(entity_id):
		return null
	var weapons = _entity_weapons[entity_id]
	var idx = _entity_active_weapon_index.get(entity_id, 0)
	if idx >= 0 and idx < weapons.size():
		return weapons[idx]
	return null

func get_active_weapon_index(entity_id: int) -> int:
	return _entity_active_weapon_index.get(entity_id, 0)

func set_active_weapon_index(entity_id: int, index: int) -> void:
	register_entity(entity_id)
	_entity_active_weapon_index[entity_id] = index

## --- Weapon Data Queries ---

## Get the base weapon_data from a weapon item.
func get_weapon_data(weapon_item: ItemData) -> WeaponData:
	if not weapon_item:
		return null
	return weapon_item.weapon_data as WeaponData

## Get ATP cost for a weapon.
func get_weapon_atp_cost(weapon_item: ItemData) -> float:
	var wd = get_weapon_data(weapon_item)
	if not wd:
		return 0.0
	return wd.atp_cost

## Get total damage for all equipped weapons on an entity.
func get_total_weapon_damage(entity_id: int) -> float:
	var total = 0.0
	for weapon in get_weapons(entity_id):
		var wd = get_weapon_data(weapon)
		if wd:
			total += wd.damage
	return total

## Get combo attacks for the currently active weapon.
func get_active_weapon_combo_data(entity_id: int) -> Array:
	var weapon = get_active_weapon(entity_id)
	var wd = get_weapon_data(weapon)
	if wd:
		return wd.combo_attacks
	return []

## Get heavy attacks for the currently active weapon.
func get_active_weapon_heavy_data(entity_id: int) -> Array:
	var weapon = get_active_weapon(entity_id)
	var wd = get_weapon_data(weapon)
	if wd:
		return wd.heavy_attacks
	return []

## Check if the active weapon builds charge from light attacks.
func does_active_weapon_build_charge(entity_id: int) -> bool:
	var weapon = get_active_weapon(entity_id)
	var wd = get_weapon_data(weapon)
	if wd:
		return wd.light_attacks_build_charge
	return false
