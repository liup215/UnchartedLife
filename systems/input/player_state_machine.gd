# systems/input/player_state_machine.gd
# Replaces the PlayerState enum and state management in Player.gd.
# Sits between InputCommandSystem (produces commands) and Player (receives commands).
# Handles state transitions: ON_FOOT -> IN_VEHICLE and back, as well as
# combat state transitions (stagger, dodge, etc.) that don't belong in Player.gd.
extends Node
class_name PlayerStateMachine

enum PlayerState {
	ON_FOOT,
	IN_VEHICLE,
}

enum CombatState {
	NORMAL,
	DODGING,
	STAGGERED,
	CHARGING,
	ATTACKING,
}

signal state_changed(new_state: PlayerState)
signal combat_state_changed(new_combat_state: CombatState)

var current_state: PlayerState = PlayerState.ON_FOOT
var current_combat_state: CombatState = CombatState.NORMAL

## Currently occupied vehicle (Node reference; this is one of the few places
## we allow a node reference, but it is managed by this system only).
var current_vehicle: Node2D = null

## Cached player reference (set by Player during initialization).
var player_actor: Actor = null

## --- Public Methods ---

func can_request_movement() -> bool:
	return current_state == PlayerState.ON_FOOT

func can_request_attack() -> bool:
	if current_state == PlayerState.IN_VEHICLE:
		return false
	return current_combat_state == CombatState.NORMAL

func can_request_dodge() -> bool:
	if current_state != PlayerState.ON_FOOT:
		return false
	return current_combat_state == CombatState.NORMAL

func can_request_interact() -> bool:
	return current_combat_state == CombatState.NORMAL

func can_request_charge() -> bool:
	if current_state == PlayerState.IN_VEHICLE:
		return false
	return current_combat_state in [CombatState.NORMAL, CombatState.ATTACKING]

func is_in_vehicle() -> bool:
	return current_state == PlayerState.IN_VEHICLE

## --- State Transitions ---

func transition_to_state(new_state: PlayerState, context: Dictionary = {}) -> void:
	if current_state == new_state:
		return
	
	# Leaving state
	match current_state:
		PlayerState.ON_FOOT:
			_on_leave_on_foot()
		PlayerState.IN_VEHICLE:
			_on_leave_vehicle()
	
	current_state = new_state
	
	# Entering state
	match new_state:
		PlayerState.ON_FOOT:
			_on_enter_on_foot()
		PlayerState.IN_VEHICLE:
			# vehicle node passed in context
			_on_enter_vehicle(context.get("vehicle", null))
	
	state_changed.emit(new_state)

func transition_combat_state(new_combat_state: CombatState) -> void:
	if current_combat_state == new_combat_state:
		return
	current_combat_state = new_combat_state
	combat_state_changed.emit(new_combat_state)

## --- Command Bus Handling ---

func _ready() -> void:
	CommandBus.command_executed.connect(_on_command_executed)

func _on_command_executed(command: CommandBus.Command) -> void:
	match command.type:
		CommandBus.CommandType.DODGE_REQUEST:
			_handle_dodge_request()
		CommandBus.CommandType.ATTACK_REQUEST:
			_handle_attack_request()
		CommandBus.CommandType.ATTACK_RELEASED:
			_handle_attack_released()
		CommandBus.CommandType.HEAVY_CHARGE_START:
			_handle_charge_started()
		CommandBus.CommandType.HEAVY_CHARGE_RELEASE:
			_handle_charge_released()
		CommandBus.CommandType.INTERACT_REQUEST:
			_handle_interact_request()
		CommandBus.CommandType.ABILITY_REQUEST:
			_handle_ability_request(command.payload)

func _handle_dodge_request() -> void:
	if can_request_dodge():
		transition_combat_state(CombatState.DODGING)

func _handle_attack_request() -> void:
	if can_request_attack():
		transition_combat_state(CombatState.ATTACKING)
		# We don't immediately reset combat state here.
		# The individual attack (combo / light) will signal completion.

func _handle_attack_released() -> void:
	# When attack is released, reset to normal after a short delay or immediately
	if current_combat_state == CombatState.ATTACKING:
		transition_combat_state(CombatState.NORMAL)

func _handle_charge_started() -> void:
	if can_request_charge():
		transition_combat_state(CombatState.CHARGING)

func _handle_charge_released() -> void:
	if current_combat_state == CombatState.CHARGING:
		transition_combat_state(CombatState.NORMAL)

func _handle_interact_request() -> void:
	if can_request_interact():
		# Interaction logic is delegated to Player or VehicleOccupancySystem
		pass

func _handle_ability_request(payload: Dictionary) -> void:
	var ability_index = payload.get("ability_index", -1)
	if ability_index >= 0:
		# Ability activation is delegated to AbilitySystem (to be built in Wave 5/6)
		pass

## --- State Enter/Leave Callbacks ---

func _on_enter_on_foot() -> void:
	# Cancel any vehicle-specific inputs
	current_vehicle = null

func _on_leave_on_foot() -> void:
	pass

func _on_enter_vehicle(vehicle: Node2D) -> void:
	if vehicle:
		current_vehicle = vehicle

func _on_leave_vehicle() -> void:
	current_vehicle = null
