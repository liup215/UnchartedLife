# player.gd
# The main script for the player character.
# It extends the base Actor class.
extends "res://features/actor/actor.gd"

func _ready():
    # Assign the specific data resource for the player.
    stats_component.data = load("res://data/items/player_data.tres")
    # Call the parent's _ready function to initialize health etc.
    super()
    
    # Programmatically add to groups to ensure timing is correct.
    add_to_group("player")
    add_to_group("saveable")
    
    # Now that the actor and its components are ready, initialize health.
    health_component.set_max_health(stats_component.get_max_health())
    
    # Set player color
    visuals.color = Color.DODGER_BLUE
    
    # After becoming ready, claim any pending save data
    SaveManager.claim_data_for_node(self)

# Player-specific logic will go here, such as input handling.
func _physics_process(_delta: float):
    # Example movement logic
    var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    velocity = direction * stats_component.get_move_speed()
    move_and_slide()

# --- Save/Load Interface ---

func save_data() -> Dictionary:
    return {
        "position_x": position.x,
        "position_y": position.y,
        "current_health": health_component.current_health
    }

func load_data(data: Dictionary):
    position.x = data.get("position_x", position.x)
    position.y = data.get("position_y", position.y)
    
    # Set health, ensuring it doesn't exceed max health
    var loaded_health = data.get("current_health", health_component.max_health)
    health_component.current_health = loaded_health
    
    # We also need to update the HUD after loading
    # The health_changed signal will do this automatically when we set health.
