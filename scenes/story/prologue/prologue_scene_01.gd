extends Node2D

## Prologue Scene 01
## First playable scene after the opening animation
## Introduces the player to the basic game world

@onready var player: CharacterBody2D = $Player
@onready var spawn_point: Marker2D = $SpawnPoint

var scene_initialized: bool = false

func _ready() -> void:
	# Initialize scene
	_setup_scene()
	
	# Position player at spawn point
	if player and spawn_point:
		player.global_position = spawn_point.global_position
	
	# Mark scene as initialized
	scene_initialized = true
	
	# Emit event for story tracking
	EventBus.emit_signal("story_scene_entered", "prologue_01")
	
	print("Prologue Scene 01 loaded successfully")

func _setup_scene() -> void:
	"""Initialize scene-specific setup"""
	# Unpause the game
	get_tree().paused = false
	
	# Ensure player input is enabled
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Connect to any necessary signals
	_connect_signals()

func _connect_signals() -> void:
	"""Connect to required EventBus signals"""
	# Example: Connect to dialogue events, quest events, etc.
	pass

func _on_exit_area_entered(area: Area2D) -> void:
	"""Called when player reaches the exit of this scene"""
	# Transition to next prologue scene or main game
	print("Prologue scene 01 complete, transitioning to main game...")
	
	# For now, transition to the main game scene
	# In the future, this could go to prologue_scene_02.tscn
	SceneManager.SwitchToScene("res://scenes/main.tscn")
