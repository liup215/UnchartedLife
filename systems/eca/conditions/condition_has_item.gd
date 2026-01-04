# condition_has_item.gd
# Condition that checks if the player has a specific item in their inventory.
extends GameCondition
class_name ConditionHasItem

# The item to check for (compared by item_name)
@export var item_id: String = ""

# The minimum number of items required
@export var required_count: int = 1

# Check if the player has the required item count
func is_met(context: Node) -> bool:
	if item_id.is_empty():
		push_warning("ConditionHasItem: item_id is empty")
		return false
	
	# Find the player node in the scene tree
	var player: Node = _get_player(context)
	if not player:
		push_warning("ConditionHasItem: Player not found in scene")
		return false
	
	# Check if player has inventory_component
	if not "inventory_component" in player:
		push_warning("ConditionHasItem: Player has no inventory_component")
		return false
	
	var inventory_component: InventoryComponent = player.inventory_component
	if not inventory_component:
		push_warning("ConditionHasItem: inventory_component is null")
		return false
	
	# Get all containers and check for item
	var total_count: int = 0
	var containers: Dictionary = inventory_component.get_all_containers()
	
	for container_name in containers.keys():
		var container: InventoryData = containers[container_name]
		if container and container.items:
			# Check all items in this container
			for item in container.items:
				if item and item.item_name == item_id:
					# Find the count for this item
					var item_index = container.items.find(item)
					if item_index >= 0 and item_index < container.item_counts.size():
						total_count += container.item_counts[item_index]
	
	# Check if we have enough
	var has_enough = total_count >= required_count
	
	if has_enough:
		print("ConditionHasItem: Player has %d of '%s' (required: %d)" % [total_count, item_id, required_count])
	else:
		print("ConditionHasItem: Player has only %d of '%s' (required: %d)" % [total_count, item_id, required_count])
	
	return has_enough

# Helper function to get the player from the scene tree
func _get_player(context: Node) -> Node:
	# Try to get player from the context's scene tree
	var tree: SceneTree = context.get_tree()
	if not tree:
		return null
	
	var players: Array[Node] = tree.get_nodes_in_group("player")
	if players.is_empty():
		return null
	
	return players[0]
