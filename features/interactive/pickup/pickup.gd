class_name Pickup extends Node2D

@export var item_data: ItemData

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var interactable_component: InteractableComponent = $InteractableComponent

func _ready():
	if item_data:
		_update_visuals()
	
	interactable_component.interacted.connect(_on_interacted)
	interactable_component.body_entered.connect(_on_player_entered)
	interactable_component.body_exited.connect(_on_player_exited)

func _update_visuals():
	if item_data and item_data.icon:
		sprite_2d.texture = item_data.icon

func _on_interacted(actor):
	# Try to find InventoryComponent on the actor
	var inventory = _find_inventory_component(actor)
	
	if inventory:
		if inventory.add_item(item_data):
			print("Picked up: " + item_data.item_name)
			queue_free()
		else:
			print("Inventory full!")
	else:
		print("Actor has no inventory!")

func _find_inventory_component(node: Node) -> InventoryComponent:
	# Check if the node itself is the component (unlikely but possible)
	if node is InventoryComponent:
		return node
		
	# Check direct children
	for child in node.get_children():
		if child is InventoryComponent:
			return child
			
	# Check specific path if standard naming is used
	var component = node.get_node_or_null("InventoryComponent")
	if component:
		return component
		
	return null

func _on_player_entered(body):
	if body.is_in_group("player"): # 确保是玩家
		sprite_2d.modulate = Color(1.5, 1.5, 1.5) # 变亮
		sprite_2d.scale = Vector2(1.5, 1.5) # 放大

func _on_player_exited(body):
	if body.is_in_group("player"):
		sprite_2d.modulate = Color(1, 1, 1) # 恢复
		sprite_2d.scale = Vector2(1, 1) # 恢复
