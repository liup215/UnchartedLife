# systems/vehicle/vehicle_command_handler.gd
# Bridges INTERACT_REQUEST commands to Player vehicle logic.
# Replaces direct vehicle interaction in Player._handle_vehicle_interaction().
extends Node
class_name VehicleCommandHandler

func _ready() -> void:
	CommandBus.add_executor(CommandBus.CommandType.INTERACT_REQUEST, _on_interact_request)

func _exit_tree() -> void:
	CommandBus.remove_executor(CommandBus.CommandType.INTERACT_REQUEST, _on_interact_request)

func _on_interact_request(_command: CommandBus.Command) -> void:
	var psm = ServiceRegistry.get_service("PlayerStateMachine")
	if not psm or not psm.player_actor:
		return

	var player := psm.player_actor as Player
	if not player:
		return

	# Delegate to Player's vehicle interaction (legacy method during transition)
	player._handle_vehicle_interaction_legacy()
