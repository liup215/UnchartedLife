# item_data.gd
# A custom Resource to hold data for any item in the game.
class_name ItemData
extends Resource

enum ItemType { WEAPON, ARMOR, CONSUMABLE, MISC }

@export var item_name: String = "New Item"
@export var item_type: ItemType = ItemType.MISC
@export_multiline var description: String = ""

@export var icon: Texture2D
@export var stackable: bool = false
@export var max_stack_size: int = 1

# You can add specific properties for different item types, for example:
# @export_group("Weapon Stats")
# @export var damage: int = 0
