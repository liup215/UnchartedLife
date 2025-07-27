# data/components/armor_data.gd
# Defines the properties of armor plating, a type of special equipment.
extends SpecialEquipmentData
class_name ArmorData

@export_group("Defense Properties")
## The flat defense bonus provided by this armor.
@export var defense_bonus: int = 25
## A dictionary of resistance bonuses (e.g., {"fire": 0.1, "acid": 0.05}).
@export var resistance_bonuses: Dictionary = {}
