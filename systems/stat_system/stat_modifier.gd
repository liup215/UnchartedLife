# systems/stat_system/stat_modifier.gd
# Pure data class representing a modification to a stat.
# Used by StatSystem to compute final values.
extends RefCounted
class_name StatModifier

enum Operation {
	ADD,          # value += modifier
	MULTIPLY,     # value *= modifier
	OVERRIDE,     # value = modifier (highest priority wins if multiple)
	MIN,          # value = max(value, modifier) — floors
	MAX           # value = min(value, modifier) — caps
}

var stat_id: String
var operation: Operation
var value: float
var priority: int = 0      # Higher priority applies later.
var source_id: String = "" # e.g. "buff_speed_boost", "equipment_boots"
var duration: float = -1.0 # -1 = permanent, else seconds remaining

func _init(p_stat_id: String, p_op: Operation, p_value: float,
		p_priority: int = 0, p_source: String = "", p_duration: float = -1.0) -> void:
	stat_id = p_stat_id
	operation = p_op
	value = p_value
	priority = p_priority
	source_id = p_source
	duration = p_duration

## Apply this modifier to a base value and return the result.
func apply(current_value: float) -> float:
	match operation:
		Operation.ADD:
			return current_value + value
		Operation.MULTIPLY:
			return current_value * value
		Operation.OVERRIDE:
			return value
		Operation.MIN:
			return max(current_value, value)
		Operation.MAX:
			return min(current_value, value)
		_:
			return current_value
