# save_manager.gd
# A global singleton for managing game saving and loading with multiple slots.
extends Node

const SAVE_DIR = "user://saves/"
const SAVE_FILE_EXTENSION = ".dat"

var _pending_load_data: Dictionary = {}

# Ensure the save directory exists
func _ready():
	DirAccess.make_dir_absolute(SAVE_DIR)

# --- Core Save/Load Logic ---

func save_game(slot_id: String):
	var file_path = SAVE_DIR.path_join(slot_id + SAVE_FILE_EXTENSION)
	print("Starting to save game to slot: %s" % slot_id)
	var save_data = {}
	
	# Add metadata for the save slot menu
	save_data["metadata"] = {
		"timestamp": Time.get_unix_time_from_system(),
		"player_name": PlayerData.player_name
	}
	
	# Handle global data singletons explicitly
	if PlayerData:
		save_data["global_player_data"] = PlayerData.save_data()
	
	# Get all nodes in the "saveable" group
	var saveable_nodes = get_tree().get_nodes_in_group("saveable")
	
	for node in saveable_nodes:
		if node.has_method("save_data"):
			save_data[node.get_path()] = node.call("save_data")
			
	# Save the dictionary to a file
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data, "\t")
		file.store_string(json_string)
		print("Game saved successfully to %s" % file_path)
	else:
		push_error("Failed to open save file for writing: %s" % file_path)

func load_game(slot_id: String):
	var file_path = SAVE_DIR.path_join(slot_id + SAVE_FILE_EXTENSION)
	print("Attempting to load game from slot: %s" % slot_id)
	if not FileAccess.file_exists(file_path):
		print("No save file found for slot: %s" % slot_id)
		return false
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var parse_result = JSON.parse_string(json_string)
		if parse_result != null:
			_pending_load_data = parse_result
			# Load global data immediately
			if PlayerData and _pending_load_data.has("global_player_data"):
				PlayerData.load_data(_pending_load_data["global_player_data"])
				_pending_load_data.erase("global_player_data")
			print("Save file loaded successfully. Scene data is pending.")
			return true
		else:
			push_error("Failed to parse save file JSON for slot: %s" % slot_id)
			_pending_load_data = {}
			return false
	else:
		push_error("Failed to open save file for reading: %s" % file_path)
		return false

func claim_data_for_node(node: Node):
	if _pending_load_data.is_empty():
		return

	var node_path = node.get_path()
	if _pending_load_data.has(node_path):
		if node.has_method("load_data"):
			print("Data claimed by and loaded for node: %s" % node_path)
			node.call("load_data", _pending_load_data[node_path])
			_pending_load_data.erase(node_path)
		else:
			push_warning("Node '%s' tried to claim data but has no load_data(data) method." % node.name)

# --- Slot Management ---

func get_save_slots_metadata() -> Array:
	var metadata_list = []
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(SAVE_FILE_EXTENSION):
				var file_path = SAVE_DIR.path_join(file_name)
				var file = FileAccess.open(file_path, FileAccess.READ)
				if file:
					var json_string = file.get_as_text()
					var data = JSON.parse_string(json_string)
					if data and data.has("metadata"):
						var metadata = data["metadata"]
						metadata["slot_id"] = file_name.get_basename()
						metadata_list.append(metadata)
			file_name = dir.get_next()
	else:
		push_error("Failed to open saves directory: %s" % SAVE_DIR)
	
	# Sort by timestamp, newest first
	metadata_list.sort_custom(func(a, b): return a.timestamp > b.timestamp)
	return metadata_list

func get_latest_slot_id() -> String:
	var metadata_list = get_save_slots_metadata()
	if not metadata_list.is_empty():
		return metadata_list[0].slot_id
	return ""

func create_new_slot_id() -> String:
	# Generate a unique ID based on the current timestamp
	return str(Time.get_unix_time_from_system())

func has_any_save_file() -> bool:
	return not get_save_slots_metadata().is_empty()
