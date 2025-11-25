# InventoryData.gd
# Inventory resource using resource_path as key for efficient lookup

extends Resource
class_name InventoryData

# InventorySlotData class for strong typing
class InventorySlotData:
	var item: ItemData
	var quantity: int

	func _init(_item: ItemData, _quantity: int = 1) -> void:
		item = _item
		quantity = _quantity

@export var capacity: int = 30
@export var is_unlimited: bool = false
# slots is a Dictionary: key -> InventorySlotData
@export var slots: Dictionary = {}

func _init() -> void:
	slots = {}

func _key_base(item: ItemData) -> String:
	if item == null:
		return ""
	if item.resource_path != "":
		return item.resource_path
	return "inst://" + str(item.get_instance_id())

func add_item(item: ItemData, amount: int = 1) -> bool:
	if item == null or amount <= 0:
		return false
	var base := _key_base(item)
	if item.stackable:
		# single entry per item type, accumulate quantity
		if slots.has(base):
			var slot: InventorySlotData = slots[base]
			slot.quantity += amount
			return true
		else:
			if not is_unlimited and slots.size() >= capacity:
				return false
			slots[base] = InventorySlotData.new(item, amount)
			return true
	else:
		# non-stackable: each unit occupies its own slot (unique key)
		while amount > 0:
			if (not is_unlimited) and slots.size() >= capacity:
				print("Inventory full, cannot add more non-stackable items.")
				return false
			var unique_key := base + ":" + str(Time.get_unix_time_from_system()) + ":" + str(randi())
			slots[unique_key] = InventorySlotData.new(item, 1)
			amount -= 1
		return true

func remove_item(item: ItemData, amount: int = 1) -> bool:
	if item == null or amount <= 0:
		return false
	var base := _key_base(item)
	if item.stackable:
		if not slots.has(base):
			return false
		var slot: InventorySlotData = slots[base]
		var take: int = min(amount, slot.quantity)
		slot.quantity -= take
		if slot.quantity <= 0:
			slots.erase(base)
		return take == amount
	else:
		# remove matching instance entries until amount satisfied
		var removed := 0
		var keys := slots.keys()
		for k in keys:
			if removed >= amount:
				break
			var slot = slots.get(k)
			if typeof(slot) == TYPE_OBJECT and slot.item == item:
				slots.erase(k)
				removed += 1
		return removed == amount

func get_total_count(item: ItemData) -> int:
	if item == null:
		return 0
	var base := _key_base(item)
	if item.stackable:
		if slots.has(base):
			return slots[base].quantity
		return 0
	else:
		var total := 0
		for k in slots.keys():
			var slot = slots.get(k)
			if typeof(slot) == TYPE_OBJECT and slot.item == item:
				total += slot.quantity
		return total

func clear() -> void:
	slots.clear()

class InventorySlotKeys:
	const KEY = "key"
	const ITEM_PATH = "item_path"
	const QUANTITY = "quantity"
