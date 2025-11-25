# InventoryManager.gd
# Global singleton for managing player inventory

extends Node

@export var inventory: Resource

func _ready():
	# Load or create inventory resource
	var inv_path = "res://data/inventory/player_weapon_inventory.tres"
	if ResourceLoader.exists(inv_path):
		inventory = load(inv_path)
	else:
		inventory = load("res://data/definitions/inventory_data.gd").new()
		inventory.is_unlimited = true
		ResourceSaver.save(inventory, inv_path, ResourceSaver.FLAG_RELATIVE_PATHS)

func add_item(item: ItemData, amount: int = 1) -> bool:
	if inventory:
		return inventory.add_item(item, amount)
	return false

func remove_item(item: ItemData, amount: int = 1) -> bool:
	if inventory:
		return inventory.remove_item(item, amount)
	return false

func get_total_count(item: ItemData) -> int:
	if inventory:
		return inventory.get_total_count(item)
	return 0

func clear_inventory():
	if inventory:
		inventory.clear()

func get_inventory_slots() -> Dictionary:
	if inventory:
		return inventory.slots
	return {}

func get_inventory_capacity() -> int:
	if inventory:
		return inventory.capacity
	return 0

func is_inventory_unlimited() -> bool:
	if inventory:
		return inventory.is_unlimited
	return false
