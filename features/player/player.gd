# player.gd
# The main script for the player character.
# It extends the base Actor class.
extends "res://features/actor/actor.gd"

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

# Dodge component (initialized in _ready)
var dodge_component: DodgeComponent = null

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
	
	# Setup dodge component if present
	if dodge_component:
		dodge_component.dodge_started.connect(_on_dodge_started)
		dodge_component.dodge_ended.connect(_on_dodge_ended)
		dodge_component.dodge_failed.connect(_on_dodge_failed)
		dodge_component.invincibility_ended.connect(_on_invincibility_ended)
	else:
		push_warning("Player: DodgeComponent not found - dodge functionality disabled")
	
	# Programmatically add to groups to ensure timing is correct.
	add_to_group("player")
	add_to_group("saveable")
	# After becoming ready, claim any pending save data
	SaveManager.claim_data_for_node(self)



func _physics_process(delta: float) -> void:
	# Handle vehicle interaction input
	if Input.is_action_just_pressed("enter_vehicle"):  # E key
		await _handle_vehicle_interaction()

	# Different behavior based on current state
	match current_state:
		PlayerState.ON_FOOT:
			_handle_on_foot_logic(delta)
		PlayerState.IN_VEHICLE:
			_handle_in_vehicle_logic(delta)

func _handle_on_foot_logic(delta: float):
	# --- Biological Processes (Always run, even during stagger/dodge) ---
	# Get movement input once for metabolism and movement logic (performance optimization)
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var has_movement_input = direction.length() > MOVEMENT_INPUT_THRESHOLD  # Check if there's movement input
	# Determine if sprinting for metabolism calculation
	var is_sprinting = Input.is_action_pressed("shift")
	_process_metabolism(delta, is_sprinting, has_movement_input)
	
	# Check if staggered - if so, no input allowed but metabolism continues
	var is_staggered = attribute_component and attribute_component.toughness_component and attribute_component.toughness_component.is_in_stagger()
	
	# Check if dodging - if so, no input allowed but metabolism continues
	var is_dodging = dodge_component and dodge_component.is_in_dodge()
	
	# If staggered or dodging, skip input/movement/combat but continue metabolism
	if is_staggered or is_dodging:
		return
	
	# Handle dodge input (reuse direction variable from above)
	if Input.is_action_just_pressed("dodge") and dodge_component:
		var dodge_direction = direction  # Use the direction already calculated
		# If no input, use last direction or velocity direction
		if dodge_direction.length() == 0:
			if velocity.length() > 0:
				dodge_direction = velocity.normalized()
			else:
				dodge_direction = last_direction
		dodge_component.attempt_dodge(dodge_direction)
	
	# --- Input and Movement ---
	# Note: direction was calculated above for metabolism to avoid duplicate Input.get_vector() calls

	# Update last direction if moving
	if direction.length() > 0:
		last_direction = direction.normalized()

	# Calculate movement speed based on sprinting state
	var base_speed = attribute_component.speed_component.get_current_speed()
	var movement_speed = base_speed

	if is_sprinting and direction.length() > 0:
		movement_speed = base_speed * 1.8  # 80% speed increase when sprinting

	velocity = direction * movement_speed

	_update_animation()
	move_and_slide()

	# Handle combat input
	_handle_combat_input()

	var weapons = actor_combat_component.actor_weapons
	for wc in weapons:
		if wc and wc.has_method("look_at"):
			wc.look_at(get_global_mouse_position())
			wc.rotation_degrees += 90  # Adjust orientation

func _handle_in_vehicle_logic(delta: float):
	# 进入载具后，player位置随vehicle同步
	if current_vehicle:
		global_position = current_vehicle.global_position
	# When in vehicle, player only does basal metabolism
	# Vehicle handles movement and glucose consumption
	_process_basal_metabolism(delta)

func _handle_vehicle_interaction():
	if current_state == PlayerState.ON_FOOT:
		# Try to enter nearby vehicle
		if nearby_vehicle and nearby_vehicle.has_method("can_be_entered") and nearby_vehicle.can_be_entered():
			var result = nearby_vehicle.enter_vehicle(self)
			if typeof(result) == TYPE_OBJECT and result.has_method("is_valid") and result.is_valid():
				result = await result
			if result:
				current_vehicle = nearby_vehicle
				current_state = PlayerState.IN_VEHICLE
				var vehicle_name = "Unknown"
				if nearby_vehicle.vehicle_data and nearby_vehicle.vehicle_data.has_method("get"):
					vehicle_name = nearby_vehicle.vehicle_data.vehicle_name
				elif nearby_vehicle.vehicle_data:
					vehicle_name = nearby_vehicle.vehicle_data.vehicle_name
				print("Entered vehicle: ", vehicle_name)
	elif current_state == PlayerState.IN_VEHICLE:
		# Try to exit current vehicle
		if current_vehicle and current_vehicle.has_method("exit_vehicle"):
			var result = await current_vehicle.exit_vehicle()
			if typeof(result) == TYPE_OBJECT and result.has_method("is_valid") and result.is_valid():
				result = await result
			if result:
				current_vehicle = null
				current_state = PlayerState.ON_FOOT
				print("Exited vehicle")

func _process_basal_metabolism(delta: float):

	# Only basal ATP consumption when in vehicle
	var base_atp_consumption = 2.0 * delta  # 2 ATP/sec during rest
	attribute_component.metabolism_component.consume_atp(base_atp_consumption)

	# ATP Recovery
	if attribute_component.metabolism_component.get_current_atp() < attribute_component.metabolism_component.get_max_atp():
		var atp_to_recover = base_atp_consumption
		var conversion_rate = attribute_component.metabolism_component.get_atp_conversion_rate()
		if conversion_rate > 0:
			var glucose_for_atp = atp_to_recover / conversion_rate
			if attribute_component.metabolism_component.get_current_glucose() >= glucose_for_atp:
				attribute_component.metabolism_component.consume_glucose(glucose_for_atp)
				attribute_component.metabolism_component.recover_atp(atp_to_recover)

	# Basal metabolic rate (reduced in vehicle - player is resting)
	var basal_glucose_cost = attribute_component.metabolism_component.get_glucose_consume_rate() * delta * 0.2  # Even more reduced in vehicle
	if attribute_component.metabolism_component.get_current_glucose() > 0:
		attribute_component.metabolism_component.consume_glucose(basal_glucose_cost)

# --- Vehicle Interaction Interface ---
# These methods are called by vehicles when player enters/exits interaction range
func show_vehicle_interaction(vehicle: Node2D):
	nearby_vehicle = vehicle
	interaction_ui_visible = true
	# TODO: Show UI prompt "Press E to enter vehicle"
	print("Vehicle nearby: ", vehicle.get_interaction_text())

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
		sprint_atp_consumption = 6.0 * delta  # Additional 6 ATP/sec when sprinting (total: 2+3+6=11 ATP/sec)

	var total_atp_consumption = base_atp_consumption + movement_atp_consumption + sprint_atp_consumption
	attribute_component.metabolism_component.consume_atp(total_atp_consumption)

	# 2. Glucose-Based ATP Recovery
	# ATP recovers toward max at a fixed production rate, independent of consumption rate
	# However, glucose is still consumed based on the conversion rate
	if attribute_component.metabolism_component.get_current_atp() < attribute_component.metabolism_component.get_max_atp():
		# Use the production rate from metabolism component for recovery
		var atp_needed = attribute_component.metabolism_component.get_max_atp() - attribute_component.metabolism_component.get_current_atp()
		var atp_to_recover = min(attribute_component.metabolism_component.atp_production_rate * delta, atp_needed)
		
		# Calculate the glucose cost for that much ATP
		var conversion_rate = attribute_component.metabolism_component.get_atp_conversion_rate()
		if conversion_rate > 0:
			var glucose_for_atp = atp_to_recover / conversion_rate
			var current_glucose = attribute_component.metabolism_component.get_current_glucose()
			
			# Check if we have enough glucose
			if current_glucose >= glucose_for_atp:
				attribute_component.metabolism_component.consume_glucose(glucose_for_atp)
				attribute_component.metabolism_component.recover_atp(atp_to_recover)
			elif current_glucose > 0:
				# Not enough glucose - recover what we can with remaining glucose
				var partial_atp = current_glucose * conversion_rate
				attribute_component.metabolism_component.consume_glucose(current_glucose)
				attribute_component.metabolism_component.recover_atp(partial_atp)

	# 3. Basal Metabolic Rate (minimal glucose consumption for basic cellular functions)
	# This continues even when ATP is full, representing basic cellular maintenance
	var basal_glucose_cost = attribute_component.metabolism_component.get_glucose_consume_rate() * delta * 0.3  # Reduced to 30% of original rate
	if attribute_component.metabolism_component.get_current_glucose() > 0:
		attribute_component.metabolism_component.consume_glucose(basal_glucose_cost)
	
	# 4. ATP Depletion Damage (permanent HP loss when ATP stays at 0)
	if attribute_component.metabolism_component.get_current_atp() < ATP_DEPLETION_THRESHOLD:
		atp_depletion_timer += delta
		
		# Apply permanent HP damage at intervals
		if atp_depletion_timer >= ATP_DEPLETION_DAMAGE_INTERVAL:
			# Apply permanent damage
			if attribute_component.health_component.get_current_health() > 1:
				# Reduce max_health permanently (this damage cannot be healed)
				var new_max_health = attribute_component.health_component.get_max_health() - ATP_DEPLETION_DAMAGE_AMOUNT
				new_max_health = max(new_max_health, 1)  # Keep at least 1 HP
				
				# Also reduce current health
				var new_current_health = attribute_component.health_component.get_current_health() - ATP_DEPLETION_DAMAGE_AMOUNT
				new_current_health = max(new_current_health, 1)  # Keep at least 1 HP to prevent death
				
				# Apply the permanent damage
				attribute_component.health_component.set_max_health(new_max_health, false)
				attribute_component.health_component.set_current_health(new_current_health)
				
				print("[METABOLISM] ATP depletion! Permanent HP damage: -", ATP_DEPLETION_DAMAGE_AMOUNT, " (Max HP now: ", new_max_health, ")")
			
			# Reset timer for next damage tick
			atp_depletion_timer -= ATP_DEPLETION_DAMAGE_INTERVAL
	else:
		# ATP is available, reset the depletion timer
		atp_depletion_timer = 0.0

func _handle_combat_input():
	if not actor_combat_component:
		return
	
	# Heavy attack - charge on hold, release on button up
	if Input.is_action_just_pressed("heavy_attack"):
		print("Starting heavy attack charge...")
		actor_combat_component.start_heavy_attack_charge()
	elif Input.is_action_just_released("heavy_attack"):
		print("Releasing heavy attack...")
		actor_combat_component.release_heavy_attack()
	
	# Light attack - Actor武器发射（如手枪/步枪等）
	if Input.is_action_just_pressed("light_attack"):
		print("Firing light attack...")
		actor_combat_component.perform_light_attack()

# --- Dodge Callbacks ---
func _on_dodge_started():
	"""Called when dodge starts"""
	# Set invincibility on health component
	if attribute_component and attribute_component.health_component:
		attribute_component.health_component.set_invincible(true)
	
	# Emit global event
	EventBus.player_dodge_started.emit(self)
	print("Dodge started! Invincible!")

func _on_dodge_ended():
	"""Called when dodge ends"""
	print("Dodge ended")

func _on_invincibility_ended():
	"""Called when invincibility ends (called by DodgeComponent)"""
	# Remove invincibility from health component
	if attribute_component and attribute_component.health_component:
		attribute_component.health_component.set_invincible(false)
	print("Invincibility ended")
	# Emit global event
	EventBus.player_dodge_ended.emit(self)

func _on_dodge_failed(reason: String):
	"""Called when dodge fails"""
	print("Dodge failed: ", reason)
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
		# Actor stats are saved in PlayerData.actor_data singleton
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
	
	# Restore vehicle reference if player was in a vehicle
	if data.has("current_vehicle_path") and data["current_vehicle_path"] != "":
		var vehicle_path = data["current_vehicle_path"]
		# Wait a frame to ensure the vehicle node is loaded
		await get_tree().process_frame
		var vehicle_node = get_node_or_null(vehicle_path)
		if vehicle_node and vehicle_node.has_method("enter_vehicle"):
			current_vehicle = vehicle_node
			# Re-enter the vehicle to restore the full state
			if current_state == PlayerState.IN_VEHICLE:
				# Temporarily reset occupied flag to allow re-entry
				var was_occupied = vehicle_node.occupied
				vehicle_node.occupied = false
				vehicle_node.enter_vehicle(self)
				# Don't restore occupied flag - enter_vehicle sets it correctly
