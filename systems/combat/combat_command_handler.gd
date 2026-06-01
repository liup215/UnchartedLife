# systems/combat/combat_command_handler.gd
# Bridges CommandBus combat commands -> ActorCombatComponent.
# This is the single point where input commands become combat actions.
# No node references are hardcoded; resolves player combat via PlayerStateMachine.
extends Node
class_name CombatCommandHandler

func _ready() -> void:
	CommandBus.add_executor(CommandBus.CommandType.ATTACK_REQUEST, _on_attack_request)
	CommandBus.add_executor(CommandBus.CommandType.ATTACK_RELEASED, _on_attack_released)
	CommandBus.add_executor(CommandBus.CommandType.HEAVY_CHARGE_START, _on_heavy_charge_start)
	CommandBus.add_executor(CommandBus.CommandType.HEAVY_CHARGE_RELEASE, _on_heavy_charge_release)
	CommandBus.add_executor(CommandBus.CommandType.RELOAD_REQUEST, _on_reload_request)

func _exit_tree() -> void:
	CommandBus.remove_executor(CommandBus.CommandType.ATTACK_REQUEST, _on_attack_request)
	CommandBus.remove_executor(CommandBus.CommandType.ATTACK_RELEASED, _on_attack_released)
	CommandBus.remove_executor(CommandBus.CommandType.HEAVY_CHARGE_START, _on_heavy_charge_start)
	CommandBus.remove_executor(CommandBus.CommandType.HEAVY_CHARGE_RELEASE, _on_heavy_charge_release)
	CommandBus.remove_executor(CommandBus.CommandType.RELOAD_REQUEST, _on_reload_request)

func _on_attack_request(_command: CommandBus.Command) -> void:
	var combat = _get_player_actor_combat()
	if combat:
		combat.perform_light_attack()

func _on_attack_released(_command: CommandBus.Command) -> void:
	# Light attack "released" has no specific action in the current system
	# (unlike heavy charge).
	pass

func _on_heavy_charge_start(_command: CommandBus.Command) -> void:
	var combat = _get_player_actor_combat()
	if combat:
		combat.start_heavy_attack_charge()

func _on_heavy_charge_release(_command: CommandBus.Command) -> void:
	var combat = _get_player_actor_combat()
	if combat:
		combat.release_heavy_attack()

func _on_reload_request(_command: CommandBus.Command) -> void:
	var combat = _get_player_actor_combat()
	if combat:
		combat.reload_all_weapons()

func _get_player_actor_combat() -> ActorCombatComponent:
	var psm: PlayerStateMachine = ServiceRegistry.get_service("PlayerStateMachine")
	if not psm or not psm.player_actor:
		return null
	var actor := psm.player_actor as Actor
	if actor and actor.actor_combat_component:
		return actor.actor_combat_component
	return null
