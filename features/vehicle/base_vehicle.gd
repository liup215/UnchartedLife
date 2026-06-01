# vehicle.gd
# The base vehicle class for RigidBody2D tank-style control.
extends RigidBody2D

class_name Vehicle

@export var vehicle_data: VehicleData

## A stable unique identifier used for save/load. Unlike NodePath, this ID
## persists across scene tree renames and allows entity-identity to be stable.
## If left empty, the node path will be used as a fallback during saving.
@export var save_id: String = ""
@onready var stats_component: VehicleStatsComponent = $VehicleStatsComponent
@onready var interaction_area: Area2D = $InteractionArea
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var interaction_ui: Control = $InteractionUI
@onready var interaction_label: Label = $InteractionUI/InteractionLabel
@onready var vehicle_camera: Camera2D = $Camera2D
@onready var vehicle_combat_component: VehicleCombatComponent = $VehicleCombatComponent
@onready var _animated_sprite = $AnimatedSprite2D

# Vehicle state
var occupied: bool = false
var driver: Node2D = null
var player_camera: Camera2D = null
var movement_component: VehicleMovementComponent = null

# Map binding - vehicles are tied to specific maps
# If empty, vehicle is available on all maps
@export var assigned_map_id: String = ""

func _ready():
	add_to_group("vehicle")
	add_to_group("saveable")
	# Claim any pending save data
	SaveManager.claim_data_for_node(self)
	
	# Listen for map changes to show/hide based on current map
	EventBus.map_changed.connect(_on_map_changed)
	
	# Check if vehicle should be visible on current map
	_update_visibility_for_current_map()
	
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	# Ensure the stats component has the data it needs
	if stats_component:
		stats_component.vehicle_data = vehicle_data
		stats_component.recalculate_stats()

	# Set owner_node for combat_component
	if vehicle_combat_component:
		vehicle_combat_component.set_actor_data(vehicle_data)

	# Get or create movement component
	movement_component = get_node_or_null("VehicleMovementComponent") as VehicleMovementComponent
	if not movement_component:
		movement_component = VehicleMovementComponent.new()
		movement_component.name = "VehicleMovementComponent"
		movement_component.stats_component = stats_component
		movement_component.animated_sprite = _animated_sprite
		add_child(movement_component)

func _exit_tree() -> void:
	if EventBus.map_changed.is_connected(_on_map_changed):
		EventBus.map_changed.disconnect(_on_map_changed)
	if interaction_area:
		if interaction_area.body_entered.is_connected(_on_body_entered):
			interaction_area.body_entered.disconnect(_on_body_entered)
		if interaction_area.body_exited.is_connected(_on_body_exited):
			interaction_area.body_exited.disconnect(_on_body_exited)

# Input component for vehicle (assigned by Player when entering vehicle)
var input_component: PlayerInputComponent = null

func set_input_component(ic: PlayerInputComponent) -> void:
	input_component = ic

func clear_input_component() -> void:
	input_component = null

func _physics_process(delta: float):
	if occupied and driver and stats_component.can_move:
		# Gather input from relayed input_component ( Player sets this on enter )
		var move_input = input_component.vehicle_move_input if input_component else 0
		var turn_input = input_component.vehicle_turn_input if input_component else 0

		movement_component.process_movement(self, move_input, turn_input, delta)
		movement_component.consume_fuel(vehicle_data, stats_component, linear_velocity.length(), delta)

		# Combat input (read from relayed component, never Input directly)
		if vehicle_combat_component and input_component:
			if input_component.should_main_attack:
				vehicle_combat_component.start_main_charge()
			if input_component.main_attack_released:
				vehicle_combat_component.stop_main_charge()
				vehicle_combat_component.fire_main_weapons()
			if input_component.should_light_attack:
				vehicle_combat_component.perform_light_attack()

		# Aim weapons at mouse
		var mouse_pos = input_component.aim_target if input_component else get_global_mouse_position()
		var main_weapon_components = vehicle_combat_component.main_weapons
		for wc in main_weapon_components:
			wc.look_at(mouse_pos)
			wc.rotation_degrees += 90
		var secondary_weapon_components = vehicle_combat_component.secondary_weapons
		for wc in secondary_weapon_components:
			wc.look_at(mouse_pos)
			wc.rotation_degrees += 90
	else:
		movement_component.apply_idle_damping(self)

func _on_body_entered(body: Node2D):
	if body.has_method("show_vehicle_interaction") and not occupied:
		body.show_vehicle_interaction(self)
		_show_interaction_ui(true)

func _on_body_exited(body: Node2D):
	if body.has_method("hide_vehicle_interaction"):
		body.hide_vehicle_interaction()
		_show_interaction_ui(false)

func _show_interaction_ui(should_show: bool):
	if interaction_ui:
		interaction_ui.visible = should_show
	if should_show and interaction_label and vehicle_data:
		interaction_label.text = get_interaction_text()

func can_be_entered() -> bool:
	return not occupied

func enter_vehicle(player: Node2D) -> bool:
	if not can_be_entered():
		return false
	occupied = true
	driver = player
	# Switch camera
	if player.has_node("Camera2D"):
		player_camera = player.get_node("Camera2D")
		player_camera.enabled = false
	if vehicle_camera:
		vehicle_camera.enabled = true
	player.set_in_vehicle_state(true)

	# hide player's weapon components
	var combat = player.actor_combat_component
	if combat:
		for weapon in combat.actor_weapons:
			weapon.visible = false

	return true

func exit_vehicle() -> bool:
	if not occupied:
		return false

	var ejected_player = driver
	occupied = false
	driver = null

	# Stop vehicle movement
	linear_velocity = Vector2.ZERO
	angular_velocity = 0

	# Switch camera back
	if vehicle_camera:
		vehicle_camera.enabled = false
	if player_camera:
		player_camera.enabled = true
		player_camera = null

	# Place player at the vehicle's position and re-enable them
	if ejected_player:
		ejected_player.global_position = global_position
		if ejected_player.has_method("set_in_vehicle_state"):
			ejected_player.set_in_vehicle_state(false)
		
		# Show player's weapon components
		var combat = ejected_player.actor_combat_component
		if combat:
			for weapon in combat.actor_weapons:
				weapon.visible = true

	# reset all weapon components
	var weapon_components = get_tree().get_nodes_in_group("weapon_components")

	for wc in weapon_components:
		wc.rotation = 0 # Reset rotation to face forward with the vehicle
	
	return true

func get_interaction_text() -> String:
	if can_be_entered():
		return "Press E to enter " + (vehicle_data.vehicle_name if vehicle_data else "Vehicle")
	else:
		return "Vehicle occupied"

# Map-related functions
func _on_map_changed(map_id: String, _spawn_position: Vector2):
	_update_visibility_for_current_map()

func _update_visibility_for_current_map():
	# If no map is assigned, vehicle is available on all maps
	if assigned_map_id.is_empty():
		visible = true
		set_physics_process(true)
		return
	
	# Check if current map matches assigned map
	var current_map = MapManager.current_map_id
	var should_be_visible = (assigned_map_id == current_map)
	
	visible = should_be_visible
	set_physics_process(should_be_visible)
	
	# Disable collision when not visible
	if collision:
		collision.disabled = not should_be_visible

# Save/Load support for SaveManager
func save_data() -> Dictionary:
	return {
		"position": {"x": global_position.x, "y": global_position.y},
		"rotation": rotation,
		"occupied": occupied,
		"assigned_map_id": assigned_map_id,
		# Vehicle stats are stored in the vehicle_data resource (not saved per-instance)
	}

func load_data(data: Dictionary) -> void:
	if data.has("position"):
		var pos_data = data["position"]
		if typeof(pos_data) == TYPE_DICTIONARY:
			global_position = Vector2(pos_data.get("x", 0), pos_data.get("y", 0))
		else:
			global_position = pos_data
	if data.has("rotation"):
		rotation = data["rotation"]
	if data.has("occupied"):
		occupied = data["occupied"]
	if data.has("assigned_map_id"):
		assigned_map_id = data["assigned_map_id"]
		# Update visibility based on loaded map assignment
		_update_visibility_for_current_map()
