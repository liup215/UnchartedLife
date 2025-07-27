# data/components/vehicle_skill_data.gd
# Defines a skill that can be unlocked and used by a vehicle.
extends Resource
class_name VehicleSkillData

@export_group("Core Properties")
## The name of the skill.
@export var skill_name: String = "New Skill"
## A description of what the skill does.
@export_multiline var description: String = "Skill description."
## The energy points required to unlock or equip this skill.
@export var energy_cost: int = 10

# --- Skill Effect ---
# The actual implementation of the skill's effect will be handled by the
# relevant systems (e.g., combat system, movement system) which will
# check if the vehicle has a specific skill.
# For example, you could add an ID to check against.
@export var skill_id: String = "unique_skill_id"
