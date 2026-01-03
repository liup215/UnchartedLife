extends Node2D

@onready var system_menu = $SystemMenu
@onready var game_scene: Node2D = $GameScene
@onready var player_instance: Node2D = $Player

## Initial game scene to load on start
@export var initial_game_scene: GameSceneData = null

## All available game scenes (for ID lookup)
@export var all_game_scenes: Array[GameSceneData] = []

# Runtime state
var current_scene_instance: Node = null
var loading_screen_instance: Control = null

func _ready():
	# Initialize player first
	_initialize_player()
	
	# Connect signals
	EventBus.request_scene_transition.connect(transition_to_scene)
	
	# If configured, start the initial game scene
	if initial_game_scene:
		call_deferred("start_new_game")

func start_new_game() -> void:
	"""Start a new game with the initial scene"""
	if initial_game_scene:
		load_game_scene(initial_game_scene)
	else:
		push_error("MainGameManager: No initial_game_scene configured!")

func _physics_process(_delta: float) -> void:
	"""Update map chunks based on player position"""
	if is_instance_valid(player_instance):
		MapManager.update_chunks(player_instance.global_position)

# Public API for external access
func get_player() -> Node2D:
	"""Get the player instance"""
	return player_instance

func _initialize_player():
	"""Initialize the persistent player instance"""
	if player_instance:
		# Position player if we have an active game scene
		if game_scene and "game_scene_data" in game_scene and game_scene.game_scene_data:
			_position_player_in_scene(game_scene.game_scene_data)
		print("MainGameManager: Player initialized from scene tree")
	else:
		push_error("MainGameManager: Player node not found in Main scene!")

func transition_to_scene(scene_id: String, spawn_point_id: String = "default") -> void:
	"""Handle scene transition request"""
	print("MainGameManager: Transition requested to '%s' at '%s'" % [scene_id, spawn_point_id])
	var data = _find_scene_data_by_id(scene_id)
	if data:
		load_game_scene(data, spawn_point_id)
	else:
		push_error("MainGameManager: Scene data not found for id: " + scene_id)

func _find_scene_data_by_id(scene_id: String) -> GameSceneData:
	for data in all_game_scenes:
		if data.scene_id == scene_id:
			return data
	return null

func load_game_scene(data: GameSceneData, spawn_point_id: String = "default"):
	"""Load a game level with loading screen"""
	print("MainGameManager: Loading game scene '%s'" % data.scene_name)
	
	# Show loading screen
	_show_loading_screen(null, "Loading " + data.scene_name + "...")
	
	# Wait a frame
	await get_tree().process_frame
	
	# If we have a current sequence scene, clean it up
	if current_scene_instance:
		current_scene_instance.queue_free()
		current_scene_instance = null
	
	# If we have a static game_scene, we can reuse it or replace it.
	# Replacing ensures clean state.
	if game_scene:
		game_scene.queue_free()
	
	# Instantiate new GameScene
	var scene_resource = load("res://scenes/game_scene.tscn")
	if not scene_resource:
		push_error("MainGameManager: Failed to load game_scene.tscn")
		_hide_loading_screen()
		return
		
	game_scene = scene_resource.instantiate()
	
	# Configure it
	game_scene.game_scene_data = data
	
	# Add to tree
	add_child(game_scene)
	# Move to correct position (e.g. before HUD)
	move_child(game_scene, 0)
	
	# Position player
	if player_instance:
		_position_player_in_scene(data, spawn_point_id)
	
	# Hide loading screen
	await get_tree().create_timer(0.5).timeout
	_hide_loading_screen()

func _position_player_in_scene(data: GameSceneData, spawn_point_id: String = "default") -> void:
	"""Position the player based on scene data"""
	if not player_instance:
		return
		
	var target_pos = Vector2.ZERO
	var found_spawn = false
	
	# 1. Try named spawn point
	if data.spawn_points.has(spawn_point_id):
		target_pos = data.spawn_points[spawn_point_id]
		found_spawn = true
		print("MainGameManager: Using named spawn point '%s': %s" % [spawn_point_id, target_pos])
	
	# 2. Fallback to default spawn point if "default" was requested but not found in map
	elif spawn_point_id == "default" and data.player_spawn:
		target_pos = data.player_spawn.spawn_position
		found_spawn = true
		print("MainGameManager: Using legacy default spawn point: %s" % target_pos)
		
	if not found_spawn:
		push_warning("MainGameManager: Could not find spawn point '%s' in scene '%s'" % [spawn_point_id, data.scene_id])
		# Last resort fallback
		if data.player_spawn:
			target_pos = data.player_spawn.spawn_position
	
	# Set player position
	# If loading from save, player position is already set by load_data
	# Otherwise, use the spawn position from game_scene_data
	var should_use_spawn_position: bool = true
	
	if SaveManager and SaveManager.has_method("is_loading_from_save"):
		should_use_spawn_position = not SaveManager.is_loading_from_save()
	
	if should_use_spawn_position:
		player_instance.global_position = target_pos
	else:
		print("MainGameManager: Player position will be loaded from save file")
	
	# If custom player data provided, use it
	if data.player_spawn and data.player_spawn.player_data:
		if player_instance.has_method("set_actor_data"):
			player_instance.set_actor_data(data.player_spawn.player_data)
		elif "actor_data" in player_instance:
			player_instance.actor_data = data.player_spawn.player_data

func _show_loading_screen(image: Texture2D = null, text: String = "Loading..."):
	"""Show the loading screen managed by main scene"""
	if not loading_screen_instance:
		# Load and instantiate loading screen
		var loading_screen_scene = load("res://ui/loading_screen/loading_screen.tscn")
		if loading_screen_scene:
			loading_screen_instance = loading_screen_scene.instantiate()
			add_child(loading_screen_instance)
	
	# Configure and show
	if loading_screen_instance:
		if image and loading_screen_instance.has_method("set_image"):
			loading_screen_instance.set_image(image)
		if text and loading_screen_instance.has_method("set_text"):
			loading_screen_instance.set_text(text)
		if loading_screen_instance.has_method("show_loading_screen"):
			loading_screen_instance.show_loading_screen()

func _hide_loading_screen():
	"""Hide the loading screen"""
	if loading_screen_instance and loading_screen_instance.has_method("hide_loading_screen"):
		loading_screen_instance.hide_loading_screen()

func _unhandled_input(event):
	# Using the built-in "ui_cancel" action, which is mapped to Escape by default.
	if event.is_action_pressed("ui_cancel"):
		if system_menu.visible:
			system_menu.close_menu()
		else:
			system_menu.open_menu()
