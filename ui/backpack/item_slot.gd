# item_slot.gd
extends PanelContainer

# 当这个物品槽被点击时发出信号，并把自身作为参数传递出去
signal slot_clicked(slot: Control)

@onready var icon_rect: TextureRect = $Icon
@onready var quantity_label: Label = $QuantityLabel
@onready var selection_border: Panel = $SelectionBorder

var item_data: ItemData

func _ready():
	# 无需手动连接，直接使用 _gui_input 回调
	pass

# 用从背包数据传来的信息来填充UI
func set_slot_data(slot_info):
	if not slot_info or slot_info.item == null:
		# 如果没有数据，则清空这个槽
		icon_rect.texture = null
		quantity_label.text = ""
		item_data = null
		return

	self.item_data = slot_info.item
	var quantity = slot_info.quantity

	if item_data == null:
		icon_rect.texture = null
		tooltip_text = ""
	else:
		var icon = item_data.icon
		if icon and typeof(icon) == TYPE_OBJECT:
			icon_rect.texture = icon
			tooltip_text = item_data.item_name

	if quantity > 1:
		quantity_label.text = str(quantity)
	else:
		quantity_label.text = ""

# 当被选中时，显示边框
func select():
	selection_border.modulate.a = 1.0

# 当取消选中时，隐藏边框
func deselect():
	selection_border.modulate.a = 0.0

# 处理鼠标输入
func _gui_input(event: InputEvent):
	# 检查是否是鼠标左键按下事件
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# 发出信号，通知父节点（BackpackUI）“我被点击了”
		slot_clicked.emit(self)
		# 接受事件，防止事件继续向上传播
		accept_event()
