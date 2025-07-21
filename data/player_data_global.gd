# player_data_global.gd
# This is an autoload singleton that holds the player's persistent data
# that should be accessible across all scenes.
extends Node

var player_name: String = "Player"
var current_slot: String = ""

# The player's total glucose, which acts as currency and energy source.
var glucose: float = 1000.0
