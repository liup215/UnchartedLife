# save_manager.gd
# A global singleton for managing game saving and loading with multiple slots.
# Uses a typed SaveData resource wrapped in binary for versioned, stable-ID persistence.
extends Node

const SAVE_DIR = "user://saves/"
const SAVE_FILE_EXTENSION = ".dat"
const LEGACY_SAVE_VERSION = 1
const CURRENT_SAVE_VERSION = 2
const MIN_SAVE_SIZE := 50

var _pending_load_data: Dictionary = {}
var _is_loading_save: bool = false  # Flag to track if we're loading from save

# Ensure the save directory exists
func _ready():
	DirAccess.make_dir_absolute(SAVE_DIR)

# --- Core Save/Load Logic ---

func save_game(slot_id: String):
	var file_path = SAVE_DIR.path_join(slot_id + SAVE_FILE_EXTENSION)
	GameLogger.info("save", "Starting save to slot: %s" % slot_id)
	
	# Build typed save data resource
	var metadata = {
		"timestamp": Time.get_unix_time_from_system(),
		"player_name": PlayerData.player_name if PlayerData else ""
	}
	
	var global_data: Dictionary = {}
	if PlayerData:
		global_data["global_player_data"] = PlayerData.save_data()
	if GameProperties:
		global_data["global_game_properties"] = GameProperties.save_data()
	if MapManager:
		global_data["global_map_manager"] = MapManager.save_data()
	
	var node_data: Dictionary = {}
	var saveable_nodes = get_tree().get_nodes_in_group("saveable")
	for node in saveable_nodes:
		if node.has_method("save_data"):
			var node_key: String = _get_node_save_key(node)
			node_data[node_key] = node.call("save_data")
	
	var save_data_resource := SaveData.new(metadata, global_data, node_data)
	var binary_data := var_to_bytes(save_data_resource)
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_32(CURRENT_SAVE_VERSION)
		file.store_32(binary_data.size())
		file.store_buffer(binary_data)
		GameLogger.info("save", "Game saved to %s" % file_path)
	else:
		GameLogger.error("save", "Failed to open save file for writing: %s" % file_path)

func load_game(slot_id: String):
	var file_path = SAVE_DIR.path_join(slot_id + SAVE_FILE_EXTENSION)
	GameLogger.info("save", "Loading game from slot: %s" % slot_id)
	if not FileAccess.file_exists(file_path):
		GameLogger.warn("save", "No save file for slot: %s" % slot_id)
		_is_loading_save = false
		return false
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Failed to open save file for reading: %s" % file_path)
		_is_loading_save = false
		return false
	
	var file_size = file.get_length()
	if file_size < MIN_SAVE_SIZE:
		GameLogger.error("save", "Save file too small to be valid: %s (%d bytes)" % [file_path, file_size])
		_is_loading_save = false
		return false
	
	var version = file.get_32()
	var payload_len = file.get_32()
	
	# Detect legacy non-versioned format (raw Dictionary bytes without header)
	var is_legacy: bool = false
	if version > 1000 or version == 0 or payload_len > file_size:
		is_legacy = true
		file.seek(0)
		payload_len = file_size
	
	var payload = file.get_buffer(payload_len)
	var parsed = bytes_to_var(payload)
	
	var save_data_obj: SaveData = null
	
	if is_legacy and parsed != null and typeof(parsed) == TYPE_DICTIONARY:
		# Legacy v0/v1 format: raw Dictionary -> upgrade to SaveData
		var metadata = parsed.get("metadata", {})
		var global_data: Dictionary = {}
		var node_data: Dictionary = {}
		for key in parsed.keys():
			if key == "metadata":
				continue
			if key.begins_with("global_"):
				global_data[key] = parsed[key]
			else:
				# old key is a NodePath string
				node_data[str(key)] = parsed[key]
		save_data_obj = SaveData.new(metadata, global_data, node_data)
		version = LEGACY_SAVE_VERSION
	elif parsed != null and parsed is SaveData:
		# Modern v2+ format: typed SaveData resource
		save_data_obj = parsed as SaveData
		if save_data_obj == null:
			GameLogger.error("save", "SaveData type cast unexpectedly failed for slot: %s" % slot_id)
			_is_loading_save = false
			return false
	else:
		GameLogger.error("save", "Failed to deserialize save file for slot: %s" % slot_id)
		_is_loading_save = false
		return false
	
	# Version migration
	if save_data_obj.save_version < CURRENT_SAVE_VERSION:
		save_data_obj = SaveData.migrate_from(save_data_obj, save_data_obj.save_version)
	
	# Populate pending load data from the resource
	_pending_load_data = save_data_obj.node_data.duplicate()
	_is_loading_save = true
	
	# Load global singleton data immediately
	var global_map = save_data_obj.global_data
	if PlayerData and global_map.has("global_player_data"):
		PlayerData.load_data(global_map["global_player_data"])
	if GameProperties and global_map.has("global_game_properties"):
		GameProperties.load_data(global_map["global_game_properties"])
	if MapManager and global_map.has("global_map_manager"):
		MapManager.load_data(global_map["global_map_manager"])
	
	if is_legacy:
		GameLogger.info("save", "Legacy v1 save migrated to v%d. Scene data pending." % CURRENT_SAVE_VERSION)
	else:
		GameLogger.info("save", "Save v%d loaded. Scene data is pending." % save_data_obj.save_version)
	return true

func claim_data_for_node(node: Node):
	if _pending_load_data.is_empty():
		return

	var node_key: String = _get_node_save_key(node)
	if _pending_load_data.has(node_key):
		if node.has_method("load_data"):
			GameLogger.debug("save", "Data claimed for node: %s (key=%s)" % [node.name, node_key])
			node.call("load_data", _pending_load_data[node_key])
			_pending_load_data.erase(node_key)
		else:
			push_warning("Node '%s' tried to claim data but has no load_data(data) method." % node.name)

## Internal helper: get the stable save key for a node.
## Uses node.save_id if available and non-empty; otherwise falls back to NodePath.
func _get_node_save_key(node: Node) -> String:
	if "save_id" in node and node.save_id and not node.save_id.is_empty():
		return node.save_id
	return str(node.get_path())

# Check if currently loading from a save file
func is_loading_from_save() -> bool:
	return _is_loading_save

# Reset the loading flag (called after scene is fully loaded)
func reset_loading_flag():
	_is_loading_save = false
	_pending_load_data.clear()

# --- Slot Management ---

func _read_save_payload(file_path: String) -> Dictionary:
	"""Read a save file and return its metadata Dictionary, or {} on failure.
	Handles both versioned SaveData format and legacy unversioned format."""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		GameLogger.error("save", "Failed to open save for reading: %s" % file_path)
		return {}
	
	var file_size = file.get_length()
	if file_size < MIN_SAVE_SIZE:
		GameLogger.warn("save", "Save file too small, skipping: %s" % file_path)
		return {}
	
	var version: int = file.get_32()
	var payload_len: int = file.get_32()
	var is_legacy: bool = false

	# Legacy files have no valid header
	if version > 1000 or version == 0 or payload_len <= 0 or payload_len > file_size:
		is_legacy = true
		file.seek(0)
		payload_len = file_size
	
	var payload: PackedByteArray = file.get_buffer(payload_len)
	var parsed = bytes_to_var(payload)
	
	var save_data_obj: SaveData = null
	if is_legacy and parsed != null and typeof(parsed) == TYPE_DICTIONARY:
		var metadata = parsed.get("metadata", {})
		var global_data: Dictionary = {}
		var node_data: Dictionary = {}
		for key in parsed.keys():
			if key == "metadata":
				continue
			if key.begins_with("global_"):
				global_data[key] = parsed[key]
			else:
				node_data[str(key)] = parsed[key]
		save_data_obj = SaveData.new(metadata, global_data, node_data)
	elif parsed != null and parsed is SaveData:
		save_data_obj = parsed as SaveData
	else:
		GameLogger.warn("save", "Skipping corrupted or incompatible save file: %s" % file_path)
		return {}

	# Ensure metadata exists even for saves that lack it
	var result: Dictionary = save_data_obj.metadata.duplicate()
	result["__save_version__"] = save_data_obj.save_version
	return result


func get_save_slots_metadata() -> Array:
	var metadata_list: Array = []
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(SAVE_FILE_EXTENSION):
				var file_path = SAVE_DIR.path_join(file_name)
				var data: Dictionary = _read_save_payload(file_path)
				if data.has("metadata"):
					var metadata = data["metadata"]
					metadata["slot_id"] = file_name.get_basename()
					metadata_list.append(metadata)
				else:
					GameLogger.warn("save", "Save file missing metadata: %s" % file_name)
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
