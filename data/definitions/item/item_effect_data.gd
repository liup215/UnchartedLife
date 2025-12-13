# ItemEffectData.gd
# Resource defining effects that can be applied when using an item
# Supports various effect types for different item behaviors

extends Resource
class_name ItemEffectData

enum EffectType {
    HEAL,                    # Restore health
    RESTORE_RESOURCE,        # Restore ATP/Glucose
    APPLY_BUFF,             # Apply temporary buff/debuff
    GRANT_ITEM,             # Add item to inventory
    EQUIP,                  # Equip weapon/armor
    TRIGGER_QUEST,          # Advance quest state
    UNLOCK_AREA,            # Unlock map area
    TELEPORT,               # Teleport to location
    FIRE_EVENT,             # Fire custom event
    REVIVE,                 # Revive fallen actor
    MODIFY_STAT,            # Modify permanent stats
    CONSUME_RESOURCE        # Consume ATP/Glucose
}

@export var effect_type: EffectType = EffectType.HEAL
@export var params: Dictionary = {}  # Flexible parameters for each effect type

# Validation and helper methods
func _init() -> void:
    params = {}

func get_effect_type_name() -> String:
    return EffectType.keys()[effect_type]

func validate_params() -> bool:
    # Basic validation for required parameters
    match effect_type:
        EffectType.HEAL:
            return params.has("amount") and params["amount"] is float
        EffectType.RESTORE_RESOURCE:
            return params.has("resource_type") and params.has("amount")
        EffectType.APPLY_BUFF:
            return params.has("buff_id") and params.has("duration")
        EffectType.GRANT_ITEM:
            return params.has("item_id") and params.has("quantity")
        EffectType.EQUIP:
            return params.has("equipment_type") and params.has("equipment_id")
        EffectType.TRIGGER_QUEST:
            return params.has("quest_id") and params.has("step")
        EffectType.UNLOCK_AREA:
            return params.has("area_id")
        EffectType.TELEPORT:
            return params.has("target_position") or params.has("target_scene")
        EffectType.FIRE_EVENT:
            return params.has("event_name")
        EffectType.REVIVE:
            return params.has("revive_percentage") if params.has("revive_percentage") else true
        EffectType.MODIFY_STAT:
            return params.has("stat_name") and params.has("modifier")
        EffectType.CONSUME_RESOURCE:
            return params.has("resource_type") and params.has("amount")
        _:
            return true
    return false