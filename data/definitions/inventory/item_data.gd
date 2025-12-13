# item_data.gd
# A custom Resource to hold data for any item in the game.
class_name ItemData
extends Resource

enum ItemType { WEAPON, ARMOR, CONSUMABLE, KEY_ITEM, QUEST, MATERIAL, SPECIAL }

@export var item_name: String = "New Item"
@export var item_type: ItemType = ItemType.KEY_ITEM
@export_multiline var description: String = ""

@export var icon: Texture2D
@export var stackable: bool = false
@export var max_stack_size: int = 1

# Optional data blocks for complex types (e.g., weapons)
@export var weapon_data: WeaponData

# Usage properties
@export var usable: bool = true
@export var cooldown: float = 0.0  # Seconds between uses
@export var consumption_mode: int = 0  # 0: ConsumeOnUse, 1: ConsumeOnSuccess, 2: NotConsumable

# Effects and requirements
@export var effects: Array[ItemEffectData] = []
@export var use_requirements: Array[Dictionary] = []  # Array of requirement dictionaries

# You can add specific properties for different item types, for example:
# @export_group("Weapon Stats")
# @export var damage: int = 0