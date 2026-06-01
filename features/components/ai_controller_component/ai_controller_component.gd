# ai_controller_component.gd
# Manages behavior scheduling for AI-controlled actors.
# Extracted from Actor._physics_process to separate AI logic from actor scene mechanics.
extends Node
class_name AIControllerComponent

## The behaviors this controller will execute, in priority order.
@export var behaviors: Array[AIBehaviorData] = []

## Whether this AI controller is currently active.
var is_active: bool = true

## Set behaviors from an external source (e.g., ActorData at spawn).
func set_behaviors(new_behaviors: Array[AIBehaviorData]):
	behaviors = new_behaviors.duplicate()

## Execute behaviors in priority order until one runs.
## Returns true if any behavior was executed.
func execute(delta: float, actor: Actor) -> bool:
	if not is_active:
		return false
	
	if behaviors.is_empty():
		return false
	
	# Reset actor velocity before evaluating behaviors
	actor.velocity = Vector2.ZERO
	
	for behavior in behaviors:
		if not behavior:
			continue
		
		if behavior.has_method("should_execute"):
			if behavior.should_execute(actor):
				behavior.execute(actor, delta)
				return true
		else:
			behavior.execute(actor, delta)
			return true
	
	return false

## Temporarily disable AI (e.g., during cutscenes or death).
func disable_ai():
	is_active = false

## Re-enable AI.
func enable_ai():
	is_active = true

## Check if AI is active.
func is_ai_active() -> bool:
	return is_active