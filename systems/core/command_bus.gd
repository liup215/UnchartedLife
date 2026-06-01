# systems/core/command_bus.gd
# Command Bus: the central pipeline for all gameplay actions.
# Every state change in the game flows through here as a serializable Command.
# Benefits: logging, validation, interception, replay, network sync.
extends Node
class_name CommandBus

enum CommandType {
	## Movement
	MOVE_REQUEST,
	DODGE_REQUEST,
	SPRINT_START,
	SPRINT_END,

	## Combat
	ATTACK_REQUEST,
	HEAVY_CHARGE_START,
	HEAVY_CHARGE_RELEASE,
	RELOAD_REQUEST,
	WEAPON_SWITCH,

	## Interaction
	INTERACT_REQUEST,
	ENTER_VEHICLE_REQUEST,
	EXIT_VEHICLE_REQUEST,
	PICKUP_ITEM,
	USE_ITEM,

	## Resources
	CONSUME_RESOURCE,
	RECOVER_RESOURCE,

	## Damage / Status
	APPLY_DAMAGE,
	APPLY_STATUS_EFFECT,
	REMOVE_STATUS_EFFECT,

	## Visual / Audio
	PLAY_ANIMATION,
	SPAWN_EFFECT,
	PLAY_SOUND,

	## Misc
	CUSTOM
}

## Immutable data packet. No node references — only entity_ids and primitives.
class Command:
	var type: CommandType
	var issuer_entity: int = -1
	var target_entity: int = -1
	var payload: Dictionary = {}
	var game_timestamp: float = 0.0

	func _init(p_type: CommandType = CommandType.CUSTOM, p_payload: Dictionary = {}) -> void:
		type = p_type
		payload = p_payload
		game_timestamp = Time.get_ticks_msec() / 1000.0

	## Serialization for save/replay/network.
	func to_dict() -> Dictionary:
		return {
			"type": type,
			"issuer": issuer_entity,
			"target": target_entity,
			"payload": payload,
			"timestamp": game_timestamp
		}

## Validators can reject commands before execution.
## Return true to allow execution, false to block.
## Signature: func(command: Command) -> bool
var _validators: Dictionary[CommandType, Array] = {}

## Executors handle the actual side effects.
## Signature: func(command: Command) -> void
var _executors: Dictionary[CommandType, Array] = {}

## Global listeners (observes ALL commands regardless of type).
## Signature: func(command: Command) -> void
var _listeners: Array[Callable] = []

signal command_issued(command: Command)
signal command_rejected(command: Command, reason: String)
signal command_executed(command: Command)

## Register a validator for a specific command type.
func add_validator(cmd_type: CommandType, validator: Callable) -> void:
	if not _validators.has(cmd_type):
		_validators[cmd_type] = []
	_validators[cmd_type].append(validator)

## Register an executor for a specific command type.
func add_executor(cmd_type: CommandType, executor: Callable) -> void:
	if not _executors.has(cmd_type):
		_executors[cmd_type] = []
	_executors[cmd_type].append(executor)

## Remove a previously registered executor.
func remove_executor(cmd_type: CommandType, executor: Callable) -> void:
	if _executors.has(cmd_type):
		_executors[cmd_type].erase(executor)

## Add a global listener.
func add_listener(listener: Callable) -> void:
	_listeners.append(listener)

func remove_listener(listener: Callable) -> void:
	_listeners.erase(listener)

## The main entry point. Issuing a command triggers validation then execution.
func issue(command: Command) -> bool:
	command_issued.emit(command)

	## Notify global listeners first (for logging/audit, non-blocking)
	for listener in _listeners:
		listener.call(command)

	## Validation phase
	var validation = _validate(command)
	if not validation.passed:
		command_rejected.emit(command, validation.reason)
		return false

	## Execution phase
	_execute(command)
	command_executed.emit(command)
	return true

class ValidationResult:
	var passed: bool = true
	var reason: String = ""

func _validate(command: Command) -> ValidationResult:
	var result := ValidationResult.new()
	var validators: Array = _validators.get(command.type, [])
	for validator in validators:
		if not validator.is_valid():
			continue
		var ok: bool = validator.call(command)
		if not ok:
			result.passed = false
			result.reason = "Validator rejected command of type %d" % command.type
			return result
	return result

func _execute(command: Command) -> void:
	var executors: Array = _executors.get(command.type, [])
	for executor in executors:
		if not executor.is_valid():
			continue
		executor.call(command)

## Convenience: create and issue in one call.
static func create_command(cmd_type: CommandType, payload: Dictionary = {},
		issuer: int = -1, target: int = -1) -> Command:
	var cmd := Command.new(cmd_type, payload)
	cmd.issuer_entity = issuer
	cmd.target_entity = target
	return cmd
