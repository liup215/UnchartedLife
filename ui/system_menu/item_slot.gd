extends PanelContainer

signal slot_clicked(item: ItemData, quantity: int)

@onready var item_icon: TextureRect = $VBoxContainer/ItemIcon
@onready var quantity_label: Label = $VBoxContainer/QuantityLabel

var item_data: ItemData
var quantity: int = 0
var _pending_setup: bool = false

func _ready():
	if _pending_setup:
		_do_setup()

func setup(item: ItemData, qty: int):
	item_data = item
	quantity = qty
	
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
	else:
		# Empty slot
		item_icon.texture = null
		quantity_label.text = ""
		modulate = Color(0.5, 0.5, 0.5, 0.3)
		# Disable tooltip for empty slots
		tooltip_text = ""

func _get_tooltip_position():
	# Position tooltip to the right of the item slot
	var global_pos = get_global_rect()
	return Vector2(global_pos.end.x + 10, global_pos.position.y)

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		slot_clicked.emit(item_data, quantity)

func _make_custom_tooltip(_for_text):
	if item_data:
		var tooltip = "[b]%s[/b]" % item_data.item_name
		if item_data.description:
			tooltip += "\n%s" % item_data.description
		if quantity > 1:
			tooltip += "\nQuantity: %d" % quantity
		return tooltip
	return ""
