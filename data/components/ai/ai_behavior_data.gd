# ai_behavior_data.gd
# The base class for all AI behavior resources.
# Each specific behavior (like wandering or chasing) will extend this class.
extends Resource
class_name AIBehaviorData

@export var name: String = "Base AI Behavior"

func should_execute(actor: Node) -> bool:
	return true

# This function will be implemented by all concrete behavior classes.
# It takes the actor executing the behavior and the delta time as arguments.
func execute(actor: Node, delta: float):
	# Base implementation does nothing.
	pass
