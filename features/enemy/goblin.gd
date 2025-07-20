# goblin.gd
# The main script for the Goblin enemy.
# It extends the base Actor class.
extends "res://features/actor/actor.gd"

func _ready():
    # Assign the specific data resource for the goblin.
    stats_component.data = load("res://data/enemies/goblin_data.tres")
    # Call the parent's _ready function to initialize health etc.
    super()
    # Set goblin color
    visuals.color = Color.INDIAN_RED

# Enemy-specific logic will go here, such as AI.
func _physics_process(_delta: float):
    # Placeholder AI: move in a circle
    velocity = Vector2(1, 0).rotated(Time.get_ticks_msec() / 1000.0) * stats_component.get_move_speed()
    move_and_slide()
