class_name InventoryComponent extends Node

signal inventory_updated(container_name: String, inventory_data: InventoryData)
signal item_added(item: ItemData, amount: int, container_name: String)
signal add_failed(item: ItemData, amount: int)

# Container dictionary: { "holster": data, "backpack": data }
var containers: Dictionary[String, InventoryData] = {}

func set_data(data: ActorData) -> void:
	containers.clear()
	if data and data.inventory_config:
		containers = data.inventory_config.duplicate()

func add_item(item: ItemData, amount: int = 1) -> bool:
	if item == null or amount <= 0:
		return false
	# Try to place item into an accepting container
	var can_accept_flag: bool = false
	for name in containers.keys():
		var inv_data: InventoryData = containers[name]
		if inv_data.can_accept_item(item):
			can_accept_flag = true
			if _try_add_to_container(name, item, amount):
				return true
			else:
				add_failed.emit(item, amount)
				return false
	if not can_accept_flag:
		# No existing container accepts this item; create a new one
		var new_container_name: String = "container_%d" % item.item_type
		var new_container := InventoryData.new()
		new_container.accepted_types.push_back(item.item_type)
		containers[new_container_name] = new_container
		if _try_add_to_container(new_container_name, item, amount):
			return true
		else:
			add_failed.emit(item, amount)
	return false

func _try_add_to_container(name: String, item: ItemData, amount: int) -> bool:
	var data: InventoryData = containers[name]
	# 这里 InventoryData.add_item 内部已经会调用 can_accept_item 进行检查
	if data.add_item(item, amount):
		item_added.emit(item, amount, name)
		return true
	return false

func add_item_to_container(container_name: String, item: ItemData, amount: int = 1) -> bool:
	if item == null or amount <= 0:
		return false
	if not containers.has(container_name):
		return false
	var data: InventoryData = containers[container_name]
	if not data.can_accept_item(item):
		return false
	return _try_add_to_container(container_name, item, amount)

func get_all_containers() -> Dictionary:
	return containers

func remove_item(item: ItemData, amount: int, source_container: String) -> bool:
	if not containers.has(source_container):
		return false
	var data: InventoryData = containers[source_container]
	if data.remove_item(item, amount):
		inventory_updated.emit(source_container, data)
		return true
	return false
