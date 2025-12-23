extends Node2D

@onready var system_menu = $SystemMenu
@onready var player: Node2D = $Player
@onready var map_container: Node2D = Node2D.new()

func _ready():
	# Add a container for the map chunks to ensure they are rendered behind other nodes.
	map_container.name = "MapContainer"
	add_child(map_container)
	move_child(map_container, 0) # Move to the back (rendered first)
	
	# Set the parent for the map manager to add chunks to.
	MapManager.set_map_parent(map_container)
	
	# Initialize player position based on current map
	_initialize_player_position()
	
	# Initial map load
	if is_instance_valid(player):
		MapManager.update_chunks(player.global_position)

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
