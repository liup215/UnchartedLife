# game_action.gd
# Base class for all game actions in the ECA (Event-Condition-Action) system.
# Actions define what happens when triggered (e.g., show dialog, spawn actor).
extends Resource
class_name GameAction

# Virtual method that subclasses must override to define action behavior
# @param context: The Node context in which this action executes (typically the GameScene)
func execute(context: Node) -> void:
	push_error("GameAction.execute() not implemented in subclass %s" % get_script().resource_path)
