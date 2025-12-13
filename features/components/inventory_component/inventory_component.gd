class_name InventoryComponent extends Node

signal inventory_updated(container_name, inventory_data)
signal item_added(item, amount, container_name)
signal add_failed(item, amount)

# 容器字典: { "holster": data, "backpack": data }
var containers: Dictionary[String, InventoryData] = {}

func set_data(data: ActorData):
	containers.clear()
	if data.inventory_config:
		containers = data.inventory_config.duplicate()
	

# 核心逻辑：智能分发
func add_item(item: ItemData, amount: int = 1) -> bool:
	if item == null or amount <= 0:
		return false
	# 优先尝试放入指定容器（如果有的话）
	var can_accept_flag = false
	for name in containers.keys():
		var data: InventoryData = containers[name]
		if data.can_accept_item(item):
			can_accept_flag = true
			if _try_add_to_container(name, item, amount):
				return true
			else:
				# 如果没有合适的容器，触发失败信号
				add_failed.emit(item, amount)
				return false # 如果指定容器能接受但添加失败，直接返回失败
	if not can_accept_flag:
		# 如果没有任何容器能接受该物品，就创建新的背包用于接收
		var new_container_name = str("container_%d" % item.item_type)
		var new_container = InventoryData.new()
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

# 获取所有容器的数据，方便UI遍历生成界面
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