extends PanelContainer

signal slot_clicked(item: ItemData, quantity: int)
signal item_used(item: ItemData, success: bool)

@onready var item_icon: TextureRect = $VBoxContainer/ItemIcon
@onready var quantity_label: Label = $VBoxContainer/QuantityLabel
@onready var use_button: Button = $VBoxContainer/UseButton

var item_data: ItemData
var quantity: int = 0
var container_name: String = ""
var _pending_setup: bool = false

func _ready():
	if _pending_setup:
		_do_setup()
	
	# Connect to ItemUseService signals
	ItemUseService.item_used.connect(_on_item_used)
	ItemUseService.item_use_failed.connect(_on_item_use_failed)

func setup(item: ItemData, qty: int, container: String = ""):
	item_data = item
	quantity = qty
	container_name = container
	
	if not is_node_ready():
		_pending_setup = true
		return
	
	_do_setup()

func _do_setup():
	if item_data:
		# Item slot
		item_icon.texture = item_data.icon if item_data.icon else preload("res://assets/charactor/actor01.png")
		if quantity > 1:
			quantity_label.text = str(quantity)
		else:
			quantity_label.text = ""
		modulate = Color(1, 1, 1, 1)
		# Enable tooltip for items
		tooltip_text = item_data.item_name
		
		# Show use button for usable items
		use_button.visible = item_data.usable
		use_button.disabled = false
	else:
		# Empty slot
		item_icon.texture = null
		quantity_label.text = ""
		modulate = Color(0.5, 0.5, 0.5, 0.3)
		# Disable tooltip for empty slots
		tooltip_text = ""
		use_button.visible = false

func _get_tooltip_position():
	# Position tooltip to the right of the item slot
	var global_pos = get_global_rect()
	return Vector2(global_pos.end.x + 10, global_pos.position.y)

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		slot_clicked.emit(item_data, quantity)

func _on_use_button_pressed():
	if item_data and container_name:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var player = players[0] as Actor
			if player:
				use_button.disabled = true
				ItemUseService.use_item(player, item_data, container_name)

func _on_item_used(actor: Actor, item: ItemData, success: bool):
	if item == item_data:
		use_button.disabled = false
		item_used.emit(item, success)

func _on_item_use_failed(actor: Actor, item: ItemData, reason: String):
	if item == item_data:
		use_button.disabled = false
		# Could show error message here
		push_warning("Item use failed: %s" % reason)

func _make_custom_tooltip(_for_text):
	if item_data:
		var tooltip = "[b]%s[/b]" % item_data.item_name
		if item_data.description:
			tooltip += "\n%s" % item_data.description
		if quantity > 1:
			tooltip += "\nQuantity: %d" % quantity
		if item_data.usable:
			tooltip += "\n[color=green]Usable[/color]"
		else:
			tooltip += "\n[color=gray]Not usable[/color]"
		return tooltip
	return ""
