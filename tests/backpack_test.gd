# backpack_test.gd
# 测试场景脚本：用于验证背包系统功能

extends Node2D

@onready var backpack_ui = preload("res://ui/backpack/backpack_ui.tscn").instantiate()
@onready var btn_add = Button.new()
@onready var btn_remove = Button.new()

func _ready():
	add_child(backpack_ui)
	btn_add.text = "添加物品"
	btn_remove.text = "移除物品"
	btn_add.position = Vector2(20, 400)
	btn_remove.position = Vector2(150, 400)
	add_child(btn_add)
	add_child(btn_remove)
	btn_add.connect("pressed", Callable(self, "_on_add_item_pressed"))
	btn_remove.connect("pressed", Callable(self, "_on_remove_item_pressed"))

func _on_add_item_pressed():
	var gun_path = "res://data/items/gun.tres"
	if ResourceLoader.exists(gun_path):
		var gun_item = load(gun_path)
		InventoryManager.add_item(gun_item, 1)
		backpack_ui.update_inventory()

func _on_remove_item_pressed():
	var item_path = "res://data/items/gun.tres"
	if ResourceLoader.exists(item_path):
		var item = load(item_path)
		InventoryManager.remove_item(item, 1)
		backpack_ui.update_inventory()
