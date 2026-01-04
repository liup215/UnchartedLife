# game_event_data.gd
# Resource that holds an array of conditions and actions for event-driven gameplay.
# Part of the ECA (Event-Condition-Action) system.
extends Resource
class_name GameEventData

# Array of conditions that must ALL be met for actions to execute
@export var conditions: Array[GameCondition] = []

# Array of actions to execute when all conditions are met
@export var actions: Array[GameAction] = []

# Optional identifier for debugging and tracking
@export var event_id: String = ""

# Try to execute this event's actions if all conditions are met
# @param context: The Node context (typically GameScene) passed to conditions and actions
# @returns: true if all conditions were met and actions executed, false otherwise
func try_execute(context: Node) -> bool:
	# Check all conditions
	for condition in conditions:
		if condition and not condition.is_met(context):
			return false  # At least one condition not met, abort
	
	# All conditions met (or no conditions), execute all actions
	for action in actions:
		if action:
			action.execute(context)
	
	return true
