# goblin.gd
# The main script for the Goblin enemy.
# It extends the base Actor class.
extends "res://features/actor/actor.gd"

func _ready():
	# Assign the specific data resource for the goblin.
	# This will be set by the spawner in a real game, 
	# but we load it directly here for testing.
	if not actor_data:
		actor_data = load("res://data/enemies/goblin_data.tres")
	
	# Call the parent's _ready function to initialize health, behaviors etc.
	super()

	# Set goblin color
	visuals.color = Color.INDIAN_RED
