# BackpackUI.gd
# UI logic for displaying and interacting with the player's inventory

extends Control

@onready var grid: GridContainer = $ScrollContainer/GridContainer

func _ready():
	update_inventory()

func update_inventory():
	# 移除所有子节点
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	var manager = get_node("/root/InventoryManager")
	if not manager or not manager.inventory:
		return
	var slots_dict = manager.get_inventory_slots()
	for slot in slots_dict.values():
		var item_slot_scene = preload("res://ui/backpack/item_slot.tscn")
		var item_slot = item_slot_scene.instantiate()
		grid.add_child(item_slot)
		item_slot.set_slot_data(slot)
		item_slot.slot_clicked.connect(_on_item_slot_clicked)
		
	# 可扩展：显示数量、点击交互等
# 可扩展：显示数量、点击交互等

var selected_slot: Control = null

func _on_item_slot_clicked(slot: Control):
	if selected_slot:
		selected_slot.deselect()
	selected_slot = slot
	selected_slot.select()
