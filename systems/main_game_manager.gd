extends Node2D

@onready var system_menu = $SystemMenu
@onready var player: Node2D = $Player
@onready var map_container: Node2D = Node2D.new()

# Prologue scene reference
const PROLOGUE_SCENE_02 = preload("res://scenes/story/prologue/prologue_scene_02.tscn")
var prologue_scene_instance: Node2D = null

func _ready():
	# Add a container for the map chunks to ensure they are rendered behind other nodes.
	map_container.name = "MapContainer"
	add_child(map_container)
	move_child(map_container, 0) # Move to the back (rendered first)
	
	# Set the parent for the map manager to add chunks to.
	MapManager.set_map_parent(map_container)
	
	# Initialize player position based on current map
	_initialize_player_position()
	
	# Check if we should load the prologue (glucose game) on first entry
	_check_and_load_prologue()
	
	# Initial map load
	if is_instance_valid(player):
		MapManager.update_chunks(player.global_position)

func _check_and_load_prologue():
	"""Check if this is the first time entering main scene and load prologue if needed"""
	# Check if coming from prologue_scene_01 (microscope) - if so, load glucose game
	# You can use PlayerData or a flag to track this
	# For now, we'll check if a specific flag is set
	if PlayerData.has("completed_microscope_tutorial") and not PlayerData.has("completed_glucose_tutorial"):
		_load_prologue_scene_02()

func _load_prologue_scene_02():
	"""Load the glucose identification game as an overlay"""
	if prologue_scene_instance:
		return  # Already loaded
	
	prologue_scene_instance = PROLOGUE_SCENE_02.instantiate()
	add_child(prologue_scene_instance)
	
	# Position player for prologue
	if is_instance_valid(player):
		player.global_position = Vector2(200, 450)
	
	# Connect to prologue completion signal if available
	if prologue_scene_instance.has_signal("prologue_completed"):
		prologue_scene_instance.prologue_completed.connect(_on_prologue_completed)

func _on_prologue_completed():
	"""Called when the glucose prologue is completed"""
	if prologue_scene_instance:
		prologue_scene_instance.queue_free()
		prologue_scene_instance = null
	
	# Mark as completed
	PlayerData.set("completed_glucose_tutorial", true)

func _initialize_player_position():
	# If loading from save, player position is already set by load_data
	# Otherwise, use the default spawn position from current map
	if is_instance_valid(player) and MapManager.current_map_data:
		# Check if this is a new game using SaveManager flag
		if not SaveManager.is_loading_from_save():
			player.global_position = MapManager.current_map_data.default_spawn_position
			print("MainGameManager: Set player position to map default: ", player.global_position)
		else:
			print("MainGameManager: Player position loaded from save file")

func _physics_process(_delta):
	# Continuously update the map based on player position
	if is_instance_valid(player):
		MapManager.update_chunks(player.global_position)

func _unhandled_input(event):
	# Using the built-in "ui_cancel" action, which is mapped to Escape by default.
	if event.is_action_pressed("ui_cancel"):
		if system_menu.visible:
			system_menu.close_menu()
		else:
			system_menu.open_menu()
