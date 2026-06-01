# data/components/special_equipment_data.gd
# A base class for special equipment (SE) components.
extends Resource
class_name SpecialEquipmentData

@export_group("Core Properties")
## The name of the equipment.
@export var equipment_name: String = "Special Equipment"
## The weight of the equipment.
@export var weight: float = 50.0
## The energy points required to equip this item.
@export var energy_cost: int = 3
