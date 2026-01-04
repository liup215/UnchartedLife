# game_condition.gd
# Base class for all game conditions in the ECA (Event-Condition-Action) system.
# Conditions determine whether actions should be executed.
extends Resource
class_name GameCondition

# Virtual method that subclasses must override to check if condition is met
# @param context: The Node context in which to check the condition (typically the GameScene)
# @returns: true if the condition is met, false otherwise
func is_met(context: Node) -> bool:
	push_error("GameCondition.is_met() not implemented in subclass %s" % get_script().resource_path)
	return false
