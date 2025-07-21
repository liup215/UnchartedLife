extends CanvasLayer

@onready var player_name_label: Label = $MarginContainer/VBoxContainer/PlayerNameLabel
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthContainer/HealthBar
@onready var health_value: Label = $MarginContainer/VBoxContainer/HealthContainer/HealthBar/HealthValue
@onready var atp_bar: ProgressBar = $MarginContainer/VBoxContainer/ATPContainer/ATPBar
@onready var atp_value: Label = $MarginContainer/VBoxContainer/ATPContainer/ATPBar/ATPValue
@onready var glucose_label: Label = $MarginContainer/VBoxContainer/GlucoseLabel

var player: Actor = null

func _ready():
    # Wait until the scene tree is ready to find the player
    get_tree().node_added.connect(_on_node_added)
    _find_player()
    
    # Initial glucose update
    if PlayerData:
        _update_glucose_label()

func _find_player():
    # Try to find the player in the scene
    var player_nodes = get_tree().get_nodes_in_group("player")
    if not player_nodes.is_empty():
        player = player_nodes[0]
        _on_player_ready(player)

func _on_node_added(node):
    # If the player is added to the scene later, we can find them here.
    if node.is_in_group("player"):
        player = node
        _on_player_ready(player)

func _on_player_ready(player_node: Actor):
    # Connect to the player's signals to update the HUD
    player_node.actor_health_changed.connect(_on_player_health_changed)
    
    # Check if the player has an ATP component before connecting
    if player_node.has_node("ATPComponent"):
        var atp_component = player_node.get_node("ATPComponent")
        atp_component.atp_changed.connect(_on_player_atp_changed)
        # Set initial ATP value
        _on_player_atp_changed(atp_component.get_current_atp(), atp_component.get_max_atp())

    # Set initial health value
    _on_player_health_changed(
        player_node.health_component.get_current_health(),
        player_node.health_component.get_max_health()
    )
    
    # Update player name
    if PlayerData:
        player_name_label.text = PlayerData.player_name

func _on_player_health_changed(current_health: int, max_health: int):
    health_bar.max_value = max_health
    health_bar.value = current_health
    health_value.text = "%d/%d" % [current_health, max_health]

func _on_player_atp_changed(current_atp: int, max_atp: int):
    atp_bar.max_value = max_atp
    atp_bar.value = current_atp
    atp_value.text = "%d/%d" % [current_atp, max_atp]

func _physics_process(_delta):
    # Continuously update glucose, as it can change frequently
    if PlayerData:
        _update_glucose_label()

func _update_glucose_label():
    glucose_label.text = "Glucose: %.1f" % PlayerData.glucose
