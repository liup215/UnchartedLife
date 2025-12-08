extends Control

@onready var tab_container: TabContainer = $HBoxContainer/LeftPanel/TabContainer
@onready var item_details_panel: PanelContainer = $HBoxContainer/RightPanel
@onready var item_name_label: Label = $HBoxContainer/RightPanel/VBoxContainer/ItemNameLabel
@onready var item_icon: TextureRect = $HBoxContainer/RightPanel/VBoxContainer/ItemIcon
@onready var item_description: Label = $HBoxContainer/RightPanel/VBoxContainer/ItemDescription
@onready var item_quantity: Label = $HBoxContainer/RightPanel/VBoxContainer/ItemQuantity

const ITEM_SLOT_SCENE = preload("res://ui/system_menu/item_slot.tscn")

var player_inventory_component: InventoryComponent
var current_container_name: String = ""
var item_slots: Dictionary = {}  # container_name -> Array[ItemSlot]

func _ready():
	_find_player_inventory()
	_setup_container_tabs()
	update_all_containers_display()

func _find_player_inventory():
	# Find player node and get its inventory component
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0] as Actor
		if player and player.inventory_component:
			player_inventory_component = player.inventory_component
			# Connect to inventory update signals
			player_inventory_component.inventory_updated.connect(_on_inventory_updated)
			player_inventory_component.item_added.connect(_on_item_added)

func _setup_container_tabs():
	if not player_inventory_component:
		return
	
	# Clear existing tabs
	for child in tab_container.get_children():
		child.queue_free()
	
	# Create tabs for each container
	var containers = player_inventory_component.get_all_containers()
	for container_name in containers.keys():
		var tab = VBoxContainer.new()
		tab.name = container_name
		tab.size_flags_vertical = SIZE_EXPAND_FILL
		tab_container.add_child(tab)
		
		# Create capacity label at the top
		var capacity_label = Label.new()
		capacity_label.name = "CapacityLabel"
		capacity_label.text = "Capacity: 0 / 30"
		capacity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		capacity_label.size_flags_horizontal = SIZE_EXPAND_FILL
		tab.add_child(capacity_label)
		
		# Create scrollable grid for this container
		var scroll_container = ScrollContainer.new()
		scroll_container.name = "ScrollContainer"
		scroll_container.size_flags_vertical = SIZE_EXPAND_FILL
		scroll_container.size_flags_horizontal = SIZE_EXPAND_FILL
		tab.add_child(scroll_container)
		
		var grid_container = GridContainer.new()
		grid_container.name = "GridContainer"
		grid_container.columns = 5
		grid_container.size_flags_horizontal = SIZE_EXPAND_FILL
		scroll_container.add_child(grid_container)
		
		# Initialize item slots array for this container
		item_slots[container_name] = []

func update_all_containers_display():
	if not player_inventory_component:
		return
	
	var containers = player_inventory_component.get_all_containers()
	for container_name in containers.keys():
		update_container_display(container_name)

func update_container_display(container_name: String):
	if not player_inventory_component or not item_slots.has(container_name):
		return
	
	# Clear existing slots for this container
	for slot in item_slots[container_name]:
		slot.queue_free()
	item_slots[container_name].clear()
	
	# Get container data
	var containers = player_inventory_component.get_all_containers()
	if not containers.has(container_name):
		return
	
	var container_data = containers[container_name] as InventoryData
	
	# Find the tab and its grid container
	var tab = tab_container.get_node(container_name)
	if not tab:
		return
	
	var grid_container = tab.get_node("ScrollContainer/GridContainer") as GridContainer
	var capacity_label = tab.get_node("CapacityLabel") as Label
	
	if not grid_container or not capacity_label:
		return
	
	# Update capacity display
	var used_slots = container_data.slots.size()
	var capacity = container_data.capacity
	if container_data.is_unlimited:
		capacity_label.text = "Capacity: Unlimited"
	else:
		capacity_label.text = "Capacity: %d / %d" % [used_slots, capacity]
	
	# Create item slots
	for slot_key in container_data.slots:
		var slot_data = container_data.slots[slot_key]
		if slot_data is InventoryData.InventorySlotData:
			var item_slot = ITEM_SLOT_SCENE.instantiate()
			item_slot.setup(slot_data.item, slot_data.quantity)
			item_slot.connect("slot_clicked", Callable(self, "_on_item_slot_clicked").bind(container_name))
			grid_container.add_child(item_slot)
			item_slots[container_name].append(item_slot)
	
	# Fill empty slots if not unlimited
	if not container_data.is_unlimited:
		var empty_slots = capacity - container_data.slots.size()
		for i in range(empty_slots):
			var empty_slot = ITEM_SLOT_SCENE.instantiate()
			empty_slot.setup(null, 0)  # Empty slot
			grid_container.add_child(empty_slot)
			item_slots[container_name].append(empty_slot)

func _on_inventory_updated(container_name: String, _inventory_data: InventoryData):
	update_container_display(container_name)

func _on_item_added(_item: ItemData, _amount: int, container_name: String):
	update_container_display(container_name)

func _on_item_slot_clicked(item: ItemData, quantity: int, _container_name: String):
	if item == null:
		# Show default message when no item is selected
		item_name_label.text = "Select an item to view details"
		item_icon.texture = preload("res://assets/charactor/actor01.png")
		item_description.text = "Click on an item in your inventory to see its details here."
		item_quantity.text = "Quantity: 0"
		return
	
	# Show item details
	item_name_label.text = item.item_name
	item_icon.texture = item.icon if item.icon else preload("res://assets/charactor/actor01.png")
	item_description.text = item.description
	item_quantity.text = "Quantity: %d" % quantity
