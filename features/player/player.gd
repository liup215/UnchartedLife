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
    
    # Set player color
    visuals.color = Color.DODGER_BLUE
    
    # After becoming ready, claim any pending save data
    SaveManager.claim_data_for_node(self)

# Player-specific logic will go here, such as input handling.
func _physics_process(delta: float):
    # --- Input and Movement ---
    var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var is_sprinting = Input.is_action_pressed("shift") # Shift key for sprinting
    
    # Calculate movement speed based on sprinting state
    var base_speed = stats_component.get_move_speed()
    var movement_speed = base_speed
    
    if is_sprinting and direction.length() > 0:
        movement_speed = base_speed * 1.8  # 80% speed increase when sprinting
    
    velocity = direction * movement_speed
    move_and_slide()
    
    # --- Biological Processes ---
    _process_metabolism(delta, is_sprinting)

func _process_metabolism(delta: float, is_sprinting: bool = false):
    if not stats_component.data:
        return

    # 1. ATP Consumption (Rest + Movement + Sprinting)
    var base_atp_consumption = 2.0 * delta  # 2 ATP/sec during rest
    var movement_atp_consumption = 0.0
    var sprint_atp_consumption = 0.0
    
    # Check if player is moving (has input)
    var is_moving = velocity.length() > 10.0  # Threshold to detect movement
    if is_moving:
        movement_atp_consumption = 3.0 * delta  # Additional 3 ATP/sec during movement
        
        # Extra consumption when sprinting
        if is_sprinting:
            sprint_atp_consumption = 6.0 * delta  # Additional 6 ATP/sec when sprinting (total: 2+3+6=11 ATP/sec)
    
    var total_atp_consumption = base_atp_consumption + movement_atp_consumption + sprint_atp_consumption
    atp_component.consume_atp(total_atp_consumption)

    # 2. Glucose-Based ATP Recovery (matches actual ATP consumption rate)
    if atp_component.current_atp < atp_component.max_atp:
        # ATP recovery should match the consumption rate to maintain balance
        # This ensures glucose consumption reflects the actual energy demand
        var atp_to_recover = total_atp_consumption  # Match the consumption rate
        
        # Calculate the glucose cost for that much ATP
        var conversion_rate = stats_component.data.atp_conversion_rate
        if conversion_rate > 0:
            var glucose_for_atp = atp_to_recover / conversion_rate
            
            # Check if we have enough glucose
            if PlayerData.glucose >= glucose_for_atp:
                PlayerData.glucose -= glucose_for_atp
                atp_component.recover_atp(atp_to_recover)
            else:
                # Out of glucose! Cannot recover ATP - this will lead to ATP depletion
                pass
    
    # 3. Basal Metabolic Rate (minimal glucose consumption for basic cellular functions)
    # This continues even when ATP is full, representing basic cellular maintenance
    var basal_glucose_cost = stats_component.data.base_metabolic_rate * delta * 0.3  # Reduced to 30% of original rate
    if PlayerData.glucose > 0:
        PlayerData.glucose -= basal_glucose_cost

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
