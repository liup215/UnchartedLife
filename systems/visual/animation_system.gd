# systems/visual/animation_system.gd
# Central authority for playing animations on entities.
# Replaces direct parent.play_combat_animation() calls in ActorCombatComponent.
# Consumes PLAY_ANIMATION commands and dispatches to the appropriate AnimatedSprite2D.
extends Node
class_name AnimationSystem

## entity_id -> AnimationPlayer / AnimatedSprite2D reference (discovered at runtime)
var _entity_animators: Dictionary[int, Node] = {}

func register_entity_animator(entity_id: int, animator: Node) -> void:
	_entity_animators[entity_id] = animator

func unregister_entity(entity_id: int) -> void:
	_entity_animators.erase(entity_id)

## --- Command Bus Integration ---

func _ready() -> void:
	CommandBus.add_executor(CommandBus.CommandType.PLAY_ANIMATION, _on_play_animation)

func _exit_tree() -> void:
	CommandBus.remove_executor(CommandBus.CommandType.PLAY_ANIMATION, _on_play_animation)

func _on_play_animation(command: CommandBus.Command) -> void:
	var entity_id: int = command.issuer_entity
	var anim_name: String = command.payload.get("animation_name", "")
	var caller_name: String = command.payload.get("caller", "unknown")
	
	if anim_name.is_empty():
		return
	
	var animator = _entity_animators.get(entity_id, null)
	if not is_instance_valid(animator):
		# Try to discover via EntityManager
		var entity_manager = ServiceRegistry.get_service("EntityManager")
		if entity_manager:
			var node = entity_manager.get_entity_node(entity_id)
			if node and node.has_method("play_combat_animation"):
				node.play_combat_animation(anim_name)
				return
		GameLogger.warn("animation", "No animator registered for entity_id %d (caller: %s)" % [entity_id, caller_name])
		return
	
	if animator.has_method("play"):
		animator.play(anim_name)
	elif animator.has_method("play_animation"):
		animator.play_animation(anim_name)
	elif animator.has_method("play_combat_animation"):
		animator.play_combat_animation(anim_name)
