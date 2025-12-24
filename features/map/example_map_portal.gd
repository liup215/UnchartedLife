# example_map_portal.gd
# Example implementation of a portal/door that switches between maps
extends Area2D

# The map to switch to when player enters
@export var target_map_id: String = ""

# The position where player spawns in the target map
@export var target_spawn_position: Vector2 = Vector2.ZERO

# Visual feedback
@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

func _ready():
	# Connect to body entered and exited signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Update label text
	if label and not target_map_id.is_empty():
		label.text = "Portal to %s\nPress E" % target_map_id

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		# Show interaction prompt
		if label:
			label.visible = true

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		# Hide interaction prompt
		if label:
			label.visible = false

func _input(event):
	# Check if player is near and presses E
	if event.is_action_pressed("enter_vehicle"): # Reusing the E key
		var overlapping_bodies = get_overlapping_bodies()
		for body in overlapping_bodies:
			if body.is_in_group("player"):
				_activate_portal(body)
				break

func _activate_portal(player: Node2D):
	if target_map_id.is_empty():
		print("Portal: No target map set!")
		return
	
	# Check if target map exists
	var target_map = MapManager.get_map_data(target_map_id)
	if not target_map:
		print("Portal: Target map '%s' not found!" % target_map_id)
		return
	
	# Use provided spawn position or map's default
	var spawn_pos = target_spawn_position if target_spawn_position != Vector2.ZERO else target_map.default_spawn_position
	
	# Switch to the target map
	if MapManager.switch_to_map(target_map_id, spawn_pos):
		# Move player to spawn position
		player.global_position = spawn_pos
		print("Portal: Teleported to %s at %s" % [target_map_id, spawn_pos])
