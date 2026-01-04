# vascular_maze_generator.gd
# A standalone vascular maze generator that simulates blood vessel systems.
# Uses a layered graph approach to create artery -> capillary -> vein progression.
# This script can be attached to a scene root node to generate a specific vascular level.
extends Node2D

class_name VascularMazeGenerator

# Export variables for configuration
@export_group("Scene References")
@export var wall_scene: PackedScene  ## Epithelial cell sprite scene for vessel walls
@export var valve_scene: PackedScene  ## One-way valve scene for branch points
@export var player_spawn_marker: Marker2D  ## Marker for player start position

@export_group("Generation Parameters")
@export var layer_count: int = 8  ## Number of layers in the maze
@export var total_length: float = 5000.0  ## Total length of the vessel system
@export var vessel_width_base: float = 100.0  ## Base width for vessels

@export_group("Segment Ratios")
@export var artery_ratio: float = 0.2  ## Artery segment as portion of total (default 20%)
@export var capillary_ratio: float = 0.6  ## Capillary segment as portion of total (default 60%)
@export var vein_ratio: float = 0.2  ## Vein segment as portion of total (default 20%)

@export_group("Vessel Properties")
@export var artery_width_multiplier: float = 1.5  ## Width multiplier for arteries
@export var capillary_width_multiplier: float = 0.6  ## Width multiplier for capillaries
@export var vein_width_multiplier: float = 2.0  ## Width multiplier for veins
@export var artery_flow_speed: float = 500.0  ## Flow push force in arteries
@export var capillary_flow_speed: float = 150.0  ## Flow push force in capillaries
@export var vein_flow_speed: float = 300.0  ## Flow push force in veins

@export_group("Wall Properties")
@export var wall_spacing: float = 20.0  ## Distance between wall sprites
@export var wall_offset: float = 50.0  ## Distance from path centerline to walls
@export var capillary_gap_chance: float = 0.15  ## Chance to skip walls in capillaries (0.0-1.0)

@export_group("Teleport Loop")
@export var enable_loop: bool = true  ## Enable teleport loop at end

# Internal variables
var vessel_layers: Array[Array] = []  ## Array of layers, each containing node positions
var vessel_paths: Array[Curve2D] = []  ## All generated vessel path curves
var start_position: Vector2 = Vector2.ZERO
var end_position: Vector2 = Vector2.ZERO

## Vessel segment types
enum SegmentType {
	ARTERY,
	CAPILLARY,
	VEIN
}

func _ready() -> void:
	# Only generate if not in editor mode
	if not Engine.is_editor_hint():
		call_deferred("generate_maze")

## Main generation function - creates the complete vascular maze
func generate_maze() -> void:
	print("VascularMazeGenerator: Starting maze generation...")
	
	# Clear any existing children (except exported nodes)
	_clear_generated_content()
	
	# Initialize
	vessel_layers.clear()
	vessel_paths.clear()
	
	# Calculate segment lengths
	var artery_length: float = total_length * artery_ratio
	var capillary_length: float = total_length * capillary_ratio
	var vein_length: float = total_length * vein_ratio
	
	# Set start position (use marker if available)
	if player_spawn_marker:
		start_position = player_spawn_marker.global_position
	else:
		start_position = global_position
	
	# Generate layered structure
	_generate_layers()
	
	# Build vessel segments
	var current_x: float = start_position.x
	
	# Artery segment (first 20%)
	print("VascularMazeGenerator: Generating artery segment...")
	_build_vessel_segment(
		SegmentType.ARTERY,
		current_x,
		artery_length,
		0,
		max(1, layer_count / 4)  # Use fewer layers for artery
	)
	current_x += artery_length
	
	# Capillary segment (middle 60%)
	print("VascularMazeGenerator: Generating capillary segment...")
	_build_vessel_segment(
		SegmentType.CAPILLARY,
		current_x,
		capillary_length,
		max(1, layer_count / 4),
		layer_count
	)
	current_x += capillary_length
	
	# Vein segment (last 20%)
	print("VascularMazeGenerator: Generating vein segment...")
	_build_vessel_segment(
		SegmentType.VEIN,
		current_x,
		vein_length,
		max(1, layer_count / 4),
		0  # Converge back to single point
	)
	current_x += vein_length
	
	end_position = Vector2(current_x, start_position.y)
	
	# Add teleport loop trigger at the end
	if enable_loop:
		_create_loop_trigger()
	
	print("VascularMazeGenerator: Maze generation complete!")
	print("  - Total paths: %d" % vessel_paths.size())
	print("  - Start: %v" % start_position)
	print("  - End: %v" % end_position)

## Generate the layered node structure
func _generate_layers() -> void:
	# Create vertical layers for the graph structure
	for i in range(layer_count):
		vessel_layers.append([])

## Build a vessel segment with specific properties
## Uses Curve2D to create smooth paths with proper tangent calculations
func _build_vessel_segment(
	segment_type: SegmentType,
	start_x: float,
	length: float,
	start_layer_range: int,
	end_layer_range: int
) -> void:
	
	var segment_properties := _get_segment_properties(segment_type)
	var num_paths: int = segment_properties.num_paths
	var width_mult: float = segment_properties.width_multiplier
	var flow_speed: float = segment_properties.flow_speed
	var has_gaps: bool = segment_properties.has_gaps
	
	# Determine layer distribution
	var path_layers: Array[int] = []
	
	if segment_type == SegmentType.ARTERY:
		# Few paths, mostly straight
		for i in range(num_paths):
			path_layers.append(i % max(1, start_layer_range))
	elif segment_type == SegmentType.CAPILLARY:
		# Many paths across all layers
		for i in range(num_paths):
			path_layers.append(randi() % layer_count)
	else:  # VEIN
		# Converging paths
		for i in range(num_paths):
			path_layers.append(i % max(1, start_layer_range))
	
	# Generate paths
	for i in range(num_paths):
		var curve := Curve2D.new()
		
		# Starting point
		var start_y: float = start_position.y + (path_layers[i] - layer_count / 2.0) * (vessel_width_base * 2)
		var start_point := Vector2(start_x, start_y)
		
		# Ending point
		var end_y: float
		if segment_type == SegmentType.VEIN:
			# Converge to center
			end_y = start_position.y + (randf() - 0.5) * vessel_width_base * 0.5
		elif segment_type == SegmentType.ARTERY:
			# Slight divergence
			end_y = start_y + (randf() - 0.5) * vessel_width_base
		else:
			# Random capillary meandering
			end_y = start_position.y + (randi() % layer_count - layer_count / 2.0) * (vessel_width_base * 2)
		
		var end_point := Vector2(start_x + length, end_y)
		
		# Add curve points
		curve.add_point(start_point)
		
		# Add intermediate waypoints for curved paths
		var num_waypoints: int = 3 if segment_type == SegmentType.CAPILLARY else 1
		for j in range(num_waypoints):
			var t: float = (j + 1.0) / (num_waypoints + 1.0)
			var waypoint_x: float = start_x + length * t
			var waypoint_y: float = lerp(start_y, end_y, t)
			
			# Add variation for capillaries
			if segment_type == SegmentType.CAPILLARY:
				waypoint_y += (randf() - 0.5) * vessel_width_base * 1.5
			
			curve.add_point(Vector2(waypoint_x, waypoint_y))
		
		curve.add_point(end_point)
		
		# Store the path
		vessel_paths.append(curve)
		
		# Generate walls along this path
		_generate_walls_along_path(curve, width_mult, has_gaps)
		
		# Generate flow field along path
		_generate_flow_field_along_path(curve, flow_speed)
		
		# Add valves at branch points (mainly for arteries)
		if segment_type == SegmentType.ARTERY and valve_scene and i % 2 == 0:
			_add_valve_at_point(start_point)

## Get properties for a specific segment type
func _get_segment_properties(segment_type: SegmentType) -> Dictionary:
	match segment_type:
		SegmentType.ARTERY:
			return {
				"num_paths": max(2, layer_count / 4),
				"width_multiplier": artery_width_multiplier,
				"flow_speed": artery_flow_speed,
				"has_gaps": false
			}
		SegmentType.CAPILLARY:
			return {
				"num_paths": layer_count * 3,
				"width_multiplier": capillary_width_multiplier,
				"flow_speed": capillary_flow_speed,
				"has_gaps": true
			}
		SegmentType.VEIN:
			return {
				"num_paths": max(2, layer_count / 3),
				"width_multiplier": vein_width_multiplier,
				"flow_speed": vein_flow_speed,
				"has_gaps": false
			}
	
	return {}

## Generate wall sprites along a vessel path
## Uses tangent calculation to properly orient sprites
func _generate_walls_along_path(curve: Curve2D, width_multiplier: float, has_gaps: bool) -> void:
	if not wall_scene:
		return
	
	var path_length := curve.get_baked_length()
	var current_distance: float = 0.0
	var wall_width := vessel_width_base * width_multiplier
	
	while current_distance < path_length:
		# Get position and tangent at current distance
		var position := curve.sample_baked(current_distance)
		var transform := curve.sample_baked_with_rotation(current_distance)
		var rotation_angle := transform.get_rotation()
		
		# Calculate perpendicular offset for walls
		var perpendicular := Vector2(-sin(rotation_angle), cos(rotation_angle))
		
		# Left wall
		if not has_gaps or randf() > capillary_gap_chance:
			var left_wall := wall_scene.instantiate() as Node2D
			left_wall.global_position = position + perpendicular * (wall_width / 2.0)
			left_wall.rotation = rotation_angle
			add_child(left_wall)
		
		# Right wall
		if not has_gaps or randf() > capillary_gap_chance:
			var right_wall := wall_scene.instantiate() as Node2D
			right_wall.global_position = position - perpendicular * (wall_width / 2.0)
			right_wall.rotation = rotation_angle + PI  # Face opposite direction
			add_child(right_wall)
		
		current_distance += wall_spacing

## Generate flow field (push forces) along a vessel path
func _generate_flow_field_along_path(curve: Curve2D, flow_speed: float) -> void:
	var path_length := curve.get_baked_length()
	var field_spacing: float = 100.0  # Distance between flow field areas
	var current_distance: float = 0.0
	
	while current_distance < path_length:
		var position := curve.sample_baked(current_distance)
		var transform := curve.sample_baked_with_rotation(current_distance)
		var rotation_angle := transform.get_rotation()
		
		# Create flow field area
		var flow_area := Area2D.new()
		flow_area.name = "FlowField"
		flow_area.global_position = position
		
		# Add collision shape
		var collision_shape := CollisionShape2D.new()
		var circle_shape := CircleShape2D.new()
		circle_shape.radius = 80.0
		collision_shape.shape = circle_shape
		flow_area.add_child(collision_shape)
		
		# Store flow direction and speed as metadata
		flow_area.set_meta("flow_direction", Vector2(cos(rotation_angle), sin(rotation_angle)))
		flow_area.set_meta("flow_speed", flow_speed)
		
		add_child(flow_area)
		
		# Connect signal to apply force to player
		flow_area.body_entered.connect(_on_flow_field_entered.bind(flow_area))
		
		current_distance += field_spacing

## Handle player entering flow field
func _on_flow_field_entered(body: Node2D, flow_area: Area2D) -> void:
	if body.is_in_group("player"):
		var flow_direction: Vector2 = flow_area.get_meta("flow_direction", Vector2.RIGHT)
		var flow_speed: float = flow_area.get_meta("flow_speed", 100.0)
		
		# Apply force to player (this is a simple example)
		# In a real implementation, you'd want a more sophisticated physics system
		if body.has_method("apply_force"):
			body.apply_force(flow_direction * flow_speed)
		elif body is CharacterBody2D:
			# For CharacterBody2D, adjust velocity
			body.velocity += flow_direction * flow_speed * 0.1

## Add a valve at a specific point
func _add_valve_at_point(point: Vector2) -> void:
	if not valve_scene:
		return
	
	var valve := valve_scene.instantiate() as Node2D
	valve.global_position = point
	add_child(valve)

## Create a teleport trigger at the end that loops back to start
func _create_loop_trigger() -> void:
	var trigger := Area2D.new()
	trigger.name = "LoopTrigger"
	trigger.global_position = end_position
	
	# Add collision shape
	var collision_shape := CollisionShape2D.new()
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = 50.0
	collision_shape.shape = circle_shape
	trigger.add_child(collision_shape)
	
	# Connect signal
	trigger.body_entered.connect(_on_loop_trigger_entered)
	
	add_child(trigger)
	
	print("VascularMazeGenerator: Loop trigger created at %v" % end_position)

## Handle player entering loop trigger
func _on_loop_trigger_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("VascularMazeGenerator: Player reached end, teleporting to start")
		body.global_position = start_position
		# Optional: emit signal for game events
		if EventBus.has_signal("vascular_loop_completed"):
			EventBus.emit_signal("vascular_loop_completed")

## Clear previously generated content (keep exported references)
func _clear_generated_content() -> void:
	# Remove all children except those that are exported or special
	for child in get_children():
		if child != player_spawn_marker:
			child.queue_free()
