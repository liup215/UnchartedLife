# systems/input/dodge_command_handler.gd
# Bridges DODGE_REQUEST commands to Player's DodgeComponent.
# Ensures dodge validation (PlayerStateMachine state check) is performed before execution.
extends Node
class_name DodgeCommandHandler

func _ready() -> void:
	CommandBus.add_validator(CommandBus.CommandType.DODGE_REQUEST, _validate_dodge)
	CommandBus.add_executor(CommandBus.CommandType.DODGE_REQUEST, _on_dodge_request)

func _exit_tree() -> void:
	CommandBus.remove_validator(CommandBus.CommandType.DODGE_REQUEST, _validate_dodge)
	CommandBus.remove_executor(CommandBus.CommandType.DODGE_REQUEST, _on_dodge_request)

func _validate_dodge(_command: CommandBus.Command) -> bool:
	var psm = ServiceRegistry.get_service("PlayerStateMachine")
	if not psm:
		return false
	return psm.can_request_dodge()

func _on_dodge_request(_command: CommandBus.Command) -> void:
	var psm = ServiceRegistry.get_service("PlayerStateMachine")
	if not psm or not psm.player_actor:
		return

	var player := psm.player_actor as Player
	if not player or not player.dodge_component:
		return

	var direction = Vector2.ZERO
	if player.input_component:
		direction = player.input_component.desired_direction
	if direction.length() == 0:
		if player.velocity.length() > 0:
			direction = player.velocity.normalized()
		else:
			direction = player.last_direction

	player.dodge_component.attempt_dodge(direction)
