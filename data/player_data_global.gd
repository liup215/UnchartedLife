# player_data_global.gd
# An autoload singleton to store persistent player data across scenes.
class_name PlayerDataGlobal
extends Node

var player_name: String = "Player"
var current_save_slot_id: String = "" # Empty means it's a new, unsaved game

# You can add more persistent data here, e.g.:
# var level: int = 1
# var experience: int = 0

# --- Save/Load Interface ---

func save_data() -> Dictionary:
    return {
        "player_name": player_name
    }

func load_data(data: Dictionary):
    player_name = data.get("player_name", "Player")
