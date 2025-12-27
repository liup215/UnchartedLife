extends Control

@onready var weapon_button: Button = $HBoxContainer/LeftPanel/Slots/WeaponButton
@onready var armor_button: Button = $HBoxContainer/LeftPanel/Slots/ArmorButton
@onready var gloves_button: Button = $HBoxContainer/LeftPanel/Slots/GlovesButton
@onready var helmet_button: Button = $HBoxContainer/LeftPanel/Slots/HelmetButton
@onready var boots_button: Button = $HBoxContainer/LeftPanel/Slots/BootsButton

@onready var details_panel: PanelContainer = $HBoxContainer/RightPanel
@onready var name_label: Label = $HBoxContainer/RightPanel/VBoxContainer/NameLabel
@onready var icon_rect: TextureRect = $HBoxContainer/RightPanel/VBoxContainer/Icon
@onready var stats_label: Label = $HBoxContainer/RightPanel/VBoxContainer/StatsLabel
@onready var unequip_button: Button = $HBoxContainer/RightPanel/VBoxContainer/UnequipButton

@export var placeholder_icon: Texture2D

var _player: Actor
var _combat: ActorCombatComponent
var _equipped_items: Dictionary[String, ItemData] = {}
var _equipped_weapon_component: WeaponComponent
var _selected_slot: String = ""

func _ready() -> void:
	weapon_button.pressed.connect(func() -> void: _select_slot("weapon"))
	armor_button.pressed.connect(func() -> void: _select_slot("armor"))
	gloves_button.pressed.connect(func() -> void: _select_slot("gloves"))
	helmet_button.pressed.connect(func() -> void: _select_slot("helmet"))
	boots_button.pressed.connect(func() -> void: _select_slot("boots"))
	unequip_button.pressed.connect(_on_unequip_pressed)

	EventBus.item_used.connect(_on_item_used)
	EventBus.equipment_changed.connect(_on_equipment_changed)
	call_deferred("_refresh")

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree():
		call_deferred("_refresh")

func _refresh() -> void:
	_player = _find_player()
	_combat = _player.actor_combat_component if _player else null
	_equipped_items.clear()
	_equipped_weapon_component = null

	if _combat and _combat.actor_weapons.size() > 0:
		var wc: WeaponComponent = _combat.actor_weapons[0]
		if wc and wc.item_data:
			_equipped_weapon_component = wc
			_equipped_items["weapon"] = wc.item_data

	_update_slot_button(weapon_button, "Weapon", _equipped_items.get("weapon", null))
	_update_slot_button(armor_button, "Armor", _equipped_items.get("armor", null))
	_update_slot_button(gloves_button, "Gloves", _equipped_items.get("gloves", null))
	_update_slot_button(helmet_button, "Helmet", _equipped_items.get("helmet", null))
	_update_slot_button(boots_button, "Boots", _equipped_items.get("boots", null))

	if _selected_slot.is_empty():
		_update_details_for_slot("weapon")
	else:
		_update_details_for_slot(_selected_slot)

func _update_slot_button(button: Button, slot_label: String, item: ItemData) -> void:
	if item:
		button.text = "%s: %s" % [slot_label, item.item_name]
		button.icon = item.icon if item.icon else placeholder_icon
	else:
		button.text = "%s: (Empty)" % slot_label
		button.icon = placeholder_icon

func _select_slot(slot_key: String) -> void:
	_selected_slot = slot_key
	_update_details_for_slot(slot_key)

func _find_player() -> Actor:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return null
	return players[0] as Actor

func _update_details_for_slot(slot_key: String) -> void:
	var item: ItemData = _equipped_items.get(slot_key, null)
	if item == null:
		name_label.text = "%s: (Empty)" % slot_key.capitalize()
		icon_rect.texture = placeholder_icon
		stats_label.text = ""
		unequip_button.disabled = true
		return

	name_label.text = item.item_name
	icon_rect.texture = item.icon if item.icon else placeholder_icon

	if slot_key == "weapon":
		unequip_button.disabled = false
		var wdata: WeaponData = item.weapon_data
		var ammo_text: String = ""
		if _equipped_weapon_component:
			ammo_text = "Ammo: %d" % int(_equipped_weapon_component.current_ammo)

		if wdata:
			stats_label.text = "Damage: %.1f\nRate: %.2f\nAmmo Cap: %d\n%s" % [
				wdata.damage,
				wdata.rate_of_fire,
				wdata.ammo_capacity,
				ammo_text,
			]
		else:
			stats_label.text = ammo_text
		return

	# Non-weapon slots: show description for now (equip system can extend later)
	unequip_button.disabled = true
	stats_label.text = item.description

func _on_item_used(actor: Actor, item: ItemData, success: bool) -> void:
	if not success:
		return
	if item and item.item_type == ItemData.ItemType.WEAPON:
		# Weapon may have been equipped; refresh list
		_refresh()

func _on_equipment_changed(actor: Actor) -> void:
	if actor == null:
		return
	if _player == null:
		return
	if actor != _player:
		return
	_refresh()

func _on_unequip_pressed() -> void:
	if _player == null:
		_player = _find_player()
	if _player == null:
		return

	# Currently only weapon slot supports runtime equip/unequip.
	if _selected_slot != "weapon":
		return
	if not _equipped_items.has("weapon"):
		return

	unequip_button.disabled = true
	ItemUseService.unequip_weapon(_player, "weapons")
	call_deferred("_refresh")
