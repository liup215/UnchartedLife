# goblin.gd
# The main script for the Goblin enemy.
# It extends the base Actor class.
extends "res://features/actor/actor.gd"

enum State { WANDER, CHASE }

var player: Node2D = null
var current_state: State = State.WANDER
var wander_direction: Vector2 = Vector2.ZERO

@onready var detection_radius: float = 400.0
@onready var wander_timer: Timer = $WanderTimer

func _ready():
    # Assign the specific data resource for the goblin.
    stats_component.data = load("res://data/enemies/goblin_data.tres")
    # Call the parent's _ready function to initialize health etc.
    super()
    
    # Now that the actor and its components are ready, initialize health.
    health_component.set_max_health(stats_component.get_max_health())
    
    # Set goblin color
    visuals.color = Color.INDIAN_RED
    # Connect the timer's timeout signal
    wander_timer.timeout.connect(_on_wander_timer_timeout)
    # Initialize the first wander direction
    _update_wander_direction()

func _physics_process(_delta: float):
    # Try to find the player if we haven't already
    if not is_instance_valid(player):
        player = get_tree().get_first_node_in_group("player")

    # If player is found, run AI logic. Otherwise, do nothing.
    if is_instance_valid(player):
        var distance_to_player = global_position.distance_to(player.global_position)
        
        if distance_to_player < detection_radius:
            current_state = State.CHASE
        else:
            current_state = State.WANDER
    else:
        # Player not found, stay in wander state and don't move.
        current_state = State.WANDER
        velocity = Vector2.ZERO
        move_and_slide()
        return

    # --- State Action Logic ---
    match current_state:
        State.WANDER:
            velocity = wander_direction * (stats_component.get_move_speed() * 0.5) # Wander at half speed
        State.CHASE:
            var direction_to_player = global_position.direction_to(player.global_position)
            velocity = direction_to_player * stats_component.get_move_speed()
    
    move_and_slide()

func _on_wander_timer_timeout():
    # This is called every time the WanderTimer finishes
    if current_state == State.WANDER:
        _update_wander_direction()

func _update_wander_direction():
    # Create a new random direction vector
    wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
