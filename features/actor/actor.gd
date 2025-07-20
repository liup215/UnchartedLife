# actor.gd
# The base script for all "living" entities in the game.
# It requires a HealthComponent and a StatsComponent to be present as children.
class_name Actor
extends CharacterBody2D

@onready var stats_component: StatsComponent = $StatsComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var visuals: Polygon2D = $Visuals

func _ready():
    # Ensure components are valid
    assert(stats_component, "StatsComponent is missing from Actor.")
    assert(health_component, "HealthComponent is missing from Actor.")

    # Initialize health from stats data
    var max_health_from_stats = stats_component.get_max_health()
    health_component.set_max_health(max_health_from_stats)

    # Connect to the health component's signals
    health_component.died.connect(_on_died)
    health_component.health_changed.connect(_on_health_changed)

func take_damage(damage_amount: int):
    if health_component.current_health == 0:
        return # Already dead, no need to process damage

    health_component.take_damage(damage_amount)

func _on_health_changed(current_health: int, max_health: int):
    EventBus.actor_health_changed.emit(self, current_health, max_health)

func _on_died():
    EventBus.actor_died.emit(self)

    # Immediately disable further processing and collision.
    set_physics_process(false)
    set_process(false)
    if get_node_or_null("CollisionShape2D"):
        get_node("CollisionShape2D").disabled = true

    # In a real game, you would handle death logic here,
    # like playing an animation, dropping loot, before finally freeing the node.
    # For now, we just free it after a short delay to allow animations to play.
    var timer = get_tree().create_timer(1.0)
    timer.timeout.connect(queue_free)
