extends CanvasLayer

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthContainer/HealthBar
@onready var health_value_label: Label = $MarginContainer/VBoxContainer/HealthContainer/HealthBar/HealthValue
@onready var player_name_label: Label = $MarginContainer/VBoxContainer/PlayerNameLabel

func _ready():
    # Set the player name from the global data
    player_name_label.text = PlayerData.player_name

    # Connect to the global event bus to listen for health changes
    EventBus.actor_health_changed.connect(_on_actor_health_changed)

func _on_actor_health_changed(actor: Node, current_health: int, max_health: int):
    # Only update the HUD if the health change is for the player
    if actor.is_in_group("player"):
        update_health_display(current_health, max_health)

func update_health_display(current: int, max_value: int):
    health_bar.max_value = max_value
    health_bar.value = current
    health_value_label.text = "%d/%d" % [current, max_value]
