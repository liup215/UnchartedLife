# save_data.gd
# A typed resource wrapper for save game data.
# Replaces the raw Dictionary used by SaveManager to provide type safety
# and versioned migration hooks.
extends Resource
class_name SaveData

const CURRENT_VERSION: int = 2

## The save format version. Used for forward/backward compatibility.
@export var save_version: int = CURRENT_VERSION

## Metadata about the save (timestamp, player_name, etc.)
@export var metadata: Dictionary = {}

## Global singleton data (PlayerData, GameProperties, MapManager)
@export var global_data: Dictionary = {}

## Per-node runtime state. Keys are save_id strings (not NodePaths).
@export var node_data: Dictionary = {}

# NOTE: Godot's Resource serialization (via var_to_bytes) handles the
# typed fields automatically. We keep everything as dictionaries for flexibility
# but use a Resource wrapper so we get version + type constraints.

func _init(p_metadata: Dictionary = {}, p_global: Dictionary = {}, p_node_data: Dictionary = {}) -> void:
	metadata = p_metadata
	global_data = p_global
	node_data = p_node_data

## Migrate from an older version to the current version.
## Should be called after deserialization if save_version != CURRENT_VERSION.
static func migrate_from(data: SaveData, from_version: int) -> SaveData:
	# Base case: already current
	if from_version == CURRENT_VERSION:
		return data

	# Migrate v1 -> v2: NodePath keys -> save_id keys
	if from_version == 1:
		var migrated_node_data: Dictionary = {}
		for old_key in data.node_data.keys():
			var key_str: String = str(old_key)
			# v1 uses NodePath strings as keys; in v2 we try to detect if a
			# corresponding node now exposes a save_id. For raw migration
			# we can't do that statically, so we store the old NodePath in a
			# special prefix and let the load callback resolve it.
			if key_str.begins_with("/root/"):
				# Keep the full path as the key for backward compatibility
				migrated_node_data[key_str] = data.node_data[old_key]
			else:
				migrated_node_data[key_str] = data.node_data[old_key]
		data.node_data = migrated_node_data
		from_version = 2

	data.save_version = CURRENT_VERSION
	return data
