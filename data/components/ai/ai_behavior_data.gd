# ai_behavior_data.gd
# The base class for all AI behavior resources.
# Each specific behavior (like wandering or chasing) will extend this class.
extends Resource
class_name AIBehaviorData

# This function will be implemented by all concrete behavior classes.
# It takes the actor executing the behavior and the delta time as arguments.
func execute(actor: Node, delta: float):
    # Base implementation does nothing.
    pass
