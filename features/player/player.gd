# player.gd
# The main script for the player character.
# It extends the base Actor class.
extends Actor
class_name Player

const PlayerStateMachine = preload("res://systems/input/player_state_machine.gd")

# Player states
enum PlayerState {
	ON_FOOT,        # Normal walking state
	IN_VEHICLE      # Inside a vehicle
}

# Constants
const MOVEMENT_INPUT_THRESHOLD: float = 0.1  # Minimum input magnitude to consider as movement
const ATP_DEPLETION_DAMAGE_AMOUNT: int = 1  # HP damage per interval when ATP is 0
const ATP_DEPLETION_DAMAGE_INTERVAL: float = 1.0  # Damage applied every 1 second
const ATP_DEPLETION_THRESHOLD: float = 0.001  # Consider ATP depleted if below this value

# Vehicle interaction
var current_state: PlayerState = PlayerState.ON_FOOT
var current_vehicle: Node2D = null  # Will be Vehicle when available
var nearby_vehicle: Node2D = null   # Vehicle player can interact with
var interaction_ui_visible: bool = false

# --- NEW: Migration Compatibility Helpers ---
# These helpers provide a uniform API for stat access that works with BOTH
# the old AttributeComponent system AND the new StatSystem.
# During Wave 2 migration, these resolve to the new StatSystem if available.
# After Wave 7 (old component deletion), they resolve to StatSystem only.

#region Custom Polygon Visuals
## Draws a smooth rounded polygon as the player's visual instead of a sprite texture.
## The shape is a "pill" / rounded-rectangle with a directional indicator (nose).
func _draw() -> void:
	# Body visual is now handled by MeshInstance2D + shader (BodyVisual node).
	# Only draw the direction indicator (nose) on top.
	var nose: Vector2 = last_direction.normalized() * 18.0
	draw_circle(nose, 6.0, Color(1.0, 1.0, 1.0, 0.9))
	# Nose outline
	var nose_seg: int = 16
	for i in range(nose_seg):
		var a: float = TAU * float(i) / float(nose_seg)
		var b: float = TAU * float(i + 1) / float(nose_seg)
		draw_line(
			nose + Vector2(cos(a), sin(a)) * 6.0,
			nose + Vector2(cos(b), sin(b)) * 6.0,
			Color(0.1, 0.35, 0.65, 1.0), 1.5)


## Builds a smooth rounded polygon (pill shape) with `radius` corners and `w`/`h` dimensions.
func _build_smooth_body(half_width: float, half_height: float, segments_per_corner: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var corners: Array[Vector2] = [
		Vector2(half_width, -half_height),   # top-right
		Vector2(half_width, half_height),    # bottom-right
		Vector2(-half_width, half_height),   # bottom-left
		Vector2(-half_width, -half_height),  # top-left
	]
	var radius: float = min(half_width, half_height)
	for c in range(corners.size()):
		var corner: Vector2 = corners[c]
		var prev: Vector2 = corners[(c + 3) % 4]
		var next: Vector2 = corners[(c + 1) % 4]
		# Start and end of the rounded corner arc
		var start: Vector2 = corner + (prev - corner).normalized() * radius
		var end: Vector2 = corner + (next - corner).normalized() * radius
		# Straight segment before this corner
		points.append(start)
		# Arc for the corner
		var center: Vector2 = corner + (start - corner).normalized() * radius + (end - corner).normalized() * radius
		var start_angle: float = (start - center).angle()
		var end_angle: float = (end - center).angle()
		# Ensure we go the shorter way around
		if end_angle < start_angle:
			end_angle += TAU
		for i in range(1, segments_per_corner):
			var t: float = float(i) / float(segments_per_corner)
			var angle: float = start_angle + (end_angle - start_angle) * t
			points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points
#endregion


## Returns the player's entity_id in the new ECS-lite architecture.
func _get_entity_id() -> int:
	if entity_id < 0:
		# EntityManager may not have been ready during _ready; retry
		var entity_manager = ServiceRegistry.get_service("EntityManager")
		if entity_manager:
			var node_id = entity_manager.get_entity_id(self)
			if node_id >= 0:
				entity_id = node_id
	return entity_id

## Consume ATP using BOTH ResourcePoolSystem (new) AND old metabolism_component.
## Dual-writing ensures old signals fire while new system becomes authoritative.
func _consume_atp(amount: float) -> void:
	var eid := _get_entity_id()
	if eid >= 0:
		var pool_system = ServiceRegistry.get_service("ResourcePoolSystem")
		if pool_system:
			pool_system.consume(eid, "atp", amount)
	# Always write to old system too (signals are still wired there)
	if attribute_component and attribute_component.metabolism_component:
		attribute_component.metabolism_component.consume_atp(amount)

## Recover ATP using BOTH ResourcePoolSystem (new) AND old metabolism_component.
func _recover_atp(amount: float) -> void:
	var eid := _get_entity_id()
	if eid >= 0:
		var pool_system = ServiceRegistry.get_service("ResourcePoolSystem")
		if pool_system:
			pool_system.recover(eid, "atp", amount)
	if attribute_component and attribute_component.metabolism_component:
		attribute_component.metabolism_component.recover_atp(amount)

## Consume glucose using BOTH ResourcePoolSystem (new) AND old metabolism_component.
func _consume_glucose(amount: float) -> void:
	var eid := _get_entity_id()
	if eid >= 0:
		var pool_system = ServiceRegistry.get_service("ResourcePoolSystem")
		if pool_system:
			pool_system.consume(eid, "glucose", amount)
	if attribute_component and attribute_component.metabolism_component:
		attribute_component.metabolism_component.consume_glucose(amount)

## Get current ATP (new StatSystem preferred, old fallback).
func _get_current_atp() -> float:
	var eid := _get_entity_id()
	if eid >= 0:
		var stat_system = ServiceRegistry.get_service("StatSystem")
		if stat_system:
			return stat_system.get_stat_value(eid, "atp", 0.0)
	return attribute_component.metabolism_component.get_current_atp()

## Get max ATP (new StatSystem preferred, old fallback).
func _get_max_atp() -> float:
	var eid := _get_entity_id()
	if eid >= 0:
		var stat_system = ServiceRegistry.get_service("StatSystem")
		if stat_system:
			return stat_system.get_stat_value(eid, "max_atp", 0.0)
	return attribute_component.metabolism_component.get_max_atp()

## Get current glucose (new StatSystem preferred, old fallback).
func _get_current_glucose() -> float:
	var eid := _get_entity_id()
	if eid >= 0:
		var stat_system = ServiceRegistry.get_service("StatSystem")
		if stat_system:
			return stat_system.get_stat_value(eid, "glucose", 0.0)
	return attribute_component.metabolism_component.get_current_glucose()

## Get glucose consume rate (new StatSystem preferred, old fallback).
func _get_glucose_consume_rate() -> float:
	var eid := _get_entity_id()
	if eid >= 0:
		var stat_system = ServiceRegistry.get_service("StatSystem")
		if stat_system:
			return stat_system.get_stat_value(eid, "glucose_consume_rate", 0.0)
	return attribute_component.metabolism_component.get_glucose_consume_rate()

## Get ATP conversion rate (new StatSystem preferred, old fallback).
func _get_atp_conversion_rate() -> float:
	var eid := _get_entity_id()
	if eid >= 0:
		var stat_system = ServiceRegistry.get_service("StatSystem")
		if stat_system:
			return stat_system.get_stat_value(eid, "atp_conversion_rate", 0.0)
	return attribute_component.metabolism_component.get_atp_conversion_rate()

## Get ATP production rate (new StatSystem preferred, old fallback).
func _get_atp_production_rate() -> float:
	var eid := _get_entity_id()
	if eid >= 0:
		var stat_system = ServiceRegistry.get_service("StatSystem")
		if stat_system:
			return stat_system.get_stat_value(eid, "atp_production_rate", 0.0)
	return attribute_component.metabolism_component.atp_production_rate

## Check if player is staggered (new StatSystem preferred, old fallback).
func _is_staggered() -> bool:
	var eid := _get_entity_id()
	if eid >= 0:
		var stat_system = ServiceRegistry.get_service("StatSystem")
		if stat_system:
			return stat_system.get_stat_value(eid, "toughness", 0.0) <= 0.0
	# Fallback: old component chain
	if attribute_component and attribute_component.toughness_component:
		return attribute_component.toughness_component.is_in_stagger()
	return false

## Get current health (new StatSystem preferred, old fallback).
func _get_current_health() -> int:
	var eid := _get_entity_id()
	if eid >= 0:
		var stat_system = ServiceRegistry.get_service("StatSystem")
		if stat_system:
			return int(stat_system.get_stat_value(eid, "health", 0.0))
	return attribute_component.health_component.get_current_health()

## Set current health (new StatSystem preferred, old fallback).
func _set_current_health(new_hp: int) -> void:
	var eid := _get_entity_id()
	if eid >= 0:
		var stat_system = ServiceRegistry.get_service("StatSystem")
		if stat_system:
			# Clamp to max
			var max_hp: float = stat_system.get_stat_value(eid, "max_health", float(new_hp))
			stat_system.set_stat_value(eid, "health", clampf(float(new_hp), 1.0, max_hp))
			return
	attribute_component.health_component.set_current_health(new_hp)

## Get current speed (new StatSystem preferred, old fallback).
func _get_current_speed() -> float:
	var eid := _get_entity_id()
	if eid >= 0:
		var stat_system = ServiceRegistry.get_service("StatSystem")
		if stat_system:
			return stat_system.get_stat_value(eid, "speed", 250.0)
	return attribute_component.speed_component.get_current_speed()

## Set invincibility on health.
func _set_invincible(state: bool) -> void:
	# New system has no invincibility concept in StatSystem yet; use old component
	if attribute_component and attribute_component.health_component:
		attribute_component.health_component.set_invincible(state)

# ---

# Dodge component (initialized in _ready)
var dodge_component: DodgeComponent = null

# Input component (autowired in _ready)
var input_component: PlayerInputComponent = null

# ATP depletion tracking
var atp_depletion_timer: float = 0.0  # Time ATP has been at 0

func get_current_state() -> int:
	return current_state

func get_last_direction() -> Vector2:
	"""Get the last movement direction"""
	return last_direction

func _ready():
	# Assign the specific data resource for the player.
	# actor_data = load("res://data/items/player_data.tres")
	# Call the parent's _ready function to initialize health, animations etc.
	super()
	# Initialize the actor's inventory 
	if inventory_component.containers.is_empty():
		inventory_component.set_data(actor_data)
	
	# Get dodge component reference
	dodge_component = get_node_or_null("DodgeComponent") as DodgeComponent
	
	# Get or create input component
	input_component = get_node_or_null("PlayerInputComponent") as PlayerInputComponent
	if not input_component:
		input_component = PlayerInputComponent.new()
		input_component.name = "PlayerInputComponent"
		add_child(input_component)
	
	# Setup dodge component if present
	if dodge_component:
		dodge_component.dodge_started.connect(_on_dodge_started)
		dodge_component.dodge_ended.connect(_on_dodge_ended)
		dodge_component.dodge_failed.connect(_on_dodge_failed)
		dodge_component.invincibility_ended.connect(_on_invincibility_ended)
	else:
		push_warning("Player: DodgeComponent not found - dodge functionality disabled")
	
	# --- Wave 4: Register with PlayerStateMachine ---
	var psm = ServiceRegistry.get_service("PlayerStateMachine")
	if psm:
		psm.player_actor = self
		psm.state_changed.connect(_on_player_state_changed)
		GameLogger.debug("player", "Registered with PlayerStateMachine")
	else:
		push_warning("Player: PlayerStateMachine not available in _ready()")

	# --- Wave 3: Register with TargetResolverSystem ---
	var target_resolver = ServiceRegistry.get_service("TargetResolverSystem")
	if target_resolver:
		target_resolver.set_player_actor(self)
		GameLogger.debug("player", "Registered with TargetResolverSystem")

	# Programmatically add to groups to ensure timing is correct.
	add_to_group("player")

	# --- Custom polygon visuals (replaces sprite) ---
	# Hide the default AnimatedSprite2D; we draw a smooth polygon instead.
	if visuals:
		visuals.visible = false
		visuals.sprite_frames = null  # Stop any animation playback
	# Trigger initial draw
	queue_redraw()
	add_to_group("saveable")
	# After becoming ready, claim any pending save data
	SaveManager.claim_data_for_node(self)

func _on_player_state_changed(_new_state: int) -> void:
	# Sync handled in _physics_process via state checks
	pass



func _physics_process(delta: float) -> void:
	# --- Wave 4: Check state machine for combat state transitions ---
	var psm = ServiceRegistry.get_service("PlayerStateMachine")
	
	# Handle vehicle interaction input (still uses old input_component temporarily)
	if input_component and input_component.should_interact:
		CommandBus.issue_type(CommandBus.CommandType.INTERACT_REQUEST, {})
		input_component.consume_transient_intents()
		return
	
	# Different behavior based on current state
	var state_for_logic := current_state
	if psm:
		state_for_logic = 0 if psm.current_state == PlayerStateMachine.PlayerState.ON_FOOT else 1
	
	match state_for_logic:
		PlayerState.ON_FOOT:
			_handle_on_foot_logic(delta)
		PlayerState.IN_VEHICLE:
			_handle_in_vehicle_logic(delta)

func _handle_on_foot_logic(delta: float):
	# --- Biological Processes (Always run, even during stagger/dodge) ---
	var direction := input_component.desired_direction if input_component else Vector2.ZERO
	var has_movement_input = direction.length() > MOVEMENT_INPUT_THRESHOLD
	var is_sprinting = input_component.is_sprinting if input_component else false
	
	# --- Wave 5: Metabolism is now handled by MetabolismSystem ---
	# Register movement context so MetabolismSystem can process ATP/glucose
	# in its per-frame tick. This removes ALL metabolism logic from Player.gd.
	var metabolism_system = ServiceRegistry.get_service("MetabolismSystem")
	if metabolism_system:
		var eid := _get_entity_id()
		if eid >= 0:
			metabolism_system.set_entity_movement_context(eid, has_movement_input, is_sprinting, "on_foot")
	# TEMPORARY: during transition, also call old method so signals still fire via dual-write
	_process_metabolism(delta, is_sprinting, has_movement_input)
	
	# Check if staggered - if so, no input allowed but metabolism continues
	var is_staggered := _is_staggered()
	
	# Check if dodging - if so, no input allowed but metabolism continues
	var is_dodging = dodge_component and dodge_component.is_in_dodge()
	
	# If staggered or dodging, skip input/movement/combat but continue metabolism
	if is_staggered or is_dodging:
		return
	
	# Handle dodge input
	if input_component and input_component.should_dodge and dodge_component:
		var dodge_direction = direction
		if dodge_direction.length() == 0:
			if velocity.length() > 0:
				dodge_direction = velocity.normalized()
			else:
				dodge_direction = last_direction
		dodge_component.attempt_dodge(dodge_direction)
	
	# Update last direction if moving
	if direction.length() > 0:
		last_direction = direction.normalized()

	# Calculate movement speed based on sprinting state
	var base_speed = _get_current_speed()
	var movement_speed = base_speed

	if is_sprinting and direction.length() > 0:
		movement_speed = base_speed * 1.8  # 80% speed increase when sprinting

	velocity = direction * movement_speed

	_update_animation()
	move_and_slide()

	# --- Wave 3: Weapon orientation via TargetResolverSystem ---
	var target_resolver = ServiceRegistry.get_service("TargetResolverSystem")
	var aim_target := Vector2.ZERO
	if target_resolver:
		aim_target = target_resolver.get_player_aim_target_world()
	elif input_component:
		# Temporary fallback during transition
		aim_target = input_component.aim_target
	var weapons = actor_combat_component.actor_weapons
	for wc in weapons:
		if wc and wc.has_method("look_at"):
			wc.look_at(aim_target)
			wc.rotation_degrees += 90  # Adjust orientation
	
	# --- Wave 4: Combat actions are now COMMAND-DRIVEN, not input-driven ---
	# _handle_combat_input() removed. The InputCommandSystem polls input,
	# converts to Commands, and the PlayerStateMachine validates them.
	# ActorCombatComponent then executes via CommandBus listeners.
	# The actual combat execution is triggered by state machine callbacks.
	
	# Consume transient one-shot intents after processing
	input_component.consume_transient_intents()

func _handle_in_vehicle_logic(delta: float):
	# Sync player position to vehicle while inside
	if current_vehicle:
		global_position = current_vehicle.global_position
	# --- Wave 5: Metabolism is now handled by MetabolismSystem ---
	# Register in-vehicle context so MetabolismSystem processes basal metabolism.
	var metabolism_system = ServiceRegistry.get_service("MetabolismSystem")
	if metabolism_system:
		var eid := _get_entity_id()
		if eid >= 0:
			metabolism_system.set_entity_movement_context(eid, false, false, "in_vehicle")
	# TEMPORARY: during transition, also call old basal method so signals still fire via dual-write
	_process_basal_metabolism(delta)

func _handle_vehicle_interaction() -> void:
	# Wave 5: Delegated to VehicleCommandHandler via CommandBus
	# This method is kept temporarily for backward compatibility but no longer called directly
	_handle_vehicle_interaction_legacy()

func _handle_vehicle_interaction_legacy() -> void:
	if not input_component or not input_component.should_interact:
		return
	if current_state == PlayerState.ON_FOOT:
		# Try to enter nearby vehicle
		if nearby_vehicle and nearby_vehicle.has_method("can_be_entered") and nearby_vehicle.can_be_entered():
			var entered: bool = nearby_vehicle.enter_vehicle(self)
			if entered:
				current_vehicle = nearby_vehicle
				current_state = PlayerState.IN_VEHICLE
				if nearby_vehicle.has_method("set_input_component"):
					nearby_vehicle.set_input_component(input_component)
				var vehicle_name: String = "Unknown"
				if nearby_vehicle.vehicle_data:
					vehicle_name = nearby_vehicle.vehicle_data.vehicle_name
				GameLogger.debug("player", "Entered vehicle: %s" % vehicle_name)
				# Notify PlayerStateMachine of state change
				var psm = ServiceRegistry.get_service("PlayerStateMachine")
				if psm:
					psm.transition_to_state(PlayerStateMachine.PlayerState.IN_VEHICLE, {"vehicle": nearby_vehicle})
	elif current_state == PlayerState.IN_VEHICLE:
		# Try to exit current vehicle
		if current_vehicle and current_vehicle.has_method("exit_vehicle"):
			var exited: bool = current_vehicle.exit_vehicle()
			if exited:
				if current_vehicle and current_vehicle.has_method("clear_input_component"):
					current_vehicle.clear_input_component()
				current_vehicle = null
				current_state = PlayerState.ON_FOOT
				GameLogger.debug("player", "Exited vehicle")
				# Notify PlayerStateMachine of state change
				var psm = ServiceRegistry.get_service("PlayerStateMachine")
				if psm:
					psm.transition_to_state(PlayerStateMachine.PlayerState.ON_FOOT, {})

func _process_basal_metabolism(delta: float):

	# Only basal ATP consumption when in vehicle
	var base_atp_consumption = 2.0 * delta  # 2 ATP/sec during rest
	_consume_atp(base_atp_consumption)

	# ATP Recovery
	if _get_current_atp() < _get_max_atp():
		var atp_to_recover = base_atp_consumption
		var conversion_rate = _get_atp_conversion_rate()
		if conversion_rate > 0:
			var glucose_for_atp = atp_to_recover / conversion_rate
			if _get_current_glucose() >= glucose_for_atp:
				_consume_glucose(glucose_for_atp)
				_recover_atp(atp_to_recover)

	# Basal metabolic rate (reduced in vehicle - player is resting)
	var basal_glucose_cost = _get_glucose_consume_rate() * delta * 0.2  # Even more reduced in vehicle
	if _get_current_glucose() > 0:
		_consume_glucose(basal_glucose_cost)

# --- Vehicle Interaction Interface ---
# These methods are called by vehicles when player enters/exits interaction range
func show_vehicle_interaction(vehicle: Node2D):
	nearby_vehicle = vehicle
	interaction_ui_visible = true
	# TODO: Show UI prompt "Press E to enter vehicle"
	GameLogger.debug("player", "Vehicle nearby: %s" % vehicle.get_interaction_text())

func hide_vehicle_interaction():
	nearby_vehicle = null
	interaction_ui_visible = false
	# TODO: Hide UI prompt

# Called by vehicle when player enters
func set_in_vehicle_state(in_vehicle: bool):
	# Hide/show player visual representation
	visuals.visible = not in_vehicle
	# Disable/enable all CollisionShape2D nodes
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = in_vehicle
	# The player's physics process is not disabled, so AI can still track them.

func _process_metabolism(delta: float, is_sprinting: bool = false, has_movement_input: bool = false):
	# 1. ATP Consumption (Rest + Movement + Sprinting)
	var base_atp_consumption = 2.0 * delta  # 2 ATP/sec during rest
	var movement_atp_consumption = 0.0
	var sprint_atp_consumption = 0.0

	# Use the has_movement_input parameter passed from input detection
	if has_movement_input:
		movement_atp_consumption = 3.0 * delta  # Additional 3 ATP/sec during movement

	# Extra consumption when sprinting
	if is_sprinting and has_movement_input:  # Only consume sprint ATP if actually moving
		sprint_atp_consumption = 6.0 * delta  # Additional 6 ATP/sec when sprinting

	var total_atp_consumption = base_atp_consumption + movement_atp_consumption + sprint_atp_consumption
	_consume_atp(total_atp_consumption)

	# 2. Glucose-Based ATP Recovery
	# ATP recovers toward max at a fixed production rate, independent of consumption rate
	# However, glucose is still consumed based on the conversion rate
	if _get_current_atp() < _get_max_atp():
		# Use the production rate for recovery
		var atp_needed = _get_max_atp() - _get_current_atp()
		var atp_to_recover = min(_get_atp_production_rate() * delta, atp_needed)
		
		# Calculate the glucose cost for that much ATP
		var conversion_rate = _get_atp_conversion_rate()
		if conversion_rate > 0:
			var glucose_for_atp = atp_to_recover / conversion_rate
			var current_glucose = _get_current_glucose()
			
			# Check if we have enough glucose
			if current_glucose >= glucose_for_atp:
				_consume_glucose(glucose_for_atp)
				_recover_atp(atp_to_recover)
			elif current_glucose > 0:
				# Not enough glucose - recover what we can with remaining glucose
				var partial_atp = current_glucose * conversion_rate
				_consume_glucose(current_glucose)
				_recover_atp(partial_atp)

	# 3. Basal Metabolic Rate (minimal glucose consumption for basic cellular functions)
	# This continues even when ATP is full, representing basic cellular maintenance
	var basal_glucose_cost = _get_glucose_consume_rate() * delta * 0.3  # Reduced to 30% of original rate
	if _get_current_glucose() > 0:
		_consume_glucose(basal_glucose_cost)
	
	# 4. ATP Depletion Damage (damages current health when ATP stays at 0)
	# This damage does NOT auto-recover, but can be healed with healing items
	if _get_current_atp() < ATP_DEPLETION_THRESHOLD:
		atp_depletion_timer += delta
		
		# Apply HP damage at intervals
		if atp_depletion_timer >= ATP_DEPLETION_DAMAGE_INTERVAL:
			# Damage current health only if we have more than 1 HP
			var current_hp = _get_current_health()
			if current_hp > 1:
				# Reduce current_health (not max_health!)
				# This damage doesn't auto-recover but can be healed with healing items
				var new_current_health = max(current_hp - ATP_DEPLETION_DAMAGE_AMOUNT, 1)
				_set_current_health(new_current_health)
			
			# Reset timer, preserving fractional time for precise timing
			atp_depletion_timer = fmod(atp_depletion_timer, ATP_DEPLETION_DAMAGE_INTERVAL)
	else:
		# ATP is available, reset the depletion timer
		# Note: Damaged health doesn't auto-recover, but can be healed with healing items
		atp_depletion_timer = 0.0

func _handle_combat_input():
	if not actor_combat_component or not input_component:
		return
	
	# Heavy attack - charge on hold, release on button up
	if input_component.should_heavy_attack:
		GameLogger.debug("player", "Starting heavy attack charge")
		actor_combat_component.start_heavy_attack_charge()
	elif input_component.heavy_attack_released and actor_combat_component.is_charging_heavy:
		GameLogger.debug("player", "Releasing heavy attack")
		actor_combat_component.release_heavy_attack()
	
	# Light attack - Actor weapon fire (pistol/rifle etc)
	if input_component.should_light_attack:
		GameLogger.debug("player", "Firing light attack")
		actor_combat_component.perform_light_attack()

# --- Dodge Callbacks ---
func _on_dodge_started():
	"""Called when dodge starts"""
	# Set invincibility on health component
	_set_invincible(true)
	
	# Emit global event
	EventBus.player_dodge_started.emit(self)
	GameLogger.debug("player", "Dodge started")

func _on_dodge_ended():
	"""Called when dodge ends"""
	GameLogger.debug("player", "Dodge ended")

func _on_invincibility_ended():
	"""Called when invincibility ends (called by DodgeComponent)"""
	# Remove invincibility from health component
	_set_invincible(false)
	GameLogger.debug("player", "Invincibility ended")
	# Emit global event
	EventBus.player_dodge_ended.emit(self)

func _on_dodge_failed(reason: String):
	"""Called when dodge fails"""
	GameLogger.debug("player", "Dodge failed: %s" % reason)
	# Emit global event
	EventBus.player_dodge_failed.emit(self, reason)

# Save/Load support for SaveManager
func save_data() -> Dictionary:
	var vehicle_path = ""
	if current_vehicle:
		vehicle_path = str(current_vehicle.get_path())
	
	return {
		"position": {"x": global_position.x, "y": global_position.y},
		"current_state": current_state,
		"current_vehicle_path": vehicle_path,
		"atp_depletion_timer": atp_depletion_timer,
		"runtime_state": runtime_state.to_dict() if runtime_state else {},
	}

func load_data(data: Dictionary) -> void:
	if data.has("position"):
		var pos_data = data["position"]
		if typeof(pos_data) == TYPE_DICTIONARY:
			global_position = Vector2(pos_data.get("x", 0), pos_data.get("y", 0))
		else:
			global_position = pos_data
	if data.has("current_state"):
		current_state = data["current_state"]
	if data.has("atp_depletion_timer"):
		atp_depletion_timer = data["atp_depletion_timer"]
	if data.has("runtime_state"):
		runtime_state.from_dict(data["runtime_state"])
	
	# Restore vehicle reference if player was in a vehicle
	if data.has("current_vehicle_path") and data["current_vehicle_path"] != "":
		var vehicle_path_str = data["current_vehicle_path"]
		# Wait a frame to ensure the vehicle node is loaded
		await get_tree().process_frame
		var vehicle_node = get_node_or_null(vehicle_path_str)
		if vehicle_node and vehicle_node.has_method("enter_vehicle"):
			current_vehicle = vehicle_node
			# Re-enter the vehicle to restore the full state
			if current_state == PlayerState.IN_VEHICLE:
				# Temporarily reset occupied flag to allow re-entry
				var was_occupied = vehicle_node.occupied
				vehicle_node.occupied = false
				vehicle_node.enter_vehicle(self)
				# Don't restore occupied flag - enter_vehicle sets it correctly
